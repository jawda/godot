extends CanvasLayer

signal shown
signal hidden


const ERROR = preload("res://GUI/shop_menu/audio/error.wav")
const OPEN_SHOP = preload("res://GUI/shop_menu/audio/open_shop.wav")
const PURCHASE = preload("res://GUI/shop_menu/audio/purchase.wav")

var is_active : bool = false

@onready var audio_stream_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

@onready var close_button: Button = %CloseButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide_menu()
	close_button.pressed.connect( hide_menu )
	pass
	
func _unhandled_input(event: InputEvent) -> void:
	if is_active == false:
		return
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		hide_menu()
	pass
	
func show_menu( items : Array[ ItemData ], dialog_triggered : bool = true ) -> void:
	print(items, items.size() )
	if dialog_triggered:
		await DialogSystem.finished
	enable_menu()
	play_audio( OPEN_SHOP )
	shown.emit()
	pass
	
func hide_menu() -> void:
	enable_menu( false )
	hidden.emit()
	pass
	
func enable_menu( _enabled : bool = true) -> void:
	get_tree().paused = _enabled
	visible = _enabled
	is_active = _enabled
	pass

func play_audio( _audio : AudioStream ) -> void:
	audio_stream_player.stream = _audio
	audio_stream_player.play()
