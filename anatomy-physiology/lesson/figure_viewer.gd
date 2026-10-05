class_name FigureViewer
extends Control
## Full-window figure viewer with photo-app style zoom: fit, preset levels, a slider,
## mouse-wheel or trackpad-pinch zoom toward the pointer, drag to pan, and double-click
## to toggle fit. On a Mac trackpad, two-finger swipes arrive as pan gestures, which the
## ScrollContainer already turns into panning; pinches arrive as magnify gestures.
## top_level lets it cover the whole window even though its parent is a container.

const MINIMUM_ZOOM: float = 0.1
const MAXIMUM_ZOOM: float = 4.0
## Zoom in/out buttons step through these levels.
const ZOOM_STEPS: Array[float] = [0.1, 0.25, 0.33, 0.5, 0.67, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0, 4.0]
const WHEEL_ZOOM_FACTOR: float = 1.15
const FIT_MENU_ID: int = 0

## 1.0 means one image pixel per screen pixel.
var _zoom: float = 1.0
## While true the zoom follows the window size.
var _is_fitting: bool = true
var _is_dragging: bool = false
## Guards against the slider's value_changed firing when code moves the slider.
var _is_updating_controls: bool = false
## Scroll position waiting to be applied next frame. Pinch gestures arrive many times a
## frame, so each zoom step must build on the pending scroll, not the stale real one.
var _pending_scroll: Vector2 = Vector2.ZERO
var _has_pending_scroll: bool = false

# ── Node references ──
@onready var _caption: Label = $ScreenPadding/Layout/Header/Caption
@onready var _close: Button = $ScreenPadding/Layout/Header/Close
@onready var _canvas: ScrollContainer = $ScreenPadding/Layout/Canvas
@onready var _stage: CenterContainer = $ScreenPadding/Layout/Canvas/Stage
@onready var _picture: TextureRect = $ScreenPadding/Layout/Canvas/Stage/Picture
@onready var _fit: Button = $ScreenPadding/Layout/ToolbarRow/Toolbar/Controls/Fit
@onready var _zoom_level: MenuButton = $ScreenPadding/Layout/ToolbarRow/Toolbar/Controls/ZoomLevel
@onready var _zoom_out: Button = $ScreenPadding/Layout/ToolbarRow/Toolbar/Controls/ZoomOut
@onready var _zoom_slider: HSlider = $ScreenPadding/Layout/ToolbarRow/Toolbar/Controls/ZoomSlider
@onready var _zoom_in: Button = $ScreenPadding/Layout/ToolbarRow/Toolbar/Controls/ZoomIn
@onready var _hint: Label = $ScreenPadding/Layout/ToolbarRow/Toolbar/Controls/Hint


func _ready() -> void:
	_close.pressed.connect(hide)
	_fit.pressed.connect(fit_to_window)
	_zoom_in.pressed.connect(_step_zoom.bind(1))
	_zoom_out.pressed.connect(_step_zoom.bind(-1))
	_zoom_slider.value_changed.connect(_on_slider_changed)
	_zoom_level.get_popup().id_pressed.connect(_on_zoom_preset)
	_stage.gui_input.connect(_on_stage_input)
	_canvas.resized.connect(_on_canvas_resized)
	if OS.get_name() == "macOS":
		_hint.text = "Pinch to zoom · two-finger drag to pan · double-click to fit"


func open(texture: Texture2D, caption: String) -> void:
	_picture.texture = texture
	_caption.text = caption
	show()
	# The canvas has no size until the viewer has been laid out once.
	await get_tree().process_frame
	fit_to_window()


func fit_to_window() -> void:
	_is_fitting = true
	_apply_zoom(_fit_zoom(), _canvas.size * 0.5)


func set_zoom(zoom: float) -> void:
	_is_fitting = false
	_apply_zoom(zoom, _canvas.size * 0.5)


func _fit_zoom() -> float:
	var texture: Texture2D = _picture.texture
	if texture == null or _canvas.size.x <= 0.0:
		return 1.0
	var fit: float = minf(_canvas.size.x / texture.get_width(), _canvas.size.y / texture.get_height())
	# Small figures may grow to fill the window, but not past double size.
	return clampf(fit, MINIMUM_ZOOM, 2.0)


