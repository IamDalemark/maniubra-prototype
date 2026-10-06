extends Node3D
## One continuous drive. The named venue is optional and never ends play.

signal attempt_finished(result: Dictionary)
signal exit_requested

const DISTRICT = preload("res://scenes/world/iloilo_district.tscn")
const SEDAN = preload("res://scenes/vehicles/sedan.tscn")
const VENUE_NAME := "Molo Plaza"

var district
var sedan
var _started := false
var _paused := false
var _elapsed := 0.0
var _arrival_hold := 0.0
var _venue_reached := false
var _events: Array = []
var _context: Dictionary = {}
var _hud: Label
var _venue: Label
var _toast: PanelContainer
var _toast_label: Label
var _toast_remaining := 0.0
var _pause_center: CenterContainer
var _pause_buttons: VBoxContainer


func _ready() -> void:
	district = DISTRICT.instantiate()
	add_child(district)
	_spawn_sedan()
	_build_ui()
	_update_hud()


func start_attempt(context: Dictionary) -> void:
	_context = context.duplicate(true)
	_elapsed = 0.0
	_arrival_hold = 0.0
	_venue_reached = false
	_events.clear()
	_started = true
	_paused = false
	_toast.visible = false
	_toast_remaining = 0.0
	_venue.text = "OPTIONAL DESTINATION\n" + VENUE_NAME
	sedan.camera.fov = clampf(float(context.get("camera_fov", 75.0)), 60.0, 95.0)
	sedan.set_audio_level(float(context.get("audio_level", 0.8)))
	sedan.driving_enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	sedan.prepare_mouse_capture()
	_update_hud()


func _physics_process(delta: float) -> void:
	if not _started or _paused:
		return
	_elapsed += delta
	if not _venue_reached:
		if district.destination_contains_vehicle(sedan) and sedan.speed_mps() < 0.5 / 3.6:
			_arrival_hold += delta
			if _arrival_hold >= 2.0:
				_award_destination()
		else:
			_arrival_hold = 0.0
	_update_hud()


func _process(delta: float) -> void:
	if not _started or _paused or _toast_remaining <= 0.0:
		return
	_toast_remaining = maxf(_toast_remaining - delta, 0.0)
	if _toast_remaining == 0.0:
		_toast.visible = false


func _input(event: InputEvent) -> void:
	if not _started:
		return
	if event.is_action_pressed("ui_cancel"):
		_set_paused(not _paused)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("drive_reset") and not _paused:
		_restart()
		get_viewport().set_input_as_handled()


func _award_destination() -> void:
	_venue_reached = true
	_venue.text = "EXPLORE ILOILO"
	_events.append({"type": "destination_reached", "venue_id": "molo_plaza", "elapsed_seconds": snappedf(_elapsed, 0.01), "detail": "Reached Molo Plaza and stopped in the marked bay."})
	_toast_label.text = "DESTINATION REACHED\nMolo Explorer badge earned"
	_toast_remaining = 4.0
	_toast.visible = true


func _on_engine_state_changed(running: bool, stalled: bool) -> void:
	if not _started or _paused:
		return
	var detail := "Engine stalled." if stalled else ("Engine started." if running else "Engine switched off.")
	_events.append({"type": "engine_stalled" if stalled else ("engine_started" if running else "engine_stopped"), "elapsed_seconds": snappedf(_elapsed, 0.01), "detail": detail})


func _end_drive() -> void:
	_started = false
	sedan.driving_enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var result := _context.duplicate(true)
	result["scenario_version"] = 1
	result["assessment_version"] = 1
	result["unix_time"] = Time.get_unix_time_from_system()
	result["completed"] = true
	result["elapsed_seconds"] = snappedf(_elapsed, 0.1)
	result["destination_venue"] = VENUE_NAME
	result["destination_reached"] = _venue_reached
	result["badge_id"] = "molo_explorer" if _venue_reached else ""
	result["step_count"] = 0
	result["shift_errors"] = 0
	result["stall_count"] = _events.filter(func(event): return event.get("type") == "engine_stalled").size()
	result["input_profile_id"] = sedan.controls.last_device
	result["events"] = _events.duplicate(true)
	result["feedback"] = "Explored Iloilo-inspired streets." + (" Molo Explorer badge earned." if _venue_reached else " Molo Plaza remained an optional destination.")
	attempt_finished.emit(result)


