class_name TerminologyScreen
extends MarginContainer
## The Medical terms screen: a searchable reference plus flashcards and a quiz drawn from
## the same entries. The practice set picks which kind of entry the drills use.

signal back_requested

enum Tab { REFERENCE, FLASHCARDS, QUIZ }
enum PracticeSet { WORD_PARTS, PREFIXES, ROOTS, SUFFIXES, WORDS, BODY, ABBREVIATIONS, EVERYTHING }

const QUIZ_SIZE: int = 20
const KINDS_BY_SET: Dictionary[PracticeSet, Array] = {
	PracticeSet.WORD_PARTS: [TermEntry.Kind.PREFIX, TermEntry.Kind.ROOT, TermEntry.Kind.SUFFIX],
	PracticeSet.PREFIXES: [TermEntry.Kind.PREFIX],
	PracticeSet.ROOTS: [TermEntry.Kind.ROOT],
	PracticeSet.SUFFIXES: [TermEntry.Kind.SUFFIX],
	PracticeSet.WORDS: [TermEntry.Kind.WORD],
	PracticeSet.BODY: [TermEntry.Kind.BODY],
	PracticeSet.ABBREVIATIONS: [TermEntry.Kind.ABBREVIATION],
	PracticeSet.EVERYTHING: [],
}

# ── Node references ──
@onready var _back: Button = $Layout/Header/Back
@onready var _practice: HBoxContainer = $Layout/Header/Practice
@onready var _practice_set: OptionButton = $Layout/Header/Practice/PracticeSet
@onready var _sections: TabContainer = $Layout/Sections
@onready var _reference: TermReference = $Layout/Sections/Reference
@onready var _flashcards: FlashcardDeck = $Layout/Sections/Flashcards
@onready var _quiz: QuizRunner = $Layout/Sections/Quiz


func _ready() -> void:
	_back.pressed.connect(back_requested.emit)
	_practice_set.item_selected.connect(func(_index: int) -> void: _load_practice())
	_sections.tab_changed.connect(_on_tab_changed)
	_load_practice()
	_on_tab_changed(_sections.current_tab)


## Opens the screen on the reference, showing one entry if given.
func open(entry: TermEntry = null, back_text: String = "← All modules") -> void:
	_back.text = back_text
	_sections.current_tab = Tab.REFERENCE
	if entry != null:
		_reference.show_term(entry)


func _load_practice() -> void:
	var entries: Array[TermEntry] = _practice_entries()
	_flashcards.load_deck(ContentLibrary.terminology_flashcards(entries))
	var questions: Array[QuizQuestion] = ContentLibrary.terminology_questions(entries)
	questions.shuffle()
	_quiz.start(questions.slice(0, QUIZ_SIZE))


func _practice_entries() -> Array[TermEntry]:
	var kinds: Array = KINDS_BY_SET[_practice_set.get_selected_id() as PracticeSet]
	var entries: Array[TermEntry] = []
	for entry: TermEntry in ContentLibrary.terms:
		if kinds.is_empty() or kinds.has(entry.kind):
			entries.append(entry)
	return entries


## The practice set only matters to the drills, so it hides on the reference tab.
func _on_tab_changed(tab: int) -> void:
	_practice.visible = tab != Tab.REFERENCE
