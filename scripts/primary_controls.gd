extends Node3D
## A repeatable manual-driving exercise in an enclosed training lot.

signal attempt_finished(result: Dictionary)
signal exit_requested

const SEDAN_SCENE = preload("res://scenes/vehicles/sedan.tscn")
const SHOPFRONT_SCENE = preload("res://scenes/props/shopfront.tscn")
const PALM_SCENE = preload("res://scenes/props/palm.tscn")
const JEEPNEY_SCENE = preload("res://scenes/props/jeepney.tscn")
const TRICYCLE_SCENE = preload("res://scenes/props/tricycle.tscn")
const TRAFFIC_CONE_SCENE = preload("res://scenes/props/traffic_cone.tscn")
const DrivingInput = preload("res://scripts/driving_input.gd")
const SPAWN_POSITION := Vector3(-2.7, 0.02, -85.0)
const LESSON_STEPS = [
	{"id": "start_engine", "goal": "Start the engine", "why": "The engine supplies power to move the car."},
	{"id": "select_first", "goal": "Get ready to move", "why": "The clutch disconnects engine power so you can select a gear."},
	{"id": "move_forward", "goal": "Move forward slowly", "why": "The accelerator adds power. Releasing the clutch sends it to the wheels."},
	{"id": "select_second", "goal": "Change to second gear", "why": "Second gear lets the engine turn more slowly as you gain speed."},
	{"id": "steer", "goal": "Change your direction", "why": "Small steering movements help you keep control."},
	{"id": "stop", "goal": "Bring the car to a stop", "why": "The brake slows the car. Holding the clutch down prevents a low-speed stall."},
	{"id": "handbrake", "goal": "Hold the stopped car", "why": "The handbrake helps keep the car still when parked."},
	{"id": "reverse", "goal": "Back up three metres", "why": "Reverse gear moves the car backward. Check behind you before moving."},
]
const METRIC_STEPS := {"engine": 0, "rpm": 0, "seatbelt": 0, "clutch": 1, "gear": 1, "speed": 2, "brake": 5, "handbrake": 6}


var sedan
var _hud: VBoxContainer
var _metrics: Dictionary = {}
var _metric_reveal_at: Dictionary = {}
var _lesson_clock := 0.0
var _guidance_panel: PanelContainer
var _why: Label
var _action: Label
var _action_progress: Label
var _control_caption: Label
var _control_viewport: SubViewport
var _control_camera: Camera3D
var _focus_id := ""
var _prompt: Label
var _controls_hint: Label
var _seatbelt_status: Label
var _seatbelt_button: Button
var _handbrake_status: Label
var _toast_panel: PanelContainer
var _toast_title: Label
var _toast_detail: Label
var _toast_remaining := 0.0
var _pause_panel: PanelContainer
var _pause_center: CenterContainer
var _started := false
var _paused := false
var _step := 0
var _elapsed := 0.0
var _events: Array = []
var _last_notice := ""
var _start_z := 0.0
var _steer_x := 0.0
var _reverse_z := 0.0
var _context: Dictionary = {}


func _lesson_steps() -> Array:
	return LESSON_STEPS


func _metric_steps() -> Dictionary:
	return METRIC_STEPS


func _lesson_heading() -> String:
	return "PRIMARY CONTROLS"


func _spawn_position() -> Vector3:
	return SPAWN_POSITION


func _is_recovering() -> bool:
	return _step > 0 and not sedan.gearbox.engine_running


func _ready() -> void:
	_build_yard()
	sedan = SEDAN_SCENE.instantiate()
	sedan.position = _spawn_position()
	add_child(sedan)
	_connect_sedan_signals()
	_build_ui()
	_update_ui()


func start_attempt(context: Dictionary) -> void:
	_context = context.duplicate(true)
	sedan.camera.fov = clampf(float(context.get("camera_fov", 75.0)), 60.0, 95.0)
	sedan.set_audio_level(float(context.get("audio_level", 0.8)))
	_started = true
	_paused = false
	_step = 0
	_elapsed = 0.0
	_events.clear()
	_lesson_clock = 0.0
	_metric_reveal_at.clear()
	_last_notice = ""
	_hide_error_toast()
	_start_z = sedan.global_position.z
	_steer_x = sedan.global_position.x
	_reverse_z = sedan.global_position.z
	sedan.driving_enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	sedan.prepare_mouse_capture()
	_update_ui()


