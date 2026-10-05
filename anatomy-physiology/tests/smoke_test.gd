class_name SmokeTest
extends Node
## Drives the real UI through every module: reads each lesson, flips and grades every
## flashcard, and answers every quiz question. Run headless:
##   Godot_console.exe --headless --path <project> res://tests/smoke_test.tscn
## Pass "-- --screenshots" (without --headless) to also save PNGs to user://screenshots.

const MAIN_SCENE: PackedScene = preload("res://main/main.tscn")

var _failures: PackedStringArray = []
var _take_screenshots: bool = false


func _ready() -> void:
	_take_screenshots = OS.get_cmdline_user_args().has("--screenshots")
	for leftover: StudyProfile in StudyProgress.profiles():
		StudyProgress.delete_profile(leftover.id)
	var study_guide: StudyGuide = MAIN_SCENE.instantiate()
	add_child(study_guide)
	await _settle()
	await _exercise_profiles(study_guide)
	await _snap("menu")
	_check(not ContentLibrary.modules.is_empty(), "no modules loaded")
	var tile_index: int = 0
	for module: StudyModule in ContentLibrary.modules:
		await _exercise_module(study_guide, module, tile_index == 0)
		tile_index += 1
	await _exercise_reviews(study_guide)
	await _exercise_continue(study_guide)
	for profile: StudyProfile in StudyProgress.profiles():
		StudyProgress.delete_profile(profile.id)
	if _failures.is_empty():
		print("SMOKE TEST PASSED: %d modules, %d questions" % [ContentLibrary.modules.size(), ContentLibrary.total_question_count()])
	else:
		for failure: String in _failures:
			printerr("FAIL: ", failure)
		print("SMOKE TEST FAILED (%d problems)" % _failures.size())
	get_tree().quit(0 if _failures.is_empty() else 1)


## Creates profiles through the real screen, then checks rename, export/import, delete.
func _exercise_profiles(study_guide: StudyGuide) -> void:
	var profile_select: ProfileSelect = study_guide._profile_select
	_check(profile_select.visible, "profile screen not shown at launch")
	_check(profile_select._no_profiles.visible, "empty-state text missing with no profiles")
	profile_select._name_input.text = "Second Student"
	profile_select._create.pressed.emit()
	await _settle()
	_check(study_guide._module_menu.visible, "creating a profile did not open the menu")
	study_guide._module_menu._switch_profile.pressed.emit()
	await _settle()
	profile_select._name_input.text = "Joe"
	profile_select._create.pressed.emit()
	await _settle()
	var active: StudyProfile = StudyProgress.active_profile()
	_check(active != null and active.display_name == "Joe", "new profile not active")
	_check(study_guide._module_menu._studying_as.text.contains("Joe"), "menu does not show profile name")

	StudyProgress.rename_profile(active.id, "Joe W")
	_check(StudyProgress.active_profile().display_name == "Joe W", "rename failed")
	StudyProgress.record_answer("m01_q01", true)
	var export_path: String = ProjectSettings.globalize_path("user://smoke_test_export.json")
	_check(StudyProgress.export_profile(active.id, export_path) == OK, "export failed")
	var imported: StudyProfile = StudyProgress.import_profile(export_path)
	_check(imported != null, "import failed")
	if imported != null:
		_check(imported.display_name == "Joe W (2)", "imported profile name should be deduplicated, got %s" % imported.display_name)
		_check(int(StudyProgress.profile_summary(imported.id)["mastered"]) == 1, "imported progress missing")
		StudyProgress.delete_profile(imported.id)
	DirAccess.remove_absolute(export_path)
	_check(StudyProgress.profiles().size() == 2, "expected 2 profiles after delete, got %d" % StudyProgress.profiles().size())

	study_guide._module_menu._switch_profile.pressed.emit()
	await _settle()
	_check(profile_select._profile_list.get_child_count() == 2, "profile list should show 2 cards")
	await _snap("profiles")
	var cards: Array[Node] = profile_select._profile_list.get_children()
	var joe_card: ProfileCard = cards[0]
	joe_card._open.pressed.emit()
	await _settle()
	_check(StudyProgress.active_profile().display_name == "Joe W", "most recent profile should be listed first")
	_check(StudyProgress.was_answered("m01_q01"), "progress lost after switching back to profile")
	StudyProgress.reset_all()


