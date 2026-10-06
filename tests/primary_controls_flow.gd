extends SceneTree
## Exercise the actual vehicle, lesson transitions, result navigation, and save.


func _initialize() -> void:
	if OS.get_environment("MANIUBRA_DATA_DIR").is_empty():
		push_error("Set MANIUBRA_DATA_DIR to a disposable test directory.")
		quit(1)
		return
	call_deferred("verify")


func frames(count: int) -> void:
	for index in count:
		await physics_frame


func shift(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	Input.action_release(action)
	await physics_frame


func reach_step(session: Node, wanted: int, maximum: int) -> bool:
	for index in maximum:
		if session._step >= wanted:
			return true
		await physics_frame
	return false


func verify() -> void:
	var app = load("res://scenes/app.tscn").instantiate()
	root.add_child(app)
	app._show_settings()
	assert(app._page == "settings")
	app._go_back()
	assert(app._page == "home")
	app._show_lessons("primary_controls")
	app._show_briefing("manual_basics")
	app._launch_lesson("res://scenes/lessons/primary_controls.tscn")
	await physics_frame
	var session = app._session
	var car = session.sedan
	assert(car.camera.current)
	assert(car.get_children().filter(func(node): return node is VehicleWheel3D).size() == 4)
	assert(car._left_hand != null and car._right_hand != null)
	assert(not car.gearbox.engine_running and not car._engine_audio.playing)
	await shift("drive_ignition")
	assert(car.gearbox.engine_running and car._engine_audio.playing)
	await shift("drive_gear_up")
	assert(session._toast_panel.visible and session._toast_title.text.contains("SHIFT ERROR"))
	assert(session._toast_detail.text.contains("clutch"))
	session._process(4.5)
	assert(not session._toast_panel.visible)
	var capture_warp := InputEventMouseMotion.new()
	capture_warp.relative = Vector2(1000, 1000)
	car._input(capture_warp)
	assert(is_zero_approx(car._look_yaw) and is_zero_approx(car._look_pitch))
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	session._input(escape)
	assert(session._paused)
	session._set_paused(false)
	Input.action_press("drive_clutch")
	await frames(18)
	await shift("drive_gear_up")
	assert(car._gear_hand_timer > 0.0)
	var wheel_grip: Vector3 = car._right_hand.position
	await frames(13)
	assert(car._right_hand.position.distance_to(wheel_grip) > 0.05)
	Input.action_release("drive_clutch")
	await frames(36)
	assert(car.gearbox.engine_stalled and not car._engine_audio.playing)
	assert(car.gearbox.engine_rpm == 0.0 and car.engine_force == 0.0)
	assert(session._toast_panel.visible and session._toast_title.text.contains("ENGINE STALLED"))
	await shift("drive_ignition")
	assert(not car.gearbox.engine_running)
	assert(session._toast_panel.visible and session._toast_title.text.contains("START BLOCKED"))
	Input.action_press("drive_clutch")
	await frames(18)
	await shift("drive_ignition")
	assert(car.gearbox.engine_running and car._engine_audio.playing)
	assert(not session._toast_panel.visible)
	Input.action_release("drive_clutch")
	Input.action_press("drive_throttle")
	assert(await reach_step(session, 3, 720))
	await create_timer(0.0).timeout
	var expected_eye: Vector3 = car.global_position + Basis(Vector3.UP, car.global_rotation.y) * Vector3(0.40, 1.45, -0.40)
	assert(car.camera.global_position.distance_to(expected_eye) < 0.01)
	Input.action_press("drive_clutch")
	await frames(16)
	await shift("drive_gear_up")
	Input.action_release("drive_clutch")
	Input.action_press("drive_right")
	assert(await reach_step(session, 5, 480))
	assert(absf(car.camera.global_rotation.z) < 0.02)
	Input.action_release("drive_right")
	Input.action_release("drive_throttle")
	Input.action_press("drive_clutch")
	Input.action_press("drive_brake")
	assert(await reach_step(session, 6, 480))
	Input.action_press("drive_handbrake")
	assert(await reach_step(session, 7, 60))
	Input.action_release("drive_handbrake")
	await frames(16)
	await shift("drive_gear_down")
	await shift("drive_gear_down")
	await shift("drive_gear_down")
	assert(car.gearbox.gear == -1)
	Input.action_release("drive_clutch")
	Input.action_release("drive_brake")
	Input.action_press("drive_throttle")
	for index in 720:
		if app._page == "result":
			break
		await physics_frame
	Input.action_release("drive_throttle")
	assert(app._page == "result")
	assert(app._last_result.get("completed") == true)
	assert(app._last_result.get("step_count") == 8)
	assert(app._last_result.get("stall_count") == 1)
	assert(load("res://scripts/attempt_store.gd").load_attempts().size() >= 1)
	print("PASS: first-person manual lesson, feedback, save, and result navigation")
	app.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit()
