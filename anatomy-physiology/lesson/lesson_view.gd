class_name LessonView
extends HBoxContainer
## A module's reading, one short page at a time. The outline on the left lists the
## sections with a checkmark for each one finished; a section counts as finished once
## its last page has been shown.

signal flashcards_requested
signal figure_requested(texture: Texture2D, caption: String)
signal term_requested(entry: TermEntry)

const OUTLINE_ENTRY_SCENE: PackedScene = preload("res://lesson/outline_entry.tscn")
const TARGET_PAGE_LENGTH: int = 700
const FILLED_DOT: String = "●"
const EMPTY_DOT: String = "○"

var _module: StudyModule = null
## The module's sections with a generated "Overview" section (the objectives) in front.
var _sections: Array[LessonSection] = []
var _section_index: int = 0
var _pages: Array[PackedStringArray] = []
var _page_index: int = 0
var _entries: Array[OutlineEntry] = []

# ── Node references ──
@onready var _read_count: Label = $Outline/Layout/ReadCount
@onready var _read_progress: ProgressBar = $Outline/Layout/ReadProgress
@onready var _outline_entries: VBoxContainer = $Outline/Layout/Sections/Entries
@onready var _breadcrumb: Label = $Page/Layout/Breadcrumb
@onready var _heading: Label = $Page/Layout/Heading
@onready var _reading: ScrollContainer = $Page/Layout/Reading
@onready var _figure: FigureCard = $Page/Layout/Reading/Content/Figure
@onready var _text: RichTextLabel = $Page/Layout/Reading/Content/Text
@onready var _tip: Callout = $Page/Layout/Reading/Content/Tip
@onready var _clinical: Callout = $Page/Layout/Reading/Content/Clinical
@onready var _previous: Button = $Page/Layout/Navigation/Previous
@onready var _page_dots: Label = $Page/Layout/Navigation/Pages
@onready var _next: Button = $Page/Layout/Navigation/Next


func _ready() -> void:
	_previous.pressed.connect(_go_back)
	_next.pressed.connect(_go_forward)
	_figure.enlarge_requested.connect(figure_requested.emit)
	_text.meta_clicked.connect(_on_term_clicked)
	_text.meta_hover_started.connect(_on_term_hovered)
	_text.meta_hover_ended.connect(func(_meta: Variant) -> void: _text.tooltip_text = "")


## Opens the module where the student left off, or at the first unfinished section.
func show_module(module: StudyModule) -> void:
	_module = module
	_sections.clear()
	_sections.append(_build_overview(module))
	_sections.append_array(module.lesson_sections)
	_build_outline()
	var saved_position: Vector2i = StudyProgress.lesson_position(module.id)
	if saved_position.x >= 0 and saved_position.x < _sections.size():
		_open_section(saved_position.x, saved_position.y)
		return
	var resume_index: int = 0
	for section_index: int in _sections.size():
		resume_index = section_index
		if not _is_read(section_index):
			break
	_open_section(resume_index, 0)


func _build_overview(module: StudyModule) -> LessonSection:
	var overview: LessonSection = LessonSection.new()
	overview.heading = "Overview"
	overview.is_single_page = true
	overview.body.append(module.summary)
	overview.body.append("By the end of this module you should be able to:")
	for objective: String in module.objectives:
		overview.body.append("- " + objective)
	return overview


## One row per section, so the rows are created here; each is an outline_entry.tscn.
func _build_outline() -> void:
	for entry: OutlineEntry in _entries:
		entry.queue_free()
	_entries.clear()
	for section_index: int in _sections.size():
		var entry: OutlineEntry = OUTLINE_ENTRY_SCENE.instantiate()
		_outline_entries.add_child(entry)
		entry.section_index = section_index
		entry.text = _sections[section_index].heading
		entry.chosen.connect(_open_section.bind(0))
		_entries.append(entry)


func _open_section(section_index: int, page_index: int) -> void:
	_section_index = section_index
	_pages = _sections[section_index].build_pages(TARGET_PAGE_LENGTH)
	_page_index = clampi(page_index, 0, _pages.size() - 1)
	_show_page()


