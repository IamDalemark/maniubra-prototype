extends SceneTree

const Gearbox = preload("res://scripts/manual_transmission.gd")
const Store = preload("res://scripts/attempt_store.gd")


func _initialize() -> void:
	if OS.get_environment("MANIUBRA_DATA_DIR").is_empty():
		push_error("Set MANIUBRA_DATA_DIR to a disposable test directory.")
		quit(1)
		return
	var gear = Gearbox.new()
	assert(not gear.request_shift(1, 0.0))
	assert(gear.gear == 0)
	assert(gear.drive_force(1.0, 0.0) == 0.0)
	assert(gear.request_shift(1, 1.0))
	assert(gear.gear == 1)
	assert(gear.drive_force(1.0, 1.0) == 0.0)
	assert(gear.drive_force(1.0, 0.0) > 0.0)
	assert(gear.request_shift(-1, 1.0))
	assert(gear.request_shift(-1, 1.0))
	assert(gear.gear == -1)
	assert(gear.drive_force(1.0, 0.0) < 0.0)
	gear.update_rpm(1.0, 1.0, 0.0, 1.0)
	assert(gear.engine_rpm > 5000.0)
	gear.update_rpm(0.0, 0.0, 0.0, 1.0)
	assert(is_equal_approx(gear.engine_rpm, gear.IDLE_RPM))

	var filename: String = OS.get_environment("MANIUBRA_DATA_DIR").path_join("maniubra_attempts.json")
	assert(DirAccess.make_dir_recursive_absolute(filename.get_base_dir()) == OK)
	var bad_file := FileAccess.open(filename, FileAccess.WRITE)
	bad_file.store_string("{malformed")
	bad_file.close()
	assert(Store.load_attempts().is_empty())
	for index in range(6):
		assert(Store.save_attempt({"lesson_id": "manual_basics", "number": index}))
	var attempts := Store.load_attempts()
	assert(attempts.size() == 5)
	assert(attempts[0]["number"] == 5 and attempts[4]["number"] == 1)
	print("PASS: manual transmission and bounded, recoverable attempt storage")
	quit()
