extends SceneTree
## Flat-road cornering regression for the sedan's ride height and rollover.


func _initialize() -> void:
	call_deferred("verify")


func verify() -> void:
	var ordinary := await _run_corner(200)
	assert(ordinary["speed_before_turn"] > 7.0)
	assert(ordinary["max_lean_degrees"] < 15.0)
	assert(ordinary["minimum_wheel_contacts"] >= 3)
	assert(ordinary["settled_body_y"] < 0.0)

	var severe := await _run_corner(400)
	assert(severe["speed_before_turn"] > 14.0)
	assert(severe["max_lean_degrees"] > 45.0)
	assert(severe["minimum_wheel_contacts"] < 3)
	print("PASS: ordinary corner stays planted; high-speed full-lock turn can tip")
	quit()


func _run_corner(acceleration_frames: int) -> Dictionary:
	var world := Node3D.new()
	root.add_child(world)
	var ground := StaticBody3D.new()
	ground.position.y = -0.12
	var ground_shape := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(500, 0.1, 500)
	ground_shape.shape = shape
	ground.add_child(ground_shape)
	world.add_child(ground)

	var car = load("res://scenes/vehicles/sedan.tscn").instantiate()
	car.position = Vector3(0, -0.05, 0)
	world.add_child(car)
	car._toggle_ignition()
	car.gearbox.gear = 1
	Input.action_press("drive_throttle")
	for index in acceleration_frames:
		await physics_frame
	var result := {
		"speed_before_turn": car.speed_mps(),
		"settled_body_y": car.global_position.y,
		"max_lean_degrees": 0.0,
		"minimum_wheel_contacts": 4,
	}
	Input.action_press("drive_right")
	for index in 240:
		await physics_frame
		var upright: float = car.global_basis.y.dot(Vector3.UP)
		result["max_lean_degrees"] = maxf(result["max_lean_degrees"], rad_to_deg(acos(clampf(upright, -1.0, 1.0))))
		var wheel_contacts := 0
		for child in car.get_children():
			if child is VehicleWheel3D and child.is_in_contact():
				wheel_contacts += 1
		result["minimum_wheel_contacts"] = mini(result["minimum_wheel_contacts"], wheel_contacts)
	Input.action_release("drive_throttle")
	Input.action_release("drive_right")
	world.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	return result
