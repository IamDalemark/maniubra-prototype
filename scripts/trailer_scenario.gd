extends "res://scripts/open_world.gd"
## A small crowded market map with the same local driving/review lifecycle.

const SHOPPER = preload("res://scripts/world/market_pedestrian.gd")


func _spawn_traffic() -> void:
	var outer: PackedVector3Array = district.lane_path()
	var inner: PackedVector3Array = district.lane_path(true)
	for setup in [
		{"kind": "tricycle", "path": outer, "at": Vector3(-1.9, 0, -40), "speed": 3.6},
		{"kind": "jeepney", "path": outer, "at": Vector3(-1.9, 0, 0), "speed": 4.4},
		{"kind": "car", "path": outer, "at": Vector3(-1.9, 0, 40), "speed": 4.8},
		{"kind": "jeepney", "path": outer, "at": Vector3(50, 0, 20), "speed": 4.1},
		{"kind": "tricycle", "path": outer, "at": Vector3(50, 0, -40), "speed": 3.8},
		{"kind": "jeepney", "path": inner, "at": Vector3(1.9, 0, 40), "speed": 4.6},
		{"kind": "tricycle", "path": inner, "at": Vector3(1.9, 0, 0), "speed": 3.4},
		{"kind": "car", "path": inner, "at": Vector3(1.9, 0, -40), "speed": 4.8},
		{"kind": "tricycle", "path": inner, "at": Vector3(46, 0, 0), "speed": 3.7},
		{"kind": "jeepney", "path": inner, "at": Vector3(24, 0, -70), "speed": 4.2},
	]:
		var actor = TRAFFIC.new()
		actor.kind = setup.kind
		actor.points = setup.path
		var index: int = district.nearest_index(actor.points, setup.at)
		actor.position = actor.points[index]
		actor.next_index = (index + 1) % actor.points.size()
		var forward: Vector3 = actor.points[actor.next_index] - actor.position
		actor.rotation.y = atan2(forward.x, forward.z)
		actor.cruise_speed = setup.speed
		actor.stop_index = (index + 2) % actor.points.size() if actor.kind != "car" else -1
		actor.stop_seconds = 5.0 if actor.kind == "jeepney" else 3.0
		actor.player = sedan
		add_child(actor)
		traffic.append(actor)


func _spawn_pedestrians() -> void:
	var randomizer := RandomNumberGenerator.new()
	randomizer.seed = _encounter_seed
	var sites: Array[Dictionary] = district.stall_sites()
	for index in sites.size():
		var site := sites[index]
		var side: float = site.side
		var z: float = site.position.z
		# A vendor behind each counter, with the sidewalk kept clear for shoppers.
		var vendor = PEDESTRIAN.new()
		vendor.position = Vector3(side * 5.55, 0.05, z - 0.6)
		vendor.rotation.y = -side * PI * 0.5
		add_child(vendor)
		pedestrians.append(vendor)
		var other := sites[index + 2 if index + 2 < sites.size() else index - 2]
		var other_z: float = other.position.z
		var walkway_x: float = side * (6.4 + (index % 3) * 0.34)
		var shopper = SHOPPER.new()
		shopper.points = PackedVector3Array([
			Vector3(walkway_x, 0.05, z + 2.0), Vector3(side * 5.45, 0.05, z + 1.9),
			Vector3(walkway_x, 0.05, z + 2.0), Vector3(walkway_x, 0.05, other_z + 2.0),
			Vector3(side * 5.45, 0.05, other_z + 1.9), Vector3(walkway_x, 0.05, other_z + 2.0),
		])
		shopper.position = shopper.points[0] + Vector3(0, 0, randomizer.randf_range(0.2, 1.0))
		shopper.next_index = 1
		shopper.stall_waypoints = {1: site.id, 4: other.id}
		shopper.walking_speed = randomizer.randf_range(0.85, 1.35)
		shopper.behavior_seed = randomizer.randi()
		shopper.stall_visited.connect(_on_stall_visited)
		add_child(shopper)
		pedestrians.append(shopper)
	for side in [-1.0, 1.0]:
		_add_pedestrian(Vector3(side * 7.25, 0.05, -47), Vector3(side * 7.25, 0.05, 48), false, "walk", randomizer.randi(), true)
	_add_pedestrian(Vector3(-5.9, 0.05, district.CROSSWALK_Z), Vector3(5.9, 0.05, district.CROSSWALK_Z), true, "walk", randomizer.randi(), false, true)
	_add_pedestrian(Vector3(-5.9, 0.05, -3), Vector3(5.9, 0.05, -3), true, "turn_back", randomizer.randi())


func _on_stall_visited(person: Node3D, stall_id: String) -> void:
	# Ambient shopping is logged once per person, keeping the review readable.
	if _started and not _paused and person.visits == 1:
		_events.append({"type": "shopper_stall_visit", "stall_id": stall_id, "elapsed_seconds": snappedf(_elapsed, 0.01), "detail": "A shopper stopped at a market stall."})


func _evaluate_market_stop(_previous: Vector3, _current: Vector3, _speed: float) -> void:
	pass # This map does not contain the Iloilo district's stop-controlled junction.
