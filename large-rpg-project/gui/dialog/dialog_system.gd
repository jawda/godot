class_name DialogSystemNode extends CanvasLayer
## Global dialog balloon.
##
## This drives the on-screen presentation — typewriter text with per-punctuation
## pacing, an animated portrait, voice blips, a NEXT/END indicator and choice
## buttons. The actual conversation content and branching come from a Dialogue
## Manager .dialogue resource, which this balloon walks line by line.
##
## Registered as the "DialogSystem" AutoLoad. The rest of the game only needs:
##   DialogSystem.start(load("res://dialog/scripts/intro.dialogue"), "start")
## A speaker name on each line (e.g. "Mira: Hello") is resolved to a portrait and
## voice pitch via [SpeakerLibrary], so single- and multi-character conversations
## work the same way.

## Emitted when the conversation finishes and the balloon closes.
signal finished
## Emitted once per typed letter so the portrait can animate its mouth and blip.
signal letter_added(letter: String)

const TYPE_SPEED: float = 0.02
# next_id values Dialogue Manager uses to mean "the conversation ends here".
const END_IDS: Array[String] = ["", "end", "end!"]
# On-screen size (px) a single portrait frame is scaled to, so portrait sheets of
# any source resolution (64px art, the 192px placeholder, etc.) display the same.
const PORTRAIT_FRAME_SIZE: float = 64.0

var is_active: bool = false

var _text_in_progress: bool = false
var _waiting_for_choice: bool = false
var _visible_text_length: int = 0
var _plain_text: String = ""

var _dialogue_resource: DialogueResource
var _current_line: DialogueLine
# Passed to Dialogue Manager so .dialogue conditions/mutations can reference this
# balloon now and other systems (e.g. a future quest manager) later.
var _game_states: Array = []

# ── Node references ──
@onready var _dialog_ui: Control = $DialogUI
@onready var _content: RichTextLabel = $DialogUI/TextBubble/Content
@onready var _name_plate: PanelContainer = $DialogUI/NamePlate
@onready var _speaker_name: Label = $DialogUI/NamePlate/SpeakerName
@onready var _portrait: DialogPortrait = $DialogUI/Portrait
@onready var _progress_indicator: PanelContainer = $DialogUI/ProgressIndicator
@onready var _progress_caption: Label = $DialogUI/ProgressIndicator/Caption
@onready var _type_timer: Timer = $DialogUI/TypeTimer
@onready var _voice_player: AudioStreamPlayer = $DialogUI/VoicePlayer
@onready var _choices: VBoxContainer = $DialogUI/Choices

@onready var _placeholder_portrait: Texture2D = preload("res://assets/characters/Placeholder_Face_192x192.png")


func _ready() -> void:
	_type_timer.timeout.connect(_on_type_timer_timeout)
	_hide_dialog()

## Opens the balloon and starts playing [param cue] from [param resource]. Pauses
## the game tree for the duration of the conversation.
func start(resource: DialogueResource, cue: String = "start") -> void:
	if resource == null:
		push_warning("DialogSystem.start: resource is null")
		return
	is_active = true
	_dialogue_resource = resource
	_game_states = [self]
	_dialog_ui.visible = true
	_dialog_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	_current_line = await resource.get_next_dialogue_line(cue, _game_states)
	if _current_line == null:
		_hide_dialog()
	else:
		_show_line()

func _hide_dialog() -> void:
	is_active = false
	_waiting_for_choice = false
	_text_in_progress = false
	get_viewport().gui_release_focus()
	_choices.visible = false
	_dialog_ui.visible = false
	_dialog_ui.process_mode = Node.PROCESS_MODE_DISABLED
	get_tree().paused = false
	finished.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	if not event.is_action_pressed("ui_accept"):
		return
	if _text_in_progress:
		# Skip the typewriter: reveal the whole line at once.
		_content.visible_characters = _visible_text_length
		_type_timer.stop()
		_text_in_progress = false
		_on_text_finished()
		get_viewport().set_input_as_handled()
		return
	if _waiting_for_choice:
		# The focused choice button handles ui_accept itself.
		return
	get_viewport().set_input_as_handled()
	_advance(_current_line.next_id)

