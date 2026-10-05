class_name Flashcard
extends RefCounted

var id: String = ""
var term: String = ""
var definition: String = ""


static func from_dictionary(data: Dictionary) -> Flashcard:
	var card: Flashcard = Flashcard.new()
	card.id = str(data.get("id", ""))
	card.term = str(data.get("term", ""))
	card.definition = str(data.get("definition", ""))
	return card
