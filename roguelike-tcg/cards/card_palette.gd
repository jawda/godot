@tool
class_name CardPalette
extends Resource

@export_group("Card Body")
@export var body_bg: Color = Color(0.08, 0.09, 0.16)
@export var border: Color = Color(0.44, 0.45, 0.52)
@export var shadow: Color = Color(0.25, 0.25, 0.3, 0.2)
@export var border_width: int = 2
@export var shadow_base: int = 4
@export var shadow_peak: int = 4

@export_group("Cost Badge")
@export var cost_bg: Color = Color(0.18, 0.19, 0.24)
@export var cost_border: Color = Color(0.52, 0.53, 0.6)
@export var cost_text: Color = Color(0.82, 0.82, 0.86)

@export_group("Art Frame")
@export var art_border: Color = Color(0.38, 0.38, 0.44, 0.4)

@export_group("Name Banner")
@export var name_bg: Color = Color(0.17, 0.17, 0.23)
@export var name_border: Color = Color(0.44, 0.45, 0.52)
@export var name_text: Color = Color(0.88, 0.88, 0.92)
@export var name_outline: Color = Color.TRANSPARENT
@export var name_outline_size: int = 0

@export_group("Type & Description")
@export var type_text: Color = Color(0.52, 0.53, 0.6, 0.75)
@export var desc_border: Color = Color(0.38, 0.38, 0.44, 0.28)
@export var desc_text: Color = Color(0.82, 0.82, 0.86)

@export_group("Rarity Strip")
@export var rarity_bg: Color = Color(0.22, 0.22, 0.28)
@export var rarity_border: Color = Color(0.48, 0.48, 0.55)
@export var rarity_text: Color = Color(0.68, 0.68, 0.74)
@export var rarity_strip_x0: int = 50
@export var rarity_strip_x1: int = 110
