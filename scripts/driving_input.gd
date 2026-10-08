extends RefCounted
## One semantic input state for keyboard and standard gamepads.

const ControllerBindings = preload("res://scripts/controller_bindings.gd")
const FILE_VERSION := 1
const BINDINGS := [
	{"action": "drive_left", "label": "Steer left", "key": KEY_A},
	{"action": "drive_right", "label": "Steer right", "key": KEY_D},
	{"action": "drive_throttle", "label": "Accelerate", "key": KEY_W},
	{"action": "drive_brake", "label": "Brake", "key": KEY_S},
	{"action": "drive_clutch", "label": "Clutch", "key": KEY_C},
	{"action": "drive_gear_up", "label": "Shift up", "key": KEY_E},
	{"action": "drive_gear_down", "label": "Shift down", "key": KEY_Q},
	{"action": "drive_handbrake", "label": "Handbrake", "key": KEY_SPACE},
	{"action": "drive_ignition", "label": "Engine on/off", "key": KEY_H},
	{"action": "drive_seatbelt", "label": "Seatbelt", "key": KEY_B},
	{"action": "drive_reset", "label": "Restart drive", "key": KEY_R},
	{"action": "drive_pause", "label": "Pause", "key": KEY_ESCAPE},
]
var steering := 0.0
var throttle := 0.0
var brake := 0.0
var clutch := 0.0 # 1 means pedal depressed and drive disengaged.
var handbrake := false
var last_device := "keyboard_mouse"


static func install_actions() -> void:
	for binding in BINDINGS:
		var action := StringName(binding["action"])
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.16)
		if keyboard_key(action) == KEY_NONE:
			_replace_keyboard_key(action, binding["key"])
	ControllerBindings.apply_to_input_map()


static func keyboard_key(action: StringName) -> Key:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
	return KEY_NONE


static func keyboard_name(action: StringName) -> String:
	return OS.get_keycode_string(keyboard_key(action))


static func display_name(action: StringName, device: String) -> String:
	return ControllerBindings.label_for_action(String(action)) if device == "gamepad" else keyboard_name(action)


static func set_keyboard_binding(action: StringName, key: Key) -> bool:
	if key == KEY_NONE or (key == KEY_ESCAPE and action != "drive_pause"):
		return false
	for binding in BINDINGS:
		var other := StringName(binding["action"])
		if other != action and keyboard_key(other) == key:
			return false
	if not InputMap.has_action(action):
		return false
	_replace_keyboard_key(action, key)
	return true


static func reset_keyboard_bindings() -> void:
	for binding in BINDINGS:
		_replace_keyboard_key(StringName(binding["action"]), binding["key"])


static func load_keyboard_bindings() -> void:
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
	if typeof(data) != TYPE_DICTIONARY or data.get("file_version") != FILE_VERSION or typeof(data.get("keyboard")) != TYPE_DICTIONARY:
		return
	var saved: Dictionary = data["keyboard"]
	var proposed: Dictionary = {}
	var used: Dictionary = {}
	for binding in BINDINGS:
		var action: String = binding["action"]
		var key := int(saved.get(action, binding["key"]))
		if key <= 0 or (key == KEY_ESCAPE and action != "drive_pause") or used.has(key):
			return
		proposed[action] = key
		used[key] = true
	for action in proposed:
		_replace_keyboard_key(StringName(action), proposed[action])


static func save_keyboard_bindings() -> bool:
	var path := _bindings_path()
	if DirAccess.make_dir_recursive_absolute(path.get_base_dir()) != OK:
		return false
	var saved := {}
	for binding in BINDINGS:
		var action: String = binding["action"]
		saved[action] = int(keyboard_key(StringName(action)))
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"file_version": FILE_VERSION, "keyboard": saved}))
	file.flush()
	file.close()
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path)) == OK


static func keyboard_hint() -> String:
	return "%s engine  %s seatbelt  %s throttle  %s brake  %s/%s steer  %s clutch  %s/%s gears  %s handbrake  %s restart  %s pause" % [keyboard_name("drive_ignition"), keyboard_name("drive_seatbelt"), keyboard_name("drive_throttle"), keyboard_name("drive_brake"), keyboard_name("drive_left"), keyboard_name("drive_right"), keyboard_name("drive_clutch"), keyboard_name("drive_gear_up"), keyboard_name("drive_gear_down"), keyboard_name("drive_handbrake"), keyboard_name("drive_reset"), keyboard_name("drive_pause")]


static func controller_hint() -> String:
	return "%s steer · %s accelerate · %s brake · %s clutch · %s/%s gears · %s handbrake · %s engine · %s seatbelt · %s restart · %s pause · %s look" % [ControllerBindings.short_label_for_source(ControllerBindings.source("steering_axis")), display_name("drive_throttle", "gamepad"), display_name("drive_brake", "gamepad"), display_name("drive_clutch", "gamepad"), display_name("drive_gear_up", "gamepad"), display_name("drive_gear_down", "gamepad"), display_name("drive_handbrake", "gamepad"), display_name("drive_ignition", "gamepad"), display_name("drive_seatbelt", "gamepad"), display_name("drive_reset", "gamepad"), display_name("drive_pause", "gamepad"), ControllerBindings.short_label_for_source(ControllerBindings.source("look_x_axis"))]


static func _bindings_path() -> String:
	var override_dir := OS.get_environment("MANIUBRA_DATA_DIR")
	return override_dir.path_join("maniubra_input.json") if not override_dir.is_empty() else "user://maniubra_input.json"


static func _replace_keyboard_key(action: StringName, key: Key) -> void:
	for old in InputMap.action_get_events(action):
		if old is InputEventKey:
			InputMap.action_erase_event(action, old)
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action, event)


func update(delta: float) -> void:
	var target_steering := Input.get_axis("drive_right", "drive_left")
	steering = move_toward(steering, target_steering, delta * 2.2)
	throttle = move_toward(throttle, Input.get_action_strength("drive_throttle"), delta * 2.6)
	brake = move_toward(brake, Input.get_action_strength("drive_brake"), delta * 3.5)
	clutch = move_toward(clutch, Input.get_action_strength("drive_clutch"), delta * 4.0)
	handbrake = Input.is_action_pressed("drive_handbrake")