func _physics_process(delta: float) -> void:
	if not _started or _paused:
		return
	_elapsed += delta
	var speed: float = sedan.speed_mps()
	match _step:
		0:
			if sedan.gearbox.engine_running:
				_advance("Engine started.")
		1:
			if sedan.gearbox.gear == 1:
				_advance("First gear selected with the clutch depressed.")
		2:
			if speed > 2.22 and sedan.global_position.z > _start_z + 4.0 and sedan.controls.clutch < 0.2:
				_advance("You moved forward under engine power.")
		3:
			if sedan.gearbox.gear == 2:
				_steer_x = sedan.global_position.x
				_advance("Second gear selected with the clutch depressed.")
		4:
			if speed > 1.0 and absf(sedan.global_position.x - _steer_x) > 1.8:
				_advance("You changed position while moving.")
		5:
			if sedan.controls.brake > 0.5 and sedan.controls.clutch > 0.65 and speed < 0.12:
				_advance("You brought the sedan to a full stop with the brake.")
		6:
			if sedan.controls.handbrake and speed < 0.35:
				_reverse_z = sedan.global_position.z
				_advance("Handbrake applied while stopped.")
		7:
			if sedan.gearbox.engine_running and sedan.gearbox.gear == -1 and sedan.global_position.z < _reverse_z - 3.0:
				_advance("You reversed at least three metres.")
	_update_ui()


func _process(delta: float) -> void:
	if not _started or _paused:
		return
	_lesson_clock += delta
	_update_metric_reveal()
	if _toast_remaining > 0.0:
		_toast_remaining = maxf(_toast_remaining - delta, 0.0)
		_toast_panel.modulate.a = minf(_toast_remaining / 0.35, 1.0)
		if _toast_remaining == 0.0:
			_toast_panel.visible = false
	# The close-up follows the car; the player's driving camera stays unchanged.
	if _control_camera != null:
		_update_control_camera()


func _input(event: InputEvent) -> void:
	if not _started:
		return
	if event.is_action_pressed("drive_pause"):
		_set_paused(not _paused)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("drive_reset") and not _paused:
		_restart()
		get_viewport().set_input_as_handled()


func _advance(message: String) -> void:
	_events.append({"type": "step_completed", "step": _step, "step_id": _lesson_steps()[_step].id, "elapsed_seconds": snappedf(_elapsed, 0.01), "detail": message})
	_last_notice = message
	_step += 1
	if _step == _lesson_steps().size():
		_finish()


func _on_shift_rejected() -> void:
	if not _started or _paused:
		return
	_events.append({"type": "shift_rejected", "elapsed_seconds": snappedf(_elapsed, 0.01), "detail": "Gear change attempted without depressing the clutch."})
	_last_notice = "Depress the clutch before shifting."
	_show_error_toast("SHIFT ERROR", _last_notice)


func _on_engine_state_changed(running: bool, stalled: bool) -> void:
	if not _started or _paused:
		return
	var event_type := "engine_stalled" if stalled else ("engine_started" if running else "engine_stopped")
	var detail := "Engine stalled. Hold %s and press %s to restart." % [DrivingInput.display_name("drive_clutch", sedan.controls.last_device), DrivingInput.display_name("drive_ignition", sedan.controls.last_device)] if stalled else ("Engine started." if running else "Engine switched off.")
	_events.append({"type": event_type, "elapsed_seconds": snappedf(_elapsed, 0.01), "detail": detail})
	_last_notice = detail
	if stalled:
		_show_error_toast("ENGINE STALLED", detail)
	elif running:
		_hide_error_toast()


func _on_ignition_rejected() -> void:
	if not _started or _paused:
		return
	var detail := "Hold %s or select neutral before starting the engine." % DrivingInput.display_name("drive_clutch", sedan.controls.last_device)
	_events.append({"type": "ignition_rejected", "elapsed_seconds": snappedf(_elapsed, 0.01), "detail": detail})
	_last_notice = detail
	_show_error_toast("START BLOCKED", detail)


func _show_error_toast(title: String, detail: String) -> void:
	_toast_title.text = "!  " + title
	_toast_detail.text = detail
	_toast_remaining = 4.5
	_toast_panel.modulate.a = 1.0
	_toast_panel.visible = true


