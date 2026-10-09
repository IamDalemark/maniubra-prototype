extends CharacterBody3D
## Small shared lane follower for ordinary cars, jeepneys and tricycles.

const JEEPNEY = preload("res://scenes/props/jeepney.tscn")
const TRICYCLE = preload("res://scenes/props/tricycle.tscn")
const MOTORCYCLE = preload("res://scenes/props/motorcycle.tscn")

var kind := "car"
var palette_index := 0
var points: PackedVector3Array
var next_index := 0
var player: Node3D
var cruise_speed := 6.3
var steering_response := 2.4
var acceleration_response := 8.5
var waypoint_radius := 2.1
var stop_index := -1
var stop_seconds := 0.0
var _stop_remaining := 0.0
var _stopped_this_lap := false


func _ready() -> void:
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.2, 1.75, 5.9) if kind == "jeepney" else (Vector3(1.5, 1.65, 2.2) if kind == "tricycle" else Vector3(1.86, 1.50, 4.0))
	if kind == "motorcycle":
		shape.size = Vector3(0.66, 1.95, 2.12)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = shape.size.y * 0.5
	add_child(collision)
	match kind:
		"jeepney":
			add_child(JEEPNEY.instantiate())
		"tricycle":
			add_child(TRICYCLE.instantiate())
		"motorcycle":
			var bike := MOTORCYCLE.instantiate()
			bike.palette_index = palette_index
			add_child(bike)
		_:
			_build_car()


func _physics_process(delta: float) -> void:
	if points.is_empty():
		return
	if _stop_remaining > 0.0:
		_stop_remaining -= delta
		velocity = Vector3.ZERO
		return
	var target := points[next_index]
	var to_target := target - global_position
	to_target.y = 0.0
	if to_target.length() < waypoint_radius:
		var passed := next_index
		next_index = (next_index + 1) % points.size()
		if next_index == 0:
			_stopped_this_lap = false
		if passed == stop_index and not _stopped_this_lap:
			_stopped_this_lap = true
			_stop_remaining = stop_seconds
			target = points[next_index]
		to_target = target - global_position
		to_target.y = 0.0
	var wanted_yaw := atan2(to_target.x, to_target.z)
	rotation.y = lerp_angle(rotation.y, wanted_yaw, minf(delta * steering_response, 1.0))
	var front := Vector3(sin(rotation.y), 0.0, cos(rotation.y))
	var desired_speed := cruise_speed
	if _blocked_ahead(front):
		desired_speed = 0.0
	elif to_target.length() < 8.0:
		desired_speed *= 0.62
	velocity = velocity.move_toward(front * desired_speed, delta * acceleration_response)
	move_and_slide()


func _blocked_ahead(front: Vector3) -> bool:
	var reach := 7.5 + velocity.length() * 0.75
	var origin := global_position + Vector3(0, 1.1, 0) + front * (1.15 if kind == "motorcycle" else 2.4)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + front * reach)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty()


func _build_car() -> void:
	var color := Color("e9e8dc") if get_instance_id() % 2 == 0 else Color("6085a2")
	_box(Vector3(1.80, 0.75, 4.0), Vector3(0, 0.73, 0), color)
	_box(Vector3(1.56, 0.65, 2.25), Vector3(0, 1.37, -0.25), color)
	_box(Vector3(1.58, 0.12, 2.35), Vector3(0, 1.73, -0.25), color)
	_box(Vector3(1.60, 0.43, 0.04), Vector3(0, 1.40, 0.91), Color("345064"))
	for side in [-1.0, 1.0]:
		for z in [-1.28, 1.23]:
			var tire := CylinderMesh.new()
			tire.top_radius = 0.35
			tire.bottom_radius = 0.35
			tire.height = 0.16
			var mesh := MeshInstance3D.new()
			mesh.mesh = tire
			mesh.rotation.z = PI / 2
			mesh.position = Vector3(side * 0.91, 0.37, z)
			mesh.material_override = _material(Color("24292b"))
			add_child(mesh)


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
	material.roughness = 0.67
	return material
