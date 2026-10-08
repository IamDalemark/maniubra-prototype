extends SceneTree
## Seeded pedestrian reactions must remain on their authored path and finish once.


func _initialize() -> void:
	if OS.get_environment("MANIUBRA_DATA_DIR").is_empty():
		push_error("Set MANIUBRA_DATA_DIR to a disposable test directory.")
		quit(1)
		return
	call_deferred("run")


func run() -> void:
	var session = preload("res://scenes/lessons/open_world.tscn").instantiate()
	root.add_child(session)
	session.start_attempt({"hazard_seed": 12345})
	var crossing_a = session.pedestrians[5]
	var crossing_b = session.pedestrians[6]
	var sidewalk = session.pedestrians[0]
	assert(sidewalk.variable_pace)
	sidewalk.collision_mask = 0
	sidewalk._behavior_wait = 0.0
	for step in 3:
		await physics_frame
	assert(sidewalk.velocity.length() > 2.3)
	assert([crossing_a.crossing_behavior, crossing_b.crossing_behavior].has("sprint"))
	assert([crossing_a.crossing_behavior, crossing_b.crossing_behavior].has("turn_back"))
	var first_setup := [crossing_a.points[0], crossing_a.crossing_behavior, crossing_b.points[0], crossing_b.crossing_behavior]
	var returner = crossing_a if crossing_a.crossing_behavior == "turn_back" else crossing_b
	var runner = crossing_b if returner == crossing_a else crossing_a
	for person in [returner, runner]:
		person.traffic = []
		person.collision_mask = 0
		assert(not person._can_cross()) # No nearby player: no sudden spawn into the road.
		session.sedan.freeze = true
		session.sedan.global_position = person.global_position + Vector3(0, 0, -12)
		assert(not person._can_cross()) # Too close for a response.
		session.sedan.global_position = person.global_position + Vector3(0, 0, -33)
		assert(person._can_cross())
		var origin: Vector3 = person.global_position
		var target: Vector3 = person.points[0]
		var maximum_speed := 0.0
		var minimum_x := minf(origin.x, target.x) - 0.5
		var maximum_x := maxf(origin.x, target.x) + 0.5
		for frame in 480:
			await physics_frame
			maximum_speed = maxf(maximum_speed, person.velocity.length())
			assert(person.global_position.x >= minimum_x and person.global_position.x <= maximum_x)
			if person._crossing_done:
				break
		assert(person._crossing_done and maximum_speed > 2.3)
		if person == returner:
			assert(person.global_position.distance_to(origin) < 0.5)
			assert(person.roaming_after_turnback and not person.crossing)
			assert(session._events.filter(func(event): return event.get("type") == "pedestrian_turn_back").size() == 1)
			var roam_speeds: Array[float] = []
			person._behavior_wait = 0.0
			for roam_frame in 240:
				await physics_frame
				roam_speeds.append(person.velocity.length())
				assert(person.global_position.x < origin.x + 0.5 and person.global_position.x > origin.x - 1.2)
				assert(absf(person.global_position.z - origin.z) < 17.5)
				if roam_frame == 110:
					person._behavior_wait = 0.0
			assert(person.global_position.distance_to(origin) > 1.0)
			assert(roam_speeds.max() - roam_speeds.min() > 0.2)
			assert(session._events.filter(func(event): return event.get("type") == "pedestrian_crossing" and not event.get("marked", false)).size() == 1)
			var waypoint_index: int = person.next_index
			person.global_position = person.points[waypoint_index]
			for step in 3:
				await physics_frame
			assert(person.next_index != waypoint_index and person.velocity.length() > 0.7)
		else:
			assert(person.global_position.distance_to(target) < 0.5)
	assert(session._events.filter(func(event): return event.get("type") == "pedestrian_crossing" and not event.get("marked", false)).size() == 2)
	session.queue_free()
	await process_frame
	var repeat = preload("res://scenes/lessons/open_world.tscn").instantiate()
	root.add_child(repeat)
	repeat.start_attempt({"hazard_seed": 12345})
	assert(first_setup == [repeat.pedestrians[5].points[0], repeat.pedestrians[5].crossing_behavior, repeat.pedestrians[6].points[0], repeat.pedestrians[6].crossing_behavior])
	print("PASS: seeded crossings finish once; turn-back continues roaming at varied speeds")
	repeat.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit()