func _hide_error_toast() -> void:
	_toast_remaining = 0.0
	if _toast_panel != null:
		_toast_panel.visible = false


func _finish() -> void:
	_started = false
	sedan.driving_enabled = false
	sedan.set_lesson_focus([])
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var mistakes := 0
	for event in _events:
		if event["type"] == "shift_rejected":
			mistakes += 1
	var result := _context.duplicate(true)
	result["scenario_version"] = 3
	result["assessment_version"] = 3
	result["step_count"] = _lesson_steps().size()
	result["unix_time"] = Time.get_unix_time_from_system()
	result["completed"] = true
	result["elapsed_seconds"] = snappedf(_elapsed, 0.1)
	result["shift_errors"] = mistakes
	var stalls := 0
	for event in _events:
		if event["type"] == "engine_stalled":
			stalls += 1
	result["stall_count"] = stalls
	result["input_profile_id"] = sedan.controls.last_device
	result["events"] = _events.duplicate(true)
	result["feedback"] = "Completed all eight control steps." + (" Practice clutch timing: %d shifts were rejected." % mistakes if mistakes else " No gear changes were rejected.") + (" The engine stalled %d time(s)." % stalls if stalls else " No engine stalls.")
	attempt_finished.emit(result)


func _restart() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var old: Node3D = sedan
	remove_child(old)
	old.queue_free()
	sedan = SEDAN_SCENE.instantiate()
	sedan.position = _spawn_position()
	add_child(sedan)
	_connect_sedan_signals()
	start_attempt(_context)


func _connect_sedan_signals() -> void:
	sedan.shift_rejected.connect(_on_shift_rejected)
	sedan.engine_state_changed.connect(_on_engine_state_changed)
	sedan.ignition_rejected.connect(_on_ignition_rejected)


func _set_paused(value: bool) -> void:
	_paused = value
	sedan.driving_enabled = not value
	_pause_center.visible = value
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_CAPTURED
	if value:
		_pause_panel.get_node("Buttons/Resume").grab_focus()


func _exit() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	exit_requested.emit()


func _update_ui() -> void:
	if _hud == null or sedan == null:
		return
	var gear_name := "R" if sedan.gearbox.gear == -1 else ("N" if sedan.gearbox.gear == 0 else str(sedan.gearbox.gear))
	var engine_status := "RUNNING" if sedan.gearbox.engine_running else ("STALLED" if sedan.gearbox.engine_stalled else "OFF")
	var values := {"speed": "%02d km/h" % roundi(sedan.speed_mps() * 3.6), "rpm": "%04d" % roundi(sedan.gearbox.engine_rpm), "gear": gear_name, "engine": engine_status, "clutch": "%d%%" % roundi(sedan.controls.clutch * 100), "brake": "%d%%" % roundi(sedan.controls.brake * 100), "handbrake": "ON" if sedan.controls.handbrake else "OFF", "seatbelt": "ON" if sedan.seatbelt_fastened else "OFF"}
	var queued := 0
	for id in _metric_steps():
		_metrics[id].text = id.to_upper() + "  " + values[id]
		if _metric_steps()[id] <= _step and not _metric_reveal_at.has(id):
			_metric_reveal_at[id] = _lesson_clock + queued * 0.32
			queued += 1
	_update_metric_reveal()
	_update_guidance()
	_controls_hint.text = "%s pause  •  %s restart" % [DrivingInput.display_name("drive_pause", sedan.controls.last_device), DrivingInput.display_name("drive_reset", sedan.controls.last_device)]
	_seatbelt_status.text = "SEATBELT  •  FASTENED" if sedan.seatbelt_fastened else "SEATBELT  •  UNFASTENED"
	_seatbelt_status.add_theme_color_override("font_color", Color("a4dfbb") if sedan.seatbelt_fastened else Color("f5c568"))
	var belt_key := DrivingInput.display_name("drive_seatbelt", sedan.controls.last_device)
	_seatbelt_button.text = "Unfasten seatbelt  [%s]" % belt_key if sedan.seatbelt_fastened else "Fasten seatbelt  [%s]" % belt_key
	_seatbelt_button.tooltip_text = "Press %s while driving, or click here while paused." % belt_key
	_handbrake_status.text = "HANDBRAKE  •  APPLIED" if sedan.controls.handbrake else "HANDBRAKE  •  RELEASED"
	_handbrake_status.add_theme_color_override("font_color", Color("f5c568") if sedan.controls.handbrake else Color("a4dfbb"))


