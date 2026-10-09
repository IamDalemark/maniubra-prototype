extends "res://scripts/world/traffic_vehicle.gd"
## Visible roadside rider; a triggered approach becomes ordinary circulating traffic.

const APPROACH_SPEED := 13.0 # 46.8 km/h, a simulator tuning value.
var travel_direction := -1
var state := "waiting"
var _approach_remaining := 0.0
var _cooldown_remaining := 0.0
var _merging := false


func _ready() -> void:
	kind = "motorcycle"
	steering_response = 12.0
	acceleration_response = 40.0
	waypoint_radius = 1.0
	super._ready()


func can_activate() -> bool:
	return state != "approaching" and _cooldown_remaining <= 0.0


func activate(route: PackedVector3Array) -> void:
	if not can_activate():
		return
	if state == "waiting":
		points = route
		next_index = 0
		_merging = true
	state = "approaching"
	cruise_speed = 4.5 if _merging else APPROACH_SPEED
	_approach_remaining = 12.0
	_cooldown_remaining = 32.0


func _physics_process(delta: float) -> void:
	_cooldown_remaining = maxf(0, _cooldown_remaining - delta)
	if state == "waiting":
		velocity = Vector3.ZERO
		return
	if state == "approaching":
		if _merging and next_index > 0 and absf(global_position.x + travel_direction * 0.38) < 0.22 and global_basis.z.z * travel_direction > 0.99 and absf(velocity.x) < 0.35:
			_merging = false
			cruise_speed = APPROACH_SPEED
		_approach_remaining -= delta
		if _approach_remaining <= 0:
			state = "circulating"
			cruise_speed = 5.0
	super._physics_process(delta)
