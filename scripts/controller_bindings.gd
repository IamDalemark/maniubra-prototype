extends RefCounted
## One saved Xbox layout shared by native Godot gamepads and the direct USB reader.

const FILE_VERSION := 1
const BUTTON_OPTIONS := [
	["a", "A", JOY_BUTTON_A], ["b", "B", JOY_BUTTON_B],
	["x", "X", JOY_BUTTON_X], ["y", "Y", JOY_BUTTON_Y],
	["lb", "LB", JOY_BUTTON_LEFT_SHOULDER], ["rb", "RB", JOY_BUTTON_RIGHT_SHOULDER],
	["up", "D-pad up", JOY_BUTTON_DPAD_UP], ["down", "D-pad down", JOY_BUTTON_DPAD_DOWN],
	["left", "D-pad left", JOY_BUTTON_DPAD_LEFT], ["right", "D-pad right", JOY_BUTTON_DPAD_RIGHT],
	["menu", "Menu", JOY_BUTTON_START], ["view", "View", JOY_BUTTON_BACK],
	["ls_click", "LS click", JOY_BUTTON_LEFT_STICK], ["rs_click", "RS click", JOY_BUTTON_RIGHT_STICK],
]
const AXIS_OPTIONS := [
	["ls_x", "Left stick horizontal", JOY_AXIS_LEFT_X],
	["rs_x", "Right stick horizontal", JOY_AXIS_RIGHT_X],
	["ls_y", "Left stick vertical", JOY_AXIS_LEFT_Y],
	["rs_y", "Right stick vertical", JOY_AXIS_RIGHT_Y],
]
const PEDAL_OPTIONS := [
	["lt", "LT", JOY_AXIS_TRIGGER_LEFT],
	["rt", "RT", JOY_AXIS_TRIGGER_RIGHT],
]
const BUTTON_ACTIONS := [
	["drive_clutch", "Clutch"], ["drive_gear_up", "Shift up"],
	["drive_gear_down", "Shift down"], ["drive_handbrake", "Handbrake"],
	["drive_ignition", "Engine on/off"], ["drive_seatbelt", "Seatbelt"],
	["drive_reset", "Restart drive"], ["drive_pause", "Pause"],
	["ui_accept", "Menu select"], ["ui_cancel", "Menu back"],
]
const AXIS_ACTIONS := [
	["steering_axis", "Steering", "horizontal"],
	["look_x_axis", "Look left/right", "horizontal"],
	["look_y_axis", "Look up/down", "vertical"],
	["drive_throttle", "Accelerate", "pedal"],
	["drive_brake", "Brake", "pedal"],
]
const DEFAULTS := {
	"steering_axis": "ls_x", "look_x_axis": "rs_x", "look_y_axis": "rs_y",
	"drive_throttle": "rt", "drive_brake": "lt",
	"drive_clutch": "lb", "drive_gear_up": "rb", "drive_gear_down": "down",
	"drive_handbrake": "a", "drive_ignition": "y", "drive_seatbelt": "x",
	"drive_reset": "up", "drive_pause": "menu",
	"ui_accept": "a", "ui_cancel": "b",
}

static var _bindings: Dictionary = {}


static func options_for(key: String) -> Array:
	if key == "drive_throttle" or key == "drive_brake":
		return PEDAL_OPTIONS
	if key == "steering_axis" or key == "look_x_axis":
		return [AXIS_OPTIONS[0], AXIS_OPTIONS[1]]
	if key == "look_y_axis":
		return [AXIS_OPTIONS[2], AXIS_OPTIONS[3]]
	return BUTTON_OPTIONS


static func source(key: String) -> String:
	_ensure_defaults()
	return _bindings.get(key, DEFAULTS.get(key, ""))


static func label_for_source(token: String) -> String:
	for option in BUTTON_OPTIONS + AXIS_OPTIONS + PEDAL_OPTIONS:
		if option[0] == token:
			return option[1]
	return "?"


static func short_label_for_source(token: String) -> String:
	if token.begins_with("ls_"):
		return "LS"
	if token.begins_with("rs_"):
		return "RS"
	return label_for_source(token)


static func label_for_action(action: String) -> String:
	if action == "drive_left" or action == "drive_right":
		return short_label_for_source(source("steering_axis")) + (" left" if action == "drive_left" else " right")
	if action == "look_left" or action == "look_right":
		return short_label_for_source(source("look_x_axis")) + (" left" if action == "look_left" else " right")
	if action == "look_up" or action == "look_down":
		return short_label_for_source(source("look_y_axis")) + (" up" if action == "look_up" else " down")
	return label_for_source(source(action))


