class_name ShrinkFigures
extends SceneTree
## Shrinks oversized figures in content/images in place so the project stays small.
## Run headless:  Godot_console.exe --headless --path . -s res://tools/shrink_figures.gd

const IMAGE_DIRECTORY: String = "res://content/images"
const MAXIMUM_WIDTH: int = 1100
const MAXIMUM_HEIGHT: int = 1400
const JPEG_QUALITY: float = 0.85


func _initialize() -> void:
	var shrunk_count: int = 0
	for file_name: String in DirAccess.get_files_at(IMAGE_DIRECTORY):
		var extension: String = file_name.get_extension().to_lower()
		if extension not in ["jpg", "jpeg", "png"]:
			continue
		var path: String = ProjectSettings.globalize_path(IMAGE_DIRECTORY.path_join(file_name))
		var image: Image = Image.load_from_file(path)
		if image == null:
			push_error("Could not read %s" % file_name)
			continue
		var scale: float = minf(float(MAXIMUM_WIDTH) / image.get_width(), float(MAXIMUM_HEIGHT) / image.get_height())
		if scale >= 1.0:
			continue
		image.resize(roundi(image.get_width() * scale), roundi(image.get_height() * scale), Image.INTERPOLATE_LANCZOS)
		var error: Error = image.save_jpg(path, JPEG_QUALITY) if extension != "png" else image.save_png(path)
		if error != OK:
			push_error("Could not save %s: %s" % [file_name, error_string(error)])
			continue
		shrunk_count += 1
		print("shrunk %s to %dx%d" % [file_name, image.get_width(), image.get_height()])
	print("Shrank %d figures." % shrunk_count)
	quit()