func _advance(next_id: String) -> void:
	_current_line = await _dialogue_resource.get_next_dialogue_line(next_id, _game_states)
	if _current_line == null:
		_hide_dialog()
	else:
		_show_line()

func _show_line() -> void:
	_waiting_for_choice = false
	_choices.visible = false
	_show_progress_indicator(false)

	_apply_speaker(_current_line.character)
	_content.text = _current_line.text
	_content.visible_characters = 0
	_visible_text_length = _content.get_total_character_count()
	_plain_text = _content.get_parsed_text()
	_text_in_progress = true
	_start_type_timer()

# Resolve the speaker name to a portrait + voice pitch, falling back to a
# placeholder portrait for any name not defined in the SpeakerLibrary.
func _apply_speaker(speaker_name: String) -> void:
	_speaker_name.text = speaker_name
	_name_plate.visible = not speaker_name.is_empty()
	var speaker: SpeakerResource = SpeakerLibrary.get_speaker(speaker_name)
	if speaker != null:
		_portrait.texture = speaker.portrait
		_portrait.audio_pitch_base = speaker.audio_pitch
	else:
		_portrait.texture = _placeholder_portrait
		_portrait.audio_pitch_base = 1.0
	_normalize_portrait_scale()

# Scale the portrait so one frame fills PORTRAIT_FRAME_SIZE on screen, regardless
# of the source sheet's resolution (e.g. 64px character art vs the 192px placeholder).
func _normalize_portrait_scale() -> void:
	var frame_width: float = float(_portrait.texture.get_width()) / float(_portrait.hframes)
	if frame_width > 0.0:
		_portrait.scale = Vector2.ONE * (PORTRAIT_FRAME_SIZE / frame_width)

func _start_type_timer() -> void:
	_type_timer.wait_time = TYPE_SPEED
	# Pause a little longer after sentence punctuation, a little after spaces/commas.
	if _content.visible_characters > 0:
		var last_letter: String = _plain_text[_content.visible_characters - 1]
		if ".!?:;".contains(last_letter):
			_type_timer.wait_time *= 4
		elif " ,".contains(last_letter):
			_type_timer.wait_time *= 2
	_type_timer.start()

func _on_type_timer_timeout() -> void:
	_content.visible_characters += 1
	if _content.visible_characters <= _visible_text_length:
		letter_added.emit(_plain_text[_content.visible_characters - 1])
		_start_type_timer()
	else:
		_text_in_progress = false
		_on_text_finished()

# Called once the line's text is fully typed (or skipped): either offer the
# choice buttons or show the NEXT/END advance indicator.
func _on_text_finished() -> void:
	var allowed_responses: Array = _current_line.responses.filter(
		func(response: DialogueResponse) -> bool: return response.is_allowed
	)
	if allowed_responses.size() > 0:
		_show_choices(allowed_responses)
	else:
		_show_progress_indicator(true)

func _show_progress_indicator(should_show: bool) -> void:
	_progress_indicator.visible = should_show
	_progress_caption.text = "END" if END_IDS.has(_current_line.next_id) else "NEXT"

func _show_choices(responses: Array) -> void:
	_waiting_for_choice = true
	_choices.visible = true
	# Release focus first so we never free a control that still holds it.
	get_viewport().gui_release_focus()
	for existing_choice in _choices.get_children():
		existing_choice.queue_free()
	for response in responses:
		var choice_button: Button = Button.new()
		choice_button.text = response.text
		choice_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		choice_button.pressed.connect(_on_choice_selected.bind(response))
		_choices.add_child(choice_button)
	# Wait two frames so the new buttons are laid out before grabbing focus.
	await get_tree().process_frame
	await get_tree().process_frame
	_choices.get_child(0).grab_focus()

func _on_choice_selected(response: DialogueResponse) -> void:
	_waiting_for_choice = false
	# Drop focus before the selected button is hidden/freed, otherwise the engine
	# tries to clean up focus on a vanished control and logs a (harmless) list error.
	get_viewport().gui_release_focus()
	_choices.visible = false
	_advance(response.next_id)
