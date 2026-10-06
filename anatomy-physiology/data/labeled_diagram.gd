class_name LabeledDiagram
extends RefCounted
## A lesson figure with its printed labels hidden, for label-the-diagram practice.

const IMAGE_DIRECTORY: String = "res://content/images"

var id: String = ""
var module_id: String = ""
var title: String = ""
var prompt: String = ""
var image_file: String = ""
## The part of the image to show, as fractions of the whole image. One figure with
## several panels can give several diagrams.
var region: Rect2 = Rect2(0.0, 0.0, 1.0, 1.0)
var credit: String = ""
var labels: Array[DiagramLabel] = []


static func from_dictionary(data: Dictionary, owning_module_id: String) -> LabeledDiagram:
	var diagram: LabeledDiagram = LabeledDiagram.new()
	diagram.id = str(data.get("id", ""))
	diagram.module_id = owning_module_id
	diagram.title = str(data.get("title", ""))
	diagram.prompt = str(data.get("prompt", ""))
	diagram.image_file = str(data.get("file", ""))
	diagram.credit = str(data.get("credit", ""))
	var region_values: Array = data.get("region", [])
	if region_values.size() == 4:
		diagram.region = Rect2(float(region_values[0]), float(region_values[1]), float(region_values[2]), float(region_values[3]))
	for label_data: Dictionary in data.get("labels", []):
		diagram.labels.append(DiagramLabel.from_dictionary(label_data))
	return diagram


func image_path() -> String:
	return IMAGE_DIRECTORY.path_join(image_file)
