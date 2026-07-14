@tool
class_name SyncedMarkdownLabel
extends MarkdownLabel
## A MarkdownLabel that displays an external Markdown file at runtime so the
## scene and the source .md file never drift out of sync.
##
## Relative image links in the file are rewritten to absolute res:// paths
## anchored to the Markdown file's own directory, because RichTextLabel can
## only load image textures from resource paths — relative paths silently
## fail to load.

## The Markdown file to load and display. This is the single source of truth:
## edits to this file appear in the scene without touching the `.tscn`.
@export_file("*.md") var source_file: String = "res://assets/characters/character_notes.md"

func _ready() -> void:
	super()
	reload()

## Reloads [member source_file], rewrites its relative image links to absolute
## `res://` paths, and displays the result.
func reload() -> void:
	if source_file.is_empty():
		return
	var file_text: String = FileAccess.get_file_as_string(source_file)
	if file_text.is_empty():
		push_warning("SyncedMarkdownLabel: could not read '%s'" % source_file)
		return
	var base_directory: String = source_file.get_base_dir()
	markdown_text = _absolutize_image_paths(file_text, base_directory)

## Replaces relative image targets in Markdown image syntax with paths anchored
## to [param base_directory], leaving already-absolute links untouched.
func _absolutize_image_paths(text: String, base_directory: String) -> String:
	var image_regex: RegEx = RegEx.create_from_string("!\\[[^\\]]*\\]\\(([^)\\s]+)")
	var rewritten_text: String = text
	for image_match in image_regex.search_all(text):
		var original_path: String = image_match.get_string(1)
		if _is_absolute_link(original_path):
			continue
		var absolute_path: String = base_directory.path_join(original_path)
		rewritten_text = rewritten_text.replace("](%s)" % original_path, "](%s)" % absolute_path)
	return rewritten_text

## Returns true when [param path] already points somewhere absolute and should
## not be rewritten (a Godot resource path, a URL, or an absolute filesystem path).
func _is_absolute_link(path: String) -> bool:
	return path.begins_with("res://") \
		or path.begins_with("user://") \
		or path.begins_with("http://") \
		or path.begins_with("https://") \
		or path.begins_with("/")
