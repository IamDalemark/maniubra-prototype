extends SceneTree
## Check that a real sedan-to-pedestrian physics contact triggers the fall and review event.


func _initialize() -> void:
	if OS.get_environment("MANIUBRA_DATA_DIR").is_empty():
		push_error("Set MANIUBRA_DATA_DIR to a disposable test directory.")
		quit(1)
		return
	call_deferred("run")


func run() -> void:
	var session = load("res://scenes/lessons/open_world.tscn").instantiate()
	root.add_child(session)
	session.start_attempt({"hazard_seed": 12345})
	var person = session.pedestrians[0]
	person.set_physics_process(false)
	session.sedan.global_position = person.global_position + Vector3(4.0, 0, 0)
	session.sedan.linear_velocity = Vector3(-9.0, 0, 0)
	for index in 90:
		await physics_frame
	var count: int = session._events.filter(func(event): return event.get("type") == "pedestrian_collision").size()
	if not person.fallen or count != 1 or not session._toast.visible:
		push_error("Physical contact did not produce one fall and one visible collision notice.")
		quit(1)
		return
	var actor = session.traffic[0]
	actor.set_physics_process(false)
	session.sedan.global_position = actor.global_position + Vector3(0, 0, -7.0)
	session.sedan.linear_velocity = Vector3(0, 0, 10.0)
	for index in 90:
		await physics_frame
	var vehicle_count: int = session._events.filter(func(event): return event.get("type") == "vehicle_collision").size()
	if vehicle_count != 1:
		push_error("Physical contact with traffic did not produce one collision notice.")
		quit(1)
		return
	print("PASS: physical pedestrian and vehicle collisions produce one incident each")
	session.queue_free()
	await process_frame
	quit()
