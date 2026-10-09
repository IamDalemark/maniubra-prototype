extends "res://scripts/primary_controls.gd"
## One perpendicular backing lesson; shared beginner UI and actual sedan physics.

const BAY := Rect2(-14.0, -3.0, 9.0, 6.0) # world X/Z; open at X = -5
const BAY_HEADING := PI / 2.0
# Body, bumpers and external mirrors must fit, not just the vehicle origin.
const CAR_HALF_WIDTH := 1.40
const CAR_HALF_LENGTH := 2.08
const PARKING_STEPS = [
	{"id": "start_engine", "goal": "Start the engine", "why": "The engine supplies power for backing into the yellow bay."},
	{"id": "select_reverse", "goal": "Get ready to back up", "why": "Stop and hold the clutch down before selecting reverse."},
	{"id": "turn_into_bay", "goal": "Turn toward the yellow bay", "why": "In reverse, steering right moves the rear toward the bay on your right."},
	{"id": "straighten", "goal": "Straighten the car", "why": "Straight wheels help you back between the yellow lines."},
	{"id": "stop_in_bay", "goal": "Stop fully inside the bay", "why": "The whole car needs clearance. The clutch prevents a low-speed stall."},
	{"id": "secure", "goal": "Secure the parked car", "why": "Neutral removes drive. The handbrake holds the stopped car."},
]
const PARKING_METRICS := {"engine": 0, "rpm": 0, "seatbelt": 0, "clutch": 1, "gear": 1, "speed": 2, "brake": 1, "handbrake": 5}

var _reverse_distance := 0.0
var _last_position := Vector3.ZERO
var _secured_seconds := 0.0
var _speed_notice_active := false
var _contact_cooldowns: Dictionary = {}
var _bay_view: Control
var _cones: Array[Node3D] = []
var _cone_starts: Array[Transform3D] = []

func _lesson_steps() -> Array:
	return PARKING_STEPS

func _metric_steps() -> Dictionary:
	return PARKING_METRICS

func _lesson_heading() -> String:
	return "BACKING PARKING"

func _spawn_position() -> Vector3:
	return Vector3(0, 0.02, 9.0)

func _is_recovering() -> bool:
	return _step > 0 and _step < 5 and not sedan.gearbox.engine_running

func start_attempt(context: Dictionary) -> void:
	_reverse_distance = 0.0
	_secured_seconds = 0.0
	_speed_notice_active = false
	_contact_cooldowns.clear()
	super.start_attempt(context)
	_last_position = sedan.global_position
	for index in _cones.size():
		_cones[index].global_transform = _cone_starts[index]
		_cones[index].linear_velocity = Vector3.ZERO
		_cones[index].angular_velocity = Vector3.ZERO
		_cones[index].sleeping = false

func _connect_sedan_signals() -> void:
	super._connect_sedan_signals()
	sedan.contact_monitor = true
	sedan.max_contacts_reported = 8
	sedan.body_entered.connect(_on_parking_contact)

func _physics_process(delta: float) -> void:
	if not _started or _paused:
		return
	_elapsed += delta
	var displacement: Vector3 = sedan.global_position - _last_position
	_last_position = sedan.global_position
	if sedan.gearbox.engine_running and sedan.gearbox.gear == -1 and displacement.dot(sedan.global_basis.z) < 0.0:
		_reverse_distance += Vector2(displacement.x, displacement.z).length()
	var speed: float = sedan.speed_mps()
	if speed > 10.0 / 3.6 and not _speed_notice_active:
		_speed_notice_active = true
		_parking_notice("parking_speed", "SLOW DOWN", "Back at walking pace. Release the accelerator, hold the clutch and brake gently.")
	elif speed < 6.0 / 3.6:
		_speed_notice_active = false
	match _step:
		0:
			if sedan.gearbox.engine_running:
				_advance("Engine started for backing practice.")
		1:
			if sedan.gearbox.gear == -1 and speed < 0.12 and sedan.controls.clutch > 0.65:
				_advance("Reverse selected while stopped with the clutch down.")
		2:
			if _reverse_distance >= 3.0 and absf(_heading_error()) < deg_to_rad(20.0):
				_advance("Backed toward the bay and turned the car toward its opening.")
		3:
			if absf(_heading_error()) < deg_to_rad(8.0) and absf(sedan.controls.steering) < 0.15:
				_advance("Aligned with the bay and straightened the steering wheel.")
		4:
			if _parked_pose() and speed < 0.12 and sedan.controls.brake > 0.5 and sedan.controls.clutch > 0.65:
				_advance("Stopped the whole car inside the bay, facing out, with the brake and clutch.")
		5:
			if _parked_pose() and speed < 0.12 and sedan.gearbox.gear == 0 and sedan.controls.handbrake and sedan.controls.brake < 0.1:
				_secured_seconds += delta
			else:
				_secured_seconds = 0.0
			if _secured_seconds >= 2.0:
				_advance("Neutral selected and handbrake held for two continuous seconds inside the bay.")
	_update_ui()
	_bay_view.queue_redraw()

