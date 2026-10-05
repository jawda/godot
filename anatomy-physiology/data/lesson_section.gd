class_name LessonSection
extends RefCounted
## One heading-and-body chunk of a module's reading. The lesson view shows it as one or
## more short pages; see build_pages().

## A body line of exactly this text forces a page break.
const PAGE_BREAK: String = "---"
const FIGURE_DIRECTORY: String = "res://content/images"

var heading: String = ""
## Paragraphs and bullets in display order. Lines starting with "- " are bullets.
var body: Array[String] = []
var tip: String = ""
var clinical: String = ""
var figure_file: String = ""
var figure_caption: String = ""
var figure_credit: String = ""
## When true the whole body is one page, however long.
var is_single_page: bool = false


static func from_dictionary(data: Dictionary) -> LessonSection:
	var section: LessonSection = LessonSection.new()
	section.heading = str(data.get("heading", ""))
	section.body.assign(data.get("body", []))
	section.tip = str(data.get("tip", ""))
	section.clinical = str(data.get("clinical", ""))
	var figure: Dictionary = data.get("figure", {})
	section.figure_file = str(figure.get("file", ""))
	section.figure_caption = str(figure.get("caption", ""))
	section.figure_credit = str(figure.get("credit", ""))
	return section


func has_figure() -> bool:
	return not figure_file.is_empty()


func figure_path() -> String:
	return FIGURE_DIRECTORY.path_join(figure_file)


## Splits the body into pages of roughly equal length, none much longer than
## target_length characters. A line ending in ":" introduces what follows, so it is
## never left stranded at the bottom of a page.
func build_pages(target_length: int) -> Array[PackedStringArray]:
	var pages: Array[PackedStringArray] = []
	for chunk: PackedStringArray in _split_on_page_breaks():
		if is_single_page:
			pages.append(chunk)
		else:
			pages.append_array(_balance_chunk(chunk, target_length))
	if pages.is_empty():
		pages.append(PackedStringArray())
	return pages


func _split_on_page_breaks() -> Array[PackedStringArray]:
	var chunks: Array[PackedStringArray] = []
	var current: PackedStringArray = []
	for line: String in body:
		if line.strip_edges() == PAGE_BREAK:
			if not current.is_empty():
				chunks.append(current)
			current = PackedStringArray()
			continue
		current.append(line)
	if not current.is_empty():
		chunks.append(current)
	return chunks


func _balance_chunk(lines: PackedStringArray, target_length: int) -> Array[PackedStringArray]:
	var total_length: int = 0
	for line: String in lines:
		total_length += line.length()
	var page_count: int = maxi(1, ceili(float(total_length) / target_length))
	var length_per_page: float = float(total_length) / page_count
	var pages: Array[PackedStringArray] = []
	var current: PackedStringArray = []
	var current_length: int = 0
	for line: String in lines:
		var would_overflow: bool = current_length + line.length() * 0.5 > length_per_page
		if not current.is_empty() and would_overflow and pages.size() < page_count - 1:
			var carried: PackedStringArray = []
			if current.size() > 1 and current[current.size() - 1].ends_with(":"):
				carried.append(current[current.size() - 1])
				current.remove_at(current.size() - 1)
			pages.append(current)
			current = carried
			current_length = 0
			for carried_line: String in carried:
				current_length += carried_line.length()
		current.append(line)
		current_length += line.length()
	if not current.is_empty():
		pages.append(current)
	return pages
