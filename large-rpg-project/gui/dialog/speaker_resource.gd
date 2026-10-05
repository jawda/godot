class_name SpeakerResource extends Resource
## Visual and audio identity for a single dialog speaker.
##
## The speaker_name is matched (case-insensitively) against the character name on
## each Dialogue Manager line, so the balloon can show the right portrait and pick
## the right voice pitch. Create one .tres per speaker under
## res://gui/dialog/speakers/ and SpeakerLibrary picks it up automatically.

## The name written before the colon in a .dialogue line, e.g. "Mira" in "Mira: Hello".
@export var speaker_name: String = ""

## A 4x2 portrait spritesheet (8 frames): top row eyes-open, bottom row blinking;
## columns are mouth states (closed, ajar, wide, shout). See [DialogPortrait].
@export var portrait: Texture2D

## Base pitch for this speaker's typing voice blips. Each blip is randomised
## slightly around this value, so different speakers sound distinct.
@export_range(0.5, 1.8, 0.02) var audio_pitch: float = 1.0
