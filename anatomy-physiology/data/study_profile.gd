class_name StudyProfile
extends RefCounted
## One person's entry in the profile list. Their progress lives in a separate file.

var id: String = ""
var display_name: String = ""
var created_unix: float = 0.0
## Fractional seconds, so two profiles used within the same second still sort correctly.
var last_used_unix: float = 0.0


static func from_dictionary(data: Dictionary) -> StudyProfile:
	var profile: StudyProfile = StudyProfile.new()
	profile.id = str(data.get("id", ""))
	profile.display_name = str(data.get("name", "Unnamed"))
	profile.created_unix = float(data.get("created", 0.0))
	profile.last_used_unix = float(data.get("last_used", 0.0))
	return profile


func to_dictionary() -> Dictionary:
	return {"id": id, "name": display_name, "created": created_unix, "last_used": last_used_unix}
