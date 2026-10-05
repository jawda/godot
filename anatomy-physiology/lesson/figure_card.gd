class_name FigureCard
extends VBoxContainer
## A figure on a lesson page. Sized to the image's aspect ratio; click to enlarge.

signal enlarge_requested(texture: Texture2D, caption: String)

const MAXIMUM_HEIGHT: float = 340.0
const MINIMUM_HEIGHT: float = 160.0
## The frame's padding around the picture, matching the FigureFrame style margins.
const FRAME_PADDING: float = 24.0

# ── Node references ──
@onready var _frame: Button = $Frame
@onready var _picture: TextureRect = $Frame/Picture
@onready var _caption: Label = $Caption
@onready var _credit: Label = $Credit


func _ready() -> void:
	_frame.pressed.connect(func() -> void: enlarge_requested.emit(_picture.texture, _caption.text))
	resized.connect(_fit_height)


## Hides the card when the section has no figure or the image file is missing.
func show_figure(section: LessonSection) -> void:
	var texture: Texture2D = null
	if section.has_figure():
		if ResourceLoader.exists(section.figure_path()):
			texture = load(section.figure_path())
		else:
			push_warning("Missing figure %s" % section.figure_path())
	visible = texture != null
	_picture.texture = texture
	_caption.text = section.figure_caption
	_caption.visible = not section.figure_caption.is_empty()
	_credit.text = section.figure_credit
	_fit_height()


func _fit_height() -> void:
	var texture: Texture2D = _picture.texture
	if texture == null or size.x <= 0.0:
		return
	var aspect: float = float(texture.get_height()) / texture.get_width()
	var natural_height: float = (size.x - FRAME_PADDING) * aspect + FRAME_PADDING
	var frame_height: float = clampf(natural_height, MINIMUM_HEIGHT, MAXIMUM_HEIGHT)
	# Shrink the frame's width to the picture so tall figures don't sit in a wide white box.
	var frame_width: float = minf(size.x, (frame_height - FRAME_PADDING) / aspect + FRAME_PADDING)
	_frame.custom_minimum_size = Vector2(frame_width, frame_height)