## Leaves a lesson mid-section, then checks the menu's Continue reopens that exact page.
func _exercise_continue(study_guide: StudyGuide) -> void:
	var module: StudyModule = ContentLibrary.modules[2]
	study_guide._module_menu.module_chosen.emit(module)
	await _settle()
	var study: ModuleStudy = study_guide._module_study
	study._lesson._open_section(4, 1)
	study._back.pressed.emit()
	await _settle()
	var menu: ModuleMenu = study_guide._module_menu
	_check(menu._continue.visible and menu._continue.text.contains(str(module.order)), "Continue button not offered for last module")
	menu._continue.pressed.emit()
	await _settle()
	_check(study.visible and study._sections.current_tab == ModuleStudy.Tab.LESSON, "Continue did not reopen the lesson")
	_check(study._lesson._section_index == 4 and study._lesson._page_index == 1, "lesson did not resume at section 5 page 2")
	study._sections.current_tab = ModuleStudy.Tab.QUIZ
	study._back.pressed.emit()
	await _settle()
	menu._continue.pressed.emit()
	await _settle()
	_check(study._sections.current_tab == ModuleStudy.Tab.QUIZ, "Continue did not reopen the last tab")
	study._back.pressed.emit()
	await _settle()


func _exercise_module(study_guide: StudyGuide, module: StudyModule, is_first: bool) -> void:
	print("%s: %d sections, %d cards, %d questions" % [module.id, module.lesson_sections.size(),
		module.flashcards.size(), module.quiz_questions.size()])
	study_guide._module_menu.module_chosen.emit(module)
	await _settle()
	var study: ModuleStudy = study_guide._module_study
	_check(study.visible, "%s: study screen not shown" % module.id)

	await _page_through_lesson(study, module, is_first)

	study._sections.current_tab = ModuleStudy.Tab.FLASHCARDS
	await _settle()
	var deck: FlashcardDeck = study._flashcards
	var flips: int = 0
	while not deck._queue.is_empty() and flips < 500:
		deck._card.pressed.emit()
		if is_first and flips == 0:
			await _settle()
			await _snap("flashcard_back")
		# Mark every other card as still learning so the requeue path runs too.
		var know_it: bool = flips % 2 == 0 or flips >= module.flashcards.size()
		(deck._know_it if know_it else deck._still_learning).pressed.emit()
		flips += 1
	_check(deck._queue.is_empty(), "%s: flashcard deck never finished" % module.id)
	_check(StudyProgress.known_flashcard_count(module) == module.flashcards.size(), "%s: not all cards known" % module.id)

	study._sections.current_tab = ModuleStudy.Tab.QUIZ
	await _settle()
	await _answer_all(study._quiz, module.id, is_first)
	_check(StudyProgress.best_quiz_score(module.id) >= 0.0, "%s: best score not recorded" % module.id)
	study._back.pressed.emit()
	await _settle()
	_check(study_guide._module_menu.visible, "%s: back did not return to menu" % module.id)


