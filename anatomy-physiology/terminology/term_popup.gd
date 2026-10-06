class_name TermPopup
extends Control
## The card that opens over a lesson when a linked term is clicked. Links inside the
## card (a word's parts, a part's words) open in place; "Open in Medical terms" asks
## the owner to switch to the full reference. top_level lets it cover the whole window
## even though its parent is a container.

signal reference_requested(entry: TermEntry)

# ── Node references ──
@onready var _scrim: ColorRect = $Scrim
@onready var _card: TermCard = $Center/Frame/Card
@onready var _open_reference: Button = $Center/Frame/Actions/OpenReference
@onready var _close: Button = $Center/Frame/Actions/Close


func _ready() -> void:
	_card.term_requested.connect(open)
	_close.pressed.connect(hide)
	_open_reference.pressed.connect(func() -> void:
		hide()
		reference_requested.emit(_card.entry))
	_scrim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			hide())


func open(entry: TermEntry) -> void:
	_card.show_term(entry)
	show()
