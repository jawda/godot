class_name FloorMapGenerator
extends RefCounted

## Generates a FloorMapData using a column-based flowchart layout.
##
## Usage:
##   var floor_map: FloorMapData = FloorMapGenerator.generate(floor_data)
##
## Pipeline:
##   1. Pick a random column count (8–10, including START and BOSS end-caps)
##   2. Assign 1–3 rooms per middle column; START and BOSS columns always have 1
##   3. Position rooms — columns evenly spaced left-to-right, rows distributed top-to-bottom
##   4. Connect rooms forward: each room wires to 1–2 rooms in the next column,
##      preferring vertically close neighbours to minimise line crossings
##   5. Guarantee every room has at least one incoming and one outgoing connection
##   6. Assign room types — each type has a minimum column fraction before it may appear,
##      so early columns never spawn REST/ELITE/SHOP before the player is ready
##   7. Guarantee at least one REST; clear REST/SHOP from boss-adjacent rooms
##   8. Assign enemy/event payloads

# ── Layout constants ───────────────────────────────────────────────────────────

## Fixed size of every room node. Rooms are a comfortable readable size; the map
## scrolls horizontally instead of squeezing rooms to fit the viewport.
const ROOM_SIZE: Vector2i = Vector2i(90, 52)

## Pixel distance between adjacent column centres.
## Corridor gap = COL_SPACING − ROOM_SIZE.x  (currently 60 px).
const COL_SPACING: float = 150.0

## Vertical canvas height used for row placement. Room y-positions span
## 0–CANVAS_HEIGHT; the UI clips to viewport height via a ScrollContainer.
const CANVAS_HEIGHT: float = 900.0

## Horizontal margin: gap between the left/right canvas edge and the START/BOSS centres.
const MARGIN_X: float = 80.0

## Vertical margin: gap between canvas top/bottom and the outermost room centres.
const MARGIN_Y: float = 80.0

## Total columns including the single-room START and BOSS end-caps.
const MIN_COLUMNS: int = 12
const MAX_COLUMNS: int = 16

## Rooms that can appear in each middle column.
const MIN_ROOMS_PER_COL: int = 2
const MAX_ROOMS_PER_COL: int = 4

## Maximum number of incoming connections any single room may accept.
## Prevents many rooms piling into one destination and creating visual fan tangles.
const MAX_INCOMING_PER_ROOM: int = 2

## Minimum REST rooms per floor = num_columns / REST_PER_COLUMNS (integer division).
## At 12 columns → 4 rests; at 16 columns → 5 rests.
const REST_PER_COLUMNS: int = 3

# ── Column fraction thresholds ─────────────────────────────────────────────────
## Each value is the minimum position (0.0 = first choice column, 1.0 = last
## column before boss) at which that room type is allowed to appear.
## This stops REST and ELITE from appearing before the player has fought anything.

const THRESHOLD_SHOP: float       = 0.20  ## ~column 2/3 in an 8-col map
const THRESHOLD_REST: float        = 0.35  ## ~column 3/4
const THRESHOLD_ELITE: float       = 0.40  ## ~column 3/4
const THRESHOLD_BLACKSMITH: float  = 0.50  ## mid-floor at earliest

# ── Public API ─────────────────────────────────────────────────────────────────

static func generate(floor_data: FloorData) -> FloorMapData:
	var num_columns: int = randi_range(MIN_COLUMNS, MAX_COLUMNS)

	# Steps 1–3: lay out rooms in a grid
	var column_room_counts: Array[int] = _column_counts(num_columns)
	var rooms: Array[RoomData] = []
	var columns: Array = []  # Array of Array — each element is an Array of room indices
	_build_grid(rooms, columns, column_room_counts, num_columns)

	# Steps 4–5: wire rooms forward column by column
	_build_connections(rooms, columns)

	# START is the lone room in column 0, BOSS in the last column
	var start_index: int = (columns[0] as Array)[0] as int
	var boss_index: int = (columns[num_columns - 1] as Array)[0] as int

	# Build room → column index map for type constraints
	var room_col_index: Array[int] = _build_room_col_map(rooms.size(), columns)

	# Step 6–7: type assignment with column-aware weight filtering
	_assign_room_types(rooms, floor_data, start_index, boss_index, room_col_index, num_columns)

	# Step 8: payload assignment
	_assign_payloads(rooms, floor_data)

	var floor_map: FloorMapData = FloorMapData.new()
	floor_map.rooms = rooms
	floor_map.start_room_index = start_index
	floor_map.boss_room_index = boss_index
	floor_map.current_room_index = -1
	return floor_map

