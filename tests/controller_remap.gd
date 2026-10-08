extends SceneTree

const ControllerBindings = preload("res://scripts/controller_bindings.gd")
const XboxUsbBridge = preload("res://scripts/xbox_usb_bridge.gd")


func _initialize() -> void:
	if OS.get_environment("MANIUBRA_DATA_DIR").is_empty():
		push_error("Set MANIUBRA_DATA_DIR to a disposable test directory.")
		quit(1)
		return
	call_deferred("run")


func run() -> void:
	var app = preload("res://scenes/app.tscn").instantiate()
	root.add_child(app)
	app._show_settings()
	assert(app._controller_options.size() == ControllerBindings.AXIS_ACTIONS.size() + ControllerBindings.BUTTON_ACTIONS.size())
	app._change_controller_binding(0, "drive_throttle") # LT; swaps brake to RT.
	assert(ControllerBindings.source("drive_throttle") == "lt")
	assert(ControllerBindings.source("drive_brake") == "rt")
	assert(_has_axis("drive_throttle", JOY_AXIS_TRIGGER_LEFT, 1.0))
	assert(_has_axis("drive_brake", JOY_AXIS_TRIGGER_RIGHT, 1.0))
	app._change_controller_binding(0, "drive_ignition") # A; swaps handbrake to Y.
	assert(ControllerBindings.source("drive_ignition") == "a")
	assert(ControllerBindings.source("drive_handbrake") == "y")
	assert(_has_button("drive_ignition", JOY_BUTTON_A))
	assert(_has_button("drive_handbrake", JOY_BUTTON_Y))
	app._change_controller_binding(1, "steering_axis") # Right stick X.
	assert(ControllerBindings.source("steering_axis") == "rs_x")
	assert(ControllerBindings.source("look_x_axis") == "ls_x")
	assert(_has_axis("drive_right", JOY_AXIS_RIGHT_X, 1.0))
	assert(_has_axis("look_right", JOY_AXIS_LEFT_X, 1.0))
	assert(app._controller_options["look_x_axis"].selected == 0)
	app.queue_free()
	await process_frame
	var bridge := XboxUsbBridge.new()
	var report := PackedByteArray()
	report.resize(22)
	report[4] = 0x20
	report[8] = 0x10 # A
	report[10] = 0x00 # LT 512
	report[11] = 0x02
	report[12] = 0xFF # RT 1023
	report[13] = 0x03
	report[14] = 0x00 # LS X full left
	report[15] = 0x80
	report[18] = 0xFF # RS X full right
	report[19] = 0x7F
	bridge._apply_report(report)
	await process_frame
	assert(Input.is_action_pressed("drive_ignition"))
	assert(not Input.is_action_pressed("drive_handbrake"))
	assert(Input.get_action_strength("drive_throttle") > 0.49)
	assert(Input.get_action_strength("drive_throttle") < 0.51)
	assert(Input.get_action_strength("drive_brake") > 0.99)
	assert(Input.get_action_strength("drive_right") > 0.99)
	assert(Input.get_action_strength("look_left") > 0.99)
	bridge._release_all()
	bridge.free()
	ControllerBindings.reset()
	ControllerBindings.load_saved()
	assert(ControllerBindings.source("drive_ignition") == "a")
	assert(ControllerBindings.source("drive_throttle") == "lt")
	assert(ControllerBindings.source("steering_axis") == "rs_x")
	var second_app = preload("res://scenes/app.tscn").instantiate()
	root.add_child(second_app)
	second_app._show_settings()
	second_app._reset_controller_bindings()
	ControllerBindings.load_saved()
	assert(ControllerBindings.source("drive_ignition") == "y")
	assert(ControllerBindings.source("drive_throttle") == "rt")
	assert(ControllerBindings.source("steering_axis") == "ls_x")
	print("PASS: controller UI, swaps, native/direct mappings, persistence, and reset")
	second_app.queue_free()
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
