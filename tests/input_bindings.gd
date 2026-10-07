extends SceneTree
## Verify runtime controller actions and persistent keyboard remapping.

const DrivingInput = preload("res://scripts/driving_input.gd")


func _initialize() -> void:
	if OS.get_environment("MANIUBRA_DATA_DIR").is_empty():
		push_error("Set MANIUBRA_DATA_DIR to a disposable test directory.")
		quit(1)
		return
	call_deferred("run")


func run() -> void:
	var app = load("res://scenes/app.tscn").instantiate()
	root.add_child(app)
	assert(_has_button("drive_ignition", JOY_BUTTON_Y))
	assert(_has_button("drive_seatbelt", JOY_BUTTON_X))
	assert(_has_button("drive_clutch", JOY_BUTTON_LEFT_SHOULDER))
	assert(_has_button("drive_gear_up", JOY_BUTTON_RIGHT_SHOULDER))
	assert(_has_button("drive_gear_down", JOY_BUTTON_DPAD_DOWN))
	assert(_has_button("drive_pause", JOY_BUTTON_START))
	assert(_has_button("ui_accept", JOY_BUTTON_A))
	assert(_has_button("ui_cancel", JOY_BUTTON_B))
	assert(_has_axis("drive_throttle", JOY_AXIS_TRIGGER_RIGHT, 1.0))
	assert(_has_axis("drive_brake", JOY_AXIS_TRIGGER_LEFT, 1.0))
	app._show_settings()
	assert(app._binding_buttons.size() == DrivingInput.BINDINGS.size())
	assert(not DrivingInput.set_keyboard_binding("drive_throttle", KEY_A))
	app._begin_key_capture("drive_throttle")
	var replacement := InputEventKey.new()
	replacement.physical_keycode = KEY_UP
	replacement.pressed = true
	app._input(replacement)
	assert(DrivingInput.keyboard_key("drive_throttle") == KEY_UP)
	assert(app._binding_buttons[&"drive_throttle"].text == "Up")
	assert(DrivingInput.keyboard_hint().contains("Up throttle"))
	assert(DrivingInput.display_name("drive_throttle", "gamepad") == "RT")
	assert(_has_axis("drive_throttle", JOY_AXIS_TRIGGER_RIGHT, 1.0))
	DrivingInput.reset_keyboard_bindings()
	assert(DrivingInput.keyboard_key("drive_throttle") == KEY_W)
	DrivingInput.load_keyboard_bindings()
	assert(DrivingInput.keyboard_key("drive_throttle") == KEY_UP)
	app._reset_keyboard_bindings()
	DrivingInput.load_keyboard_bindings()
	assert(DrivingInput.keyboard_key("drive_throttle") == KEY_W)
	assert(_has_button("drive_ignition", JOY_BUTTON_Y))
	print("PASS: Xbox preset, settings remap, duplicate rejection, persistence, and reset")
	app.queue_free()
	await process_frame
	quit()


func _has_button(action: StringName, button: JoyButton) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and event.button_index == button:
			return true
	return false


func _has_axis(action: StringName, axis: JoyAxis, value: float) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion and event.axis == axis and is_equal_approx(event.axis_value, value):
			return true
	return false
