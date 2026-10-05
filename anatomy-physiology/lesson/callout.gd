class_name Callout
extends PanelContainer
## A boxed aside in a lesson page: a memory tip or a clinical connection.

## Set in the parent scene to pick the clinical styling instead of the tip styling.
@export var is_clinical: bool = false

# ── Node references ──
@onready var _kind: Label = $Layout/Kind
@onready var _body: RichTextLabel = $Layout/Body


func _ready() -> void:
	if is_clinical:
		theme_type_variation = &"CalloutClinical"
		_kind.theme_type_variation = &"CalloutClinicalLabel"
		_kind.text = "CLINICAL CONNECTION"


## Hides the callout when there is nothing to say.
func show_text(text: String) -> void:
	visible = not text.is_empty()
	_body.text = text