func _bound_text(text: String) -> String:
	for binding in DrivingInput.BINDINGS:
		var action: String = binding["action"]
		text = text.replace("{" + action + "}", DrivingInput.display_name(StringName(action), sedan.controls.last_device))
	return text


func _teaching_action() -> Dictionary:
	if sedan.gearbox.engine_stalled or (_step > 0 and not sedan.gearbox.engine_running):
		if sedan.controls.clutch < 0.65:
			return _instruction("Hold {drive_clutch} all the way down.", "clutch", 1, 2)
		return _instruction("Keep holding the clutch. Press {drive_ignition} to restart.", "ignition", 2, 2)
	match _step:
		0:
			if sedan.gearbox.gear != 0 and sedan.controls.clutch < 0.65:
				return _instruction("Hold {drive_clutch} all the way down before starting.", "clutch", 1, 2)
			return _instruction("Press {drive_ignition} once. Listen for the engine.", "ignition", 1, 1)
		1, 3:
			if sedan.controls.clutch < 0.65:
				return _instruction("Hold {drive_clutch} all the way down.", "clutch", 1, 2)
			var target_gear := 1 if _step == 1 else 2
			var action := "drive_gear_down" if sedan.gearbox.gear > target_gear else "drive_gear_up"
			return _instruction("Keep the clutch down. Press {" + action + "} once for gear %d." % target_gear, "gear", 2, 2)
		2:
			if sedan.controls.throttle < 0.25 and sedan.speed_mps() < 1.0:
				return _instruction("Hold {drive_throttle} gently to add a little power.", "accelerator", 1, 3)
			if sedan.controls.clutch > 0.2:
				return _instruction("Keep the accelerator held. Release {drive_clutch} to move.", "clutch", 2, 3)
			return _instruction("Keep moving forward until SPEED reaches 8 km/h.", "accelerator", 3, 3)
		4:
			return _instruction("Gently steer with {drive_left} / {drive_right} while moving.", "steering", 1, 1)
		5:
			if sedan.controls.throttle > 0.1:
				return _instruction("Release {drive_throttle} to stop adding power.", "accelerator", 1, 3)
			if sedan.controls.clutch < 0.65:
				return _instruction("Hold {drive_clutch} all the way down.", "clutch", 2, 3)
			return _instruction("Keep the clutch down. Hold {drive_brake} until SPEED is 0.", "brake", 3, 3)
		6:
			return _instruction("Stay stopped. Hold {drive_handbrake} to apply the handbrake.", "handbrake", 1, 1)
		7:
			if sedan.controls.handbrake:
				return _instruction("Release {drive_handbrake} to lower the handbrake.", "handbrake", 1, 5)
			if sedan.gearbox.gear != -1:
				if sedan.controls.clutch < 0.65:
					return _instruction("Hold {drive_clutch} all the way down.", "clutch", 2, 5)
				var next_gear := "R" if sedan.gearbox.gear == 0 else ("N" if sedan.gearbox.gear == 1 else str(sedan.gearbox.gear - 1))
				return _instruction("Keep the clutch down. Press {drive_gear_down} once for " + next_gear + ".", "gear", 3, 5)
			if sedan.controls.brake > 0.1:
				return _instruction("Release {drive_brake}. Check the mirrors and look behind.", "brake", 4, 5)
			if sedan.controls.clutch > 0.2:
				return _instruction("Hold {drive_throttle} gently, then release {drive_clutch}.", "clutch", 5, 5)
			return _instruction("Hold {drive_throttle} gently. Back up three metres.", "accelerator", 5, 5)
	return _instruction("Lesson complete.", "", 1, 1)


func _instruction(text: String, focus: String, index: int, total: int) -> Dictionary:
	return {"text": text, "focus": focus, "index": index, "total": total}


