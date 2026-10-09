extends "res://scripts/world/pedestrian.gd"
## A shopper approaches a counter, spends time there, and visits another stall.

signal stall_visited(person: Node3D, stall_id: String)

var stall_waypoints: Dictionary = {}
var visits := 0
var _dwell_remaining := 0.0
var _visited_index := -1


func _physics_process(delta: float) -> void:
	if fallen:
		super._physics_process(delta)
		return
	if _dwell_remaining > 0.0:
		_dwell_remaining = maxf(0, _dwell_remaining - delta)
		velocity = Vector3.ZERO
		_left_arm.rotation.x = lerpf(_left_arm.rotation.x, 0.12, delta * 4.0)
		_right_arm.rotation.x = lerpf(_right_arm.rotation.x, -0.25, delta * 4.0)
		_left_leg.rotation.x = 0.0
		_right_leg.rotation.x = 0.0
		return
	if next_index != _visited_index and not points.is_empty() and global_position.distance_to(points[next_index]) < 0.4 and stall_waypoints.has(next_index):
		_visited_index = next_index
		_dwell_remaining = _randomizer.randf_range(3.0, 6.0)
		visits += 1
		velocity = Vector3.ZERO
		rotation.y = PI # The counter is just before the customer along the street.
		stall_visited.emit(self, stall_waypoints[next_index])
		return
	if next_index != _visited_index:
		_visited_index = -1
	# The base walker supplies articulated walking, collision and fall reactions.
	super._physics_process(delta)
