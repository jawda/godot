class_name DiagramBoard
extends Control
## Shows one diagram's figure, cropped to its region, with a DiagramBlank over every
## printed label. Blanks are re-positioned whenever the zoom changes, so they always
## sit exactly on top of the text they hide. The zoom buttons live in the practice
## screen's toolbar and drive this through zoom_in(), zoom_out() and fit_to_canvas().

signal blank_clicked(blank: DiagramBlank)
signal chip_dropped(blank: DiagramBlank, chip: LabelChip)
signal entry_submitted(blank: DiagramBlank)
signal entry_edited(blank: DiagramBlank)
## Sent whenever the zoom changes, so the toolbar can show the level.
signal zoom_changed(zoom: float, can_zoom_in: bool, can_zoom_out: bool)

const BLANK_SCENE: PackedScene = preload("res://diagrams/diagram_blank.tscn")
const ZOOM_STEPS: Array[float] = [0.33, 0.5, 0.67, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0]
const MINIMUM_ZOOM: float = 0.25
const MAXIMUM_ZOOM: float = 3.0
## A fitted figure may grow a little past its own size, but not so far it looks soft.
const MAXIMUM_FIT_ZOOM: float = 1.5
## Matches BOX_PADDING in tools/fill_diagram_boxes.py: space around the printed text.
const BOX_PADDING_PIXELS: float = 4.0
const MINIMUM_FONT_SIZE: int = 9
const MAXIMUM_FONT_SIZE: int = 28
## Fitting never shrinks the labels below this text size; a tall figure scrolls instead.
const READABLE_FONT_SIZE: float = 12.0

var blanks: Array[DiagramBlank] = []
var _diagram: LabeledDiagram = null
## Region of the figure on show, in texture pixels.
var _region_pixels: Rect2 = Rect2()
var _texture_size: Vector2 = Vector2.ONE
var _zoom: float = 1.0
var _is_fitting: bool = true
## Each blank's box in texture pixels, trimmed so neighbouring blanks don't overlap.
var _box_by_blank: Dictionary[DiagramBlank, Rect2] = {}

# ── Node references ──
@onready var _canvas: ScrollContainer = $Canvas
@onready var _centering: CenterContainer = $Canvas/Centering
@onready var _stage: Control = $Canvas/Centering/Stage
@onready var _picture: TextureRect = $Canvas/Centering/Stage/Picture
@onready var _blank_layer: Control = $Canvas/Centering/Stage/Blanks


func _ready() -> void:
	_canvas.resized.connect(_on_canvas_resized)
	# The tab may be built while hidden, when the canvas has no size to fit to yet.
	visibility_changed.connect(_on_canvas_resized)
	_stage.gui_input.connect(_on_stage_input)


## Builds a blank per label and returns them in reading order (left column top to
## bottom, then right column), which is also the Tab order when typing.
func show_diagram(diagram: LabeledDiagram, is_typing: bool) -> Array[DiagramBlank]:
	_diagram = diagram
	_clear_blanks()
	var texture: Texture2D = load(diagram.image_path())
	_texture_size = Vector2(texture.get_size())
	_region_pixels = Rect2(diagram.region.position * _texture_size, diagram.region.size * _texture_size)
	var cropped: AtlasTexture = AtlasTexture.new()
	cropped.atlas = texture
	cropped.region = _region_pixels
	_picture.texture = cropped
	var ordered_labels: Array[DiagramLabel] = diagram.labels.duplicate()
	var middle_x: float = diagram.region.get_center().x
	ordered_labels.sort_custom(func(first: DiagramLabel, second: DiagramLabel) -> bool:
		var first_side: int = 0 if first.box.get_center().x < middle_x else 1
		var second_side: int = 0 if second.box.get_center().x < middle_x else 1
		if first_side != second_side:
			return first_side < second_side
		return first.box.position.y < second.box.position.y)
	for diagram_label: DiagramLabel in ordered_labels:
		var blank: DiagramBlank = BLANK_SCENE.instantiate()
		_blank_layer.add_child(blank)
		blank.setup(diagram_label, is_typing)
		blank.clicked.connect(blank_clicked.emit)
		blank.chip_dropped.connect(chip_dropped.emit)
		blank.entry_submitted.connect(entry_submitted.emit)
		blank.entry_edited.connect(entry_edited.emit)
		blanks.append(blank)
	_trim_overlaps()
	_is_fitting = true
	_apply_zoom(_fit_zoom())
	return blanks


func fit_to_canvas() -> void:
	_is_fitting = true
	_apply_zoom(_fit_zoom())


func zoom_in() -> void:
	_step_zoom(1)


func zoom_out() -> void:
	_step_zoom(-1)


func set_zoom(zoom: float) -> void:
	_is_fitting = false
	_apply_zoom(zoom)


func _fit_zoom() -> float:
	if _region_pixels.size.x <= 0.0 or _canvas.size.x <= 0.0:
		return 1.0
	var width_fit: float = _canvas.size.x / _region_pixels.size.x
	var height_fit: float = _canvas.size.y / _region_pixels.size.y
	# Fit the whole figure unless that makes the labels too small to read; then fit
	# the width and let it scroll vertically.
	var readable_zoom: float = READABLE_FONT_SIZE / _typical_line_height()
	var fit: float = minf(width_fit, maxf(height_fit, readable_zoom))
	return clampf(fit, MINIMUM_ZOOM, MAXIMUM_FIT_ZOOM)