func _update_guidance() -> void:
	var step: Dictionary = _lesson_steps()[mini(_step, _lesson_steps().size() - 1)]
	var instruction := _teaching_action()
	var recovering: bool = _is_recovering()
	_prompt.text = "Restart the engine" if recovering else step.goal
	_why.text = "WHY  " + ("The engine stopped. Hold the clutch down to restart without moving." if recovering else step.why)
	_action_progress.text = "%s  %d / %d  •  ACTION %d / %d" % [_lesson_heading(), mini(_step + 1, _lesson_steps().size()), _lesson_steps().size(), instruction.index, instruction.total]
	_action.text = _bound_text(instruction.text)
	var focus: String = instruction.focus
	sedan.set_lesson_focus([focus] if _started and focus != "" else [])
	_focus_id = focus
	_control_caption.text = {"clutch": "CLUTCH • LEFT PEDAL", "brake": "BRAKE • MIDDLE PEDAL", "accelerator": "ACCELERATOR • RIGHT PEDAL", "gear": "GEAR LEVER", "handbrake": "HANDBRAKE", "steering": "STEERING WHEEL", "ignition": "ENGINE START"}.get(focus, "")
	_control_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if _started else SubViewport.UPDATE_DISABLED
	_update_control_camera()


func _update_control_camera() -> void:
	if _control_camera == null:
		return
	var at := Vector3(0.42, 0.79, 0.18)
	var target := Vector3(0.42, 0.52, 0.64)
	match _focus_id:
		"steering":
			at = Vector3(0.40, 1.27, -0.63)
			target = Vector3(0.40, 1.07, 0.10)
		"gear":
			at = Vector3(-0.09, 1.43, -0.43)
			target = Vector3(-0.09, 1.19, -0.02)
		"handbrake":
			at = Vector3(0.08, 1.40, -0.32)
			target = Vector3(0.08, 1.15, 0.07)
		"ignition":
			at = Vector3(0.19, 1.07, 0.14)
			target = Vector3(0.19, 1.025, 0.23)
	_control_camera.global_position = sedan.to_global(at)
	_control_camera.look_at(sedan.to_global(target), sedan.global_basis.y)


func _update_metric_reveal() -> void:
	for id in _metrics:
		var label: Label = _metrics[id]
		var at: float = _metric_reveal_at.get(id, INF)
		label.visible = _lesson_clock >= at
		label.modulate.a = clampf((_lesson_clock - at) / 0.22, 0.0, 1.0)


func _build_yard() -> void:
	var sky := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("76b7e5")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("f4e7ce")
	env.ambient_light_energy = 0.73
	sky.environment = env
	add_child(sky)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, -26, 0)
	sun.light_energy = 1.55
	sun.shadow_enabled = true
	add_child(sun)

	# The asphalt is one continuous collision surface. The outer walls keep
	# exploratory driving inside the 160 by 240 metre school lot.
	_surface(Vector3(200, 0.12, 280), Vector3(0, -0.17, 0), Color("6b8a63"), true, "OuterGround")
	_surface(Vector3(160, 0.08, 240), Vector3(0, -0.04, 0), Color("4b555a"), true, "LotSurface")
	_build_lot_perimeter()
	_build_lot_markings()
	_build_lot_cones()
	_build_roundabout(Vector3(-48, 0, 66))
	_build_roundabout_sign()

	# Familiar roadside shapes sit beyond the practice boundary, not in the
	# driving path. Cones and paint define the actual exercise area.
	for side in [-1.0, 1.0]:
		for index in 3:
			var shop = SHOPFRONT_SCENE.instantiate()
			shop.palette_index = (index + (0 if side < 0 else 2)) % 4
			shop.position = Vector3(side * 93.0, 0, -60.0 + float(index) * 60.0)
			shop.rotation.y = -side * PI / 2.0
			add_child(shop)
		for z in [-97.0, -35.0, 35.0, 97.0]:
			var palm := PALM_SCENE.instantiate()
			palm.position = Vector3(side * 85.5, 0, z)
			add_child(palm)
	var parked := JEEPNEY_SCENE.instantiate()
	parked.position = Vector3(88, 0, 20)
	parked.rotation.y = -PI / 2.0
	add_child(parked)
	var tricycle := TRICYCLE_SCENE.instantiate()
	tricycle.position = Vector3(-88, 0, -15)
	tricycle.rotation.y = PI / 2.0
	add_child(tricycle)


