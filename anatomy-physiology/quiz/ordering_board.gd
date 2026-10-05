class_name OrderingBoard
extends VBoxContainer
## Holds the rows of an ordering question. Rows are created per question, so they are
## built here in code; each row is an instance of ordering_item.tscn.

const ORDERING_ITEM_SCENE: PackedScene = preload("res://quiz/ordering_item.tscn")


func show_items(correct_order: Array[String]) -> void:
	clear()
	var shuffled: Array[String] = correct_order.duplicate()
	var attempts: int = 0
	while shuffled == correct_order and attempts < 20:
		shuffled.shuffle()
		attempts += 1
	for text: String in shuffled:
		var item: OrderingItem = ORDERING_ITEM_SCENE.instantiate()
		add_child(item)
		item.set_item_text(text)
		item.move_requested.connect(_on_move_requested)
	_renumber()


func clear() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()


## Colours each row and returns whether the whole order is correct.
func check_against(correct_order: Array[String]) -> bool:
	var all_correct: bool = true
	var rows: Array[Node] = get_children()
	for row_index: int in rows.size():
		var item: OrderingItem = rows[row_index]
		var is_correct: bool = correct_order[row_index] == item.item_text
		all_correct = all_correct and is_correct
		item.reveal(is_correct, correct_order.find(item.item_text) + 1)
	return all_correct


func _on_move_requested(item: OrderingItem, direction: int) -> void:
	var target_index: int = clampi(item.get_index() + direction, 0, get_child_count() - 1)
	move_child(item, target_index)
	_renumber()


func _renumber() -> void:
	var rows: Array[Node] = get_children()
	for row_index: int in rows.size():
		var item: OrderingItem = rows[row_index]
		item.set_position_number(row_index + 1, rows.size())
