extends Node
## Resolves a dialog speaker name to its [SpeakerResource] so the dialog balloon
## can show the right portrait and voice pitch.
##
## Drop a new SpeakerResource .tres into [constant SPEAKERS_DIRECTORY] and it is
## registered automatically on load — no manual wiring. Names are matched
## case-insensitively against the character name of each Dialogue Manager line.
##
## Registered as the "SpeakerLibrary" AutoLoad singleton, which is why this script
## intentionally declares no class_name (Godot forbids class_name on AutoLoads).

const SPEAKERS_DIRECTORY: String = "res://gui/dialog/speakers/"

# Maps speaker_name.to_lower() -> SpeakerResource.
var _speakers_by_name: Dictionary = {}

func _ready() -> void:
	_load_speakers()

func _load_speakers() -> void:
	var directory: DirAccess = DirAccess.open(SPEAKERS_DIRECTORY)
	if directory == null:
		push_warning("SpeakerLibrary: could not open '%s'" % SPEAKERS_DIRECTORY)
		return
	for file_name in directory.get_files():
		# Exported builds rename resources to *.tres.remap; tolerate both.
		var resource_name: String = file_name.trim_suffix(".remap")
		if not resource_name.ends_with(".tres"):
			continue
		var loaded_resource: Resource = load(SPEAKERS_DIRECTORY.path_join(resource_name))
		if loaded_resource is SpeakerResource and not loaded_resource.speaker_name.is_empty():
			_speakers_by_name[loaded_resource.speaker_name.to_lower()] = loaded_resource

## Returns the SpeakerResource registered for [param speaker_name], or null if no
## speaker with that name has been defined. The caller is responsible for falling
## back to a placeholder portrait so unknown speakers never hard-error.
func get_speaker(speaker_name: String) -> SpeakerResource:
	return _speakers_by_name.get(speaker_name.to_lower(), null)
