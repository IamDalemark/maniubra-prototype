extends VehicleBody3D
## Original procedural sedan geometry, viewed from its left front seat.

signal shift_rejected
signal gear_changed(gear: int)
signal engine_state_changed(running: bool, stalled: bool)
signal ignition_rejected

const DrivingInput = preload("res://scripts/driving_input.gd")
const ManualTransmission = preload("res://scripts/manual_transmission.gd")

var controls = DrivingInput.new()
var gearbox = ManualTransmission.new()
var driving_enabled := true
var camera: Camera3D
var _rear_camera: Camera3D
var _side_cameras: Array[Camera3D] = []
var _steering_visual: MeshInstance3D
var _lever: MeshInstance3D
var _speed_needle: Node3D
var _rpm_needle: Node3D
var _gear_display: Label3D
var _left_hand: MeshInstance3D
var _right_hand: MeshInstance3D
var _left_arm: MeshInstance3D
var _right_arm: MeshInstance3D
var _gear_hand_timer := 0.0
var audio_level := 0.8
var _engine_audio: AudioStreamPlayer
var _road_audio: AudioStreamPlayer
var _look_yaw := 0.0
var _look_pitch := 0.0
var _ignore_mouse_until_msec := 0


func _ready() -> void:
	DrivingInput.install_actions()
	_build_vehicle()
	_build_cockpit()
	_build_mirror()
	_build_audio()


func _exit_tree() -> void:
	if _engine_audio != null:
		_engine_audio.stop()
	if _road_audio != null:
		_road_audio.stop()


func _process(_delta: float) -> void:
	# VehicleBody3D advances after physics callbacks. Follow its final transform
	# just before rendering so the cockpit and eye remain in the same frame.
	_update_camera()
	_rear_camera.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(0, 1.76, -0.92))
	for index in _side_cameras.size():
		var side: float = -1.0 if index == 0 else 1.0
		_side_cameras[index].global_transform = global_transform * Transform3D(Basis(Vector3.UP, -side * 0.72), Vector3(side * 1.0, 1.21, 0.69))


func _physics_process(delta: float) -> void:
	if not driving_enabled:
		engine_force = 0.0
		brake = 36.0
		return
	controls.update(delta)
	if Input.is_action_just_pressed("drive_ignition"):
		_toggle_ignition()
	if gearbox.update_stall(controls.throttle, controls.clutch, controls.brake, speed_mps(), delta):
		_sync_engine_audio()
		engine_state_changed.emit(false, true)
	var steering_limit := lerpf(0.42, 0.25, clampf(speed_mps() / 25.0, 0.0, 1.0))
	steering = controls.steering * steering_limit
	engine_force = gearbox.drive_force(controls.throttle, controls.clutch)
	brake = controls.brake * 34.0 + (40.0 if controls.handbrake else 0.0)
	gearbox.update_rpm(controls.throttle, controls.clutch, speed_mps() * 3.6, delta)
	_steering_visual.rotation.z = -controls.steering * 0.8
	_lever.rotation.x = float(gearbox.gear) * 0.06
	_update_hands(delta)
	_speed_needle.rotation.z = -2.2 + minf(speed_mps() * 3.6 / 120.0, 1.0) * 4.4
	_rpm_needle.rotation.z = -2.2 + clampf((gearbox.engine_rpm - gearbox.IDLE_RPM) / (gearbox.REDLINE_RPM - gearbox.IDLE_RPM), 0.0, 1.0) * 4.4
	_gear_display.text = "R" if gearbox.gear == -1 else ("N" if gearbox.gear == 0 else str(gearbox.gear))
	if _engine_audio != null:
		_engine_audio.pitch_scale = 0.72 + (gearbox.engine_rpm - gearbox.IDLE_RPM) / (gearbox.REDLINE_RPM - gearbox.IDLE_RPM) * 1.45
	_update_audio_mix()
	if Input.is_action_just_pressed("drive_gear_up"):
		_shift(1)
	if Input.is_action_just_pressed("drive_gear_down"):
		_shift(-1)
	var look_axis := Vector2(Input.get_axis("look_left", "look_right"), Input.get_axis("look_up", "look_down"))
	if look_axis.length() > 0.12:
		_look_yaw = clampf(_look_yaw - look_axis.x * delta * 1.4, -2.2, 2.2)
		_look_pitch = clampf(_look_pitch - look_axis.y * delta * 1.4, -0.55, 0.55)


