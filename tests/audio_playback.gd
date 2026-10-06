extends SceneTree
## Catch silent imported loops and a disconnected settings volume slider.


func _initialize() -> void:
	call_deferred("verify")


func verify() -> void:
	var car = load("res://scenes/vehicles/sedan.tscn").instantiate()
	root.add_child(car)
	assert(car._engine_audio != null and car._road_audio != null)
	car.set_audio_level(0.0)
	assert(car._engine_audio.volume_db <= -80.0)
	assert(car._road_audio.volume_db <= -80.0)
	car.set_audio_level(0.8)
	assert(car._engine_audio.volume_db > -10.0)
	assert(car._road_audio.volume_db > -25.0)
	# The WAVs are two seconds long. Both players must survive past that point.
	await create_timer(3.2).timeout
	assert(car._engine_audio.playing and car._road_audio.playing)
	print("PASS: engine and road loops continue; audio volume mutes and restores")
	car._engine_audio.stop()
	car._road_audio.stop()
	await create_timer(0.1).timeout
	car.queue_free()
	await process_frame
	quit()
