extends SceneTree
## Counterflow is authored on the market straight; rider onset must be escapable.

const Market = preload("res://scripts/world/trailer_market.gd")


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
	return condition


func pose(session: Node3D, at: Vector3, direction: int, speed: float) -> void:
	session.sedan.global_position = at
	session.sedan.rotation.y = 0.0 if direction > 0 else PI
	session.sedan.linear_velocity = Vector3(0, 0, direction * speed)


func run() -> void:
	if not check(Market.counterflow_direction(Vector3(-1.9, 0, 0), Vector3.BACK) == 0 and Market.counterflow_direction(Vector3(1.9, 0, 0), Vector3.FORWARD) == 0, "Correct lane incorrectly classified."):
		return
	if not check(Market.counterflow_direction(Vector3(1.9, 0, -30), Vector3.BACK) == 1 and Market.counterflow_direction(Vector3(-1.9, 0, 30), Vector3.FORWARD) == -1, "Opposing direction not detected on both lanes."):
		return
	if not check(Market.counterflow_direction(Vector3(1.9, 0, 61), Vector3.BACK) == 0 and Market.counterflow_direction(Vector3(48, 0, 0), Vector3.BACK) == 0, "Encounter incorrectly applies at bends or return street."):
		return
	var session = load("res://scenes/lessons/trailer_scenario.tscn").instantiate()
	root.add_child(session)
	session.start_attempt({"hazard_seed": 261010})
	session.sedan.freeze = true
	var north = session.motorcycles[0]
	var south = session.motorcycles[1]
	for actor in session.traffic + session.pedestrians:
		actor.set_physics_process(false)
	var blocker = session.traffic[0]
	for index in 10:
		session.traffic[index].global_position = Vector3(48, 0.05, -50 + index * 9)
	pose(session, Vector3(-1.9, 0.05, -30), 1, 5)
	session._evaluate_counterflow(1.0)
	if not check(session._events.filter(func(event): return event.get("type") == "counterflow").is_empty(), "Correct-lane driver receives a counterflow event."):
		return
	pose(session, Vector3(1.9, 0.05, -30), 1, 0)
	session._evaluate_counterflow(1.0)
	if not check(north.state == "waiting", "Stationary driver triggered the motorcycle."):
		return
	pose(session, Vector3(1.9, 0.05, 40), 1, 5)
	if not check(not session._motorcycle_eligible(north, 1), "Motorcycle can launch too close to the player."):
		return
	pose(session, Vector3(1.9, 0.05, -30), 1, 5)
	blocker.global_position = Vector3(0.38, 0.05, 55)
	session._evaluate_counterflow(0.7)
	if not check(north.state == "waiting", "Blocked merge did not suppress motorcycle launch."):
		return
	blocker.global_position = Vector3(48, 0.05, -50)
	session._evaluate_counterflow(0.1)
	if not check(north.state == "approaching" and south.state == "waiting", "Counterflow did not activate the rider ahead."):
		return
	for step in 20:
		session._evaluate_counterflow(0.1)
	if not check(session._events.filter(func(event): return event.get("type") == "counterflow").size() == 1 and session._events.filter(func(event): return event.get("type") == "motorcycle_approach").size() == 1, "Sustained counterflow duplicates events."):
		return
	var origin: Vector3 = north.global_position
	pose(session, Vector3(-1.9, 0.05, -30), 1, 0)
	north.set_physics_process(true)
	var fastest := 0.0
	for frame in 360:
		await physics_frame
		fastest = maxf(fastest, north.velocity.length())
		if north.global_position.z < 48:
			if not check(north.global_position.x > 0.33 and north.global_position.x < 1.3, "Motorcycle left its own lane during the approach at %s, speed %.1f." % [north.global_position, north.velocity.length()]):
				return
	if not check(north.global_position.distance_to(origin) > 30 and fastest > 9.0, "Motorcycle approach incomplete: at %s, fastest %.1f, merging %s, waypoint %d." % [north.global_position, fastest, north._merging, north.next_index]):
		return
	session._set_paused(true)
	var paused_at: Vector3 = north.global_position
	for frame in 12:
		await physics_frame
	if not check(north.global_position == paused_at, "Pause did not stop the motorcycle."):
		return
	session._set_paused(false)
	pose(session, Vector3(-1.9, 0.05, 30), -1, 5)
	session._evaluate_counterflow(0.7)
	if not check(south.state == "approaching", "Reverse-heading counterflow did not activate the other rider."):
		return
	session._on_sedan_body_entered(south)
	if not check(session._events.any(func(event): return event.get("type") == "vehicle_collision") and session._toast.visible, "Motorcycle contact is missing its error toast."):
		return
	var old_map_id: int = session.district.get_instance_id()
	session._restart()
	if not check(session.motorcycles.size() == 2 and session.motorcycles.all(func(rider): return rider.state == "waiting") and session._events.is_empty(), "Restart retained motorcycle encounter state."):
		return
	if not check(session.district.get_instance_id() != old_map_id, "Restart retained the displaced physical obstacles."):
		return
	session.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("PASS: lane/direction checks, stationary/close/blocked gating, fast approach, one event, pause, contact and restart")
	quit()
