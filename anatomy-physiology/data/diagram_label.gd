class_name DiagramLabel
extends RefCounted
## One printed label on a labeled diagram: the answer, and where it is printed.

enum Grade { WRONG, CLOSE, EXACT }

## The answer as it should be written.
var text: String = ""
## Normalised forms of text and any alternates that also count as right.
var accepted_answers: Array[String] = []
## Where the printed label sits, as fractions of the whole image.
var box: Rect2 = Rect2()
## How many printed lines the label wraps over, so the blank can use the same text size.
var line_count: int = 1


static func from_dictionary(data: Dictionary) -> DiagramLabel:
	var label: DiagramLabel = DiagramLabel.new()
	label.text = str(data.get("text", ""))
	label.accepted_answers.append(normalize(label.text))
	for alternate: String in data.get("accept", []):
		label.accepted_answers.append(normalize(alternate))
	var box_values: Array = data.get("box", [])
	if box_values.size() == 4:
		label.box = Rect2(float(box_values[0]), float(box_values[1]), float(box_values[2]), float(box_values[3]))
	label.line_count = maxi(1, int(data.get("lines", 1)))
	return label


## Lower case, punctuation and extra spaces removed, so "Biceps  femoris." matches.
static func normalize(answer: String) -> String:
	var normalized: String = ""
	var last_was_space: bool = true
	for character: String in answer.to_lower():
		var is_word_character: bool = (character >= "a" and character <= "z") or (character >= "0" and character <= "9")
		if is_word_character:
			normalized += character
			last_was_space = false
		elif not last_was_space:
			normalized += " "
			last_was_space = true
	return normalized.strip_edges()


func is_placed_correctly(placed_text: String) -> bool:
	return normalize(placed_text) == accepted_answers[0]


## Typed answers: a slip of a letter or two in a long name still counts, but is flagged
## so the right spelling gets seen.
func grade_typed(typed_text: String) -> Grade:
	var typed: String = normalize(typed_text)
	if typed.is_empty():
		return Grade.WRONG
	if accepted_answers.has(typed):
		return Grade.EXACT
	for accepted: String in accepted_answers:
		var tolerance: int = 0
		if accepted.length() >= 9:
			tolerance = 2
		elif accepted.length() >= 5:
			tolerance = 1
		if tolerance > 0 and _edit_distance(typed, accepted) <= tolerance:
			return Grade.CLOSE
	return Grade.WRONG


static func _edit_distance(first: String, second: String) -> int:
	var previous_row: PackedInt32Array = PackedInt32Array(range(second.length() + 1))
	for first_index: int in range(1, first.length() + 1):
		var current_row: PackedInt32Array = PackedInt32Array([first_index])
		for second_index: int in range(1, second.length() + 1):
			var substitution_cost: int = 0 if first[first_index - 1] == second[second_index - 1] else 1
			current_row.append(mini(mini(previous_row[second_index] + 1, current_row[second_index - 1] + 1),
				previous_row[second_index - 1] + substitution_cost))
		previous_row = current_row
	return previous_row[second.length()]