func _input(event: InputEvent) -> void:
	if not driving_enabled:
		return
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		controls.last_device = "gamepad"
	elif event is InputEventKey:
		controls.last_device = "keyboard_mouse"
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if Time.get_ticks_msec() < _ignore_mouse_until_msec or event.relative.length() > 75.0:
			return
		_look_yaw = clampf(_look_yaw - event.relative.x * 0.0023, -2.2, 2.2)
		_look_pitch = clampf(_look_pitch - event.relative.y * 0.0023, -0.55, 0.55)
		_update_camera()


func speed_mps() -> float:
	return Vector2(linear_velocity.x, linear_velocity.z).length()


func prepare_mouse_capture() -> void:
	_look_yaw = 0.0
	_look_pitch = 0.0
	_ignore_mouse_until_msec = Time.get_ticks_msec() + 400
	_update_camera()


func set_audio_level(level: float) -> void:
	audio_level = clampf(level, 0.0, 1.0)
	_update_audio_mix()


func _toggle_ignition() -> void:
	if gearbox.toggle_ignition(controls.clutch):
		_sync_engine_audio()
		engine_state_changed.emit(gearbox.engine_running, false)
	else:
		ignition_rejected.emit()


func _sync_engine_audio() -> void:
	if _engine_audio == null:
		return
	if gearbox.engine_running and not _engine_audio.playing:
		_engine_audio.play()
	elif not gearbox.engine_running and _engine_audio.playing:
		_engine_audio.stop()


func _update_audio_mix() -> void:
	var muted := audio_level <= 0.0
	var level_db := 0.0 if muted else linear_to_db(audio_level)
	if _engine_audio != null:
		_engine_audio.volume_db = -80.0 if muted else -4.0 + level_db
	if _road_audio != null:
		_road_audio.volume_db = -80.0 if muted else -18.0 + minf(speed_mps() * 3.6, 55.0) * 0.22 + level_db


func _shift(direction: int) -> void:
	if gearbox.request_shift(direction, controls.clutch):
		_gear_hand_timer = 0.65
		gear_changed.emit(gearbox.gear)
	else:
		shift_rejected.emit()


func _build_vehicle() -> void:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.82, 0.74, 4.05)
	collision.shape = shape
	collision.position.y = 0.62
	add_child(collision)
	var roof_collision := CollisionShape3D.new()
	var roof_shape := BoxShape3D.new()
	roof_shape.size = Vector3(1.72, 0.16, 2.42)
	roof_collision.shape = roof_shape
	roof_collision.position = Vector3(0, 2.00, -0.42)
	add_child(roof_collision)
	for x in [-0.79, 0.79]:
		for z in [-1.37, 1.37]:
			var wheel := VehicleWheel3D.new()
			# Raise the suspension mounts relative to the chassis. This puts the
			# vehicle origin/center of gravity low without shrinking the wheels.
			wheel.position = Vector3(x, 0.50, z)
			wheel.wheel_radius = 0.36
			wheel.wheel_rest_length = 0.18
			wheel.suspension_stiffness = 58.0
			wheel.suspension_max_force = 10000.0
			wheel.suspension_travel = 0.10
			wheel.damping_compression = 1.35
			wheel.damping_relaxation = 1.55
			wheel.wheel_friction_slip = 1.0
			# Keep ordinary cornering planted while allowing an extreme turn to tip.
			wheel.wheel_roll_influence = 0.65
			wheel.use_as_steering = z > 0
			wheel.use_as_traction = z < 0
			add_child(wheel)
			var tire_mesh := CylinderMesh.new()
			tire_mesh.top_radius = 0.36
			tire_mesh.bottom_radius = 0.36
			tire_mesh.height = 0.19
			var tire := MeshInstance3D.new()
			tire.mesh = tire_mesh
			tire.material_override = _material(Color("202528"), 0.9)
			tire.rotation.z = PI / 2
			wheel.add_child(tire)

	_box(self, Vector3(1.8, 0.55, 3.95), Vector3(0, 0.57, 0), Color("467e80"), 0.28)
	_box(self, Vector3(1.75, 0.13, 1.22), Vector3(0, 0.86, 1.36), Color("377174"), 0.24)
	_box(self, Vector3(1.6, 0.12, 1.07), Vector3(0, 0.91, -1.36), Color("377174"), 0.24)
	# Full roof shell and darker headliner frame the driver's view without
	# covering the windshield or any of the three mirror surfaces.
	_box(self, Vector3(1.78, 0.13, 2.48), Vector3(0, 2.045, -0.42), Color("467e80"), 0.32)
	_box(self, Vector3(1.65, 0.045, 2.34), Vector3(0, 1.95, -0.42), Color("343b3d"), 0.92)
	for x in [-0.83, 0.83]:
		_box(self, Vector3(0.15, 0.15, 2.37), Vector3(x, 1.91, -0.42), Color("252d30"), 0.82)
	for x in [-0.83, 0.83]:
		_box(self, Vector3(0.12, 1.12, 0.11), Vector3(x, 1.36, 0.68), Color("343e40"), 0.4)
		_box(self, Vector3(0.10, 1.1, 0.11), Vector3(x, 1.36, -1.04), Color("343e40"), 0.4)
	_box(self, Vector3(1.76, 0.18, 0.15), Vector3(0, 1.91, 0.70), Color("222b2d"), 0.84)
	_box(self, Vector3(1.74, 0.14, 0.13), Vector3(0, 1.90, -1.56), Color("252d30"), 0.84)


