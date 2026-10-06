class_name PreviewDiagrams
extends SceneTree
## Saves one PNG per labeled diagram: the figure cropped to the diagram's region with
## every label box painted over, so you can check no printed label still shows.
## Run headless:  Godot_console.exe --headless --path . -s res://tools/preview_diagrams.gd -- <output folder> [id prefix]

const MODULES_DIRECTORY: String = "res://content/modules"
const IMAGE_DIRECTORY: String = "res://content/images"
const BOX_FILL: Color = Color(1.0, 0.85, 0.2, 1.0)
const BOX_EDGE: Color = Color(0.85, 0.2, 0.1, 1.0)


func _initialize() -> void:
	var user_arguments: PackedStringArray = OS.get_cmdline_user_args()
	if user_arguments.is_empty():
		push_error("Pass an output folder after --")
		quit(1)
		return
	var output_directory: String = user_arguments[0]
	var id_prefix: String = user_arguments[1] if user_arguments.size() > 1 else ""
	DirAccess.make_dir_recursive_absolute(output_directory)
	var saved_count: int = 0
	for file_name: String in DirAccess.get_files_at(MODULES_DIRECTORY):
		if not file_name.ends_with(".json"):
			continue
		var module_data: Variant = JSON.parse_string(FileAccess.get_file_as_string(MODULES_DIRECTORY.path_join(file_name)))
		if not module_data is Dictionary:
			continue
		for diagram_data: Dictionary in (module_data as Dictionary).get("diagrams", []):
			var diagram_id: String = str(diagram_data.get("id", ""))
			if not diagram_id.begins_with(id_prefix):
				continue
			var image: Image = _paint_diagram(diagram_data)
			if image == null:
				continue
			image.save_png(output_directory.path_join("%s.png" % diagram_id))
			saved_count += 1
	print("Saved %d diagram previews to %s" % [saved_count, output_directory])
	quit()


func _paint_diagram(diagram_data: Dictionary) -> Image:
	var image_path: String = ProjectSettings.globalize_path(IMAGE_DIRECTORY.path_join(str(diagram_data.get("file", ""))))
	var image: Image = Image.load_from_file(image_path)
	if image == null:
		push_error("Could not read %s" % image_path)
		return null
	image.convert(Image.FORMAT_RGBA8)
	var image_size: Vector2 = Vector2(image.get_size())
	for label_data: Dictionary in diagram_data.get("labels", []):
		var box: Array = label_data.get("box", [])
		if box.size() != 4:
			continue
		var pixel_rect: Rect2i = Rect2i(Rect2(Vector2(box[0], box[1]) * image_size, Vector2(box[2], box[3]) * image_size))
		image.fill_rect(pixel_rect, BOX_EDGE)
		image.fill_rect(pixel_rect.grow(-2), BOX_FILL)
	var region: Array = diagram_data.get("region", [0, 0, 1, 1])
	var region_rect: Rect2i = Rect2i(Rect2(Vector2(region[0], region[1]) * image_size, Vector2(region[2], region[3]) * image_size))
	return image.get_region(region_rect.intersection(Rect2i(Vector2i.ZERO, image.get_size())))
