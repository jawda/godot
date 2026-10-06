class_name ModuleStudy
extends MarginContainer
## One module's study screen: Lesson, Flashcards, Quiz, and Diagrams tabs.
## TabContainer turns each child node into a tab named after the node.

signal back_requested

enum Tab { LESSON, FLASHCARDS, QUIZ, DIAGRAMS }

var _module: StudyModule = null

# ── Node references ──
@onready var _back: Button = $Layout/Header/Back
@onready var _number: Label = $Layout/Header/Titles/Number
@onready var _title: Label = $Layout/Header/Titles/Title
@onready var _sections: TabContainer = $Layout/Sections
@onready var _lesson: LessonView = $Layout/Sections/Lesson
@onready var _flashcards: FlashcardDeck = $Layout/Sections/Flashcards
@onready var _quiz: QuizRunner = $Layout/Sections/Quiz
@onready var _diagrams: DiagramPractice = $Layout/Sections/Diagrams
@onready var _figure_viewer: FigureViewer = $FigureViewer


func _ready() -> void:
	_back.pressed.connect(back_requested.emit)
	_lesson.flashcards_requested.connect(func() -> void: _sections.current_tab = Tab.FLASHCARDS)
	_lesson.figure_requested.connect(_figure_viewer.open)
	_sections.tab_changed.connect(_on_tab_changed)


func show_module(module: StudyModule, opening_tab: int = Tab.LESSON) -> void:
	_module = module
	_number.text = "MODULE %d  ·  %s" % [module.order, module.course]
	_title.text = module.title
	_lesson.show_module(module)
	_flashcards.load_deck(module.flashcards)
	_quiz.start(module.quiz_questions, module.id)
	_diagrams.load_diagrams(module.diagrams)
	_sections.set_tab_hidden(Tab.DIAGRAMS, module.diagrams.is_empty())
	if opening_tab == Tab.DIAGRAMS and module.diagrams.is_empty():
		opening_tab = Tab.LESSON
	_figure_viewer.hide()
	# tab_changed only fires on an actual change, so record the place directly too.
	_sections.current_tab = opening_tab
	_on_tab_changed(opening_tab)


## Remembers the module and tab so the home screen can offer "Continue".
func _on_tab_changed(tab: int) -> void:
	if _module != null:
		StudyProgress.set_last_place(_module.id, tab)