func _build_lot_perimeter() -> void:
	for side in [-1.0, 1.0]:
		var edge_x: float = side * 80.0
		_surface(Vector3(0.8, 1.25, 240), Vector3(edge_x, 0.625, 0), Color("39464a"), true, "LotWallSide%d" % int(side))
		_surface(Vector3(0.08, 0.18, 240), Vector3(edge_x - side * 0.45, 0.52, 0), Color("e9bc43"), false)
		_surface(Vector3(0.08, 0.08, 240), Vector3(edge_x, 2.17, 0), Color("4e6265"), false)
		for z in range(-120, 121, 12):
			_surface(Vector3(0.20, 2.25, 0.20), Vector3(edge_x, 1.12, float(z)), Color("586b6b"), false)
	for side in [-1.0, 1.0]:
		var edge_z: float = side * 120.0
		_surface(Vector3(160, 1.25, 0.8), Vector3(0, 0.625, edge_z), Color("39464a"), true, "LotWallEnd%d" % int(side))
		_surface(Vector3(160, 0.18, 0.08), Vector3(0, 0.52, edge_z - side * 0.45), Color("e9bc43"), false)
		_surface(Vector3(160, 0.08, 0.08), Vector3(0, 2.17, edge_z), Color("4e6265"), false)
		for x in range(-80, 81, 12):
			_surface(Vector3(0.20, 2.25, 0.20), Vector3(float(x), 1.12, edge_z), Color("586b6b"), false)


func _build_lot_markings() -> void:
	var white := Color("ece9dc")
	var yellow := Color("e8bd4a")
	# Long, unobstructed launch lane before the central slalom.
	for side in [-1.0, 1.0]:
		_surface(Vector3(0.16, 0.018, 75), Vector3(side * 8.0, 0.015, -68), white, false)
	for z in range(-100, -30, 12):
		_surface(Vector3(0.16, 0.018, 5.0), Vector3(0, 0.015, float(z)), white, false)
	_surface(Vector3(16.0, 0.018, 0.25), Vector3(0, 0.015, -26), yellow, false)
	# A marked maneuver corridor and four generous parking bays.
	for side in [-1.0, 1.0]:
		_surface(Vector3(0.16, 0.018, 84), Vector3(side * 13.0, 0.015, 29), yellow, false)
	for x in [22.0, 34.0, 46.0, 58.0, 70.0]:
		_surface(Vector3(0.15, 0.018, 43), Vector3(x, 0.015, 37), white, false)
	for z in [15.5, 58.5]:
		_surface(Vector3(48, 0.018, 0.15), Vector3(46, 0.015, z), white, false)
	_surface(Vector3(20, 0.018, 0.22), Vector3(0, 0.015, 88), yellow, false)


func _build_lot_cones() -> void:
	for index in 9:
		_spawn_cone(Vector3(-4.2 if index % 2 == 0 else 4.2, 0.30, -12.0 + float(index) * 10.0), index)
	for index in 4:
		_spawn_cone(Vector3(17.0, 0.30, 10.0 + float(index) * 14.0), 9 + index)
	for index in 4:
		_spawn_cone(Vector3(-16.0 + float(index) * 10.0, 0.30, 94.0), 13 + index)


func _spawn_cone(at: Vector3, index: int) -> void:
	var cone := TRAFFIC_CONE_SCENE.instantiate()
	cone.name = "TrainingCone%02d" % index
	cone.position = at
	add_child(cone)


func _build_roundabout(center: Vector3) -> void:
	_road_ring(center, 10.0, 22.0, Color("404a50"))
	_road_ring(center, 21.5, 21.62, Color("e9d8a8"))
	_road_ring(center, 10.35, 10.47, Color("e9d8a8"))
	var island := CylinderMesh.new()
	island.top_radius = 10.0
	island.bottom_radius = 10.0
	island.height = 0.22
	island.radial_segments = 64
	var island_visual := MeshInstance3D.new()
	island_visual.mesh = island
	island_visual.material_override = _road_material(Color("68865d"))
	island_visual.position = center + Vector3(0, 0.10, 0)
	add_child(island_visual)
	var island_body := StaticBody3D.new()
	island_body.position = center + Vector3(0, 0.10, 0)
	var island_shape := CylinderShape3D.new()
	island_shape.radius = 9.9
	island_shape.height = 0.22
	var island_collision := CollisionShape3D.new()
	island_collision.shape = island_shape
	island_body.add_child(island_collision)
	add_child(island_body)
	var palm := PALM_SCENE.instantiate()
	palm.position = center + Vector3(0, 0.22, 0)
	add_child(palm)
	for angle in [0.0, 2.1, 4.2]:
		var flower := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.8
		sphere.height = 1.0
		flower.mesh = sphere
		flower.material_override = _road_material(Color("cc9860"))
		flower.position = center + Vector3(cos(angle) * 5.5, 0.58, sin(angle) * 5.5)
		add_child(flower)


