extends RefCounted
## Simplified manual gearbox. Engine power reaches the wheels only in gear
## with the clutch released; shifts require the clutch pedal depressed.

var gear := 0
var engine_running := false
var engine_stalled := false
var engine_rpm := 0.0
var _stall_time := 0.0
const IDLE_RPM := 900.0
const REDLINE_RPM := 6800.0
const ROAD_SPEED_AT_REDLINE := [0.0, 38.0, 66.0, 98.0, 132.0, 166.0]
const STALL_DELAY := 0.35


func toggle_ignition(clutch: float) -> bool:
	if engine_running:
		engine_running = false
		engine_stalled = false
		engine_rpm = 0.0
		_stall_time = 0.0
		return true
	if gear != 0 and clutch < 0.65:
		return false
	engine_running = true
	engine_stalled = false
	engine_rpm = IDLE_RPM
	_stall_time = 0.0
	return true


func update_stall(throttle: float, clutch: float, brake: float, speed_mps: float, delta: float) -> bool:
	if not engine_running:
		return false
	var loaded_at_low_speed := gear != 0 and clutch < 0.25 and speed_mps < 0.9
	if loaded_at_low_speed and (throttle < 0.25 or brake > 0.5):
		_stall_time += delta
		if _stall_time >= STALL_DELAY:
			engine_running = false
			engine_stalled = true
			engine_rpm = 0.0
			_stall_time = 0.0
			return true
	else:
		_stall_time = 0.0
	return false


func request_shift(direction: int, clutch: float) -> bool:
	if clutch < 0.65:
		return false
	gear = clampi(gear + direction, -1, 5)
	return true


func drive_force(throttle: float, clutch: float) -> float:
	if not engine_running or gear == 0:
		return 0.0
	var ratio: float = [0.0, 1.0, 0.72, 0.55, 0.43, 0.36][abs(gear)]
	return throttle * (1.0 - clutch) * 1750.0 * ratio * signf(float(gear))


func update_rpm(throttle: float, clutch: float, speed_kmh: float, delta: float) -> void:
	if not engine_running:
		engine_rpm = 0.0
		return
	var free_revs := IDLE_RPM + throttle * 5200.0
	var target := free_revs
	if gear != 0 and clutch < 0.65:
		var road_revs: float = IDLE_RPM + absf(speed_kmh) / ROAD_SPEED_AT_REDLINE[abs(gear)] * (REDLINE_RPM - IDLE_RPM)
		target = lerpf(road_revs + throttle * 450.0, free_revs, clutch)
	engine_rpm = move_toward(engine_rpm, clampf(target, IDLE_RPM, REDLINE_RPM), delta * 5500.0)