# ── Layout ─────────────────────────────────────────────────────────────────────

static func _column_counts(num_columns: int) -> Array[int]:
	var counts: Array[int] = []
	counts.append(1)  # START column
	for _col: int in range(1, num_columns - 1):
		counts.append(randi_range(MIN_ROOMS_PER_COL, MAX_ROOMS_PER_COL))
	counts.append(1)  # BOSS column
	return counts

static func _build_grid(
		rooms: Array[RoomData],
		columns: Array,
		column_room_counts: Array[int],
		num_columns: int) -> void:
	for col_index: int in num_columns:
		var col_indices: Array[int] = []
		var col_center_x: float = MARGIN_X + col_index * COL_SPACING
		var room_count: int = column_room_counts[col_index]

		for row_index: int in room_count:
			var room_center_y: float = _row_center_y(row_index, room_count)
			var room: RoomData = RoomData.new()
			room.position = Vector2i(
				int(col_center_x - ROOM_SIZE.x * 0.5),
				int(room_center_y - ROOM_SIZE.y * 0.5)
			)
			room.size = ROOM_SIZE
			col_indices.append(rooms.size())
			rooms.append(room)

		columns.append(col_indices)

static func _row_center_y(row_index: int, room_count: int) -> float:
	var usable_y: float = CANVAS_HEIGHT - 2.0 * MARGIN_Y
	return MARGIN_Y + float(row_index + 1) * usable_y / float(room_count + 1)

static func _build_room_col_map(room_count: int, columns: Array) -> Array[int]:
	var room_col_index: Array[int] = []
	room_col_index.resize(room_count)
	for col_index: int in columns.size():
		for room_idx: Variant in (columns[col_index] as Array):
			room_col_index[room_idx as int] = col_index
	return room_col_index

# ── Connections ────────────────────────────────────────────────────────────────

static func _build_connections(rooms: Array[RoomData], columns: Array) -> void:
	for col_index: int in range(columns.size() - 1):
		# Work on sorted copies so rank == position in the array.
		# Sorting is usually a no-op (rooms are built top-to-bottom) but is explicit
		# so the non-crossing invariant is guaranteed regardless of insertion order.
		var from_col: Array = (columns[col_index] as Array).duplicate()
		var to_col: Array = (columns[col_index + 1] as Array).duplicate()
		_sort_col_by_y(rooms, from_col)
		_sort_col_by_y(rooms, to_col)

		var incoming_count: Array[int] = []
		for _i: int in to_col.size():
			incoming_count.append(0)

		# Non-crossing invariant: every new connection must target a to-col rank
		# that is >= the highest rank already used.  Because from-col is processed
		# top-to-bottom, this guarantees the rank sequence is non-decreasing, making
		# it geometrically impossible for two connections to cross.
		var max_to_rank: int = 0

		for from_variant: Variant in from_col:
			var from_index: int = from_variant as int

			# Non-crossing candidates: only rooms at rank >= max_to_rank
			var nc_candidates: Array = to_col.slice(max_to_rank)

			# Within those, prefer rooms still under the incoming cap
			var candidates: Array = _under_capacity(nc_candidates, to_col, incoming_count)
			if candidates.is_empty():
				candidates = nc_candidates  # all at cap — overflow rather than disconnect

			var max_targets: int = mini(2, candidates.size())
			var target_count: int = randi_range(1, max_targets)
			var targets: Array[int] = _pick_targets(rooms, from_index, candidates, target_count)

			for target_index: int in targets:
				_connect_rooms(rooms, from_index, target_index)
				var to_rank: int = to_col.find(target_index)
				incoming_count[to_rank] += 1
				max_to_rank = maxi(max_to_rank, to_rank)

		# Orphan repair — every to-col room must have at least one incoming connection.
		# Same-source connections never cross, so using the nearest from-col room is safe.
		for to_pos: int in to_col.size():
			if incoming_count[to_pos] > 0:
				continue
			var orphan_index: int = to_col[to_pos] as int
			var rescuer_index: int = _nearest_in_set(rooms, orphan_index, from_col)
			_connect_rooms(rooms, rescuer_index, orphan_index)
			incoming_count[to_pos] += 1

