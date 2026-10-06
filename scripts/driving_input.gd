extends RefCounted
## One semantic input state for keyboard and standard gamepads.

var steering := 0.0
var throttle := 0.0
var brake := 0.0
var clutch := 0.0 # 1 means pedal depressed and drive disengaged.
var handbrake := false
var last_device := "keyboard_mouse"


static func install_actions() -> void:
	if InputMap.has_action("drive_left"):
		return
	_key("drive_left", KEY_A)
	_key("drive_right", KEY_D)
	_key("drive_throttle", KEY_W)
	_key("drive_brake", KEY_S)
	_key("drive_clutch", KEY_C)
	_key("drive_handbrake", KEY_SPACE)
	_key("drive_gear_up", KEY_E)
	_key("drive_gear_down", KEY_Q)
	_key("drive_reset", KEY_R)
	_axis("drive_left", JOY_AXIS_LEFT_X, -1.0)
	_axis("drive_right", JOY_AXIS_LEFT_X, 1.0)
	_axis("drive_throttle", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_axis("drive_brake", JOY_AXIS_TRIGGER_LEFT, 1.0)
	_button("drive_clutch", JOY_BUTTON_LEFT_SHOULDER)
	_button("drive_handbrake", JOY_BUTTON_A)
	_button("drive_gear_up", JOY_BUTTON_RIGHT_SHOULDER)
	_button("drive_gear_down", JOY_BUTTON_DPAD_DOWN)
	_axis("look_left", JOY_AXIS_RIGHT_X, -1.0)
	_axis("look_right", JOY_AXIS_RIGHT_X, 1.0)
	_axis("look_up", JOY_AXIS_RIGHT_Y, -1.0)
	_axis("look_down", JOY_AXIS_RIGHT_Y, 1.0)


static func _key(action: StringName, key: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.16)
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action, event)


static func _axis(action: StringName, axis: JoyAxis, value: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.16)
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	InputMap.action_add_event(action, event)


static func _button(action: StringName, button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)


func update(delta: float) -> void:
	var target_steering := Input.get_axis("drive_left", "drive_right")
	steering = move_toward(steering, target_steering, delta * 2.2)
	throttle = move_toward(throttle, Input.get_action_strength("drive_throttle"), delta * 2.6)
	brake = move_toward(brake, Input.get_action_strength("drive_brake"), delta * 3.5)
	clutch = move_toward(clutch, Input.get_action_strength("drive_clutch"), delta * 4.0)
	handbrake = Input.is_action_pressed("drive_handbrake")
