class_name TermCard
extends PanelContainer
## Everything about one terminology entry: its meaning, a word's breakdown into parts,
## a body term's opposite, examples, and for a word part the words built from it. Every
## other entry it mentions is a link, reported through term_requested.

signal term_requested(entry: TermEntry)

## A word part lists at most this many of the words built from it.
const MAXIMUM_USED_IN: int = 12

var entry: TermEntry = null

# ── Node references ──
@onready var _kind: Label = $Layout/Kind
@onready var _term: Label = $Layout/Term
@onready var _meaning: Label = $Layout/Meaning
@onready var _details: RichTextLabel = $Layout/Details


func _ready() -> void:
	_details.meta_clicked.connect(_on_meta_clicked)


func show_term(shown_entry: TermEntry) -> void:
	entry = shown_entry
	_kind.text = shown_entry.kind_label().to_upper()
	_term.text = shown_entry.term
	_meaning.text = shown_entry.meaning
	_details.text = _details_bbcode(shown_entry)
	_details.visible = not _details.text.is_empty()


func _details_bbcode(shown_entry: TermEntry) -> String:
	var sections: PackedStringArray = []
	if shown_entry.kind == TermEntry.Kind.WORD:
		var pieces: PackedStringArray = []
		for part_id: String in shown_entry.part_ids:
			var part: TermEntry = ContentLibrary.get_term(part_id)
			if part != null:
				pieces.append("%s  %s" % [_link(part), part.meaning])
		sections.append("[b]Built from[/b]\n" + "\n".join(pieces))
	var opposite: TermEntry = ContentLibrary.get_term(shown_entry.opposite_id)
	if opposite != null:
		sections.append("[b]Opposite[/b]  %s" % _link(opposite))
	if not shown_entry.examples.is_empty():
		sections.append("[b]Example%s[/b]\n%s" % ["s" if shown_entry.examples.size() > 1 else "",
			"\n".join(shown_entry.examples)])
	if shown_entry.is_word_part():
		var words: Array[TermEntry] = ContentLibrary.words_using_part(shown_entry.id)
		if not words.is_empty():
			var links: PackedStringArray = []
			for word: TermEntry in words.slice(0, MAXIMUM_USED_IN):
				links.append(_link(word))
			var more: String = "  and %d more" % (words.size() - MAXIMUM_USED_IN) if words.size() > MAXIMUM_USED_IN else ""
			sections.append("[b]Used in[/b]  %s%s" % [",  ".join(links), more])
	return "\n\n".join(sections)


func _link(linked_entry: TermEntry) -> String:
	return "[url=%s%s]%s[/url]" % [TermLinker.LINK_PREFIX, linked_entry.id, linked_entry.term]


func _on_meta_clicked(meta: Variant) -> void:
	var linked_entry: TermEntry = TermLinker.entry_for_meta(meta)
	if linked_entry != null:
		term_requested.emit(linked_entry)