func _build_cockpit() -> void:
	_box(self, Vector3(1.65, 0.22, 0.52), Vector3(0, 1.06, 0.53), Color("313b3e"), 0.85)
	_box(self, Vector3(1.68, 0.45, 0.13), Vector3(0, 0.91, 0.85), Color("293133"), 0.85)
	_box(self, Vector3(0.86, 0.055, 0.24), Vector3(0.40, 1.16, 0.70), Color("102027"), 0.27)
	_box(self, Vector3(0.87, 0.055, 0.15), Vector3(0.40, 1.42, 0.74), Color("222a2c"), 0.76)
	_speed_needle = _gauge(Vector3(0.23, 1.29, 0.59), Color("e4e9e4"))
	_rpm_needle = _gauge(Vector3(0.58, 1.29, 0.59), Color("e4e9e4"))
	_gear_display = Label3D.new()
	_gear_display.text = "N"
	_gear_display.position = Vector3(0.40, 1.25, 0.48)
	_gear_display.rotation.y = PI
	_gear_display.font_size = 40
	_gear_display.pixel_size = 0.00165
	_gear_display.modulate = Color("d8f6ed")
	add_child(_gear_display)
	_box(self, Vector3(0.58, 0.35, 0.06), Vector3(-0.40, 1.15, 0.55), Color("10191e"), 0.28)
	_box(self, Vector3(0.51, 0.28, 0.012), Vector3(-0.40, 1.15, 0.51), Color("183a55"), 0.19)
	for x in [-0.57, -0.40, -0.23]:
		_box(self, Vector3(0.13, 0.16, 0.014), Vector3(x, 1.16, 0.50), Color("355778"), 0.28)
	var screen_caption := Label3D.new()
	screen_caption.text = "AUDIO  MAP  INFO"
	screen_caption.position = Vector3(-0.40, 1.12, 0.48)
	screen_caption.rotation.y = PI
	screen_caption.font_size = 24
	screen_caption.pixel_size = 0.00145
	screen_caption.modulate = Color("d5e6ee")
	add_child(screen_caption)
	for x in [-0.77, 0.77]:
		_box(self, Vector3(0.20, 0.16, 0.045), Vector3(x, 1.17, 0.55), Color("141e23"), 0.52)
		for y in [1.12, 1.16, 1.20]:
			_box(self, Vector3(0.16, 0.012, 0.05), Vector3(x, y, 0.52), Color("6b797e"), 0.5)
	_box(self, Vector3(1.64, 0.025, 0.06), Vector3(0, 1.17, 0.77), Color("8e9694"), 0.34)
	_box(self, Vector3(0.14, 0.35, 1.72), Vector3(0.80, 0.94, -0.12), Color("30383a"), 0.83)
	_box(self, Vector3(0.18, 0.08, 1.74), Vector3(0.78, 1.20, -0.12), Color("686b66"), 0.66)
	_box(self, Vector3(0.24, 0.18, 0.75), Vector3(0.08, 0.88, -0.03), Color("30393c"), 0.84)
	for x in [-0.36, 0.43]:
		_box(self, Vector3(0.44, 0.12, 0.52), Vector3(x, 0.69, -0.68), Color("74665a"), 0.88)
		_box(self, Vector3(0.44, 0.72, 0.16), Vector3(x, 1.04, -0.99), Color("74665a"), 0.88)
	for x in [0.19, 0.41, 0.65]:
		_box(self, Vector3(0.10, 0.16, 0.03), Vector3(x, 0.52, 0.64), Color("9ca8a5"), 0.65)
	_steering_visual = _box(self, Vector3(0.42, 0.055, 0.08), Vector3(0.40, 1.07, 0.10), Color("171c1e"), 0.8)
	_box(_steering_visual, Vector3(0.065, 0.42, 0.08), Vector3.ZERO, Color("171c1e"), 0.8)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.20
	ring.outer_radius = 0.255
	var ring_visual := MeshInstance3D.new()
	ring_visual.mesh = ring
	ring_visual.rotation.x = PI / 2
	ring_visual.material_override = _material(Color("192225"), 0.75)
	_steering_visual.add_child(ring_visual)
	_box(_steering_visual, Vector3(0.13, 0.13, 0.10), Vector3.ZERO, Color("a2b7ae"), 0.4)
	_lever = _box(self, Vector3(0.055, 0.34, 0.055), Vector3(-0.09, 1.06, -0.02), Color("b6c2bd"), 0.35)
	_box(_lever, Vector3(0.13, 0.11, 0.13), Vector3(0, 0.18, 0), Color("182326"), 0.85)
	_build_hands()
	for x in [-0.44, 0.44]:
		_box(self, Vector3(0.51, 0.035, 0.28), Vector3(x, 1.88, 0.31), Color("454b4a"), 0.9)
	_box(self, Vector3(0.22, 0.035, 0.30), Vector3(0, 1.875, 0.34), Color("1d282b"), 0.85)
	camera = Camera3D.new()
	camera.position = Vector3(0.40, 1.45, -0.40)
	camera.rotation.y = PI
	camera.fov = 75.0
	camera.near = 0.045
	add_child(camera)
	camera.top_level = true
	camera.global_position = to_global(Vector3(0.40, 1.45, -0.40))
	camera.current = true
	for x in [-1.07, 1.07]:
		_box(self, Vector3(0.26, 0.12, 0.13), Vector3(x, 1.12, 0.68), Color("252c2e"), 0.5)