## Changes zoom while keeping the image point under `anchor` (canvas coordinates) still.
func _apply_zoom(zoom: float, anchor: Vector2) -> void:
	var texture: Texture2D = _picture.texture
	if texture == null:
		return
	var new_zoom: float = clampf(zoom, MINIMUM_ZOOM, MAXIMUM_ZOOM)
	var old_scroll: Vector2 = _pending_scroll if _has_pending_scroll else Vector2(_canvas.scroll_horizontal, _canvas.scroll_vertical)
	var old_offset: Vector2 = _centering_offset(_zoom)
	var image_point: Vector2 = (old_scroll + anchor - old_offset) / _zoom
	_zoom = new_zoom
	var picture_size: Vector2 = Vector2(texture.get_size()) * _zoom
	_picture.custom_minimum_size = picture_size
	# The stage is at least as big as the canvas so a small picture sits centred.
	_stage.custom_minimum_size = Vector2(maxf(picture_size.x, _canvas.size.x), maxf(picture_size.y, _canvas.size.y))
	_update_controls()
	var target_scroll: Vector2 = image_point * _zoom + _centering_offset(_zoom) - anchor
	var stage_size: Vector2 = _stage.custom_minimum_size
	target_scroll = target_scroll.clamp(Vector2.ZERO, (stage_size - _canvas.size).max(Vector2.ZERO))
	_pending_scroll = target_scroll
	if _has_pending_scroll:
		return
	_has_pending_scroll = true
	# Scroll limits only update after the containers re-sort, so scroll on the next frame.
	await get_tree().process_frame
	_canvas.scroll_horizontal = roundi(_pending_scroll.x)
	_canvas.scroll_vertical = roundi(_pending_scroll.y)
	_has_pending_scroll = false


## Where the centred picture's top-left sits inside the stage at a given zoom. Computed
## rather than read from the node, because the node only moves after the next layout.
func _centering_offset(zoom: float) -> Vector2:
	var picture_size: Vector2 = Vector2(_picture.texture.get_size()) * zoom
	return ((_canvas.size - picture_size) * 0.5).max(Vector2.ZERO)


func _step_zoom(direction: int) -> void:
	var next_zoom: float = _zoom
	if direction > 0:
		for step: float in ZOOM_STEPS:
			if step > _zoom + 0.001:
				next_zoom = step
				break
	else:
		for step_index: int in range(ZOOM_STEPS.size() - 1, -1, -1):
			if ZOOM_STEPS[step_index] < _zoom - 0.001:
				next_zoom = ZOOM_STEPS[step_index]
				break
	set_zoom(next_zoom)


func _on_zoom_preset(item_id: int) -> void:
	if item_id == FIT_MENU_ID:
		fit_to_window()
	else:
		set_zoom(item_id / 100.0)


func _on_slider_changed(percent: float) -> void:
	if not _is_updating_controls:
		set_zoom(percent / 100.0)


func _update_controls() -> void:
	_is_updating_controls = true
	_zoom_slider.value = _zoom * 100.0
	_is_updating_controls = false
	_zoom_level.text = "%d%%" % roundi(_zoom * 100.0)
	_zoom_in.disabled = _zoom >= MAXIMUM_ZOOM - 0.001
	_zoom_out.disabled = _zoom <= MINIMUM_ZOOM + 0.001


func _on_canvas_resized() -> void:
	if visible and _is_fitting:
		fit_to_window()


func _on_stage_input(event: InputEvent) -> void:
	var pinch: InputEventMagnifyGesture = event as InputEventMagnifyGesture
	if pinch != null:
		_is_fitting = false
		_apply_zoom(_zoom * pinch.factor, pinch.position + _stage.position)
		_stage.accept_event()
		return
	var button_event: InputEventMouseButton = event as InputEventMouseButton
	if button_event != null:
		_handle_mouse_button(button_event)
		return
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null and _is_dragging:
		_canvas.scroll_horizontal -= roundi(motion.relative.x)
		_canvas.scroll_vertical -= roundi(motion.relative.y)
		_stage.accept_event()


func _handle_mouse_button(button_event: InputEventMouseButton) -> void:
	# The stage's position inside the canvas is minus the scroll offset.
	var anchor: Vector2 = button_event.position + _stage.position
	match button_event.button_index:
		MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN:
			if button_event.pressed:
				var factor: float = WHEEL_ZOOM_FACTOR if button_event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / WHEEL_ZOOM_FACTOR
				_is_fitting = false
				_apply_zoom(_zoom * factor, anchor)
			_stage.accept_event()
		MOUSE_BUTTON_LEFT:
			if button_event.double_click:
				if _is_fitting:
					_is_fitting = false
					_apply_zoom(1.0, anchor)
				else:
					fit_to_window()
			else:
				_is_dragging = button_event.pressed
				_stage.mouse_default_cursor_shape = Control.CURSOR_DRAG if _is_dragging else Control.CURSOR_MOVE
			_stage.accept_event()
