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


func _ready() -> void:
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.65
	var collision := CollisionShape3D.new()
	collision.shape = capsule
	collision.position.y = 0.84
	add_child(collision)
	var shirt := Color("ba7859") if get_instance_id() % 2 == 0 else Color("e2b86e")
	_box(Vector3(0.42, 0.75, 0.28), Vector3(0, 1.03, 0), shirt)
	_box(Vector3(0.38, 0.51, 0.28), Vector3(0, 0.43, 0), Color("364d5d"))
	var head := SphereMesh.new()
	head.radius = 0.22
	head.height = 0.44
	var visual := MeshInstance3D.new()
	visual.mesh = head
	visual.position.y = 1.66
	visual.material_override = _material(Color("bc8d68"))
	add_child(visual)


func _physics_process(delta: float) -> void:
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
	velocity = direction * walking_speed
	move_and_slide()


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


func _box(size: Vector3, at: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.position = at
	visual.material_override = _material(color)
	add_child(visual)


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material