## Clicks Next through every page; the last Next should hand off to the flashcards tab.
func _page_through_lesson(study: ModuleStudy, module: StudyModule, take_snaps: bool) -> void:
	var lesson: LessonView = study._lesson
	var page_count: int = 0
	var longest_page: int = 0
	var figures_shown: int = 0
	while study._sections.current_tab == ModuleStudy.Tab.LESSON and page_count < 300:
		var parsed_page: String = lesson._text.get_parsed_text()
		longest_page = maxi(longest_page, parsed_page.length())
		_check(not parsed_page.is_empty(), "%s: empty lesson page in %s" % [module.id, lesson._heading.text])
		_check(not parsed_page.contains("["), "%s: unparsed BBCode in %s" % [module.id, lesson._heading.text])
		if lesson._figure.visible:
			figures_shown += 1
			if take_snaps and figures_shown == 1:
				await _settle()
				await _snap("lesson_figure")
				lesson._figure._frame.pressed.emit()
				await _settle()
				await _exercise_viewer(study._figure_viewer)
				study._figure_viewer._close.pressed.emit()
		if take_snaps and page_count == 0:
			await _settle()
			await _snap("lesson_overview")
		lesson._next.pressed.emit()
		page_count += 1
	_check(study._sections.current_tab == ModuleStudy.Tab.FLASHCARDS, "%s: lesson never finished" % module.id)
	_check(StudyProgress.read_section_count(module) == module.lesson_sections.size(), "%s: sections not all marked read" % module.id)
	var expected_figures: int = 0
	for section: LessonSection in module.lesson_sections:
		if section.has_figure():
			expected_figures += 1
			_check(ResourceLoader.exists(section.figure_path()), "%s: missing image %s" % [module.id, section.figure_file])
	_check(figures_shown == expected_figures, "%s: showed %d of %d figures" % [module.id, figures_shown, expected_figures])
	print("    lesson: %d pages, longest %d chars, %d figures" % [page_count, longest_page, figures_shown])
	if take_snaps:
		study._sections.current_tab = ModuleStudy.Tab.LESSON
		lesson._open_section(3, 0)
		await _settle()
		await _snap("lesson_outline_progress")
		study._sections.current_tab = ModuleStudy.Tab.FLASHCARDS


## Checks fit, stepping, presets, and the slider all agree on the zoom level.
func _exercise_viewer(viewer: FigureViewer) -> void:
	_check(viewer.visible, "figure viewer did not open")
	var fit_zoom: float = viewer._zoom
	_check(viewer._is_fitting and fit_zoom > 0.1 and fit_zoom <= 2.0, "viewer did not fit the figure (zoom %.2f)" % fit_zoom)
	await _snap("figure_viewer")
	viewer._zoom_in.pressed.emit()
	await _settle()
	_check(viewer._zoom > fit_zoom and not viewer._is_fitting, "zoom in did not increase zoom")
	viewer._on_zoom_preset(150)
	await _settle()
	_check(is_equal_approx(viewer._zoom, 1.5), "150% preset not applied")
	_check(viewer._zoom_level.text == "150%" and is_equal_approx(viewer._zoom_slider.value, 150.0), "zoom label/slider out of sync")
	_check(viewer._picture.size.x > viewer._canvas.size.x or viewer._picture.size.y > viewer._canvas.size.y, "150% picture should overflow the canvas")
	await _snap("figure_viewer_zoomed")
	viewer._zoom_slider.value = 60.0
	await _settle()
	_check(is_equal_approx(viewer._zoom, 0.6), "slider did not set zoom")
	viewer._zoom_out.pressed.emit()
	await _settle()
	_check(is_equal_approx(viewer._zoom, 0.5), "zoom out should step to 50%%, got %.2f" % viewer._zoom)
	# A trackpad pinch arrives as a burst of small magnify events within one frame.
	var zoom_before_pinch: float = viewer._zoom
	for pinch_step: int in 15:
		var pinch: InputEventMagnifyGesture = InputEventMagnifyGesture.new()
		pinch.factor = 1.1
		pinch.position = viewer._canvas.size * 0.5
		viewer._on_stage_input(pinch)
	await _settle()
	_check(is_equal_approx(viewer._zoom, zoom_before_pinch * pow(1.1, 15)), "pinch zoom wrong: %.3f" % viewer._zoom)
	_check(viewer._canvas.scroll_horizontal > 0 and viewer._canvas.scroll_vertical > 0, "pinch toward the centre should scroll into the image")
	# Pinch again off-centre: the image point under the fingers must not move.
	var anchor: Vector2 = viewer._canvas.size * Vector2(0.3, 0.7)
	var point_before: Vector2 = _image_point_under(viewer, anchor)
	var off_centre_pinch: InputEventMagnifyGesture = InputEventMagnifyGesture.new()
	off_centre_pinch.factor = 0.8
	off_centre_pinch.position = anchor - viewer._stage.position
	viewer._on_stage_input(off_centre_pinch)
	await _settle()
	var drift: float = point_before.distance_to(_image_point_under(viewer, anchor))
	_check(drift < 2.0, "pinch drifted %.1f image pixels from the pointer" % drift)
	viewer._fit.pressed.emit()
	await _settle()
	_check(viewer._is_fitting and is_equal_approx(viewer._zoom, fit_zoom), "fit did not restore fit zoom")


