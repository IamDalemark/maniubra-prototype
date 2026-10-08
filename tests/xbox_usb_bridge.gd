extends SceneTree

func _initialize() -> void:
	var app := preload("res://scenes/app.tscn").instantiate()
	root.add_child(app)
	await create_timer(5.0).timeout
	app._show_settings()
	var connected: bool = app._xbox_usb_bridge.connected
	print("Xbox USB connected: ", connected)
	print("Bridge process: ", app._xbox_usb_bridge._process_id)
	print("Bridge running: ", OS.is_process_running(app._xbox_usb_bridge._process_id))
	print("Port: ", app._xbox_usb_bridge._udp.get_local_port(), " pending: ", app._xbox_usb_bridge._udp.get_available_packet_count())
	print("Settings status: ", app._controller_status.text)
	print("USB throttle: ", Input.get_action_strength("drive_throttle"))
	assert(not connected or "direct input" in app._controller_status.text)
	app.queue_free()
	await process_frame
	quit(0 if connected else 1)
