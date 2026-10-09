extends SceneTree
## Scripted clearance check using real sedan physics; dynamic actors are removed.
## This does not replace a human playthrough with traffic.

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1600, 900)
	var scene = load("res://scenes/lessons/trailer_scenario.tscn").instantiate()
	root.add_child(scene)
	scene.start_attempt({"hazard_seed": 261010, "camera_fov": 75.0})
	# Separate map/vehicle clearance from unpredictable actors for this geometry pass.
	scene._clear_actors()
	var car = scene.sedan
	Input.action_press("drive_clutch")
	car._toggle_ignition()
	car.gearbox.request_shift(1, 1.0)
	car.toggle_seatbelt()
	for frame in 60:
		await physics_frame
	Input.action_release("drive_clutch")
	var lane: PackedVector3Array = scene.district.lane_path()
	var index := 1
	var traveled := 0.0
	var last: Vector3 = car.global_position
	var min_up := 1.0
	var peak_error := 0.0
	var progress_time := 0.0
	var captured := false
	for frame in 7200:
		await physics_frame
		var at: Vector3 = car.global_position
		traveled += Vector2(at.x-last.x, at.z-last.z).length()
		last = at
		var target: Vector3 = lane[index]
		if Vector2(at.x-target.x,at.z-target.z).length() < 4.2:
			index += 1
			progress_time = 0.0
			if index >= lane.size():
				break
			target = lane[index]
		progress_time += 1.0 / 60
		var difference := target - at
		var angle := wrapf(atan2(difference.x,difference.z)-car.rotation.y,-PI,PI)
		var steering := clampf(atan(2.7 * 2.0 * sin(angle) / maxf(difference.length(),4.0)) / 0.42, -1.0, 1.0)
		Input.action_release("drive_left")
		Input.action_release("drive_right")
		Input.action_press("drive_left" if steering > 0 else "drive_right", absf(steering))
		var speed: float = car.speed_mps()
		Input.action_press("drive_throttle", clampf(0.10 + (4.5-speed)*0.18,0.0,0.65))
		Input.action_press("drive_brake", clampf((speed-5.0)*0.4,0.0,0.4))
		min_up = minf(min_up,car.global_basis.y.dot(Vector3.UP))
		# Distance from the road centreline segments, not just sparse waypoints.
		var nearest := 999.0
		var center: PackedVector3Array = scene.district.centreline()
		for j in center.size():
			var a := Vector2(center[j].x,center[j].z)
			var b := Vector2(center[(j+1)%center.size()].x,center[(j+1)%center.size()].z)
			var p := Vector2(at.x,at.z)
			var t := clampf((p-a).dot(b-a)/(b-a).length_squared(),0,1)
			nearest = minf(nearest,p.distance_to(a+(b-a)*t))
		peak_error = maxf(peak_error,nearest)
		if index >= 18 and not captured and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/screenshots/trailer_market_turn.png")
			captured = true
		if frame % 1200 == 0:
			print("DRIVE index=",index," pos=",at," speed=",speed," road_offset=",nearest)
		if progress_time > 18 or nearest > 4.4 or not car.gearbox.engine_running:
			print("FAIL scripted map drive at ",at," index=",index," offset=",nearest," engine=",car.gearbox.engine_running)
			quit(1)
			return
	for action in ["drive_throttle","drive_brake","drive_left","drive_right"]:
		Input.action_release(action)
	print("DRIVE RESULT index=",index,"/",lane.size()," distance=",traveled," max_road_offset=",peak_error," min_up=",min_up," events=",scene._events)
	var ok: bool = index >= lane.size() and min_up > 0.9 and not scene._events.any(func(event): return event.get("type") in ["roadside_collision","vehicle_collision"])
	scene.queue_free()
	await process_frame
	print("PASS: scripted full map loop with real sedan physics" if ok else "FAIL: map loop did not complete")
	quit(0 if ok else 1)