func _heading_error() -> float:
	return wrapf(BAY_HEADING - atan2(sedan.global_basis.z.x, sedan.global_basis.z.z), -PI, PI)

func _whole_car_inside() -> bool:
	for x in [-CAR_HALF_WIDTH, CAR_HALF_WIDTH]:
		for z in [-CAR_HALF_LENGTH, CAR_HALF_LENGTH]:
			var corner: Vector3 = sedan.to_global(Vector3(x, 0, z))
			if not BAY.has_point(Vector2(corner.x, corner.z)):
				return false
	return true

func _parked_pose() -> bool:
	return _whole_car_inside() and absf(_heading_error()) < deg_to_rad(8.0) and sedan.global_basis.y.dot(Vector3.UP) > 0.95

func _teaching_action() -> Dictionary:
	if _step == 0 or _is_recovering():
		return super._teaching_action()
	if _step == 1 or (_step >= 2 and _step < 5 and sedan.gearbox.gear != -1):
		if sedan.speed_mps() >= 0.12:
			return _instruction("Hold {drive_clutch} and {drive_brake} until SPEED is 0.", "brake", 1, 3)
		if sedan.controls.clutch < 0.65:
			return _instruction("Hold {drive_clutch} all the way down.", "clutch", 2, 3)
		return _instruction("Keep the clutch down. Press {drive_gear_down} once at a time until GEAR is R.", "gear", 3, 3)
	if _step < 5 and sedan.controls.handbrake:
		return _instruction("Release {drive_handbrake} before backing.", "handbrake", 1, 1)
	if _step >= 2 and _step < 5 and (sedan.global_position.x < -11.9 or sedan.global_position.z < -5.0):
		if sedan.speed_mps() >= 0.12:
			return _instruction("You passed the bay. Hold {drive_clutch} and {drive_brake} to stop.", "brake", 1, 2)
		return _instruction("Press {drive_reset} for a fresh approach. Turn sooner and use less speed.", "steering", 2, 2)
	if _step == 2 or _step == 3:
		if _step == 3 and absf(_heading_error()) < deg_to_rad(8.0):
			return _instruction("Release {drive_left} / {drive_right} to straighten the wheel.", "steering", 4, 4)
		if sedan.controls.brake > 0.5 or (sedan.speed_mps() < 0.15 and sedan.controls.brake > 0.1):
			return _instruction("Check mirrors and behind you. Release {drive_brake} when clear.", "brake", 1, 4)
		if sedan.controls.throttle < 0.25 and sedan.speed_mps() < 1.0:
			return _instruction("Hold {drive_throttle} gently to add a little power.", "accelerator", 2, 4)
		if sedan.controls.clutch > 0.2:
			return _instruction("Keep the accelerator held. Release {drive_clutch} to back up.", "clutch", 3, 4)
		var turn_action := "drive_right" if _heading_error() > 0.0 else "drive_left"
		return _instruction("Back slowly. Hold {" + turn_action + "} until the car points straight out of the bay.", "steering", 4, 4)
	if _step == 4:
		if absf(_heading_error()) >= deg_to_rad(8.0):
			var turn_action := "drive_right" if _heading_error() > 0.0 else "drive_left"
			return _instruction("Back slowly with {" + turn_action + "} to face straight out of the bay.", "steering", 1, 4)
		if not _whole_car_inside():
			if sedan.controls.brake > 0.1:
				return _instruction("Release {drive_brake} when clear. The whole car must enter the yellow bay.", "brake", 1, 4)
			if sedan.controls.clutch > 0.2:
				if sedan.controls.throttle < 0.25:
					return _instruction("Hold {drive_throttle} gently to add a little power.", "accelerator", 1, 4)
				return _instruction("Keep the accelerator held. Release {drive_clutch} to back into the bay.", "clutch", 1, 4)
			return _instruction("Back at walking pace between the yellow lines. Stop near the centre of the bay.", "accelerator", 1, 4)
		if sedan.controls.throttle > 0.1:
			return _instruction("Release {drive_throttle}. The whole car is inside the bay.", "accelerator", 2, 4)
		if sedan.controls.clutch < 0.65:
			return _instruction("Hold {drive_clutch} all the way down to prevent a stall.", "clutch", 3, 4)
		return _instruction("Keep the clutch down. Hold {drive_brake} until SPEED is 0.", "brake", 4, 4)
	if _step == 5:
		if not _parked_pose():
			return _instruction("The car left its position. Restart with {drive_reset} to practise again.", "steering", 1, 4)
		if sedan.gearbox.gear == 0 and sedan.controls.handbrake and sedan.controls.brake > 0.1:
			return _instruction("Keep {drive_handbrake} held. Release {drive_brake} to let the handbrake hold the car.", "brake", 4, 4)
		if sedan.speed_mps() >= 0.12:
			return _instruction("Hold {drive_clutch} and {drive_brake} to stay stopped.", "brake", 1, 4)
		if sedan.gearbox.gear != 0:
			if sedan.controls.clutch < 0.65:
				return _instruction("Keep the brake held. Hold {drive_clutch} all the way down.", "clutch", 1, 4)
			var shift_action := "drive_gear_up" if sedan.gearbox.gear < 0 else "drive_gear_down"
			return _instruction("Keep the clutch down. Press {" + shift_action + "} once at a time until GEAR is N.", "gear", 2, 4)
		if not sedan.controls.handbrake:
			return _instruction("Keep the brake held. Hold {drive_handbrake} to apply the handbrake.", "handbrake", 3, 4)
		return _instruction("Stay stopped. Hold {drive_handbrake} for two seconds: %.1f / 2.0." % _secured_seconds, "handbrake", 4, 4)

	return _instruction("Backing parking complete.", "", 1, 1)

