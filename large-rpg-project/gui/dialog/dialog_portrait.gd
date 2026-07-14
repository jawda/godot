class_name DialogPortrait extends Sprite2D
## The speaker portrait inside the dialog balloon.
##
## It animates a simple two-state mouth in time with the typewriter and blinks at
## random intervals, plus plays a pitched voice blip per spoken letter.
##
## The portrait spritesheet is a 4x2 grid of 8 frames: the top row (0-3) is
## eyes-open, the bottom row (4-7) is eyes-closed (blink). Within each row the
## columns are mouth states: 0 = closed, 1 = ajar, 2 = wide, 3 = shout.

# Columns in the portrait grid to use for the closed and open mouth.
const MOUTH_CLOSED_COLUMN: int = 0
const MOUTH_OPEN_COLUMN: int = 2
const PORTRAIT_COLUMNS: int = 4

## Base pitch for this speaker's voice blips. The balloon sets this whenever the
## speaking character changes, so each speaker sounds distinct.
var audio_pitch_base: float = 1.0

var _is_blinking: bool = false
var _is_mouth_open: bool = false
var _mouth_open_frames: int = 0

# ── Node references ──
@onready var _voice_player: AudioStreamPlayer = $"../VoicePlayer"

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	DialogSystem.letter_added.connect(_on_letter_added)
	_blink_loop()

# Driven by DialogSystem.letter_added once per typed character. Vowels and digits
# open the mouth and play a blip; end punctuation plays a lower blip and closes it.
func _on_letter_added(letter: String) -> void:
	if "aeiouy1234567890".contains(letter):
		_set_mouth_open(true)
		_mouth_open_frames += 3
		_voice_player.pitch_scale = randf_range(audio_pitch_base - 0.04, audio_pitch_base + 0.04)
		_voice_player.play()
	elif ".,!?".contains(letter):
		_voice_player.pitch_scale = audio_pitch_base - 0.1
		_voice_player.play()
		_mouth_open_frames = 0

	if _mouth_open_frames > 0:
		_mouth_open_frames -= 1

	if _mouth_open_frames == 0 and _is_mouth_open:
		_set_mouth_open(false)
		_voice_player.pitch_scale = randf_range(audio_pitch_base - 0.08, audio_pitch_base + 0.02)
		_voice_player.play()

func _set_mouth_open(is_open: bool) -> void:
	if _is_mouth_open != is_open:
		_is_mouth_open = is_open
		_update_frame()

func _set_blinking(is_blinking: bool) -> void:
	if _is_blinking != is_blinking:
		_is_blinking = is_blinking
		_update_frame()

func _update_frame() -> void:
	var column: int = MOUTH_OPEN_COLUMN if _is_mouth_open else MOUTH_CLOSED_COLUMN
	var row: int = 1 if _is_blinking else 0
	frame = row * PORTRAIT_COLUMNS + column

# Loops forever: hold a frame, toggle the blink state, repeat. Open eyes linger a
# random while; the closed-eye blink itself is brief.
func _blink_loop() -> void:
	if _is_blinking:
		await get_tree().create_timer(0.15).timeout
	else:
		await get_tree().create_timer(randf_range(0.1, 3.0)).timeout
	_set_blinking(not _is_blinking)
	_blink_loop()
