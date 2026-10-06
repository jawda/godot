class_name TermListEntry
extends Button
## One row of the Medical terms list: the term, then its meaning in muted text.

signal chosen(entry: TermEntry)

var entry: TermEntry = null
## Lowercase term, forms, and meaning, plus the term without hyphens and slashes, so a
## search for "itis", "cardio", or "inflammation" finds the right rows.
var search_text: String = ""

# ── Node references ──
@onready var _term: Label = $Content/Term
@onready var _meaning: Label = $Content/Meaning


func _ready() -> void:
	pressed.connect(func() -> void: chosen.emit(entry))


func show_term(shown_entry: TermEntry) -> void:
	entry = shown_entry
	_term.text = shown_entry.term
	_meaning.text = shown_entry.meaning
	var searchable: PackedStringArray = [shown_entry.term, shown_entry.plain_term(), shown_entry.meaning]
	searchable.append_array(shown_entry.forms)
	search_text = " ".join(searchable).to_lower()


func set_current(is_current: bool) -> void:
	theme_type_variation = &"OutlineEntryCurrent" if is_current else &"OutlineEntry"