func _build_roundabout_sign() -> void:
	_surface(Vector3(0.10, 2.6, 0.10), Vector3(-22.0, 1.30, 24), Color("35434a"), false)
	_surface(Vector3(2.90, 0.95, 0.10), Vector3(-22.0, 2.75, 24), Color("294d69"), false)
	var lettering := Label3D.new()
	lettering.text = "PRACTICE LOOP\nROUNDABOUT"
	lettering.font_size = 42
	lettering.pixel_size = 0.0022
	lettering.modulate = Color("f9e6a5")
	lettering.position = Vector3(-22.0, 2.69, 23.92)
	lettering.rotation.y = PI
	add_child(lettering)


func _road_ring(center: Vector3, inner: float, outer: float, color: Color) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in 64:
		var a := float(index) * TAU / 64.0
		var b := float(index + 1) * TAU / 64.0
		var y := 0.012 if outer > 20.0 else 0.016
		var inner_a := center + Vector3(cos(a) * inner, y, sin(a) * inner)
		var outer_a := center + Vector3(cos(a) * outer, y, sin(a) * outer)
		var inner_b := center + Vector3(cos(b) * inner, y, sin(b) * inner)
		var outer_b := center + Vector3(cos(b) * outer, y, sin(b) * outer)
		for vertex in [inner_a, outer_a, inner_b, outer_a, outer_b, inner_b]:
			tool.add_vertex(vertex)
	tool.generate_normals()
	var visual := MeshInstance3D.new()
	visual.mesh = tool.commit()
	var material := _road_material(color)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	visual.material_override = material
	add_child(visual)


func _road_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	return material


func _surface(size: Vector3, at: Vector3, color: Color, collider: bool, surface_name: String = "") -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = material
	visual.position = at
	if surface_name != "":
		visual.name = surface_name + "Visual"
	add_child(visual)
	if collider:
		var body := StaticBody3D.new()
		if surface_name != "":
			body.name = surface_name
		body.position = at
		var shape := BoxShape3D.new()
		shape.size = size
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
		add_child(body)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 24)
	layer.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)
	_build_guidance(layer)
	_build_driver_check(layout)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(spacer)
	_hud = VBoxContainer.new()
	_hud.add_theme_constant_override("separation", 5)
	layout.add_child(_hud)
	for ids in [["engine", "rpm", "seatbelt", "clutch"], ["gear", "speed", "brake", "handbrake"]]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 24)
		_hud.add_child(row)
		for id in ids:
			var metric := _label(19, Color("f7f5e9"))
			metric.autowrap_mode = TextServer.AUTOWRAP_OFF
			metric.visible = false
			_metrics[id] = metric
			row.add_child(metric)
	_controls_hint = _label(15, Color("f2e5c7"))
	layout.add_child(_controls_hint)
	_build_error_toast(layer)
	_pause_center = CenterContainer.new()
	_pause_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pause_center.visible = false
	layer.add_child(_pause_center)
	_pause_panel = PanelContainer.new()
	_pause_panel.custom_minimum_size = Vector2(340, 180)
	_pause_center.add_child(_pause_panel)
	var buttons := VBoxContainer.new()
	buttons.name = "Buttons"
	_pause_panel.add_child(buttons)
	var title := _label(25, Color.WHITE)
	title.text = "Paused"
	buttons.add_child(title)
	var resume := Button.new()
	resume.name = "Resume"
	resume.text = "Resume"
	resume.pressed.connect(func(): _set_paused(false))
	buttons.add_child(resume)
	var restart := Button.new()
	restart.text = "Restart lesson"
	restart.pressed.connect(func(): _pause_center.visible = false; _restart())
	buttons.add_child(restart)
	var exit_button := Button.new()
	exit_button.text = "Exit to courses"
	exit_button.pressed.connect(_exit)
	buttons.add_child(exit_button)