func _update_camera() -> void:
	var yaw_only := Basis(Vector3.UP, global_rotation.y)
	var eye := global_position + yaw_only * Vector3(0.40, 1.45, -0.40)
	# The eye must travel with the cockpit. Smoothing its world position makes
	# the seat move away from the camera as speed rises, causing visible shake.
	camera.global_position = eye
	camera.global_rotation = Vector3(_look_pitch, global_rotation.y + PI + _look_yaw, 0.0)


func _build_hands() -> void:
	var skin := Color("c88b62")
	for side in [1.0, -1.0]:
		var hand := _box(self, Vector3(0.075, 0.055, 0.055), Vector3.ZERO, skin, 0.88)
		for finger in [-0.024, 0.0, 0.024]:
			_box(hand, Vector3(0.016, 0.045, 0.031), Vector3(finger, 0.031, -0.010), skin, 0.88)
		var arm_mesh := CylinderMesh.new()
		arm_mesh.top_radius = 0.039
		arm_mesh.bottom_radius = 0.055
		arm_mesh.height = 1.0
		var arm := MeshInstance3D.new()
		arm.mesh = arm_mesh
		arm.material_override = _material(skin, 0.86)
		add_child(arm)
		if side > 0.0:
			_left_hand = hand
			_left_arm = arm
		else:
			_right_hand = hand
			_right_arm = arm
	_update_hands(0.0)


func _update_hands(delta: float) -> void:
	_gear_hand_timer = maxf(_gear_hand_timer - delta, 0.0)
	var left_grip := _steering_visual.position + _steering_visual.basis * Vector3(0.18, 0.15, -0.065)
	var right_grip := _steering_visual.position + _steering_visual.basis * Vector3(-0.18, 0.15, -0.065)
	var shift_reach: float = sin((1.0 - _gear_hand_timer / 0.65) * PI) if _gear_hand_timer > 0.0 else 0.0
	var right_target := right_grip.lerp(_lever.position + Vector3(0.0, 0.21, -0.02), shift_reach)
	_left_hand.position = left_grip
	_right_hand.position = right_target
	_left_hand.rotation.z = _steering_visual.rotation.z
	_right_hand.rotation.z = lerpf(_steering_visual.rotation.z, 0.0, shift_reach)
	_pose_arm(_left_arm, Vector3(0.78, 0.78, -0.18), left_grip)
	_pose_arm(_right_arm, Vector3(0.04, 0.78, -0.18), right_target)


func _pose_arm(arm: MeshInstance3D, elbow: Vector3, wrist: Vector3) -> void:
	var reach := wrist - elbow
	arm.transform = Transform3D(Basis(Quaternion(Vector3.UP, reach.normalized())).scaled(Vector3(1.0, reach.length(), 1.0)), (elbow + wrist) * 0.5)