func _show_page() -> void:
	var section: LessonSection = _sections[_section_index]
	var is_first_page: bool = _page_index == 0
	var is_last_page: bool = _page_index == _pages.size() - 1
	_breadcrumb.text = "Section %d of %d" % [_section_index + 1, _sections.size()]
	if _pages.size() > 1:
		_breadcrumb.text += "   ·   Page %d of %d" % [_page_index + 1, _pages.size()]
	_heading.text = section.heading
	_text.text = TermLinker.link_terms(_page_bbcode(_pages[_page_index]))
	if is_first_page:
		_figure.show_figure(section)
	else:
		_figure.visible = false
	_tip.show_text(section.tip if is_last_page else "")
	_clinical.show_text(section.clinical if is_last_page else "")
	_page_dots.text = _dots()
	_previous.disabled = _section_index == 0 and is_first_page
	var is_last_section: bool = _section_index == _sections.size() - 1
	if not is_last_page:
		_next.text = "Next page  →"
	elif is_last_section:
		_next.text = "Practice flashcards  →"
	else:
		_next.text = "Next section  →"
	_reading.scroll_vertical = 0
	StudyProgress.save_lesson_position(_module.id, _section_index, _page_index)
	if is_last_page:
		_mark_read(_section_index)
	_refresh_outline()


func _go_forward() -> void:
	if _page_index < _pages.size() - 1:
		_page_index += 1
		_show_page()
	elif _section_index < _sections.size() - 1:
		_open_section(_section_index + 1, 0)
	else:
		flashcards_requested.emit()


func _go_back() -> void:
	if _page_index > 0:
		_page_index -= 1
		_show_page()
	elif _section_index > 0:
		_open_section(_section_index - 1, 999)


func _on_term_clicked(meta: Variant) -> void:
	var entry: TermEntry = TermLinker.entry_for_meta(meta)
	if entry != null:
		term_requested.emit(entry)


## Hovering a linked term previews its meaning before the student commits to a click.
func _on_term_hovered(meta: Variant) -> void:
	var entry: TermEntry = TermLinker.entry_for_meta(meta)
	if entry == null:
		return
	var breakdown: String = ContentLibrary.term_breakdown(entry)
	_text.tooltip_text = "%s: %s" % [entry.term, entry.meaning]
	if not breakdown.is_empty():
		_text.tooltip_text += "\n" + breakdown


func _page_bbcode(lines: PackedStringArray) -> String:
	var parts: PackedStringArray = []
	var pending_bullets: PackedStringArray = []
	for line: String in lines:
		if line.begins_with("- "):
			pending_bullets.append(line.substr(2))
			continue
		if not pending_bullets.is_empty():
			parts.append("[ul]%s[/ul]" % "\n".join(pending_bullets))
			pending_bullets.clear()
		parts.append(line)
	if not pending_bullets.is_empty():
		parts.append("[ul]%s[/ul]" % "\n".join(pending_bullets))
	return "\n\n".join(parts)


func _dots() -> String:
	if _pages.size() <= 1:
		return ""
	var dots: PackedStringArray = []
	for page_index: int in _pages.size():
		dots.append(FILLED_DOT if page_index <= _page_index else EMPTY_DOT)
	return "  ".join(dots)


func _section_key(section_index: int) -> String:
	return StudyProgress.lesson_section_key(_module, _sections[section_index].heading)


func _is_read(section_index: int) -> bool:
	return StudyProgress.is_section_read(_section_key(section_index))


func _mark_read(section_index: int) -> void:
	StudyProgress.mark_section_read(_section_key(section_index))


func _refresh_outline() -> void:
	var read_count: int = 0
	for entry: OutlineEntry in _entries:
		var is_read: bool = _is_read(entry.section_index)
		if is_read:
			read_count += 1
		entry.set_state(is_read, entry.section_index == _section_index)
	_read_count.text = "%d of %d complete" % [read_count, _entries.size()]
	_read_progress.value = float(read_count) / maxi(_entries.size(), 1)
