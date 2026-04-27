class_name Toast
extends Control

@onready var _panel: PanelContainer = $Panel
@onready var _label: Label          = $Panel/Message

func show_message(message: String) -> void:
	_label.text = message
	_panel.modulate.a = 1.0
	show()
	await get_tree().process_frame
	_panel.position = Vector2(size.x * 0.5 - _panel.size.x * 0.5, size.y * 0.58)
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_interval(0.8)
	tween.tween_property(_panel, "position:y", _panel.position.y - 28.0, 0.5) \
			.set_delay(0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(_panel, "modulate:a", 0.0, 0.45).set_delay(0.8)
	await tween.finished
	hide()
