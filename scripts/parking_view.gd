extends Control
## A teaching diagram of the actual car and bay, not a replacement driving camera.
var lesson: Node3D

func _point(at: Vector2) -> Vector2:
	return Vector2(24, 148) + Vector2((at.x + 16.0) * 12.0, -at.y * 10.0)

func _draw() -> void:
	if lesson == null or lesson.sedan == null:
		return
	var font := ThemeDB.fallback_font
	draw_style_box(_panel(), Rect2(Vector2.ZERO, size))
	draw_string(font, Vector2(14, 24), "BACKING BAY • POSITION GUIDE", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("f2c847"))
	var bay: Rect2 = lesson.BAY
	var rect := Rect2(_point(Vector2(bay.position.x, bay.end.y)), Vector2(bay.size.x * 12, bay.size.y * 10))
	var inside: bool = lesson._parked_pose()
	draw_rect(rect, Color("305c52") if inside else Color("35424a"))
	draw_rect(rect, Color("a4dfbb") if inside else Color("f2c847"), false, 2.0)
	draw_string(font, rect.position + Vector2(38, 35), "BAY", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("e2dec8"))
	var car: Node3D = lesson.sedan
	var corners := PackedVector2Array()
	for corner in [Vector3(-1.4, 0, -2.08), Vector3(1.4, 0, -2.08), Vector3(1.4, 0, 2.08), Vector3(-1.4, 0, 2.08)]:
		var at: Vector3 = car.to_global(corner)
		corners.append(_point(Vector2(at.x, at.z)))
	draw_colored_polygon(corners, Color("62b4b7"))
	corners.append(corners[0])
	draw_polyline(corners, Color("ecf4e9"), 1.5, true)
	var nose: Vector3 = car.to_global(Vector3(0, 0, 1.8))
	var centre := _point(Vector2(car.global_position.x, car.global_position.z))
	draw_line(centre, _point(Vector2(nose.x, nose.z)), Color("ffffff"), 3, true)
	draw_circle(_point(Vector2(nose.x, nose.z)), 3, Color("ffffff"))
	draw_string(font, Vector2(14, 206), "Whole car inside • facing out" if inside else "Check mirrors • back at walking pace", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("a4dfbb") if inside else Color("e2dec8"))

func _panel() -> StyleBoxFlat:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.04, 0.09, 0.13, 0.92)
	panel.set_corner_radius_all(6)
	return panel
