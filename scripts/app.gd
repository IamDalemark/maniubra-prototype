extends Control
## Course navigation and ownership of one driving session at a time.

const Catalog = preload("res://scripts/course_catalog.gd")
const AttemptStore = preload("res://scripts/attempt_store.gd")
const DrivingInput = preload("res://scripts/driving_input.gd")
const ControllerBindings = preload("res://scripts/controller_bindings.gd")
const XboxUsbBridge = preload("res://scripts/xbox_usb_bridge.gd")
const COURSE_ART = {
	"primary_controls": "res://assets/ui/course_art/primary_controls.png",
	"secondary_controls": "res://assets/ui/course_art/secondary_controls.png",
	"maneuvers": "res://assets/ui/course_art/maneuvers.png",
	"open_world": "res://assets/ui/course_art/open_world.png",
	"reversing": "res://assets/ui/course_art/reversing.png",
	"turning": "res://assets/ui/course_art/turning.png",
	"lane_changing": "res://assets/ui/course_art/lane_changing.png",
	"trailer_market": "res://assets/ui/course_art/trailer_market.png",
}
const LESSON_ART = {
	"parking": "maneuvers", "reversing": "reversing",
	"left_turn": "turning", "right_turn": "turning", "u_turn": "turning",
	"lane_changing": "lane_changing", "merging": "lane_changing",
	"overtaking": "lane_changing", "lane_positioning": "lane_changing",
	"trailer_market": "trailer_market",
}
const LESSON_SUMMARY = {
	"manual_basics": "Start the engine, clutch, shift, steer, stop, and reverse.",
	"secondary_basics": "Signals, lights, wipers, horn, and hazards.",
	"parking": "Practice precise placement and clearance.",
	"reversing": "Back up with control and observation.",
	"left_turn": "Choose the lane, signal, and yield.",
	"right_turn": "Check restrictions and make a safe turn.",
	"u_turn": "Find a permitted place to turn around.",
	"lane_changing": "Check, signal, and move into a clear lane.",
	"merging": "Choose a gap and join traffic smoothly.",
	"overtaking": "Read markings before you pass.",
	"lane_positioning": "Hold an appropriate place in the lane.",
	"philippine_roads": "Explore Iloilo-inspired streets at your own pace.",
	"trailer_market": "Crowded palengke, shoppers, narrow lanes, and local traffic.",
}

var _content: VBoxContainer
var _page := "home"
var _course_id := ""
var _lesson_id := ""
var _session = null
var _last_result: Dictionary = {}
var _camera_fov := 75.0
var _audio_level := 0.8
var _pending_binding_action: StringName = &""
var _binding_buttons: Dictionary = {}
var _binding_notice: Label
var _controller_status: Label
var _xbox_usb_bridge: Node
var _controller_options: Dictionary = {}
var _controller_notice: Label


func _ready() -> void:
	DrivingInput.install_actions()
	DrivingInput.load_keyboard_bindings()
	ControllerBindings.load_saved()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_xbox_usb_bridge = XboxUsbBridge.new()
	_xbox_usb_bridge.connection_changed.connect(_on_usb_connection_changed)
	_xbox_usb_bridge.input_changed.connect(_on_usb_input_changed)
	add_child(_xbox_usb_bridge)
	_build_shell()
	_show_home()


func _input(event: InputEvent) -> void:
	if _page != "settings" or _pending_binding_action == &"" or not event is InputEventKey or not event.pressed or event.echo:
		return
	get_viewport().set_input_as_handled()
	if event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE:
		_pending_binding_action = &""
		_refresh_binding_buttons()
		_binding_notice.text = "Binding change cancelled."
		return
	var key: Key = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
	if not DrivingInput.set_keyboard_binding(_pending_binding_action, key):
		_binding_notice.text = "That key is already used, or is reserved. Choose another key."
		return
	_pending_binding_action = &""
	_refresh_binding_buttons()
	_binding_notice.text = "Keyboard bindings saved." if DrivingInput.save_keyboard_bindings() else "Binding changed for this run, but could not be saved."


func _unhandled_input(event: InputEvent) -> void:
	if _page != "session" and event.is_action_pressed("ui_cancel"):
		_go_back()
		get_viewport().set_input_as_handled()


func _build_shell() -> void:
	var background := ColorRect.new()
	background.color = Color("142321")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 24)
	add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)

	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 12)
	scroll.add_child(_content)


