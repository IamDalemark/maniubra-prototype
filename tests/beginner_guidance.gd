extends SceneTree
## Beginner cues must follow actual clutch/gear state and saved input labels.

func _initialize() -> void:
	call_deferred("verify")

func check(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
	return condition

func verify() -> void:
	root.size = Vector2i(1280, 800)
	var session = load("res://scenes/lessons/primary_controls.tscn").instantiate()
	root.add_child(session)
	session.start_attempt({})
	session.set_physics_process(false)
	session.sedan.freeze = true
	var car = session.sedan
	car.set_physics_process(false)
	if not check(session._prompt.text == "Start the engine" and session._why.text.contains("power") and session._action.text.contains("H"), "Initial goal, reason and binding are missing."):
		return
	if not check(car._lesson_focus == ["ignition"] and car.camera.current and session._control_camera.current, "Initial physical cue or separate close-up is missing."):
		return
	if not check(not session._metrics.rpm.visible and not session._metrics.seatbelt.visible and not session._metrics.speed.visible, "Metrics were shown all at once."):
		return
	session._process(0.36)
	if not check(session._metrics.rpm.visible and not session._metrics.seatbelt.visible, "Metrics did not appear in sequence."):
		return
	session._set_paused(true)
	var clock: float = session._lesson_clock
	session._process(2.0)
	if not check(session._lesson_clock == clock, "Pause advanced the beginner metric reveal."):
		return
	session._set_paused(false)
	session._process(0.40)
	if not check(session._metrics.seatbelt.visible and not session._metrics.speed.visible, "Unintroduced driving metrics appeared early."):
		return
	car.gearbox.engine_running = true
	session._step = 1
	session._update_ui()
	var clutch = car._pedals.clutch
	var original_material = clutch.material_override
	if not check(car._lesson_focus == ["clutch"] and clutch.material_overlay != null and car._pedals.brake.material_overlay == null and session._action.text.contains("all the way down"), "Clutch substep did not isolate its physical target."):
		return
	if not check(car._pedals.clutch.position.x > car._pedals.brake.position.x and car._pedals.brake.position.x > car._pedals.accelerator.position.x, "Pedals are not ordered left clutch, middle brake, right accelerator from the driver's seat."):
		return
	car.controls.clutch = 0.9
	session._update_ui()
	if not check(car._lesson_focus == ["gear"] and clutch.material_overlay == null and clutch.material_override == original_material and session._action.text.contains("Press E once"), "Clutch completion did not switch to shifting or restore the material."):
		return
	car.controls.last_device = "gamepad"
	session._update_ui()
	if not check(session._action.text.contains(car.DrivingInput.display_name("drive_gear_up", "gamepad")) and not session._action.text.contains("Press E once"), "Controller labels did not follow the active device."):
		return
	car.controls.last_device = "keyboard_mouse"
	car.gearbox.gear = 3
	session._update_ui()
	if not check(session._action.text.contains("Press Q once") and session._action.text.contains("gear 1"), "An accidental overshift leaves the beginner with an impossible first-gear instruction."):
		return
	car.gearbox.gear = 1
	var eye: Transform3D = car.camera.global_transform
	session._step = 2
	car.controls.clutch = 0.9
	car.controls.throttle = 0.0
	session._update_ui()
	if not check(car._lesson_focus == ["accelerator"], "Move-away guidance skipped adding power."):
		return
	car.controls.throttle = 0.4
	session._update_ui()
	if not check(car._lesson_focus == ["clutch"] and session._action.text.contains("Release C"), "Move-away guidance skipped releasing the clutch."):
		return
	car.controls.clutch = 0.0
	session._update_ui()
	if not check(session._action.text.contains("8 km/h") and car.camera.global_transform == eye, "Guidance moved the driving camera or lost its motion goal."):
		return
	car.gearbox.engine_running = false
	car.gearbox.engine_stalled = true
	session._update_ui()
	if not check(session._prompt.text == "Restart the engine" and car._lesson_focus == ["clutch"], "A stalled engine leaves an impossible driving prompt."):
		return
	car.controls.clutch = 1.0
	session._update_ui()
	if not check(car._lesson_focus == ["ignition"] and session._action.text.contains("restart"), "Recovery did not guide ignition after depressing the clutch."):
		return
	session._restart()
	if not check(session._step == 0 and session._lesson_clock == 0 and not session._metrics.speed.visible and session.sedan._lesson_focus == ["ignition"], "Restart retained beginner reveal or highlight state."):
		return
	var open_car = load("res://scenes/vehicles/sedan.tscn").instantiate()
	root.add_child(open_car)
	if not check(open_car._lesson_focus.is_empty() and open_car._pedals.clutch.material_overlay == null, "Shared sedan glows outside Primary Controls."):
		return
	open_car.queue_free()
	session.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("PASS: goals/reasons, sequential metrics, pause, clutch/gear/power cues, device labels, recovery and restart")
	quit()