## Median printed line height in texture pixels, a stand-in for the figure's text size.
func _typical_line_height() -> float:
	var heights: Array[float] = []
	for blank: DiagramBlank in blanks:
		heights.append((_box_by_blank[blank].size.y - BOX_PADDING_PIXELS * 2.0) / blank.label.line_count)
	if heights.is_empty():
		return READABLE_FONT_SIZE
	heights.sort()
	return maxf(heights[heights.size() / 2], 4.0)


func _apply_zoom(zoom: float) -> void:
	if _diagram == null:
		return
	# Keep the same part of the figure in the middle of the canvas.
	var old_centre: Vector2 = (Vector2(_canvas.scroll_horizontal, _canvas.scroll_vertical) + _canvas.size * 0.5) / _zoom
	_zoom = clampf(zoom, MINIMUM_ZOOM, MAXIMUM_ZOOM)
	var stage_size: Vector2 = _region_pixels.size * _zoom
	_stage.custom_minimum_size = stage_size
	_centering.custom_minimum_size = stage_size.max(_canvas.size)
	for blank: DiagramBlank in blanks:
		_place_blank(blank)
	zoom_changed.emit(_zoom, _zoom < MAXIMUM_ZOOM - 0.001, _zoom > MINIMUM_ZOOM + 0.001)
	# Scroll limits only update after the containers re-sort, so scroll on the next frame.
	await get_tree().process_frame
	var target_scroll: Vector2 = old_centre * _zoom - _canvas.size * 0.5
	_canvas.scroll_horizontal = roundi(target_scroll.x)
	_canvas.scroll_vertical = roundi(target_scroll.y)


func _place_blank(blank: DiagramBlank) -> void:
	var box_pixels: Rect2 = _box_by_blank[blank]
	var stage_rect: Rect2 = Rect2((box_pixels.position - _region_pixels.position) * _zoom, box_pixels.size * _zoom)
	# The printed text is about as tall as its line spacing; the blank shrinks it further if needed.
	var printed_line_height: float = (box_pixels.size.y - BOX_PADDING_PIXELS * 2.0) / blank.label.line_count
	var font_size: int = clampi(roundi(printed_line_height * _zoom), MINIMUM_FONT_SIZE, MAXIMUM_FONT_SIZE)
	blank.place_at(stage_rect, font_size)


## Labels printed in a tight list (carpals, nerves of a plexus) get padded boxes that
## overlap, and the later blank would hide the earlier one's text. Split each
## overlapping pair down the middle of the overlap, across its thinner direction.
func _trim_overlaps() -> void:
	_box_by_blank.clear()
	for blank: DiagramBlank in blanks:
		_box_by_blank[blank] = Rect2(blank.label.box.position * _texture_size, blank.label.box.size * _texture_size)
	for first_index: int in blanks.size():
		for second_index: int in range(first_index + 1, blanks.size()):
			var first: Rect2 = _box_by_blank[blanks[first_index]]
			var second: Rect2 = _box_by_blank[blanks[second_index]]
			var overlap: Rect2 = first.intersection(second)
			if not overlap.has_area():
				continue
			if overlap.size.y <= overlap.size.x:
				var split_y: float = overlap.get_center().y
				var upper_is_first: bool = first.get_center().y < second.get_center().y
				var upper: Rect2 = first if upper_is_first else second
				var lower: Rect2 = second if upper_is_first else first
				upper.size.y = split_y - upper.position.y
				lower.size.y = lower.end.y - split_y
				lower.position.y = split_y
				first = upper if upper_is_first else lower
				second = lower if upper_is_first else upper
			else:
				var split_x: float = overlap.get_center().x
				var left_is_first: bool = first.get_center().x < second.get_center().x
				var left: Rect2 = first if left_is_first else second
				var right: Rect2 = second if left_is_first else first
				left.size.x = split_x - left.position.x
				right.size.x = right.end.x - split_x
				right.position.x = split_x
				first = left if left_is_first else right
				second = right if left_is_first else left
			_box_by_blank[blanks[first_index]] = first
			_box_by_blank[blanks[second_index]] = second


func _clear_blanks() -> void:
	for blank: DiagramBlank in blanks:
		_blank_layer.remove_child(blank)
		blank.queue_free()
	blanks.clear()
	_box_by_blank.clear()


func _step_zoom(direction: int) -> void:
	var next_zoom: float = _zoom
	if direction > 0:
		for step: float in ZOOM_STEPS:
			if step > _zoom + 0.001:
				next_zoom = step
				break
	else:
		for step_index: int in range(ZOOM_STEPS.size() - 1, -1, -1):
			if ZOOM_STEPS[step_index] < _zoom - 0.001:
				next_zoom = ZOOM_STEPS[step_index]
				break
	set_zoom(next_zoom)


func _on_canvas_resized() -> void:
	if is_visible_in_tree() and _is_fitting:
		fit_to_canvas()


## Trackpad pinch, or Ctrl/Cmd plus the scroll wheel, zooms. Plain scrolling still scrolls.
func _on_stage_input(event: InputEvent) -> void:
	var pinch: InputEventMagnifyGesture = event as InputEventMagnifyGesture
	if pinch != null:
		set_zoom(_zoom * pinch.factor)
		_stage.accept_event()
		return
	var button_event: InputEventMouseButton = event as InputEventMouseButton
	if button_event == null or not button_event.pressed or not button_event.is_command_or_control_pressed():
		return
	if button_event.button_index == MOUSE_BUTTON_WHEEL_UP:
		set_zoom(_zoom * 1.15)
		_stage.accept_event()
	elif button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		set_zoom(_zoom / 1.15)
		_stage.accept_event()