func _image_point_under(viewer: FigureViewer, anchor: Vector2) -> Vector2:
	var scroll: Vector2 = Vector2(viewer._canvas.scroll_horizontal, viewer._canvas.scroll_vertical)
	return (scroll + anchor - viewer._picture.position) / viewer._zoom


## Answers wrong on every third question so missed-question tracking gets exercised.
func _answer_all(runner: QuizRunner, label: String, take_snaps: bool) -> void:
	var answered: int = 0
	while runner._session.visible and answered < 200:
		var question: QuizQuestion = runner._questions[runner._question_index]
		var parsed_explanation: String = _parse_bbcode(question.explanation)
		_check(not parsed_explanation.contains("["), "%s: unparsed BBCode in %s" % [label, question.id])
		var answer_wrong: bool = answered % 3 == 2
		if question.kind == QuizQuestion.Kind.ORDERING:
			_check(question.ordered_items.size() >= 3, "%s: ordering with < 3 items" % question.id)
			if take_snaps and answered < 40:
				await _settle()
				await _snap("ordering_before")
			runner._advance.pressed.emit()
		else:
			_check(runner._choice_buttons.size() == question.choices.size(), "%s: choice buttons missing" % question.id)
			_check(question.correct_choice >= 0 and question.correct_choice < question.choices.size(), "%s: answer index out of range" % question.id)
			var correct_slot: int = runner._choice_order.find(question.correct_choice)
			var slot: int = (correct_slot + 1) % question.choices.size() if answer_wrong else correct_slot
			runner._choice_buttons[slot].pressed.emit()
		_check(runner._feedback.visible, "%s: no feedback after answering" % question.id)
		if take_snaps and answered == 2:
			await _settle()
			await _snap("quiz_feedback")
		runner._advance.pressed.emit()
		answered += 1
	_check(runner._results.visible, "%s: results never shown" % label)
	if take_snaps:
		await _settle()
		await _snap("quiz_results")


func _exercise_reviews(study_guide: StudyGuide) -> void:
	var missed_before: int = StudyProgress.missed_question_ids().size()
	_check(missed_before > 0, "nothing recorded as missed")
	study_guide._module_menu.missed_review_requested.emit()
	await _settle()
	var runner: QuizRunner = study_guide._review_session._runner
	_check(runner._questions.size() == missed_before, "missed review size mismatch")
	await _answer_all(runner, "missed review", false)
	study_guide._review_session._back.pressed.emit()
	await _settle()
	study_guide._module_menu.mixed_review_requested.emit()
	await _settle()
	_check(runner._questions.size() == mini(ReviewSession.MIXED_REVIEW_SIZE, ContentLibrary.total_question_count()), "mixed review size wrong")
	await _snap("mixed_review")
	await _answer_all(runner, "mixed review", false)
	study_guide._review_session._back.pressed.emit()
	await _settle()
	await _snap("menu_after")


func _parse_bbcode(text: String) -> String:
	var parser: RichTextLabel = RichTextLabel.new()
	parser.bbcode_enabled = true
	parser.text = text
	var parsed: String = parser.get_parsed_text()
	parser.free()
	return parsed


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _settle() -> void:
	for frame_index: int in 3:
		await get_tree().process_frame


func _snap(shot_name: String) -> void:
	if not _take_screenshots:
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("user://screenshots")
	get_viewport().get_texture().get_image().save_png("user://screenshots/%s.png" % shot_name)
