extends SceneTree

const DrivingInput = preload("res://scripts/driving_input.gd")
const XboxUsbBridge = preload("res://scripts/xbox_usb_bridge.gd")

class ActionObserver extends Node:
	var pause_count := 0
	func _input(event: InputEvent) -> void:
		if event.is_action_pressed("drive_pause"):
			pause_count += 1


func _initialize() -> void:
	DrivingInput.install_actions()
	var bridge := XboxUsbBridge.new()
	var observer := ActionObserver.new()
	root.add_child(bridge)
	root.add_child(observer)
	var report := PackedByteArray()
	report.resize(22)
	report[4] = 0x20
	report[8] = 0x94 # A, Y, Menu
	report[9] = 0x32 # D-pad down, LB, RB
	report[12] = 0xFF # RT 1023
	report[13] = 0x03
	report[14] = 0x00 # LS X full left
	report[15] = 0x80
	bridge._apply_report(report)
	await process_frame
	assert(Input.is_action_pressed("drive_handbrake"))
	assert(Input.is_action_pressed("drive_ignition"))
	assert(Input.is_action_pressed("drive_pause"))
	assert(Input.is_action_pressed("drive_gear_down"))
	assert(Input.is_action_pressed("drive_clutch"))
	assert(Input.is_action_pressed("drive_gear_up"))
	assert(Input.get_action_strength("drive_throttle") > 0.99)
	assert(Input.get_action_strength("drive_left") > 0.99)
	assert(observer.pause_count == 1)
	bridge._release_all()
	await process_frame
	assert(not Input.is_action_pressed("drive_handbrake"))
	assert(Input.get_action_strength("drive_throttle") == 0.0)
	print("Xbox USB GIP mapping and disconnect release passed")
	quit()
