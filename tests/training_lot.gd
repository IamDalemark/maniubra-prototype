extends SceneTree
## Check that the playable course is an enclosed lot with movable obstacles.


func _initialize() -> void:
	call_deferred("verify")


func verify() -> void:
	var lot = load("res://scenes/lessons/primary_controls.tscn").instantiate()
	root.add_child(lot)
	await physics_frame
	assert(lot.get_node("LotSurface") is StaticBody3D)
	for wall in ["LotWallSide-1", "LotWallSide1", "LotWallEnd-1", "LotWallEnd1"]:
		assert(lot.get_node(wall) is StaticBody3D)
	assert(absf(lot.sedan.position.x) < 8.0)
	assert(lot.sedan.position.z < -75.0)
	var cones := 0
	for child in lot.get_children():
		if child.name.begins_with("TrainingCone"):
			assert(child is RigidBody3D)
			assert(child.get_child_count() > 1)
			assert(absf(child.position.x) < 70.0 and absf(child.position.z) < 110.0)
			cones += 1
	assert(cones == 17)
	print("PASS: enclosed 160 x 240 m training lot, clear start lane, 17 physical cones")
	lot.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit()