func _parking_notice(type: String, title: String, detail: String) -> void:
	_events.append({"type": type, "elapsed_seconds": snappedf(_elapsed, 0.01), "detail": detail})
	_show_error_toast(title, detail)

func _on_parking_contact(body: Node) -> void:
	if not _started or _paused or not body.name.begins_with("TrainingCone"):
		return
	var key := String(body.name)
	if _elapsed - float(_contact_cooldowns.get(key, -10.0)) < 3.0:
		return
	_contact_cooldowns[key] = _elapsed
	_parking_notice("parking_contact", "CONE CONTACT", "You touched a cone. Stop, check your clearance and adjust slowly. Restart to reset the cones.")

func _finish() -> void:
	_started = false
	sedan.driving_enabled = false
	sedan.set_lesson_focus([])
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var result := _context.duplicate(true)
	result.merge({"scenario_version": 1, "assessment_version": 1, "step_count": PARKING_STEPS.size(), "unix_time": Time.get_unix_time_from_system(), "completed": true, "elapsed_seconds": snappedf(_elapsed, 0.1), "input_profile_id": sedan.controls.last_device, "events": _events.duplicate(true)}, true)
	result["shift_errors"] = _events.filter(func(event): return event.type == "shift_rejected").size()
	result["stall_count"] = _events.filter(func(event): return event.type == "engine_stalled").size()
	result["cone_contacts"] = _events.filter(func(event): return event.type == "parking_contact").size()
	result["speed_reminders"] = _events.filter(func(event): return event.type == "parking_speed").size()
	result["feedback"] = "Backed into the bay, straightened, stopped fully inside and secured the car. %d cone contacts; %d walking-pace reminders. Practise again with smaller steering corrections." % [result.cone_contacts, result.speed_reminders]
	attempt_finished.emit(result)

func _build_lot_markings() -> void:
	var gold := Color("f2c847")
	# Wide perpendicular bay, with space to practise the first reverse turn.
	for z in [-3.0, 3.0]:
		_surface(Vector3(9, 0.018, 0.15), Vector3(-9.5, 0.016, z), gold, false)
	_surface(Vector3(0.15, 0.018, 6), Vector3(-14, 0.016, 0), gold, false)
	for z in [-2.4, -1.2, 0.0, 1.2, 2.4]:
		_surface(Vector3(0.13, 0.018, 0.6), Vector3(-5, 0.016, z), gold, false)
	_surface(Vector3(0.10, 0.018, 25), Vector3(3.8, 0.016, 3), Color("c9cec8"), false)
	_surface(Vector3(0.10, 0.018, 25), Vector3(-3, 0.016, 3), Color("c9cec8"), false)
	_surface(Vector3(0.12, 2.8, 0.12), Vector3(-15.5, 1.4, 0), Color("35434a"), false)
	_surface(Vector3(0.12, 1.0, 3.8), Vector3(-15.5, 2.8, 0), Color("294d69"), false)
	var sign := Label3D.new()
	sign.text = "P\nBACKING PRACTICE"
	sign.font_size = 48
	sign.pixel_size = 0.003
	sign.position = Vector3(-15.42, 2.8, 0)
	sign.rotation.y = PI / 2.0
	add_child(sign)

func _build_lot_cones() -> void:
	for at in [Vector3(-14.6, 0.30, -3.6), Vector3(-14.6, 0.30, 3.6), Vector3(-5, 0.30, -3.6), Vector3(-5, 0.30, 3.6)]:
		_spawn_cone(at, _cones.size())
		var cone: Node3D = get_node("TrainingCone%02d" % _cones.size())
		_cones.append(cone)
		_cone_starts.append(cone.transform)

func _build_ui() -> void:
	super._build_ui()
	_bay_view = load("res://scripts/parking_view.gd").new()
	_bay_view.lesson = self
	_bay_view.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_bay_view.position = Vector2(-324, -324)
	_bay_view.size = Vector2(300, 220)
	_bay_view.clip_contents = true
	_bay_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_guidance_panel.get_parent().add_child(_bay_view)
