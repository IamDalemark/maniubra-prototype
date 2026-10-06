extends CharacterBody3D
## Sidewalk walker; selected walkers cross only with adequate response distance.

signal crossing_started(person: Node3D)

var points: PackedVector3Array
var next_index := 0
var player: Node3D
var crossing := false
var traffic: Array = []
var walking_speed := 1.1
var _crossing_active := false
var _crossing_done := false
var fallen := false
var _visual: Node3D
var _fall_target := Vector3.ZERO
var _fall_progress := 0.0
var _left_arm: Node3D
var _right_arm: Node3D
var _left_leg: Node3D
var _right_leg: Node3D
var _walk_phase := 0.0
var _collision: CollisionShape3D


func _ready() -> void:
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.65
	var collision := CollisionShape3D.new()
	collision.shape = capsule
	collision.position.y = 0.84
	add_child(collision)
	_collision = collision
	_visual = Node3D.new()
	_visual.position.y = 0.15
	add_child(_visual)
	var shirt := Color("ba7859") if get_instance_id() % 2 == 0 else Color("e2b86e")
	_box(_visual, Vector3(0.52, 0.68, 0.29), Vector3(0, 1.14, 0), shirt)
	_box(_visual, Vector3(0.46, 0.15, 0.31), Vector3(0, 0.73, 0), Color("364d5d"))
	_left_arm = _limb(Vector3(-0.36, 1.36, 0), shirt, Color("bc8d68"), true)
	_right_arm = _limb(Vector3(0.36, 1.36, 0), shirt, Color("bc8d68"), true)
	_left_leg = _limb(Vector3(-0.14, 0.67, 0), Color("364d5d"), Color("24292c"), false)
	_right_leg = _limb(Vector3(0.14, 0.67, 0), Color("364d5d"), Color("24292c"), false)
	var head := SphereMesh.new()
	head.radius = 0.22
	head.height = 0.44
	var visual := MeshInstance3D.new()
	visual.mesh = head
	visual.position.y = 1.67
	visual.material_override = _material(Color("bc8d68"))
	_visual.add_child(visual)
	_box(_visual, Vector3(0.39, 0.13, 0.37), Vector3(0, 1.88, -0.03), Color("252a2c"))


func _physics_process(delta: float) -> void:
	if fallen:
		_fall_progress = minf(_fall_progress + delta * 3.1, 1.0)
		_visual.rotation = _visual.rotation.lerp(_fall_target, _fall_progress)
		return
	if points.is_empty():
		return
	if crossing and not _crossing_active:
		if _crossing_done or not _can_cross():
			velocity = Vector3.ZERO
			return
		_crossing_active = true
		crossing_started.emit(self)
	var target := points[next_index]
	var difference := target - global_position
	difference.y = 0.0
	if difference.length() < 0.4:
		if crossing:
			_crossing_done = true
			velocity = Vector3.ZERO
			return
		next_index = (next_index + 1) % points.size()
		target = points[next_index]
		difference = target - global_position
		difference.y = 0.0
	var direction := difference.normalized()
	rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), minf(delta * 4.0, 1.0))
	_walk_phase += delta * 7.0
	_left_arm.rotation.x = sin(_walk_phase) * 0.38
	_right_arm.rotation.x = -sin(_walk_phase) * 0.38
	_left_leg.rotation.x = -sin(_walk_phase) * 0.28
	_right_leg.rotation.x = sin(_walk_phase) * 0.28
	velocity = direction * walking_speed
	move_and_slide()


func fall(impact_direction: Vector3) -> void:
	if fallen:
		return
	fallen = true
	velocity = Vector3.ZERO
	var local_direction := global_basis.inverse() * impact_direction.normalized()
	if absf(local_direction.x) > absf(local_direction.z):
		_fall_target.z = -signf(local_direction.x) * 1.42
	else:
		_fall_target.x = signf(local_direction.z) * 1.42
	_collision.set_deferred("disabled", true)


func _can_cross() -> bool:
	if player == null:
		return false
	var distance := player.global_position.distance_to(global_position)
	var speed: float = player.speed_mps()
	var trigger_distance := maxf(38.0, speed * 4.0)
	if distance < 20.0 or distance > trigger_distance:
		return false
	for actor in traffic:
		if actor != null and actor.global_position.distance_to(global_position) < 13.0:
			return false
	return true


func _limb(at: Vector3, cloth: Color, end_color: Color, arm: bool) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = at
	_visual.add_child(pivot)
	_box(pivot, Vector3(0.16, 0.43 if arm else 0.55, 0.17), Vector3(0, -0.21 if arm else -0.27, 0), cloth)
	_box(pivot, Vector3(0.14, 0.20, 0.15) if arm else Vector3(0.20, 0.12, 0.31), Vector3(0, -0.52 if arm else -0.58, 0.07), end_color)
	return pivot


func _box(parent: Node3D, size: Vector3, at: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.position = at
	visual.material_override = _material(color)
	parent.add_child(visual)


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material
