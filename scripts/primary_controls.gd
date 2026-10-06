extends Node3D
## A repeatable manual-driving exercise in a small explorable street district.

signal attempt_finished(result: Dictionary)
signal exit_requested

const SEDAN_SCENE = preload("res://scenes/vehicles/sedan.tscn")
const SHOPFRONT_SCENE = preload("res://scenes/props/shopfront.tscn")
const STREETLAMP_SCENE = preload("res://scenes/props/streetlamp.tscn")
const MARKET_STALL_SCENE = preload("res://scenes/props/market_stall.tscn")
const PALM_SCENE = preload("res://scenes/props/palm.tscn")
const JEEPNEY_SCENE = preload("res://scenes/props/jeepney.tscn")
const TRICYCLE_SCENE = preload("res://scenes/props/tricycle.tscn")
const STEP_TEXT = [
	"Hold C to depress the clutch, then press E to select first gear.",
	"Release C, hold W, and travel forward past 8 km/h.",
	"Depress C and press E to shift into second gear.",
	"Steer with A/D while moving to change your position in the yard.",
	"Brake with S until the sedan comes to a full stop.",
	"Hold Space to apply the handbrake while stopped.",
	"Release Space, hold C, press Q three times for reverse, then back up 3 m.",
]

var sedan
var _hud: Label
var _prompt: Label
var _feedback: Label
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


func _ready() -> void:
	_build_yard()
	sedan = SEDAN_SCENE.instantiate()
	sedan.position = Vector3(-2.7, 0.65, -42)
	add_child(sedan)
	sedan.shift_rejected.connect(_on_shift_rejected)
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
	_last_notice = ""
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
			if sedan.gearbox.gear == 1:
				_advance("First gear selected with the clutch depressed.")
		1:
			if speed > 2.22 and sedan.global_position.z > _start_z + 4.0 and sedan.controls.clutch < 0.2:
				_advance("You moved forward under engine power.")
		2:
			if sedan.gearbox.gear == 2:
				_steer_x = sedan.global_position.x
				_advance("Second gear selected with the clutch depressed.")
		3:
			if speed > 1.0 and absf(sedan.global_position.x - _steer_x) > 1.8:
				_advance("You changed position while moving.")
		4:
			if sedan.controls.brake > 0.5 and speed < 0.35:
				_advance("You brought the sedan to a full stop with the brake.")
		5:
			if sedan.controls.handbrake and speed < 0.35:
				_reverse_z = sedan.global_position.z
				_advance("Handbrake applied while stopped.")
		6:
			if sedan.gearbox.gear == -1 and sedan.global_position.z < _reverse_z - 3.0:
				_advance("You reversed at least three metres.")
	_update_ui()


func _input(event: InputEvent) -> void:
	if not _started:
		return
	if event.is_action_pressed("ui_cancel"):
		_set_paused(not _paused)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("drive_reset") and not _paused:
		_restart()
		get_viewport().set_input_as_handled()


func _advance(message: String) -> void:
	_events.append({"type": "step_completed", "step": _step, "elapsed_seconds": snappedf(_elapsed, 0.01), "detail": message})
	_last_notice = message
	_step += 1
	if _step == STEP_TEXT.size():
		_finish()


func _on_shift_rejected() -> void:
	if not _started or _paused:
		return
	_events.append({"type": "shift_rejected", "elapsed_seconds": snappedf(_elapsed, 0.01), "detail": "Gear change attempted without depressing the clutch."})
	_last_notice = "Depress the clutch before shifting."


func _finish() -> void:
	_started = false
	sedan.driving_enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var mistakes := 0
	for event in _events:
		if event["type"] == "shift_rejected":
			mistakes += 1
	var result := _context.duplicate(true)
	result["scenario_version"] = 1
	result["assessment_version"] = 1
	result["unix_time"] = Time.get_unix_time_from_system()
	result["completed"] = true
	result["elapsed_seconds"] = snappedf(_elapsed, 0.1)
	result["shift_errors"] = mistakes
	result["input_profile_id"] = sedan.controls.last_device
	result["events"] = _events.duplicate(true)
	result["feedback"] = "Completed all seven control steps." + (" Practice clutch timing: %d shifts were rejected." % mistakes if mistakes else " No gear changes were rejected.")
	attempt_finished.emit(result)


