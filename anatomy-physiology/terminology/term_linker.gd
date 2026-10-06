class_name TermLinker
extends RefCounted
## Turns known terminology in lesson BBCode into [url=term:<id>] links. Whole words and
## body terms match case-insensitively, abbreviations exactly ("ER" but not "er"). Each
## entry links only its first appearance per call, so a page isn't a wall of underlines.

const LINK_PREFIX: String = "term:"
## Characters that mean something in a regular expression and must be escaped.
const PATTERN_SPECIALS: String = "\\.^$|?*+()[]{}"

static var _pattern: RegEx = null
static var _tag_pattern: RegEx = null
## Lowercase text -> entry for words and body terms; exact text -> entry for abbreviations.
static var _entries_by_folded_text: Dictionary[String, TermEntry] = {}
static var _entries_by_exact_text: Dictionary[String, TermEntry] = {}


static func link_terms(bbcode: String) -> String:
	if _pattern == null:
		_build_patterns()
	if _entries_by_folded_text.is_empty() and _entries_by_exact_text.is_empty():
		return bbcode
	var linked_ids: Dictionary[String, bool] = {}
	var output: PackedStringArray = []
	var text_start: int = 0
	# Only the text between tags is searched, so tag names like [b] are never touched.
	for tag_match: RegExMatch in _tag_pattern.search_all(bbcode):
		output.append(_link_text(bbcode.substr(text_start, tag_match.get_start() - text_start), linked_ids))
		output.append(tag_match.get_string())
		text_start = tag_match.get_end()
	output.append(_link_text(bbcode.substr(text_start), linked_ids))
	return "".join(output)


## The entry a link from link_terms() points at, or null for any other meta.
static func entry_for_meta(meta: Variant) -> TermEntry:
	var meta_text: String = str(meta)
	if not meta_text.begins_with(LINK_PREFIX):
		return null
	return ContentLibrary.get_term(meta_text.trim_prefix(LINK_PREFIX))


static func _link_text(text: String, linked_ids: Dictionary[String, bool]) -> String:
	var output: PackedStringArray = []
	var text_start: int = 0
	for term_match: RegExMatch in _pattern.search_all(text):
		var matched_text: String = term_match.get_string()
		var entry: TermEntry = _entries_by_exact_text.get(matched_text, null)
		if entry == null:
			entry = _entries_by_folded_text.get(matched_text.to_lower(), null)
		if entry == null or linked_ids.has(entry.id):
			continue
		linked_ids[entry.id] = true
		output.append(text.substr(text_start, term_match.get_start() - text_start))
		output.append("[url=%s%s]%s[/url]" % [LINK_PREFIX, entry.id, matched_text])
		text_start = term_match.get_end()
	output.append(text.substr(text_start))
	return "".join(output)


static func _build_patterns() -> void:
	_tag_pattern = RegEx.create_from_string("\\[[^\\]]*\\]")
	for entry: TermEntry in ContentLibrary.terms:
		if entry.is_word_part() or not entry.links_from_lessons:
			continue
		var texts: Array[String] = [entry.term]
		texts.append_array(entry.forms)
		for text: String in texts:
			if entry.kind == TermEntry.Kind.ABBREVIATION:
				_entries_by_exact_text[text] = entry
			# A body term wins over a word with the same spelling.
			elif not _entries_by_folded_text.has(text.to_lower()) or entry.kind == TermEntry.Kind.BODY:
				_entries_by_folded_text[text.to_lower()] = entry
	# Longest first, so "right upper quadrant" wins over a shorter term inside it.
	var folded_texts: Array[String] = _escaped_longest_first(_entries_by_folded_text.keys())
	var exact_texts: Array[String] = _escaped_longest_first(_entries_by_exact_text.keys())
	var alternatives: PackedStringArray = []
	if not folded_texts.is_empty():
		alternatives.append("(?i:%s)" % "|".join(folded_texts))
	if not exact_texts.is_empty():
		alternatives.append("(?:%s)" % "|".join(exact_texts))
	if alternatives.is_empty():
		_pattern = RegEx.new()
		return
	# Lookarounds rather than \b, so terms ending in symbols (O₂, NAD⁺) still match.
	_pattern = RegEx.create_from_string("(?<!\\w)(?:%s)(?!\\w)" % "|".join(alternatives))


static func _escaped_longest_first(texts: Array) -> Array[String]:
	var sorted_texts: Array[String] = []
	sorted_texts.assign(texts)
	sorted_texts.sort_custom(func(first: String, second: String) -> bool: return first.length() > second.length())
	var escaped: Array[String] = []
	for text: String in sorted_texts:
		var characters: PackedStringArray = []
		for character: String in text:
			characters.append("\\" + character if PATTERN_SPECIALS.contains(character) else character)
		escaped.append("".join(characters))
	return escaped
