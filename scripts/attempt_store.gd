extends RefCounted
## Local, bounded, versioned records for one learner on this Mac.

const FILE_VERSION := 1


static func _path() -> String:
	var override_dir := OS.get_environment("MANIUBRA_DATA_DIR")
	if not override_dir.is_empty():
		return override_dir.path_join("maniubra_attempts.json")
	return "user://maniubra_attempts.json"


static func load_attempts() -> Array:
	var path := _path()
	if not FileAccess.file_exists(path):
		return []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return []
	var data: Variant = parser.data
	if typeof(data) != TYPE_DICTIONARY or data.get("file_version") != FILE_VERSION:
		return []
	if typeof(data.get("attempts")) != TYPE_ARRAY:
		return []
	return data["attempts"]


static func save_attempt(attempt: Dictionary) -> bool:
	var path := _path()
	if DirAccess.make_dir_recursive_absolute(path.get_base_dir()) != OK:
		return false
	var attempts := load_attempts()
	attempts.push_front(attempt)
	attempts.resize(mini(attempts.size(), 5))
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"file_version": FILE_VERSION, "attempts": attempts}))
	file.flush()
	file.close()
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path)) == OK