func _gauge(center: Vector3, tick_color: Color) -> Node3D:
	var face := CylinderMesh.new()
	face.top_radius = 0.133
	face.bottom_radius = 0.133
	face.height = 0.017
	face.radial_segments = 32
	var dial := MeshInstance3D.new()
	dial.mesh = face
	dial.position = center
	dial.rotation.x = PI / 2.0
	dial.material_override = _material(Color("111b24"), 0.22)
	add_child(dial)
	var rim_mesh := TorusMesh.new()
	rim_mesh.inner_radius = 0.128
	rim_mesh.outer_radius = 0.145
	var rim := MeshInstance3D.new()
	rim.mesh = rim_mesh
	rim.position = center + Vector3(0, 0, -0.016)
	rim.rotation.x = PI / 2.0
	rim.material_override = _material(Color("c9d3d3"), 0.23)
	add_child(rim)
	for index in 13:
		var angle := -2.2 + float(index) * 4.4 / 12.0
		var tick := _box(self, Vector3(0.010, 0.023 if index % 3 == 0 else 0.014, 0.013), center + Vector3(sin(angle) * 0.102, cos(angle) * 0.102, -0.028), tick_color, 0.38)
		tick.rotation.z = -angle
	var needle := Node3D.new()
	needle.position = center + Vector3(0, 0, -0.044)
	add_child(needle)
	_box(needle, Vector3(0.010, 0.085, 0.017), Vector3(0, 0.034, 0), Color("d4483e"), 0.44)
	_box(needle, Vector3(0.028, 0.028, 0.027), Vector3.ZERO, Color("e8ebdf"), 0.27)
	return needle


func _build_mirror() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(256, 72)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.world_3d = get_viewport().world_3d
	add_child(viewport)
	_rear_camera = Camera3D.new()
	_rear_camera.fov = 63.0
	viewport.add_child(_rear_camera)
	_rear_camera.current = true
	_box(self, Vector3(0.53, 0.17, 0.035), Vector3(0, 1.72, 0.51), Color("101719"), 0.2)
	var mirror := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.48, 0.12)
	mirror.mesh = quad
	mirror.position = Vector3(0, 1.72, 0.48)
	mirror.rotation.y = PI
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = viewport.get_texture()
	mirror.material_override = material
	add_child(mirror)
	for side in [-1.0, 1.0]:
		var side_viewport := SubViewport.new()
		side_viewport.size = Vector2i(160, 100)
		side_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		side_viewport.world_3d = get_viewport().world_3d
		add_child(side_viewport)
		var side_camera := Camera3D.new()
		side_camera.fov = 68.0
		side_viewport.add_child(side_camera)
		side_camera.current = true
		_side_cameras.append(side_camera)
		var side_x: float = float(side)
		_box(self, Vector3(0.36, 0.24, 0.04), Vector3(side_x * 1.02, 1.21, 0.71), Color("171e20"), 0.3)
		var glass := MeshInstance3D.new()
		var side_quad := QuadMesh.new()
		side_quad.size = Vector2(0.30, 0.18)
		glass.mesh = side_quad
		glass.position = Vector3(side_x * 1.02, 1.21, 0.68)
		glass.rotation.y = PI
		var glass_material := StandardMaterial3D.new()
		glass_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glass_material.albedo_texture = side_viewport.get_texture()
		glass.material_override = glass_material
		add_child(glass)


func _build_audio() -> void:
	if not ResourceLoader.exists("res://assets/audio/engine_idle.wav") or not ResourceLoader.exists("res://assets/audio/road_noise.wav"):
		push_warning("Audio has not been imported; open the project in the editor once to import WAV files.")
		return
	var engine_stream := load("res://assets/audio/engine_idle.wav") as AudioStreamWAV
	var road_stream := load("res://assets/audio/road_noise.wav") as AudioStreamWAV
	if engine_stream == null or road_stream == null:
		push_error("Engine or road audio could not be loaded as a WAV stream.")
		return
	# Imported WAVs have loop_end=0 until a real sample endpoint is supplied.
	# Enabling LOOP_FORWARD without this ends playback immediately.
	engine_stream.loop_begin = 0
	engine_stream.loop_end = roundi(engine_stream.get_length() * engine_stream.mix_rate)
	engine_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	road_stream.loop_begin = 0
	road_stream.loop_end = roundi(road_stream.get_length() * road_stream.mix_rate)
	road_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_engine_audio = AudioStreamPlayer.new()
	_engine_audio.stream = engine_stream
	add_child(_engine_audio)
	_road_audio = AudioStreamPlayer.new()
	_road_audio.stream = road_stream
	add_child(_road_audio)
	set_audio_level(audio_level)
	_sync_engine_audio()
	_road_audio.play()


func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


func _box(parent: Node3D, size: Vector3, at: Vector3, color: Color, roughness: float) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = box
	instance.material_override = _material(color, roughness)
	instance.position = at
	parent.add_child(instance)
	return instance
