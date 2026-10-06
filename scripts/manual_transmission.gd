extends RefCounted
## Simplified manual gearbox. Engine power reaches the wheels only in gear
## with the clutch released; shifts require the clutch pedal depressed.

var gear := 0
var engine_rpm := 900.0
const IDLE_RPM := 900.0
const REDLINE_RPM := 6800.0
const ROAD_SPEED_AT_REDLINE := [0.0, 38.0, 66.0, 98.0, 132.0, 166.0]


func request_shift(direction: int, clutch: float) -> bool:
	if clutch < 0.65:
		return false
	gear = clampi(gear + direction, -1, 5)
	return true


func drive_force(throttle: float, clutch: float) -> float:
	if gear == 0:
		return 0.0
	var ratio: float = [0.0, 1.0, 0.72, 0.55, 0.43, 0.36][abs(gear)]
	return throttle * (1.0 - clutch) * 1750.0 * ratio * signf(float(gear))


func update_rpm(throttle: float, clutch: float, speed_kmh: float, delta: float) -> void:
	var free_revs := IDLE_RPM + throttle * 5200.0
	var target := free_revs
	if gear != 0 and clutch < 0.65:
		var road_revs: float = IDLE_RPM + absf(speed_kmh) / ROAD_SPEED_AT_REDLINE[abs(gear)] * (REDLINE_RPM - IDLE_RPM)
		target = lerpf(road_revs + throttle * 450.0, free_revs, clutch)
	engine_rpm = move_toward(engine_rpm, clampf(target, IDLE_RPM, REDLINE_RPM), delta * 5500.0)
