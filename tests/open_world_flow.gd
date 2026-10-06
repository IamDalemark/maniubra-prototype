extends SceneTree
## Exercise course launch, optional arrival, badge, review, and free exploration.


func _initialize() -> void:
	if OS.get_environment("MANIUBRA_DATA_DIR").is_empty():
		push_error("Set MANIUBRA_DATA_DIR to a disposable test directory.")
		quit(1)
		return
	call_deferred("run")


func run() -> void:
	var app = load("res://scenes/app.tscn").instantiate()
	root.add_child(app)
	app._show_lessons("open_world")
	app._show_briefing("philippine_roads")
	app._launch_lesson("res://scenes/lessons/open_world.tscn")
	await physics_frame
	var drive = app._session
	assert(drive._started and drive.sedan.camera.current)
	assert(drive.traffic.size() == 6 and drive.pedestrians.size() == 7)
	assert(drive.district.get_children().filter(func(node): return node is StaticBody3D and node.name.begins_with("VendorObstacle")).size() == 3)
	var car_start: Vector3 = drive.traffic[0].global_position
	var walker_start: Vector3 = drive.pedestrians[0].global_position
	for index in 90:
		await physics_frame
	assert(drive.traffic[0].global_position.distance_to(car_start) > 2.0)
	assert(drive.pedestrians[0].global_position.distance_to(walker_start) > 1.0)
	assert(drive._venue.text.contains("Molo Plaza"))
	assert(drive.district.get_node("RoundaboutIsland") != null)
	assert(drive.district.START.distance_to(drive.district.DESTINATION) > 550.0)
	drive.sedan.freeze = true
	drive.sedan.global_position = drive.pedestrians[5].global_position + Vector3(5.2, 0, -33)
	for index in 3:
		await physics_frame
	assert(drive.pedestrians[5]._crossing_active)
	assert(drive._events.any(func(event): return event.get("type") == "pedestrian_crossing"))
	assert(drive.sedan.contact_monitor and drive.sedan.max_contacts_reported >= 8)
	drive._on_sedan_body_entered(drive.pedestrians[0])
	assert(drive.pedestrians[0].fallen)
	assert(drive._events.filter(func(event): return event.get("type") == "pedestrian_collision").size() == 1)
	drive._on_sedan_body_entered(drive.pedestrians[0])
	assert(drive._events.filter(func(event): return event.get("type") == "pedestrian_collision").size() == 1)
	for index in 20:
		await physics_frame
	assert(drive.pedestrians[0]._visual.rotation.length() > 0.5)
	drive._on_sedan_body_entered(drive.traffic[0])
	drive._on_sedan_body_entered(drive.traffic[0])
	assert(drive._events.filter(func(event): return event.get("type") == "vehicle_collision").size() == 1)
	var before_stop_events: int = drive._events.size()
	drive._evaluate_market_stop(Vector3(-202, 0, -21), Vector3(-202, 0, -20), 0.0)
	drive._evaluate_market_stop(Vector3(-202, 0, -10), Vector3(-202, 0, -8), 4.0)
	assert(drive._events.size() == before_stop_events)
	drive._evaluate_market_stop(Vector3(-202, 0, -50), Vector3(-202, 0, -49), 4.0)
	drive._evaluate_market_stop(Vector3(-202, 0, -10), Vector3(-202, 0, -8), 4.0)
	assert(drive._events.filter(func(event): return event.get("type") == "stop_line_missed").size() == 1)
	# Ending the drive without visiting the venue is a valid exploratory result.
	drive._end_drive()
	assert(app._page == "result")
	assert(not app._last_result["destination_reached"])
	assert(app._last_result["badge_id"] == "")
	assert(int(app._last_result["hazard_seed"]) > 0)
	app._launch_lesson("res://scenes/lessons/open_world.tscn")
	await physics_frame
	drive = app._session
	var car = drive.sedan
	car.freeze = true
	car.global_position = drive.district.DESTINATION + Vector3(5.0, 0, 0)
	await physics_frame
	assert(not drive.district.destination_contains_vehicle(car))
	car.global_position = drive.district.DESTINATION
	await physics_frame
	assert(drive.district.destination_contains_vehicle(car))
	drive._physics_process(2.1)
	assert(drive._venue_reached and drive._toast.visible and drive._started)
	assert(drive._events.size() == 1)
	drive._physics_process(3.0)
	assert(drive._events.size() == 1 and drive._started)
	drive._end_drive()
	assert(app._page == "result")
	assert(app._last_result["destination_reached"])
	assert(app._last_result["badge_id"] == "molo_explorer")
	assert(load("res://scripts/attempt_store.gd").load_attempts().size() >= 2)
	print("PASS: Open World launch, optional venue, one badge, continued drive and saved review")
	app.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit()
