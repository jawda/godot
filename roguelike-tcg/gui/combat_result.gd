class_name CombatResult
extends Control

## Emitted when the player clicks Continue after seeing the result.
signal continue_pressed

# ── Node references ─────────────────────────────────────────────────────────────

@onready var _background: ColorRect  = $Background
@onready var _panel: PanelContainer  = $Center/ResultPanel
@onready var _label: Label           = $Center/ResultPanel/Contents/ResultLabel
@onready var _continue_button: Button = $Center/ResultPanel/Contents/Continue

# ── Lifecycle ──────────────────────────────────────────────────────────────────

func _ready() -> void:
	_continue_button.pressed.connect(func() -> void: continue_pressed.emit())

# ── Public API ─────────────────────────────────────────────────────────────────

func show_result(victory: bool) -> void:
	var panel_style: StyleBoxFlat = _panel.get_theme_stylebox("panel") as StyleBoxFlat
	panel_style.border_color = Color(0.55, 0.28, 0.85) if victory else Color(0.72, 0.14, 0.14)
	_label.add_theme_color_override("font_color",
			Color(0.95, 0.78, 0.18) if victory else Color(0.92, 0.32, 0.32))
	_label.text = "Victory!" if victory else "Defeated."
	_continue_button.show()
	show()
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(_background, "modulate:a", 1.0, 0.35)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.35).set_delay(0.1)
