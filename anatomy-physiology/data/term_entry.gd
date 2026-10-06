class_name TermEntry
extends RefCounted
## One medical terminology entry: a word part, a whole word broken into parts, a body
## orientation term, or an abbreviation. Loaded from content/terminology/*.json.

enum Kind { PREFIX, ROOT, SUFFIX, WORD, BODY, ABBREVIATION }

const KIND_BY_NAME: Dictionary[String, Kind] = {
	"prefix": Kind.PREFIX,
	"root": Kind.ROOT,
	"suffix": Kind.SUFFIX,
	"word": Kind.WORD,
	"body": Kind.BODY,
	"abbreviation": Kind.ABBREVIATION,
}
const KIND_LABELS: Dictionary[Kind, String] = {
	Kind.PREFIX: "Prefix",
	Kind.ROOT: "Root",
	Kind.SUFFIX: "Suffix",
	Kind.WORD: "Word",
	Kind.BODY: "Body term",
	Kind.ABBREVIATION: "Abbreviation",
}

var id: String = ""
var kind: Kind = Kind.ROOT
var term: String = ""
var meaning: String = ""
## Body terms only: Directional terms, Body planes, Body regions, Body cavities, Body positions.
var group: String = ""
## Other spellings that link from lesson text (plurals, variants).
var forms: Array[String] = []
var examples: Array[String] = []
## Words only: ids of the prefix/root/suffix entries the word is built from, in order.
var part_ids: Array[String] = []
## Body terms only: id of the opposite term, if any.
var opposite_id: String = ""
## False for terms that are also everyday English ("deep", "mental") and would link
## from lesson text where they don't mean the anatomy term.
var links_from_lessons: bool = true


static func from_dictionary(data: Dictionary) -> TermEntry:
	var entry: TermEntry = TermEntry.new()
	entry.id = str(data.get("id", ""))
	entry.kind = KIND_BY_NAME.get(str(data.get("kind", "root")), Kind.ROOT)
	entry.term = str(data.get("term", ""))
	entry.meaning = str(data.get("meaning", ""))
	entry.group = str(data.get("group", ""))
	entry.forms.assign(data.get("forms", []))
	entry.examples.assign(data.get("examples", []))
	entry.part_ids.assign(data.get("parts", []))
	entry.opposite_id = str(data.get("opposite", ""))
	entry.links_from_lessons = bool(data.get("link", true))
	return entry


## "Root", or the body term's group, for the small heading above a term.
func kind_label() -> String:
	return group if kind == Kind.BODY and not group.is_empty() else KIND_LABELS[kind]


## True for prefixes, roots, and suffixes.
func is_word_part() -> bool:
	return kind == Kind.PREFIX or kind == Kind.ROOT or kind == Kind.SUFFIX


## The term with hyphens, slashes, and spaces removed, for search and sorting:
## "cardi/o" becomes "cardio", "-itis" becomes "itis".
func plain_term() -> String:
	return term.to_lower().replace("-", "").replace("/", "").replace(" ", "")