func _clear_page(page: String, title: String, description: String) -> void:
	_page = page
	_pending_binding_action = &""
	_binding_buttons.clear()
	_controller_options.clear()
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	_add_text("MANIUBRA / LEARN THE ROAD", 16, Color("93c7ac"))
	_add_text(title, 32)
	_add_text(description, 19)


func _add_text(value: String, font_size: int, color := Color.WHITE) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	_content.add_child(label)
	return label


func _add_button(title: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size.y = 48
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(action)
	_content.add_child(button)
	return button


func _show_home() -> void:
	_clear_page("home", "Learn the road, one course at a time.", "Single-player driving practice from the driver's seat.")
	_add_button("Courses", _show_courses).grab_focus()
	_add_button("Settings", _show_settings)
	_add_button("Quit", func(): get_tree().quit())


func _show_settings() -> void:
	_clear_page("settings", "Settings", "Adjust the cockpit, audio, and input controls.")
	var fov_label := _add_text("Camera field of view: %.0f°" % _camera_fov, 18)
	var fov_slider := HSlider.new()
	fov_slider.min_value = 60.0
	fov_slider.max_value = 95.0
	fov_slider.step = 1.0
	fov_slider.value = _camera_fov
	fov_slider.value_changed.connect(func(value: float): _camera_fov = value; fov_label.text = "Camera field of view: %.0f°" % value)
	_content.add_child(fov_slider)
	var audio_label := _add_text("Audio volume: %d%%" % roundi(_audio_level * 100), 18)
	var audio_slider := HSlider.new()
	audio_slider.min_value = 0.0
	audio_slider.max_value = 1.0
	audio_slider.step = 0.05
	audio_slider.value = _audio_level
	audio_slider.value_changed.connect(func(value: float): _audio_level = value; audio_label.text = "Audio volume: %d%%" % roundi(value * 100))
	_content.add_child(audio_slider)
	_add_text("Controller bindings", 24, Color("f5c548"))
	_controller_status = _add_text("", 17, Color("d4e7d6"))
	_refresh_controller_status()
	_add_text("Choose a controller control for each action. If a driving control is already assigned, the two assignments swap. Menu select and back are separate from driving controls.", 16, Color("d4e7d6"))
	_controller_notice = _add_text("", 16, Color("eecb7d"))
	for binding in ControllerBindings.AXIS_ACTIONS + ControllerBindings.BUTTON_ACTIONS:
		var key: String = binding[0]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		_content.add_child(row)
		var caption := Label.new()
		caption.text = binding[1]
		caption.custom_minimum_size.x = 190
		caption.add_theme_font_size_override("font_size", 17)
		row.add_child(caption)
		var picker := OptionButton.new()
		picker.custom_minimum_size = Vector2(210, 39)
		for option in ControllerBindings.options_for(key):
			picker.add_item(option[1])
		picker.item_selected.connect(_change_controller_binding.bind(key))
		row.add_child(picker)
		_controller_options[key] = picker
	_refresh_controller_options()
	_add_button("Restore default controller bindings", _reset_controller_bindings)
	_add_text("Keyboard bindings", 24, Color("f5c548"))
	_add_text("Select an action, then press a key. Escape cancels. Controller axes and buttons use the Xbox layout above.", 16, Color("d4e7d6"))
	_binding_notice = _add_text("", 16, Color("eecb7d"))
	for binding in DrivingInput.BINDINGS:
		var action := StringName(binding["action"])
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		_content.add_child(row)
		var caption := Label.new()
		caption.text = binding["label"]
		caption.custom_minimum_size.x = 190
		caption.add_theme_font_size_override("font_size", 17)
		row.add_child(caption)
		var button := Button.new()
		button.custom_minimum_size = Vector2(165, 39)
		button.pressed.connect(_begin_key_capture.bind(action))
		row.add_child(button)
		_binding_buttons[action] = button
	_refresh_binding_buttons()
	_add_button("Restore default keys", _reset_keyboard_bindings)
	_add_button("Back", _show_home)
	fov_slider.grab_focus()


func _begin_key_capture(action: StringName) -> void:
	_pending_binding_action = action
	_binding_notice.text = "Press a key for %s." % _binding_label(action)
	_refresh_binding_buttons()


func _binding_label(action: StringName) -> String:
	for binding in DrivingInput.BINDINGS:
		if binding["action"] == String(action):
			return binding["label"]
	return String(action)


func _refresh_binding_buttons() -> void:
	for action in _binding_buttons:
		var button: Button = _binding_buttons[action]
		button.text = "Press a key…" if action == _pending_binding_action else DrivingInput.keyboard_name(action)


func _reset_keyboard_bindings() -> void:
	DrivingInput.reset_keyboard_bindings()
	_refresh_binding_buttons()
	_binding_notice.text = "Default keys restored." if DrivingInput.save_keyboard_bindings() else "Defaults restored for this run, but could not be saved."


func _change_controller_binding(index: int, key: String) -> void:
	var option: Array = ControllerBindings.options_for(key)[index]
	_xbox_usb_bridge._release_all()
	if ControllerBindings.set_binding(key, option[0]):
		_refresh_controller_options()
		_controller_notice.text = "Controller bindings saved." if ControllerBindings.save() else "Binding changed for this run, but could not be saved."


func _reset_controller_bindings() -> void:
	_xbox_usb_bridge._release_all()
	ControllerBindings.reset()
	_refresh_controller_options()
	_controller_notice.text = "Default controller bindings restored." if ControllerBindings.save() else "Defaults restored for this run, but could not be saved."


func _refresh_controller_options() -> void:
	for key in _controller_options:
		var picker: OptionButton = _controller_options[key]
		var options: Array = ControllerBindings.options_for(key)
		for index in options.size():
			if options[index][0] == ControllerBindings.source(key):
				picker.select(index)
				break


func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	if _page == "settings":
		_refresh_controller_status()


func _on_usb_connection_changed(_connected: bool) -> void:
	if _page == "settings":
		_refresh_controller_status()


func _on_usb_input_changed() -> void:
	if _session != null and _session.get("sedan") != null:
		_session.sedan.controls.last_device = "gamepad"


func _refresh_controller_status() -> void:
	var devices := Input.get_connected_joypads()
	if _xbox_usb_bridge != null and _xbox_usb_bridge.connected:
		_controller_status.text = "Connected: Xbox One USB controller (direct input)"
	else:
		_controller_status.text = "No controller detected on this Mac." if devices.is_empty() else "Connected: %s" % Input.get_joy_name(devices[0])


func _show_courses() -> void:
	_clear_page("courses", "Choose your road to practice", "Explore each course. Yellow cards are ready to drive; the others show what's coming next.")
	var grid := _selection_grid(2)
	var first: Button = null
	var attempts := AttemptStore.load_attempts()
	for course in Catalog.get_courses():
		var playable := _course_has_playable_lesson(course)
		var detail := "COURSE %02d  /  %s" % [grid.get_child_count() + 1, "PLAYABLE NOW" if playable else "COMING SOON"]
		if course["id"] == "primary_controls":
			var count := 0
			for attempt in attempts:
				if attempt is Dictionary and attempt.get("course_id") == "primary_controls":
					count += 1
			if count > 0:
				detail = "PLAYABLE NOW  /  %d RECENT ATTEMPT%s" % [count, "" if count == 1 else "S"]
		var button := _selection_card(grid, course["title"].substr(3), course["description"], detail, COURSE_ART[course["id"]], _show_lessons.bind(course["id"]), playable, 250)
		if first == null:
			first = button
	_add_button("Back", _show_home)
	if first != null:
		first.grab_focus()


func _show_lessons(course_id: String) -> void:
	var course := Catalog.get_course(course_id)
	if course.is_empty():
		_show_courses()
		return
	_course_id = course_id
	_clear_page("lessons", course["title"], course["description"])
	var grid := _selection_grid(3 if course_id == "maneuvers" else 2)
	var first: Button = null
	for lesson in course["lessons"]:
		var playable := _lesson_available(lesson)
		var art_key: String = LESSON_ART.get(lesson["id"], course_id)
		var button := _selection_card(grid, lesson["title"], LESSON_SUMMARY.get(lesson["id"], lesson["objective"]), "READY TO DRIVE" if playable else "COMING SOON", COURSE_ART[art_key], _show_briefing.bind(lesson["id"]), playable, 228)
		if first == null:
			first = button
	_add_button("Back to courses", _show_courses)
	if first != null:
		first.grab_focus()


func _selection_grid(columns: int) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = columns
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	_content.add_child(grid)
	return grid


func _lesson_available(lesson: Dictionary) -> bool:
	var path: String = lesson.get("scene_path", "")
	return not path.is_empty() and ResourceLoader.exists(path)


func _course_has_playable_lesson(course: Dictionary) -> bool:
	for lesson in course["lessons"]:
		if _lesson_available(lesson):
			return true
	return false


func _selection_card(grid: GridContainer, title: String, description: String, status: String, art_path: String, action: Callable, playable: bool, height: float) -> Button:
	var accent := Color("f5c548") if playable else Color("788b8e")
	var button := Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(258, height)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.clip_contents = true
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("0b1a22")
		style.border_color = accent if state == "normal" else Color("ffd85d")
		style.border_width_left = 2 if state == "normal" else 4
		style.border_width_top = 2 if state == "normal" else 4
		style.border_width_right = 2 if state == "normal" else 4
		style.border_width_bottom = 5 if state == "normal" else 7
		style.set_corner_radius_all(8)
		button.add_theme_stylebox_override(state, style)
	button.pressed.connect(action)
	grid.add_child(button)

	var vertical := VBoxContainer.new()
	vertical.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vertical.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vertical.add_theme_constant_override("separation", 0)
	button.add_child(vertical)
	var art_frame := Control.new()
	art_frame.custom_minimum_size.y = 140 if height >= 245 else 118
	art_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art_frame.clip_contents = true
	art_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vertical.add_child(art_frame)
	var art := TextureRect.new()
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture = load(art_path)
	art.modulate = Color.WHITE if playable else Color(0.77, 0.82, 0.82)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_frame.add_child(art)
	var badge := PanelContainer.new()
	badge.position = Vector2(12, 12)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(0.03, 0.09, 0.13, 0.90)
	badge_style.content_margin_left = 9
	badge_style.content_margin_right = 9
	badge_style.content_margin_top = 5
	badge_style.content_margin_bottom = 5
	badge.add_theme_stylebox_override("panel", badge_style)
	art_frame.add_child(badge)
	var status_label := Label.new()
	status_label.text = status
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.add_theme_color_override("font_color", Color("ffd45c") if playable else Color("d6e2df"))
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(status_label)

	var footer := MarginContainer.new()
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for edge in ["left", "right"]:
		footer.add_theme_constant_override("margin_" + edge, 15)
	footer.add_theme_constant_override("margin_top", 9)
	footer.add_theme_constant_override("margin_bottom", 11)
	vertical.add_child(footer)
	var copy := VBoxContainer.new()
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_theme_constant_override("separation", 3)
	footer.add_child(copy)
	var headline := Label.new()
	headline.text = title.to_upper()
	headline.add_theme_font_size_override("font_size", 20)
	headline.add_theme_color_override("font_color", Color("f8f9f2"))
	headline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(headline)
	var subline := Label.new()
	subline.text = description
	subline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subline.add_theme_font_size_override("font_size", 14)
	subline.add_theme_color_override("font_color", Color("c7d8d9"))
	subline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(subline)
	return button


func _show_briefing(lesson_id: String) -> void:
	var lesson := Catalog.get_lesson(_course_id, lesson_id)
	if lesson.is_empty():
		_show_lessons(_course_id)
		return
	_lesson_id = lesson_id
	_clear_page("briefing", lesson["title"], lesson["objective"])
	var scene_path: String = lesson.get("scene_path", "")
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		_add_text("This lesson is not available yet.", 18, Color("e5c98c"))
		_add_button("Start lesson — coming soon", func(): pass).disabled = true
	else:
		_add_text("Keyboard: " + DrivingInput.keyboard_hint() + " · mouse look.\nXbox: " + DrivingInput.controller_hint() + ". The seatbelt button can also be clicked while paused.", 17, Color("d4e7d6"))
		if _course_id == "open_world":
			_add_text(lesson.get("briefing", "Molo Plaza appears as an optional venue name while you drive. Find it using the streets and signs; stop in its painted bay for a badge. You can explore for as long as you like and end the drive from pause."), 17, Color("f5d47d"))
		var previous := AttemptStore.load_attempts()
		var same_count := 0
		for attempt in previous:
			if attempt is Dictionary and attempt.get("lesson_id") == lesson_id:
				same_count += 1
		_add_text("Recent attempts for this lesson: %d" % same_count, 16, Color("a8c3b5"))
		_add_button("Start lesson", _launch_lesson.bind(scene_path)).grab_focus()
	var back := _add_button("Back to lessons", _show_lessons.bind(_course_id))
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		back.grab_focus()


func _launch_lesson(scene_path: String) -> void:
	if not ResourceLoader.exists(scene_path):
		_show_briefing(_lesson_id)
		return
	_clear_session()
	_session = load(scene_path).instantiate()
	get_tree().root.add_child(_session)
	_session.attempt_finished.connect(_on_attempt_finished)
	_session.exit_requested.connect(_on_session_exit)
	hide()
	_page = "session"
	_session.start_attempt({
		"course_id": _course_id,
		"lesson_id": _lesson_id,
		"vehicle_id": "generic_sedan",
		"input_profile_id": "keyboard_mouse",
		"camera_fov": _camera_fov,
		"audio_level": _audio_level,
	})


func _on_attempt_finished(result: Dictionary) -> void:
	_last_result = result
	var saved := AttemptStore.save_attempt(result)
	_clear_session()
	show()
	_show_result(saved)


func _on_session_exit() -> void:
	_clear_session()
	show()
	_show_briefing(_lesson_id)


func _clear_session() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if _session != null:
		_session.queue_free()
		_session = null


func _show_result(saved: bool) -> void:
	_clear_page("result", "Drive complete", _last_result.get("feedback", ""))
	if _last_result.get("course_id") == "open_world":
		var status := "MOLO EXPLORER BADGE" if _last_result.get("destination_reached") else "DESTINATION OPTIONAL"
		if not _last_result.get("has_destination", true):
			status = "MARKET STREET DRIVE"
		_add_text("%.1f SECONDS EXPLORED     •     %s     •     %d STALLS" % [_last_result.get("elapsed_seconds", 0.0), status, _last_result.get("stall_count", 0)], 18, Color("f5c548"))
	else:
		var steps: int = int(_last_result.get("step_count", 8))
		_add_text("%d / %d STEPS COMPLETE     •     %.1f SECONDS     •     %d REJECTED SHIFTS     •     %d STALLS" % [steps, steps, _last_result.get("elapsed_seconds", 0.0), _last_result.get("shift_errors", 0), _last_result.get("stall_count", 0)], 18, Color("f5c548"))
	_add_text("What happened", 24, Color("f8f9f2"))
	for event in _last_result.get("events", []):
		if not event is Dictionary:
			continue
		var when := "%.1fs" % float(event.get("elapsed_seconds", 0.0))
		if event.get("type") == "step_completed":
			_add_text("✓  %s  ·  Step %d — %s" % [when, int(event.get("step", 0)) + 1, event.get("detail", "")], 16, Color("a9dfba"))
		elif event.get("type") == "engine_started":
			_add_text("✓  %s  ·  %s" % [when, event.get("detail", "")], 16, Color("a9dfba"))
		else:
			_add_text("!  %s  ·  %s" % [when, event.get("detail", "")], 16, Color("ffd27e"))
	if not saved:
		_add_text("The attempt could not be saved on this Mac.", 17, Color("e5c98c"))
	else:
		var comparable := []
		for attempt in AttemptStore.load_attempts():
			if attempt is Dictionary and attempt.get("lesson_id") == _last_result.get("lesson_id") and attempt.get("scenario_version") == _last_result.get("scenario_version") and attempt.get("assessment_version") == _last_result.get("assessment_version") and attempt.get("vehicle_id") == _last_result.get("vehicle_id") and attempt.get("input_profile_id") == _last_result.get("input_profile_id"):
				comparable.append(attempt)
		_add_text("Comparable recent attempts: %d" % comparable.size(), 17, Color("a8c3b5"))
	var lesson := Catalog.get_lesson(_course_id, _lesson_id)
	_add_button("Drive again" if _course_id == "open_world" else "Retry lesson", _launch_lesson.bind(lesson.get("scene_path", ""))).grab_focus()
	_add_button("Back to courses", _show_courses)


func _go_back() -> void:
	match _page:
		"briefing":
			_show_lessons(_course_id)
		"lessons":
			_show_courses()
		"courses":
			_show_home()
		"result":
			_show_courses()
		"settings":
			_show_home()