func _restart() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var old: Node3D = sedan
	remove_child(old)
	old.queue_free()
	sedan = SEDAN_SCENE.instantiate()
	sedan.position = Vector3(-2.7, 0.65, -42)
	add_child(sedan)
	sedan.shift_rejected.connect(_on_shift_rejected)
	start_attempt(_context)


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
	_hud.text = "SPEED  %02d km/h     RPM  %04d     GEAR  %s\nCLUTCH  %d%%     HANDBRAKE  %s" % [roundi(sedan.speed_mps() * 3.6), roundi(sedan.gearbox.engine_rpm), gear_name, roundi(sedan.controls.clutch * 100), "ON" if sedan.controls.handbrake else "OFF"]
	_prompt.text = "PRIMARY CONTROLS   •   %d / %d\n%s" % [mini(_step + 1, STEP_TEXT.size()), STEP_TEXT.size(), STEP_TEXT[mini(_step, STEP_TEXT.size() - 1)]]
	_feedback.text = _last_notice


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
	_surface(Vector3(300, 0.10, 450), Vector3(-50, -0.12, 95), Color("6b8a63"), true)
	_surface(Vector3(18.0, 0.06, 430), Vector3(0, -0.04, 95), Color("465157"), false)
	# The cross street gives the player two real turns; its western branch
	# connects to the circulating road around a raised central island.
	_surface(Vector3(230, 0.06, 18.0), Vector3(-45, -0.04, 70), Color("465157"), false)
	for side in [-1.0, 1.0]:
		_surface(Vector3(6.0, 0.16, 179), Vector3(side * 12.5, 0.045, -30.5), Color("b8afa0"), false)
		_surface(Vector3(6.0, 0.16, 229), Vector3(side * 12.5, 0.045, 195.5), Color("b8afa0"), false)
		for z in range(-85, 306, 3):
			if z < 59 or z > 81:
				_surface(Vector3(0.13, 0.025, 2.9), Vector3(side * 8.60, 0.004, float(z)), Color("eee4c9"), false)
			if z < 59 or z > 81:
				_surface(Vector3(0.44, 0.19, 2.84), Vector3(side * 9.22, 0.075, float(z)), Color("ebbd45") if z % 2 == 0 else Color("555b58"), false)
		for index in range(18):
			if index in [8, 9, 10]:
				continue
			var shop = SHOPFRONT_SCENE.instantiate()
			shop.palette_index = (index + (0 if side < 0 else 2)) % 4
			shop.position = Vector3(side * 20.0, 0, -49.0 + float(index) * 14.0)
			shop.rotation.y = -side * PI / 2.0
			add_child(shop)
		for z in [-38.0, -10.0, 18.0, 46.0]:
			var lamp := STREETLAMP_SCENE.instantiate()
			lamp.position = Vector3(side * 10.1, 0, z)
			lamp.rotation.y = -side * PI / 2.0
			add_child(lamp)
		for z in [-44.0, -16.0, 12.0, 40.0]:
			var tree := PALM_SCENE.instantiate()
			tree.position = Vector3(side * 14.9, 0, z)
			add_child(tree)
		for z in [-24.0, 31.0]:
			var stall := MARKET_STALL_SCENE.instantiate()
			stall.position = Vector3(side * 12.8, 0, z)
			stall.rotation.y = -side * PI / 2.0
			add_child(stall)
	for z in range(-83, 307, 8):
		if z < 59 or z > 81:
			_surface(Vector3(0.12, 0.018, 3.7), Vector3(0, 0.009, float(z)), Color("e8d7a5"), false)
	for x in range(-151, 70, 8):
		if abs(x) > 13 and abs(x + 85) > 23:
			_surface(Vector3(3.7, 0.018, 0.12), Vector3(float(x), 0.009, 70), Color("e8d7a5"), false)
	_build_roundabout(Vector3(-85, 0, 70))
	_build_roundabout_sign()
	var parked := JEEPNEY_SCENE.instantiate()
	parked.position = Vector3(11.4, 0, 9.0)
	parked.rotation.y = 0.08
	add_child(parked)
	var tricycle := TRICYCLE_SCENE.instantiate()
	tricycle.position = Vector3(-11.4, 0, 28.0)
	tricycle.rotation.y = PI
	add_child(tricycle)


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
	_surface(Vector3(0.10, 2.6, 0.10), Vector3(-8.9, 1.30, 58), Color("35434a"), false)
	_surface(Vector3(2.90, 0.95, 0.10), Vector3(-8.9, 2.75, 58), Color("294d69"), false)
	var lettering := Label3D.new()
	lettering.text = "ROUNDABOUT\nRIGHT TURN  20 m"
	lettering.font_size = 42
	lettering.pixel_size = 0.0022
	lettering.modulate = Color("f9e6a5")
	lettering.position = Vector3(-8.9, 2.69, 57.92)
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


func _surface(size: Vector3, at: Vector3, color: Color, collider: bool) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = material
	visual.position = at
	add_child(visual)
	if collider:
		var body := StaticBody3D.new()
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
	_prompt = _label(24, Color("f7f5e9"))
	layout.add_child(_prompt)
	_feedback = _label(17, Color("a4dfbb"))
	layout.add_child(_feedback)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(spacer)
	_hud = _label(22, Color("f7f5e9"))
	layout.add_child(_hud)
	var hint := _label(15, Color("f2e5c7"))
	hint.text = "W throttle  S brake  A/D steer  C clutch  E/Q gears  Space handbrake  R restart  Esc pause  Mouse look"
	layout.add_child(hint)
	_pause_center = CenterContainer.new()
	_pause_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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


func _label(size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("182321"))
	label.add_theme_constant_override("outline_size", 3)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label