## Sort a column array in-place by room centre y (top to bottom).
static func _sort_col_by_y(rooms: Array[RoomData], col: Array) -> void:
	col.sort_custom(func(idx_a: Variant, idx_b: Variant) -> bool:
		return _room_center(rooms[idx_a as int]).y < _room_center(rooms[idx_b as int]).y)

## Returns candidates whose incoming_count (looked up via parent_col rank) is below cap.
static func _under_capacity(candidates: Array, parent_col: Array, incoming_count: Array[int]) -> Array:
	var result: Array = []
	for idx_variant: Variant in candidates:
		var rank: int = parent_col.find(idx_variant)
		if rank >= 0 and incoming_count[rank] < MAX_INCOMING_PER_ROOM:
			result.append(idx_variant)
	return result

static func _pick_targets(
		rooms: Array[RoomData],
		from_index: int,
		candidate_col: Array,
		count: int) -> Array[int]:
	if candidate_col.size() <= count:
		var all: Array[int] = []
		for idx: Variant in candidate_col:
			all.append(idx as int)
		return all

	var from_y: float = _room_center(rooms[from_index]).y
	var sorted: Array = candidate_col.duplicate()
	sorted.sort_custom(func(idx_a: Variant, idx_b: Variant) -> bool:
		var dist_a: float = absf(_room_center(rooms[idx_a as int]).y - from_y)
		var dist_b: float = absf(_room_center(rooms[idx_b as int]).y - from_y)
		return dist_a < dist_b)

	var result: Array[int] = []
	for i: int in count:
		result.append(sorted[i] as int)
	return result

static func _nearest_in_set(rooms: Array[RoomData], target_index: int, candidate_col: Array) -> int:
	var target_center: Vector2 = _room_center(rooms[target_index])
	var best_index: int = candidate_col[0] as int
	var best_distance: float = target_center.distance_to(_room_center(rooms[best_index]))
	for i: int in range(1, candidate_col.size()):
		var candidate_index: int = candidate_col[i] as int
		var distance: float = target_center.distance_to(_room_center(rooms[candidate_index]))
		if distance < best_distance:
			best_distance = distance
			best_index = candidate_index
	return best_index

# ── Room type assignment ───────────────────────────────────────────────────────

static func _assign_room_types(
		rooms: Array[RoomData],
		floor_data: FloorData,
		start_index: int,
		boss_index: int,
		room_col_index: Array[int],
		num_columns: int) -> void:
	rooms[start_index].room_type = RoomData.RoomType.START
	rooms[boss_index].room_type = RoomData.RoomType.BOSS

	var num_middle_cols: int = num_columns - 2

	for room_index: int in rooms.size():
		if room_index == start_index or room_index == boss_index:
			continue
		# col_fraction: 0.0 = first choice column, 1.0 = last column before boss
		var col_position: int = room_col_index[room_index] - 1
		var col_fraction: float = float(col_position) / float(maxi(num_middle_cols - 1, 1))
		rooms[room_index].room_type = _pick_weighted_type(floor_data, col_fraction)

	# Remove duplicate special types within each column so the player always
	# has a meaningful choice (e.g. never "REST or REST").
	_deduplicate_column_types(rooms, start_index, boss_index, room_col_index)
	# Prevent the same type running across consecutive columns (REST→REST→REST),
	# which forces the player down that type with no ability to avoid it.
	_deduplicate_consecutive_columns(rooms, start_index, boss_index, room_col_index, num_columns)

	var min_rests: int = num_columns / REST_PER_COLUMNS
	_guarantee_rest_count(rooms, start_index, boss_index, room_col_index, num_middle_cols, min_rests)
	_clear_boss_adjacency(rooms, boss_index)
	# The entire pre-boss column becomes REST — every path through the floor
	# ends with a guaranteed heal before the boss fight.
	_set_pre_boss_column_rest(rooms, boss_index)

