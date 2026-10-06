class_name TermReference
extends HBoxContainer
## The searchable Medical terms list on the left and the chosen term's card on the right.
## Search matches the term, its other spellings, and its meaning, so "itis", "cardio",
## and "inflammation" all work. The filter toggles narrow it to one kind of entry.

const LIST_ENTRY_SCENE: PackedScene = preload("res://terminology/term_list_entry.tscn")

var _entries: Array[TermListEntry] = []
var _current: TermListEntry = null
## Filter toggle -> the kinds it shows; an empty list means everything.
var _kinds_by_filter: Dictionary[Button, Array] = {}

# ── Node references ──
@onready var _search: LineEdit = $List/Layout/Search
@onready var _show_all: Button = $List/Layout/Filters/All
@onready var _show_prefixes: Button = $List/Layout/Filters/Prefixes
@onready var _show_roots: Button = $List/Layout/Filters/Roots
@onready var _show_suffixes: Button = $List/Layout/Filters/Suffixes
@onready var _show_words: Button = $List/Layout/Filters/Words
@onready var _show_body: Button = $List/Layout/Filters/Body
@onready var _show_abbreviations: Button = $List/Layout/Filters/Abbreviations
@onready var _count: Label = $List/Layout/Count
@onready var _results: ScrollContainer = $List/Layout/Results
@onready var _result_list: VBoxContainer = $List/Layout/Results/Entries
@onready var _no_matches: Label = $List/Layout/NoMatches
@onready var _card: TermCard = $Detail/Card


func _ready() -> void:
	_kinds_by_filter = {
		_show_all: [],
		_show_prefixes: [TermEntry.Kind.PREFIX],
		_show_roots: [TermEntry.Kind.ROOT],
		_show_suffixes: [TermEntry.Kind.SUFFIX],
		_show_words: [TermEntry.Kind.WORD],
		_show_body: [TermEntry.Kind.BODY],
		_show_abbreviations: [TermEntry.Kind.ABBREVIATION],
	}
	for filter_button: Button in _kinds_by_filter:
		filter_button.toggled.connect(func(is_on: bool) -> void:
			if is_on:
				_apply_filter())
	_search.text_changed.connect(func(_text: String) -> void: _apply_filter())
	_card.term_requested.connect(show_term)
	_build_entries()
	_apply_filter()


## Selects an entry, clearing the search and filter first if they would hide it.
func show_term(entry: TermEntry) -> void:
	var row: TermListEntry = _row_for(entry)
	if row == null:
		return
	if not row.visible:
		_search.text = ""
		_show_all.button_pressed = true
		_apply_filter()
	_select(row)
	# The row has no position until the list has been laid out.
	await get_tree().process_frame
	_results.ensure_control_visible(row)


func _build_entries() -> void:
	for entry: TermEntry in ContentLibrary.terms:
		var row: TermListEntry = LIST_ENTRY_SCENE.instantiate()
		_result_list.add_child(row)
		row.show_term(entry)
		row.chosen.connect(show_term)
		_entries.append(row)


func _apply_filter() -> void:
	var kinds: Array = _active_kinds()
	var query: String = _search.text.strip_edges().to_lower()
	var plain_query: String = query.replace("-", "").replace("/", "")
	var shown_count: int = 0
	var first_shown: TermListEntry = null
	for row: TermListEntry in _entries:
		var kind_matches: bool = kinds.is_empty() or kinds.has(row.entry.kind)
		var text_matches: bool = query.is_empty() or row.search_text.contains(query) \
			or (not plain_query.is_empty() and row.search_text.contains(plain_query))
		row.visible = kind_matches and text_matches
		if row.visible:
			shown_count += 1
			if first_shown == null:
				first_shown = row
	_count.text = "%d of %d terms" % [shown_count, _entries.size()]
	_no_matches.visible = shown_count == 0
	if _current == null or not _current.visible:
		_select(first_shown)


func _active_kinds() -> Array:
	for filter_button: Button in _kinds_by_filter:
		if filter_button.button_pressed:
			return _kinds_by_filter[filter_button]
	return []


func _select(row: TermListEntry) -> void:
	if _current != null:
		_current.set_current(false)
	_current = row
	_card.visible = row != null
	if row == null:
		return
	row.set_current(true)
	_card.show_term(row.entry)


func _row_for(entry: TermEntry) -> TermListEntry:
	for row: TermListEntry in _entries:
		if row.entry == entry:
			return row
	return null
