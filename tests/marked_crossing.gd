extends SceneTree
## The visible market zebra and the ordinary pedestrian must share one path.

class ApproachingDriver extends Node3D:
	func speed_mps() -> float:
		return 5.0


func _initialize() -> void:
	if OS.get_environment("MANIUBRA_DATA_DIR").is_empty():
		push_error("Set MANIUBRA_DATA_DIR to a disposable test directory.")
		quit(1)
		return
	call_deferred("run")


func run() -> void:
	var session = preload("res://scenes/lessons/open_world.tscn").instantiate()
	root.add_child(session)
	session.start_attempt({"hazard_seed": 321})
	var crossing = session.pedestrians[7]
	var crossing_z: float = session.district.MARKET_CROSSWALK_Z
	assert(crossing.marked_crossing and crossing.crossing_behavior == "walk")
	assert(crossing.global_position.z == crossing_z and crossing.points[0].z == crossing_z)
	assert(crossing.global_position.x < -204.25 and crossing.points[0].x > -195.75)
	for stripe in 7:
		var paint: MeshInstance3D = session.district.get_node("MarketCrosswalkStripe%d" % stripe)
		assert(paint.position.x == -200.0)
		assert(absf(paint.position.z - crossing_z) <= 2.2)
		assert((paint.mesh as BoxMesh).size.x >= 8.0)
	crossing.traffic = []
	crossing.collision_mask = 0
	session.sedan.freeze = true
	for frame in 4:
		await physics_frame
	assert(not crossing._crossing_active) # Waiting while the real car is stationary.
	var moving_driver := ApproachingDriver.new()
	session.add_child(moving_driver)
	moving_driver.global_position = session.sedan.global_position
	crossing.player = moving_driver
	var entered_road := false
	var reached_other_lane := false
	for frame in 1000:
		await physics_frame
		if crossing.crossing:
			assert(absf(crossing.global_position.z - crossing_z) < 0.1)
		if crossing.global_position.x > -203.8:
			entered_road = true
		if crossing.global_position.x > -200.0:
			reached_other_lane = true
		if crossing.roaming_after_crosswalk:
			break
	assert(entered_road and reached_other_lane)
	assert(crossing.roaming_after_crosswalk and not crossing.crossing)
	assert(crossing.global_position.x > -193.7)
	assert(crossing.points[0].x > -193.0 and crossing.points[1].x > -193.0)
	assert(session._events.filter(func(event): return event.get("type") == "pedestrian_crossing" and event.get("marked", false)).size() == 1)
	for frame in 120:
		await physics_frame
		assert(crossing.global_position.x > -193.7)
	assert(session._events.filter(func(event): return event.get("type") == "pedestrian_crossing" and event.get("marked", false)).size() == 1)
	print("PASS: marked pedestrian crosses the painted lane, then walks along the far sidewalk")
	session.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit()