## Pick a weighted random room type, zeroing out types that require a higher
## col_fraction than the current room's position in the progression.
static func _pick_weighted_type(floor_data: FloorData, col_fraction: float) -> RoomData.RoomType:
	var entries: Array = [
		[RoomData.RoomType.COMBAT,   floor_data.combat_weight],
		[RoomData.RoomType.ELITE,    floor_data.elite_weight    if col_fraction >= THRESHOLD_ELITE      else 0],
		[RoomData.RoomType.REST,     floor_data.rest_weight     if col_fraction >= THRESHOLD_REST       else 0],
		[RoomData.RoomType.TREASURE, floor_data.treasure_weight],
		[RoomData.RoomType.EVENT,    floor_data.event_weight],
		[RoomData.RoomType.SHOP,     floor_data.shop_weight     if col_fraction >= THRESHOLD_SHOP       else 0],
	]
	if floor_data.allow_blacksmith:
		var blacksmith_weight: int = floor_data.blacksmith_weight if col_fraction >= THRESHOLD_BLACKSMITH else 0
		entries.append([RoomData.RoomType.BLACKSMITH, blacksmith_weight])

	var total_weight: int = 0
	for entry: Array in entries:
		total_weight += entry[1] as int

	if total_weight == 0:
		return RoomData.RoomType.COMBAT

	var roll: int = randi_range(0, total_weight - 1)
	var cumulative: int = 0
	for entry: Array in entries:
		cumulative += entry[1] as int
		if roll < cumulative:
			return entry[0] as RoomData.RoomType

	return RoomData.RoomType.COMBAT

## Prevents the same non-COMBAT type from appearing in two consecutive columns.
## Processes left to right: any room whose type already appeared in the immediately
## preceding column is downgraded to COMBAT. This cascades cleanly — if col 7 has
## REST and col 8's REST is downgraded, col 9's REST is not blocked by col 8.
static func _deduplicate_consecutive_columns(
		rooms: Array[RoomData],
		start_index: int,
		boss_index: int,
		room_col_index: Array[int],
		num_columns: int) -> void:
	var prev_col_types: Dictionary = {}
	for col_index: int in num_columns:
		var current_col_types: Dictionary = {}
		for room_index: int in rooms.size():
			if room_col_index[room_index] != col_index:
				continue
			if room_index == start_index or room_index == boss_index:
				continue
			var room_type: RoomData.RoomType = rooms[room_index].room_type
			if room_type == RoomData.RoomType.COMBAT:
				continue
			if prev_col_types.has(room_type):
				rooms[room_index].room_type = RoomData.RoomType.COMBAT
			else:
				current_col_types[room_type] = true
		prev_col_types = current_col_types

## Ensures at least min_count REST rooms exist on the floor.
## First pass only promotes COMBAT rooms at or past THRESHOLD_REST so early
## columns stay combat-heavy. A second pass relaxes that constraint if the
## first pass falls short (rare on large floors).
static func _guarantee_rest_count(
		rooms: Array[RoomData],
		start_index: int,
		boss_index: int,
		room_col_index: Array[int],
		num_middle_cols: int,
		min_count: int) -> void:
	var boss_connections: Array[int] = rooms[boss_index].connected_room_indices

	var rest_count: int = 0
	for room: RoomData in rooms:
		if room.room_type == RoomData.RoomType.REST:
			rest_count += 1

	if rest_count >= min_count:
		return

	# First pass: only convert rooms at or past the REST threshold
	for room_index: int in rooms.size():
		if rest_count >= min_count:
			return
		if room_index == start_index or room_index == boss_index:
			continue
		if rooms[room_index].room_type != RoomData.RoomType.COMBAT:
			continue
		if room_index in boss_connections:
			continue
		var col_frac: float = float(room_col_index[room_index] - 1) / float(maxi(num_middle_cols - 1, 1))
		if col_frac < THRESHOLD_REST:
			continue
		rooms[room_index].room_type = RoomData.RoomType.REST
		rest_count += 1

	# Second pass: relax the threshold if still short
	for room_index: int in rooms.size():
		if rest_count >= min_count:
			return
		if room_index == start_index or room_index == boss_index:
			continue
		if rooms[room_index].room_type != RoomData.RoomType.COMBAT:
			continue
		if room_index in boss_connections:
			continue
		rooms[room_index].room_type = RoomData.RoomType.REST
		rest_count += 1