func _build_guidance(layer: CanvasLayer) -> void:
	_guidance_panel = PanelContainer.new()
	_guidance_panel.name = "BeginnerGuide"
	_guidance_panel.anchor_left = 0.5
	_guidance_panel.anchor_right = 0.5
	_guidance_panel.offset_left = -280
	_guidance_panel.offset_right = 280
	_guidance_panel.offset_top = 12
	_guidance_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.10, 0.13, 0.96)
	style.border_width_top = 3
	style.border_color = Color("f5c568")
	style.set_corner_radius_all(9)
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	_guidance_panel.add_theme_stylebox_override("panel", style)
	layer.add_child(_guidance_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	_guidance_panel.add_child(row)
	var copy := VBoxContainer.new()
	copy.custom_minimum_size.x = 350
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 6)
	row.add_child(copy)
	_prompt = _label(24, Color("f5d479"))
	copy.add_child(_prompt)
	_why = _label(16, Color("c8d8dc"))
	copy.add_child(_why)
	_action_progress = _label(12, Color("97b2ba"))
	copy.add_child(_action_progress)
	_action = _label(21, Color("fff8e7"))
	copy.add_child(_action)
	var visual := VBoxContainer.new()
	visual.custom_minimum_size.x = 160
	row.add_child(visual)
	_control_caption = _label(12, Color("f5d479"))
	_control_caption.custom_minimum_size.y = 30
	visual.add_child(_control_caption)
	var image := TextureRect.new()
	image.custom_minimum_size = Vector2(160, 112)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	visual.add_child(image)
	_control_viewport = SubViewport.new()
	_control_viewport.size = Vector2i(320, 224)
	_control_viewport.world_3d = get_viewport().world_3d
	_control_viewport.transparent_bg = true
	add_child(_control_viewport)
	_control_camera = Camera3D.new()
	_control_camera.cull_mask = sedan.LESSON_CONTROL_LAYER
	_control_camera.fov = 52
	_control_camera.near = 0.025
	_control_viewport.add_child(_control_camera)
	_control_camera.current = true
	image.texture = _control_viewport.get_texture()


func _build_driver_check(layout: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	layout.add_child(row)
	var panel := PanelContainer.new()
	panel.name = "DriverCheck"
	panel.custom_minimum_size.x = 280.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.13, 0.15, 0.88)
	style.border_width_left = 4
	style.border_color = Color("d6a23f")
	style.set_corner_radius_all(7)
	panel.add_theme_stylebox_override("panel", style)
	row.add_child(panel)
	var margin := MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 11)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	margin.add_child(content)
	var heading := _label(15, Color("f5c568"))
	heading.text = "DRIVER CHECK"
	content.add_child(heading)
	_seatbelt_status = _label(15, Color("f5c568"))
	content.add_child(_seatbelt_status)
	_seatbelt_button = Button.new()
	_seatbelt_button.name = "SeatbeltButton"
	_seatbelt_button.focus_mode = Control.FOCUS_NONE
	_seatbelt_button.tooltip_text = "Press B while driving, or click here while paused."
	_seatbelt_button.pressed.connect(func(): sedan.toggle_seatbelt(); _update_ui())
	content.add_child(_seatbelt_button)
	_handbrake_status = _label(15, Color("a4dfbb"))
	content.add_child(_handbrake_status)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)


func _build_error_toast(layer: CanvasLayer) -> void:
	_toast_panel = PanelContainer.new()
	_toast_panel.name = "ErrorToast"
	_toast_panel.anchor_left = 1.0
	_toast_panel.anchor_right = 1.0
	_toast_panel.offset_left = -390.0
	_toast_panel.offset_right = -24.0
	_toast_panel.offset_top = 236.0
	_toast_panel.offset_bottom = 334.0
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_panel.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color("18232b")
	style.border_width_left = 5
	style.border_color = Color("f2a93b")
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 8
	_toast_panel.add_theme_stylebox_override("panel", style)
	layer.add_child(_toast_panel)
	var padding := MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]:
		padding.add_theme_constant_override("margin_" + edge, 14)
	_toast_panel.add_child(padding)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	padding.add_child(content)
	_toast_title = _label(16, Color("f2b64e"))
	content.add_child(_toast_title)
	_toast_detail = _label(16, Color("f8f4e9"))
	content.add_child(_toast_detail)


func _label(size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("182321"))
	label.add_theme_constant_override("outline_size", 3)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label
