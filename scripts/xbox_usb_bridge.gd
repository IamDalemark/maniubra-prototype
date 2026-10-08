extends Node
## Feeds original Xbox One USB (045e:02d1) reports into the existing Godot actions.

signal connection_changed(connected: bool)
signal input_changed

const TIMEOUT_SECONDS := 0.5
const BUTTONS := [
	[4, 0x10, "drive_handbrake"], [4, 0x10, "ui_accept"],
	[4, 0x20, "ui_cancel"], [4, 0x40, "drive_seatbelt"],
	[4, 0x80, "drive_ignition"], [4, 0x04, "drive_pause"],
	[5, 0x01, "drive_reset"], [5, 0x02, "drive_gear_down"],
	[5, 0x10, "drive_clutch"], [5, 0x20, "drive_gear_up"],
]
const ACTIONS := [
	"drive_handbrake", "ui_accept", "ui_cancel", "drive_seatbelt",
	"drive_ignition", "drive_pause", "drive_reset", "drive_gear_down",
	"drive_clutch", "drive_gear_up", "drive_left", "drive_right",
	"drive_throttle", "drive_brake", "look_left", "look_right",
	"look_up", "look_down",
]

var connected := false
var _udp: PacketPeerUDP
var _process_id := -1
var _seconds_since_report := 0.0
var _strengths: Dictionary = {}


func _ready() -> void:
	if not OS.has_feature("macos") or OS.get_environment("MANIUBRA_DISABLE_USB_BRIDGE") == "1":
		return
	_udp = PacketPeerUDP.new()
	if _udp.bind(0, "127.0.0.1") != OK:
		push_warning("Xbox USB bridge could not bind a local UDP port.")
		_udp = null
		return
	var helper := OS.get_executable_path().get_base_dir().path_join("maniubra_xbox_usb_bridge")
	if not FileAccess.file_exists(helper):
		helper = ProjectSettings.globalize_path("res://tools/maniubra_xbox_usb_bridge")
	if not FileAccess.file_exists(helper):
		push_warning("Xbox USB bridge executable is missing; run tools/build_xbox_usb_bridge.sh.")
		return
	_process_id = OS.create_process(helper, [str(_udp.get_local_port())])
	if _process_id < 0:
		push_warning("Xbox USB bridge could not start.")


func _process(delta: float) -> void:
	if _udp == null:
		return
	_seconds_since_report += delta
	while _udp.get_available_packet_count() > 0:
		var packet := _udp.get_packet()
		if packet.size() != 22 or packet.slice(0, 4).get_string_from_ascii() != "MUB1" or packet[4] != 0x20:
			continue
		_seconds_since_report = 0.0
		if not connected:
			connected = true
			connection_changed.emit(true)
		_apply_report(packet)
	if connected and _seconds_since_report > TIMEOUT_SECONDS:
		connected = false
		_release_all()
		connection_changed.emit(false)


func _apply_report(packet: PackedByteArray) -> void:
	for entry in BUTTONS:
		_set_action(entry[2], 1.0 if packet[entry[0] + 4] & entry[1] else 0.0)
	_set_axis("drive_left", "drive_right", _stick(packet, 14))
	_set_axis("look_left", "look_right", _stick(packet, 18))
	_set_axis("look_up", "look_down", _stick(packet, 20))
	_set_action("drive_brake", clampf(float(_u16(packet, 10)) / 1023.0, 0.0, 1.0))
	_set_action("drive_throttle", clampf(float(_u16(packet, 12)) / 1023.0, 0.0, 1.0))


func _u16(packet: PackedByteArray, index: int) -> int:
	return int(packet[index]) | (int(packet[index + 1]) << 8)


func _stick(packet: PackedByteArray, index: int) -> float:
	var raw := _u16(packet, index)
	if raw >= 32768:
		raw -= 65536
	var value := clampf(float(raw) / 32767.0, -1.0, 1.0)
	return 0.0 if absf(value) < 0.12 else value


func _set_axis(negative: String, positive: String, value: float) -> void:
	_set_action(negative, maxf(-value, 0.0))
	_set_action(positive, maxf(value, 0.0))


func _set_action(action: String, strength: float) -> void:
	var old := float(_strengths.get(action, 0.0))
	if absf(old - strength) < 0.01:
		return
	_strengths[action] = strength
	var event := InputEventAction.new()
	event.action = StringName(action)
	event.pressed = strength > 0.0
	event.strength = strength
	Input.parse_input_event(event)
	if strength > 0.0:
		input_changed.emit()


func _release_all() -> void:
	for action in ACTIONS:
		_set_action(action, 0.0)


func _exit_tree() -> void:
	_release_all()
	if _process_id > 0:
		OS.kill(_process_id)
	if _udp != null:
		_udp.close()
