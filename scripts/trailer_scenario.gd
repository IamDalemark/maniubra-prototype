extends "res://scripts/open_world.gd"
## A small crowded market map with the same local driving/review lifecycle.

const SHOPPER = preload("res://scripts/world/market_pedestrian.gd")
const MOTORCYCLE = preload("res://scripts/world/approaching_motorcycle.gd")

var motorcycles: Array = []
var _counterflow_held := 0.0
var _counterflow_clear := 0.0
var _counterflow_latched := false
var _motorcycle_launched := false


func start_attempt(context: Dictionary) -> void:
	_counterflow_held = 0.0
	_counterflow_clear = 0.0
	_counterflow_latched = false
	_motorcycle_launched = false
	super.start_attempt(context)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _started and not _paused:
		_evaluate_counterflow(delta)


func _clear_actors() -> void:
	super._clear_actors()
	motorcycles.clear()


func _restart() -> void:
	# Rebuild the physical cones as well as the crowd and encounter state.
	var old: Node3D = district
	remove_child(old)
	old.queue_free()
	district = district_scene.instantiate()
	add_child(district)
	super._restart()


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
	for direction in [-1, 1]:
		var rider = MOTORCYCLE.new()
		rider.travel_direction = direction
		rider.palette_index = 0 if direction < 0 else 1
		rider.position = Vector3(-direction * 4.9, 0.05, -direction * 61.0)
		rider.rotation.y = PI if direction < 0 else 0.0
		rider.player = sedan
		add_child(rider)
		traffic.append(rider)
		motorcycles.append(rider)


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


func _evaluate_counterflow(delta: float) -> void:
	var forward: Vector3 = sedan.global_basis.z.normalized()
	var direction: int = district.counterflow_direction(sedan.global_position, forward)
	if sedan.linear_velocity.dot(forward) < 1.0:
		direction = 0
	if direction == 0:
		_counterflow_held = 0.0
		_counterflow_clear += delta
		if _counterflow_clear >= 0.8:
			_counterflow_latched = false
			_motorcycle_launched = false
		return
	_counterflow_clear = 0.0
	_counterflow_held += delta
	if _counterflow_held < 0.6:
		return
	if not _counterflow_latched:
		_counterflow_latched = true
		_record_error("counterflow", "COUNTERFLOW", "Watch for oncoming traffic. Return to your lane when clear.")
	if _motorcycle_launched:
		return
	for rider in motorcycles:
		if rider.travel_direction != -direction or not _motorcycle_eligible(rider, direction):
			continue
		var was_waiting: bool = rider.state == "waiting"
		var distance: float = absf(rider.global_position.z - sedan.global_position.z)
		rider.activate(_motorcycle_route(rider.travel_direction))
		_motorcycle_launched = true
		_events.append({"type": "motorcycle_approach", "elapsed_seconds": snappedf(_elapsed, 0.01), "distance_meters": snappedf(distance, 0.1), "detail": "A roadside motorcycle pulled into the oncoming lane and accelerated." if was_waiting else "An oncoming motorcycle accelerated while you were counterflowing."})
		_show_toast("ONCOMING MOTORCYCLE", "Slow down. Return to your lane when clear.", true)
		break


func _motorcycle_eligible(rider: Node3D, player_direction: int) -> bool:
	if not rider.can_activate():
		return false
	if rider.state != "waiting" and (absf(rider.global_position.x) > 0.9 or absf(rider.global_position.z) > 53.0 or rider.global_basis.z.z * rider.travel_direction < 0.75):
		return false
	var ahead: float = (rider.global_position.z - sedan.global_position.z) * player_direction
	var minimum: float = maxf(38.0, (sedan.speed_mps() + MOTORCYCLE.APPROACH_SPEED) * 2.5 + 5.0)
	if ahead < minimum or ahead > 125.0:
		return false
	if rider.state == "waiting":
		var merge := Vector3(-rider.travel_direction * 0.38, 0.05, -rider.travel_direction * 55.0)
		for actor in traffic:
			if actor != rider and actor.global_position.distance_to(merge) < 10.0:
				return false
		for person in pedestrians:
			if not person.fallen and person.global_position.distance_to(merge) < 3.0:
				return false
	return true


func _motorcycle_route(direction: int) -> PackedVector3Array:
	var lane: PackedVector3Array = district.lane_path(direction < 0)
	# The narrow rider uses its own lane close to the centre, passing slow queues.
	# Its 0.66 m collision width stays wholly on that side of the centreline.
	for index in lane.size():
		if absf(lane[index].x) < 2.5 and absf(lane[index].z) < 55.0:
			var point: Vector3 = lane[index]
			point.x = -direction * 0.38
			lane[index] = point
	var index: int = district.nearest_index(lane, Vector3(-direction * 0.38, 0.05, -direction * 40.0))
	var route := PackedVector3Array([Vector3(-direction * 0.38, 0.05, -direction * 55.0)])
	for step in lane.size():
		route.append(lane[(index + step) % lane.size()])
	return route
