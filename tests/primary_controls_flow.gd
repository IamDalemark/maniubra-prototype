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


func click_button(button: Button) -> void:
	var point := button.get_global_rect().get_center()
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.position = point
	down.global_position = point
	down.pressed = true
	root.push_input(down, true)
	await process_frame
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.position = point
	up.global_position = point
	up.pressed = false
	root.push_input(up, true)
	await process_frame


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
	assert(not car.seatbelt_fastened)
	assert(session._seatbelt_status.text.contains("UNFASTENED"))
	var right_on_wheel: Vector3 = car._right_hand.position
	await shift("drive_seatbelt")
	assert(car.seatbelt_fastened and session._seatbelt_status.text.contains("FASTENED"))
	assert(car._seatbelt_hand_timer > 0.0)
	await frames(14)
	assert(car._right_hand.position.distance_to(right_on_wheel) > 0.06)
	assert(car._right_hand.position.x > car._steering_visual.position.x + 0.15)
	assert(car._right_hand.position.y > right_on_wheel.y + 0.10)
	session._set_paused(true)
	await process_frame
	assert(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE)
	await click_button(session._seatbelt_button)
	assert(not car.seatbelt_fastened)
	assert(car._seatbelt_hand_timer > 0.0)
	var paused_reach_time: float = car._seatbelt_hand_timer
	await frames(4)
	assert(car._seatbelt_hand_timer < paused_reach_time)
	await click_button(session._seatbelt_button)
	assert(car.seatbelt_fastened)
	session._set_paused(false)
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
	await process_frame
	await click_button(session._pause_panel.get_node("Buttons/Resume"))
	assert(not session._paused)
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
	assert(session._metrics.speed.text == "SPEED  00 km/h")
	Input.action_press("drive_handbrake")
	assert(await reach_step(session, 7, 60))
	assert(car._handbrake_hand_timer > 0.0)
	await frames(8)
	assert(car._right_hand.position.distance_to(right_on_wheel) > 0.08)
	await frames(10)
	assert(session._handbrake_status.text.contains("APPLIED"))
	assert(car._handbrake_lever.rotation.x > 0.3)
	Input.action_release("drive_handbrake")
	await frames(10)
	assert(session._handbrake_status.text.contains("RELEASED"))
	assert(car._handbrake_lever.rotation.x < 0.3)
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
	assert(app._last_result.get("scenario_version") == 3 and app._last_result.get("assessment_version") == 3)
	var completed_steps: Array = app._last_result.events.filter(func(event): return event.type == "step_completed")
	assert(completed_steps.size() == 8 and completed_steps.all(func(event): return not String(event.get("step_id", "")).is_empty()))
	assert(app._last_result.get("stall_count") == 1)
	assert(load("res://scripts/attempt_store.gd").load_attempts().size() >= 1)
	print("PASS: first-person manual lesson, feedback, save, and result navigation")
	app.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit()
