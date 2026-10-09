extends SceneTree
## The second map must be playable through the existing catalog/review lifecycle.

const Shopper = preload("res://scripts/world/market_pedestrian.gd")
const Market = preload("res://scripts/world/trailer_market.gd")


func _initialize() -> void:
	if OS.get_environment("MANIUBRA_DATA_DIR").is_empty():
		push_error("Set MANIUBRA_DATA_DIR to a disposable test directory.")
		quit(1)
		return
	call_deferred("run")


func check(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
	return condition


func run() -> void:
	var app = load("res://scenes/app.tscn").instantiate()
	root.add_child(app)
	app._show_lessons("open_world")
	app._show_briefing("trailer_market")
	app._launch_lesson("res://scenes/lessons/trailer_scenario.tscn")
	await physics_frame
	var session = app._session
	if not check(session._started and session.sedan.camera.current and not session.has_destination, "New map failed to launch in first person."):
		return
	if not check(not session._venue.text.contains("Molo") and session.pedestrians.size() == 28, "New map has incorrect heading or crowd population."):
		return
	if not check(session.traffic.filter(func(actor): return actor.kind == "jeepney").size() == 4 and session.traffic.filter(func(actor): return actor.kind == "tricycle").size() == 4, "Jeepneys and tricycles are missing from traffic."):
		return
	var outer := Market.lane_path()
	var inner := Market.lane_path(true)
	if not check(outer.size() > 30 and outer[0].distance_to(outer[outer.size() - 1]) < 5.0, "Road loop is not continuous."):
		return
	for lane in [outer, inner]:
		for point in lane:
			if absf(point.x) < 3.0 and absf(point.z) < 45:
				if not check(is_equal_approx(absf(point.x), 1.9), "Traffic leaves its main-road lane."):
					return
	# The counter projects into the lane edge while leaving jeepney clearance.
	for site in Market.stall_sites():
		if not check(absf(site.position.x) - 0.9 < Market.ROAD_WIDTH * 0.5 and absf(site.position.x) - 0.9 > 3.0, "Stall either misses the road or obstructs the travel corridor."):
			return
	session.sedan.freeze = true
	var shopper = session.pedestrians.filter(func(person): return person is Shopper)[0]
	for frame in 160:
		await physics_frame
		if shopper.visits > 0:
			break
	if not check(shopper.visits == 1 and shopper._dwell_remaining > 0.0, "Shopper did not arrive and stop at the counter."):
		return
	var at_counter: Vector3 = shopper.global_position
	for frame in 30:
		await physics_frame
	if not check(shopper.global_position.distance_to(at_counter) < 0.01, "Shopper moves while browsing at the stall."):
		return
	session._set_paused(true)
	var remaining: float = shopper._dwell_remaining
	for frame in 10:
		await physics_frame
	if not check(is_equal_approx(shopper._dwell_remaining, remaining), "Pause did not freeze shoppers."):
		return
	session._set_paused(false)
	for frame in 420:
		await physics_frame
		if shopper.next_index >= 3 and shopper.global_position.distance_to(at_counter) > 1.0:
			break
	if not check(shopper.next_index >= 3 and shopper.global_position.distance_to(at_counter) > 1.0, "Shopper did not leave for another stall."):
		return
	if not check(session._events.any(func(event): return event.get("type") == "shopper_stall_visit"), "Shopper visit was not recorded."):
		return
	session._on_sedan_body_entered(shopper)
	if not check(shopper.fallen and session._toast.visible, "Crowd contact did not retain the fall/toast reaction."):
		return
	session._end_drive()
	if not check(app._page == "result" and app._last_result.get("map_id") == "trailer_market" and app._last_result.get("destination_venue") == "", "Market session review identifies the wrong map."):
		return
	var attempts = load("res://scripts/attempt_store.gd").load_attempts()
	if not check(attempts[0].get("lesson_id") == "trailer_market", "Market result did not save with the stable lesson ID."):
		return
	app._launch_lesson("res://scenes/lessons/trailer_scenario.tscn")
	await physics_frame
	if not check(app._session._started and app._session.pedestrians.size() == 28, "Market retry did not reconstruct the crowd."):
		return
	app._session._restart()
	if not check(app._session._events.is_empty() and app._session.sedan.position == Market.START, "Market restart did not reset state."):
		return
	app._clear_session()
	app.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("PASS: market map, shopper arrival/dwell/departure, pause, contact, saved review and retry")
	quit()
