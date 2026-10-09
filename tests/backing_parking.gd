extends SceneTree
## Boundary criteria plus a real reverse-turn drive through menu, review and retry.
var capture := false

func _initialize() -> void:
	if OS.get_environment("MANIUBRA_DATA_DIR").is_empty():
		push_error("Use a disposable MANIUBRA_DATA_DIR.")
		quit(1)
		return
	capture = OS.get_cmdline_user_args().has("--capture")
	call_deferred("verify")

func check(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
	return condition

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func tap(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	Input.action_release(action)
	await physics_frame

func screenshot(name: String) -> void:
	if not capture:
		return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/" + name + ".png")

func verify() -> void:
	var app = load("res://scenes/app.tscn").instantiate()
	root.add_child(app)
	app._show_lessons("maneuvers")
	app._show_briefing("parking")
	var catalog = load("res://scripts/course_catalog.gd")
	var parking: Dictionary = catalog.get_lesson("maneuvers", "parking")
	if not check(app._lesson_available(parking) and parking.title.contains("Backing"), "Guided parking is not selectable."): return
	if not check(not app._lesson_available(catalog.get_lesson("maneuvers", "reversing")), "Unimplemented maneuvers became available."): return
	app._launch_lesson(parking.scene_path)
	var lesson = app._session
	var car = lesson.sedan
	if not check(lesson._prompt.text == "Start the engine" and lesson._why.text.contains("bay") and car._lesson_focus == ["ignition"], "Primary-style goal, why and glow were not reused."): return
	await frames(20)
	await screenshot("backing_parking_start")
	# Isolate criterion boundaries from physics; then restart for the real drive.
	lesson.set_physics_process(false)
	car.freeze = true
	car.set_physics_process(false)
	car.position = Vector3(-9.5, 0.02, 0)
	car.rotation = Vector3(0, PI / 2, 0)
	if not check(lesson._parked_pose(), "A centred, facing-out car was rejected."): return
	car.position.x = -6.0
	if not check(not lesson._whole_car_inside(), "Checking only the origin accepts a protruding bumper."): return
	car.position = Vector3(-9.5, 0.02, 2.0)
	if not check(not lesson._whole_car_inside(), "An external mirror over the side line was accepted."): return
	car.position.z = 0.0
	car.rotation.y = -PI / 2
	if not check(not lesson._parked_pose(), "Forward-in parking was accepted as backing."): return
	car.rotation.y = PI / 2 + deg_to_rad(10)
	if not check(not lesson._parked_pose(), "A diagonal car was accepted."): return
	car.rotation = Vector3(0, PI / 2, PI / 2)
	if not check(not lesson._parked_pose(), "A tipped car was accepted."): return
	car.rotation = Vector3(0, PI / 2, 0)
	car.gearbox.engine_running = true
	lesson._step = 1
	car.controls.clutch = 1.0
	car.controls.last_device = "gamepad"
	lesson._update_ui()
	if not check(lesson._action.text.contains(car.DrivingInput.display_name("drive_gear_down", "gamepad")), "Parking ignores the controller binding."): return
	car.controls.last_device = "keyboard_mouse"
	car.gearbox.gear = -1
	lesson._step = 2
	car.controls.brake = 0.0
	car.controls.throttle = 0.0
	lesson._update_ui()
	if not check(lesson._focus_id == "accelerator", "Backing guidance skipped adding power."): return
	car.controls.throttle = 0.4
	lesson._update_ui()
	if not check(lesson._focus_id == "clutch" and lesson._action.text.contains("Release C"), "Backing guidance did not separately teach clutch release."): return
	car.controls.clutch = 0.0
	lesson._update_ui()
	if not check(lesson._focus_id == "steering", "Backing guidance did not progress to steering."): return
	car.controls.clutch = 1.0
	car.controls.brake = 1.0
	lesson._step = 4
	car.linear_velocity = Vector3(0.2, 0, 0)
	lesson._physics_process(0.1)
	if not check(lesson._step == 4, "A moving car completed the stop."): return
	car.linear_velocity = Vector3.ZERO
	lesson._physics_process(0.1)
	if not check(lesson._step == 5, "A fully parked stop did not advance."): return
	car.gearbox.gear = 0
	car.controls.handbrake = true
	car.controls.brake = 0.0
	lesson._physics_process(0.7)
	lesson._set_paused(true)
	var held: float = lesson._secured_seconds
	lesson._physics_process(4.0)
	if not check(lesson._secured_seconds == held and lesson._step == 5, "Pause counted as securing the car."): return
	lesson._set_paused(false)
	car.controls.handbrake = false
	lesson._physics_process(0.1)
	if not check(lesson._secured_seconds == 0, "Interrupted handbrake hold did not reset."): return
	var cone: Node = lesson._cones[0]
	lesson._on_parking_contact(cone)
	lesson._on_parking_contact(cone)
	if not check(lesson._events.filter(func(e): return e.type == "parking_contact").size() == 1 and lesson._toast_title.text.contains("CONE CONTACT"), "Cone feedback duplicates or is missing."): return
	car.linear_velocity = Vector3(3.0, 0, 0)
	lesson._physics_process(0.1)
	lesson._physics_process(0.1)
	if not check(lesson._events.filter(func(e): return e.type == "parking_speed").size() == 1, "Speed reminder repeats every frame."): return
	cone.position += Vector3(1, 0, 1)
	lesson._restart()
	lesson.set_physics_process(true)
	car = lesson.sedan
	if not check(lesson._step == 0 and lesson._events.is_empty() and lesson._secured_seconds == 0 and cone.transform == lesson._cone_starts[0], "Restart retained task, incidents or displaced cones."): return
	await tap("drive_ignition")
	Input.action_press("drive_clutch")
	Input.action_press("drive_brake")
	await frames(20)
	if not check(lesson._focus_id == "gear" and lesson._action.text.contains("R"), "Reverse cue did not follow the clutch."): return
	await tap("drive_gear_down")
	await frames(4)
	if not check(lesson._step == 2, "Reverse selection did not advance."): return
	Input.action_release("drive_brake")
	Input.action_press("drive_throttle", 0.27)
	Input.action_press("drive_right")
	Input.action_release("drive_clutch")
	var captured_turn := false
	# Real inputs/forces: no teleporting in this complete driving flow.
	for i in 1200:
		await physics_frame
		Input.action_press("drive_brake", clampf((car.speed_mps() - 1.4) * 0.2, 0.0, 0.35))
		if car.rotation.y > 0.8 and not captured_turn:
			captured_turn = true
			await screenshot("backing_parking_turn")
		if car.rotation.y > 1.53:
			Input.action_release("drive_right")
			break
	if not check(captured_turn, "The sedan never made the reverse turn."): return
	for i in 600:
		await physics_frame
		Input.action_press("drive_brake", clampf((car.speed_mps() - 1.4) * 0.2, 0.0, 0.35))
		if car.position.x < -9.0: break
	Input.action_release("drive_throttle")
	Input.action_press("drive_clutch")
	Input.action_press("drive_brake")
	await frames(100)
	if not check(lesson._step == 5 and lesson._parked_pose() and lesson._reverse_distance > 8.0, "Actual backing drive did not stop fully in the bay."): return
	await screenshot("backing_parking_parked")
	if capture:
		lesson._set_paused(true)
		lesson._pause_center.visible = false
		var overview := Camera3D.new()
		lesson.add_child(overview)
		overview.position = Vector3(16, 20, -18)
		overview.look_at(Vector3(-5, 0, 2))
		overview.current = true
		await screenshot("backing_parking_lot")
		overview.queue_free()
		car.camera.current = true
		lesson._set_paused(false)
	await tap("drive_gear_up")
	Input.action_press("drive_handbrake")
	Input.action_release("drive_brake")
	for i in 240:
		await physics_frame
		if app._page == "result": break
	for action in ["drive_clutch", "drive_brake", "drive_handbrake", "drive_throttle", "drive_right"]:
		Input.action_release(action)
	if not check(app._page == "result" and app._last_result.completed and app._last_result.lesson_id == "parking", "Parking did not reach its review."): return
	var result: Dictionary = app._last_result
	var steps: Array = result.events.filter(func(e): return e.type == "step_completed")
	if not check(result.step_count == 6 and steps.size() == 6 and steps[-1].step_id == "secure" and result.cone_contacts == 0 and result.stall_count == 0, "Parking result identity or observations are wrong."): return
	var store = load("res://scripts/attempt_store.gd")
	if not check(store.load_attempts().any(func(a): return a.lesson_id == "parking" and a.completed), "Parking result was not persisted."): return
	await screenshot("backing_parking_review")
	app._launch_lesson(parking.scene_path)
	if not check(app._session._step == 0 and app._session._events.is_empty(), "Retry did not create a fresh backing lesson."): return
	# Independently drive into a physical cone to verify the Jolt signal path.
	var retry = app._session
	car = retry.sedan
	car.position = retry._cones[2].position + Vector3(0, -0.28, -4.0)
	car.gearbox.engine_running = true
	car.gearbox.gear = 1
	Input.action_press("drive_throttle", 0.5)
	for i in 300:
		await physics_frame
		if retry._events.any(func(e): return e.type == "parking_contact"): break
	Input.action_release("drive_throttle")
	if not check(retry._events.any(func(e): return e.type == "parking_contact") and retry._toast_title.text.contains("CONE CONTACT"), "Actual physical cone contact did not produce corrective feedback."): return
	app._session._exit()
	if not check(app._page == "briefing" and app._session == null, "Exit did not return to the correct briefing."): return
	app.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("PASS: backing parking boundaries, beginner guide, feedback/reset, real reverse turn, stop/secure, saved review and retry")
	quit()