static func set_binding(key: String, token: String) -> bool:
	_ensure_defaults()
	if not DEFAULTS.has(key):
		return false
	var allowed := false
	for option in options_for(key):
		if option[0] == token:
			allowed = true
			break
	if not allowed:
		return false
	if _bindings[key] == token:
		return true
	var old: String = _bindings[key]
	# Gameplay buttons cannot fire two driving actions. Menu buttons have separate context.
	var group := _group_for(key)
	for other in _bindings:
		if other == key or _bindings[other] != token:
			continue
		if group == _group_for(other):
			_bindings[other] = old
	_bindings[key] = token
	apply_to_input_map()
	return true


static func reset() -> void:
	_bindings = DEFAULTS.duplicate(true)
	apply_to_input_map()


static func load_saved() -> void:
	_ensure_defaults()
	var path := _bindings_path()
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return
	var data: Variant = parser.data
	if typeof(data) != TYPE_DICTIONARY or data.get("file_version") != FILE_VERSION or typeof(data.get("controller")) != TYPE_DICTIONARY:
		return
	var saved: Dictionary = data["controller"]
	var used: Dictionary = {}
	for key in DEFAULTS:
		if not saved.has(key):
			return
		var valid := false
		for option in options_for(key):
			if saved[key] == option[0]:
				valid = true
		if not valid:
			return
		var usage := _group_for(key) + ":" + String(saved[key])
		if used.has(usage):
			return
		used[usage] = true
	# Apply through the same swap rule so malformed duplicates never reach gameplay.
	_bindings = DEFAULTS.duplicate(true)
	for key in DEFAULTS:
		set_binding(key, saved[key])
	apply_to_input_map()


static func save() -> bool:
	_ensure_defaults()
	var path := _bindings_path()
	if DirAccess.make_dir_recursive_absolute(path.get_base_dir()) != OK:
		return false
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"file_version": FILE_VERSION, "controller": _bindings}))
	file.flush()
	file.close()
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path)) == OK


static func apply_to_input_map() -> void:
	_ensure_defaults()
	for action in ["drive_left", "drive_right", "drive_throttle", "drive_brake", "drive_clutch", "drive_gear_up", "drive_gear_down", "drive_handbrake", "drive_ignition", "drive_seatbelt", "drive_reset", "drive_pause", "ui_accept", "ui_cancel", "look_left", "look_right", "look_up", "look_down"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.16)
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				InputMap.action_erase_event(action, event)
	_add_axis_pair("drive_left", "drive_right", source("steering_axis"))
	_add_axis_pair("look_left", "look_right", source("look_x_axis"))
	_add_axis_pair("look_up", "look_down", source("look_y_axis"))
	_add_axis("drive_throttle", source("drive_throttle"), 1.0)
	_add_axis("drive_brake", source("drive_brake"), 1.0)
	for binding in BUTTON_ACTIONS:
		var token: String = source(binding[0])
		for option in BUTTON_OPTIONS:
			if option[0] == token:
				var event := InputEventJoypadButton.new()
				event.button_index = option[2]
				InputMap.action_add_event(binding[0], event)
				break


static func _add_axis_pair(negative: String, positive: String, token: String) -> void:
	_add_axis(negative, token, -1.0)
	_add_axis(positive, token, 1.0)


static func _add_axis(action: String, token: String, value: float) -> void:
	for option in AXIS_OPTIONS + PEDAL_OPTIONS:
		if option[0] == token:
			var event := InputEventJoypadMotion.new()
			event.axis = option[2]
			event.axis_value = value
			InputMap.action_add_event(action, event)
			return


static func _ensure_defaults() -> void:
	if _bindings.is_empty():
		_bindings = DEFAULTS.duplicate(true)


static func _group_for(key: String) -> String:
	if key.begins_with("ui_"):
		return "menu"
	if key in ["drive_throttle", "drive_brake"]:
		return "pedal"
	if key in ["steering_axis", "look_x_axis"]:
		return "horizontal"
	if key == "look_y_axis":
		return "vertical"
	return "drive"


static func _bindings_path() -> String:
	var override_dir := OS.get_environment("MANIUBRA_DATA_DIR")
	return override_dir.path_join("maniubra_controller.json") if not override_dir.is_empty() else "user://maniubra_controller.json"
