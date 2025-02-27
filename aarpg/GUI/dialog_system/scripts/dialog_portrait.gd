@tool
class_name DialogPortrait extends Sprite2D


var blink : bool = false : set = _set_blink
var open_mouth : bool = false : set = _set_open_mouth
var mouth_open_frames : int = 0
var audio_pitch_base : float = 1.0

@onready var audio_stream_player: AudioStreamPlayer = $"../AudioStreamPlayer"


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	DialogSystem.letter_added.connect( check_mount_open )
	blinker()
	pass

func check_mount_open( l : String ) -> void:
	#is the letter a vowel or number 
	#just so the animation isnt playing all the time
	if 'aeiouy1234567890'.contains( l ):
		open_mouth = true
		mouth_open_frames += 3 #then the magic happens in the setter function
		audio_stream_player.pitch_scale = randf_range( audio_pitch_base - 0.04, audio_pitch_base + 0.04 ) #give is some audio fun
		audio_stream_player.play()
	elif '.,!?'.contains( l ):#or an end punctuation
		mouth_open_frames = 0
		
	if mouth_open_frames > 0:
		mouth_open_frames -= 1
	
	if mouth_open_frames == 0:
		open_mouth = false
	pass

# move mouth and make blink
func update_portrait() -> void:
	if open_mouth == true:
		frame = 2
	else:
		frame = 0
		
	if blink == true:
		frame += 1
	pass

func _set_blink( _value : bool ) -> void:
	if blink != _value:
		blink = _value
		update_portrait()
	pass
	
func blinker() -> void:
	if blink == false:
		await get_tree().create_timer( randf_range( 0.1, 3) ).timeout
		
	else:
		await get_tree().create_timer( 0.15 ).timeout
	blink = not blink
	blinker()
	
func _set_open_mouth( _value : bool ) -> void:
	if open_mouth != _value:
		open_mouth = _value
		update_portrait()
	
	pass
