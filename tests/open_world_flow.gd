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
	assert(drive._venue.text.contains("Molo Plaza"))
	assert(drive.district.get_node("RoundaboutIsland") != null)
	assert(drive.district.START.distance_to(drive.district.DESTINATION) > 550.0)
	# Ending the drive without visiting the venue is a valid exploratory result.
	drive._end_drive()
	assert(app._page == "result")
	assert(not app._last_result["destination_reached"])
	assert(app._last_result["badge_id"] == "")
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