## Ensures no column contains two rooms of the same non-COMBAT type.
## Duplicates are downgraded to COMBAT so the player always has a meaningful choice
## (e.g. never presented with "REST or REST" when both paths lead to the same type).
static func _deduplicate_column_types(
		rooms: Array[RoomData],
		start_index: int,
		boss_index: int,
		room_col_index: Array[int]) -> void:
	var col_type_seen: Dictionary = {}
	for room_index: int in rooms.size():
		if room_index == start_index or room_index == boss_index:
			continue
		var room_type: RoomData.RoomType = rooms[room_index].room_type
		if room_type == RoomData.RoomType.COMBAT:
			continue
		var col_index: int = room_col_index[room_index]
		if not col_type_seen.has(col_index):
			col_type_seen[col_index] = {}
		var seen: Dictionary = col_type_seen[col_index] as Dictionary
		if seen.has(room_type):
			rooms[room_index].room_type = RoomData.RoomType.COMBAT
		else:
			seen[room_type] = true

## Strip SHOP from rooms that feed directly into the boss — the player can't spend
## gold meaningfully right before the fight. REST is set by _set_pre_boss_column_rest.
static func _clear_boss_adjacency(rooms: Array[RoomData], boss_index: int) -> void:
	for connected_index: int in rooms[boss_index].connected_room_indices:
		if rooms[connected_index].room_type == RoomData.RoomType.SHOP:
			rooms[connected_index].room_type = RoomData.RoomType.COMBAT

## Converts every room in the pre-boss column to REST. No matter which path the
## player took through the floor, they always get a full heal before the boss.
static func _set_pre_boss_column_rest(rooms: Array[RoomData], boss_index: int) -> void:
	for connected_index: int in rooms[boss_index].connected_room_indices:
		rooms[connected_index].room_type = RoomData.RoomType.REST

# ── Payload assignment ─────────────────────────────────────────────────────────

static func _assign_payloads(rooms: Array[RoomData], floor_data: FloorData) -> void:
	for room: RoomData in rooms:
		match room.room_type:
			RoomData.RoomType.COMBAT:
				if not floor_data.combat_enemies.is_empty():
					var enemy_count: int = randi_range(1, mini(3, floor_data.combat_enemies.size()))
					for _spawn: int in enemy_count:
						room.combat_enemies.append(floor_data.combat_enemies.pick_random())
			RoomData.RoomType.ELITE:
				if not floor_data.elite_enemies.is_empty():
					room.elite_enemy = floor_data.elite_enemies.pick_random()
			RoomData.RoomType.BOSS:
				if not floor_data.boss_pool.is_empty():
					room.boss_enemy = floor_data.boss_pool.pick_random()
			RoomData.RoomType.EVENT:
				if not floor_data.event_pool.is_empty():
					room.event = floor_data.event_pool.pick_random()

# ── Utilities ──────────────────────────────────────────────────────────────────

static func _room_center(room: RoomData) -> Vector2:
	return Vector2(room.position) + Vector2(room.size) * 0.5

static func _connect_rooms(rooms: Array[RoomData], index_a: int, index_b: int) -> void:
	if index_b not in rooms[index_a].connected_room_indices:
		rooms[index_a].connected_room_indices.append(index_b)
	if index_a not in rooms[index_b].connected_room_indices:
		rooms[index_b].connected_room_indices.append(index_a)