func _exit() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	exit_requested.emit()


func _restart() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var old: Node3D = sedan
	remove_child(old)
	old.queue_free()
	_spawn_sedan()
	_pause_center.visible = false
	start_attempt(_context)


func _spawn_sedan() -> void:
	sedan = SEDAN.instantiate()
	sedan.position = district.START
	add_child(sedan)
	sedan.engine_state_changed.connect(_on_engine_state_changed)


func _set_paused(value: bool) -> void:
	_paused = value
	sedan.driving_enabled = not value
	_pause_center.visible = value
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_CAPTURED
	if value:
		_pause_buttons.get_node("Resume").grab_focus()
	else:
		sedan.prepare_mouse_capture()


func _update_hud() -> void:
	if sedan == null or _hud == null:
		return
	var gear_name := "R" if sedan.gearbox.gear == -1 else ("N" if sedan.gearbox.gear == 0 else str(sedan.gearbox.gear))
	var engine_status := "RUNNING" if sedan.gearbox.engine_running else ("STALLED" if sedan.gearbox.engine_stalled else "OFF")
	_hud.text = "SPEED  %02d km/h     RPM  %04d     GEAR  %s     ENGINE  %s\nCLUTCH  %d%%     HANDBRAKE  %s     SEATBELT  %s" % [roundi(sedan.speed_mps() * 3.6), roundi(sedan.gearbox.engine_rpm), gear_name, engine_status, roundi(sedan.controls.clutch * 100), "ON" if sedan.controls.handbrake else "OFF", "ON" if sedan.seatbelt_fastened else "OFF"]


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 24)
	layer.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)
	_venue = _label(22, Color("f5c548"))
	layout.add_child(_venue)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(spacer)
	_hud = _label(21, Color("f7f5e9"))
	layout.add_child(_hud)
	var controls_hint := _label(14, Color("f2e5c7"))
	controls_hint.text = "H engine  B seatbelt  W throttle  S brake  A/D steer  C clutch  E/Q gears  Space handbrake  R restart  Esc pause"
	layout.add_child(controls_hint)
	_toast = PanelContainer.new()
	_toast.anchor_left = 1.0
	_toast.anchor_right = 1.0
	_toast.offset_left = -354.0
	_toast.offset_right = -24.0
	_toast.offset_top = 24.0
	_toast.offset_bottom = 115.0
	_toast.visible = false
	var toast_style := StyleBoxFlat.new()
	toast_style.bg_color = Color("142629")
	toast_style.border_color = Color("f5c548")
	toast_style.border_width_left = 5
	_toast.add_theme_stylebox_override("panel", toast_style)
	layer.add_child(_toast)
	_toast_label = _label(18, Color("f5dc88"))
	_toast.add_child(_toast_label)
	_pause_center = CenterContainer.new()
	_pause_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_center.visible = false
	_pause_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_pause_center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(330, 190)
	_pause_center.add_child(panel)
	_pause_buttons = VBoxContainer.new()
	_pause_buttons.add_theme_constant_override("separation", 8)
	panel.add_child(_pause_buttons)
	var title := _label(25, Color.WHITE)
	title.text = "Open World paused"
	_pause_buttons.add_child(title)
	var resume := Button.new()
	resume.name = "Resume"
	resume.text = "Resume"
	resume.pressed.connect(func(): _set_paused(false))
	_pause_buttons.add_child(resume)
	var restart := Button.new()
	restart.text = "Restart drive"
	restart.pressed.connect(_restart)
	_pause_buttons.add_child(restart)
	var review := Button.new()
	review.text = "End drive and review"
	review.pressed.connect(_end_drive)
	_pause_buttons.add_child(review)
	var exit_button := Button.new()
	exit_button.text = "Exit without review"
	exit_button.pressed.connect(_exit)
	_pause_buttons.add_child(exit_button)


func _label(size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("182321"))
	label.add_theme_constant_override("outline_size", 3)
	return label
