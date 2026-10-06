extends Node3D
## A compressed, connected Iloilo-inspired district for the first Open World pass.

const SHOPFRONT = preload("res://scenes/props/shopfront.tscn")
const PALM = preload("res://scenes/props/palm.tscn")
const STALL = preload("res://scenes/props/market_stall.tscn")
const ROAD_X := [-200.0, 0.0, 200.0]
const ROAD_Z := [-250.0, 0.0, 250.0]
const ROAD_WIDTH := 8.5
const START := Vector3(-201.8, 0.05, -225.0)
const DESTINATION := Vector3(211.0, 0.05, 221.0)
const DESTINATION_SIZE := Vector2(10.0, 13.0)


func _ready() -> void:
	_environment()
	_box(Vector3(530, 0.22, 640), Vector3(0, -0.16, 0), Color("728969"), true, "Ground")
	_build_roads()
	_build_plaza()
	_build_calle_real()
	_build_riverside()
	_build_neighborhood()
	_build_destination()
	_build_bounds()


func destination_contains_vehicle(vehicle: Node3D) -> bool:
	# The sedan's exterior footprint is about 1.8 by 3.95 metres.
	for local in [Vector3(-0.9, 0, -1.98), Vector3(0.9, 0, -1.98), Vector3(-0.9, 0, 1.98), Vector3(0.9, 0, 1.98)]:
		var point := vehicle.to_global(local)
		if absf(point.x - DESTINATION.x) > DESTINATION_SIZE.x * 0.5 or absf(point.z - DESTINATION.z) > DESTINATION_SIZE.y * 0.5:
			return false
	return true


func _environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("80bde8")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("f4e8cc")
	env.ambient_light_energy = 0.72
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, -31, 0)
	sun.light_energy = 1.48
	sun.shadow_enabled = true
	add_child(sun)


func _build_roads() -> void:
	for road_x in ROAD_X:
		_box(Vector3(ROAD_WIDTH, 0.09, 510), Vector3(road_x, -0.04, 0), Color("465057"), false)
		for edge in [-1.0, 1.0]:
			_box(Vector3(0.09, 0.015, 495), Vector3(road_x + edge * 4.04, 0.017, 0), Color("e7e8df"), false)
		for z in range(-238, 239, 12):
			if abs(z) < 13 or abs(z - 250) < 13 or abs(z + 250) < 13:
				continue
			_box(Vector3(0.12, 0.016, 4.4), Vector3(road_x, 0.018, z), Color("dfb849"), false)
	for road_z in ROAD_Z:
		_box(Vector3(410, 0.09, ROAD_WIDTH), Vector3(0, -0.035, road_z), Color("465057"), false)
		for edge in [-1.0, 1.0]:
			_box(Vector3(395, 0.015, 0.09), Vector3(0, 0.021, road_z + edge * 4.04), Color("e7e8df"), false)
		for x in range(-188, 189, 12):
			if abs(x) < 13 or abs(x - 200) < 13 or abs(x + 200) < 13:
				continue
			_box(Vector3(4.4, 0.016, 0.12), Vector3(x, 0.024, road_z), Color("dfb849"), false)
	# Broad sidewalks mark the road edges but do not block the destination bay.
	for x in ROAD_X:
		for side in [-1.0, 1.0]:
			if x == 200.0 and side > 0.0:
				continue
			_box(Vector3(2.0, 0.10, 474), Vector3(x + side * 5.45, -0.015, 0), Color("b7ad96"), false)
	for z in ROAD_Z:
		for side in [-1.0, 1.0]:
			_box(Vector3(374, 0.10, 2.0), Vector3(0, -0.015, z + side * 5.45), Color("b7ad96"), false)
	for x in ROAD_X:
		for z in ROAD_Z:
			for side in [-1.0, 1.0]:
				for stripe in 5:
					_box(Vector3(0.48, 0.014, 0.58), Vector3(x + side * (6.2 + stripe * 0.86), 0.03, z - 7.6), Color("f4f0df"), false)
	_build_roundabout()


func _build_roundabout() -> void:
	# The centre crossroad opens onto a ring around a collidable planted island.
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in 48:
		var a := float(index) * TAU / 48.0
		var b := float(index + 1) * TAU / 48.0
		for point in [Vector3(cos(a) * 5.8, 0.032, sin(a) * 5.8), Vector3(cos(a) * 10.0, 0.032, sin(a) * 10.0), Vector3(cos(b) * 5.8, 0.032, sin(b) * 5.8), Vector3(cos(a) * 10.0, 0.032, sin(a) * 10.0), Vector3(cos(b) * 10.0, 0.032, sin(b) * 10.0), Vector3(cos(b) * 5.8, 0.032, sin(b) * 5.8)]:
			tool.add_vertex(point)
	tool.generate_normals()
	var ring := MeshInstance3D.new()
	ring.mesh = tool.commit()
	var mat := _material(Color("465057"))
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ring.material_override = mat
	add_child(ring)
	var island := CylinderMesh.new()
	island.top_radius = 5.8
	island.bottom_radius = 5.8
	island.height = 0.25
	island.radial_segments = 48
	var island_visual := MeshInstance3D.new()
	island_visual.mesh = island
	island_visual.position.y = 0.12
	island_visual.material_override = _material(Color("67905a"))
	add_child(island_visual)
	var body := StaticBody3D.new()
	body.name = "RoundaboutIsland"
	body.position.y = 0.12
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 5.7
	shape.height = 0.25
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	var palm := PALM.instantiate()
	palm.position.y = 0.25
	add_child(palm)


func _build_plaza() -> void:
	# A paired church/plaza silhouette anchors the destination neighborhood.
	_box(Vector3(29, 0.12, 37), Vector3(231, -0.01, 198), Color("c0ad8b"), false)
	_box(Vector3(16, 10, 20), Vector3(239, 5, 194), Color("e4d5b1"), true, "MoloChurch")
	_box(Vector3(17, 0.65, 22), Vector3(239, 10.15, 194), Color("87715c"), false)
	_box(Vector3(13.8, 0.55, 0.52), Vector3(239, 7.1, 183.66), Color("a28a6e"), false)
	for x in [232.5, 245.5]:
		_box(Vector3(4.8, 18, 4.8), Vector3(x, 9.0, 184), Color("d6c29a"), false)
		for y in [6.8, 12.8, 18.2]:
			_box(Vector3(5.45, 0.42, 5.45), Vector3(x, y, 184), Color("927b61"), false)
		for y in [9.3, 14.9]:
			_box(Vector3(0.85, 2.4, 0.12), Vector3(x, y, 181.52), Color("3d5360"), false)
		_cone(2.55, 5.8, Vector3(x, 21.25, 184), Color("866e58"))
		_cone(0.33, 1.6, Vector3(x, 24.9, 184), Color("e1c895"))
	for x in [235.9, 239.0, 242.1]:
		_box(Vector3(1.7, 4.2, 0.16), Vector3(x, 3.5, 183.86), Color("3e5260"), false)
		_box(Vector3(1.95, 0.22, 0.22), Vector3(x, 5.68, 183.82), Color("b39977"), false)
	_box(Vector3(2.3, 0.65, 0.15), Vector3(239, 0.35, 183.70), Color("786755"), false)
	_cone(1.65, 0.12, Vector3(239, 8.15, 183.74), Color("50616b"))
	_sign("MOLO CHURCH", Vector3(220, 2.5, 180.5), PI)
	_box(Vector3(24, 0.12, 29), Vector3(232, -0.015, 232), Color("92a772"), false)
	for x in [222.0, 242.0]:
		for z in [221.0, 243.0]:
			var tree := PALM.instantiate()
			tree.position = Vector3(x, 0.05, z)
			add_child(tree)
	_sign("MOLO PLAZA", Vector3(221, 2.7, 223.5), PI)


func _build_calle_real() -> void:
	for index in 10:
		var center_x := -170.0 + float(index) * 16.5
		var shop := SHOPFRONT.instantiate()
		shop.palette_index = index % 4
		shop.position = Vector3(center_x, 0, 267)
		shop.rotation.y = PI
		add_child(shop)
		var stone := Color("e2d1ad") if index % 2 == 0 else Color("c8b89a")
		_box(Vector3(10.4, 0.42, 0.55), Vector3(center_x, 7.65, 263.55), stone, false)
		_box(Vector3(10.2, 0.24, 0.7), Vector3(center_x, 4.08, 262.85), Color("a78a70"), false)
		for offset in [-4.15, 0.0, 4.15]:
			_box(Vector3(0.43, 3.75, 0.58), Vector3(center_x + offset, 2.0, 262.72), stone, false)
	_sign("CALLE REAL", Vector3(-70, 4.7, 259.0), PI)
	for x in [-156.0, -92.0, -28.0]:
		var lamp := PALM.instantiate()
		lamp.position = Vector3(x, 0.05, 258)
		add_child(lamp)


func _build_riverside() -> void:
	# Water runs beneath three bridge crossings; the road remains continuous.
	_box(Vector3(500, 0.022, 21), Vector3(0, -0.026, 112), Color("4f9bb4"), false)
	for x in ROAD_X:
		_box(Vector3(ROAD_WIDTH, 0.08, 30), Vector3(x, 0.005, 112), Color("59636a"), false)
		for side in [-1.0, 1.0]:
			_box(Vector3(0.13, 0.75, 30), Vector3(x + side * 4.23, 0.47, 112), Color("bcc9c6"), false)
	_box(Vector3(480, 0.07, 4), Vector3(0, 0.02, 129), Color("bcaf96"), false)
	for x in range(-240, 241, 8):
		if minf(absf(float(x + 200)), minf(absf(float(x)), absf(float(x - 200)))) < 9.0:
			continue
		for z in [101.0, 123.0]:
			_box(Vector3(0.12, 1.05, 0.12), Vector3(float(x), 0.56, z), Color("627b7c"), false)
			_box(Vector3(7.9, 0.11, 0.11), Vector3(float(x) + 4.0, 1.02, z), Color("627b7c"), false)
	for x in [-145.0, -88.0, -32.0, 50.0, 112.0, 170.0]:
		var palm := PALM.instantiate()
		palm.position = Vector3(x, 0.08, 133)
		add_child(palm)
	_sign("ILOILO RIVER ESPLANADE", Vector3(72, 3.1, 138), PI)


func _build_neighborhood() -> void:
	# Put a compact local shopping street in the first forward view from A.
	# Shopfronts remain beyond the sidewalks and clear of the two travel lanes.
	for side in [-1.0, 1.0]:
		for index in 8:
			var shop := SHOPFRONT.instantiate()
			shop.palette_index = (index + (0 if side < 0.0 else 2)) % 4
			shop.position = Vector3(-200.0 + side * 12.0, 0, -207.0 + float(index) * 13.5)
			shop.rotation.y = PI / 2.0 if side < 0.0 else -PI / 2.0
			add_child(shop)
	_sign("ILOILO MARKET", Vector3(-192.2, 5.2, -136.0), -PI / 2.0)
	for index in 9:
		var shop := SHOPFRONT.instantiate()
		shop.palette_index = (index + 2) % 4
		shop.position = Vector3(-145.0 + float(index) * 32.0, 0, -268)
		add_child(shop)
	for index in 6:
		var shop := SHOPFRONT.instantiate()
		shop.palette_index = index % 4
		shop.position = Vector3(216, 0, -212.0 + float(index) * 42.0)
		shop.rotation.y = -PI / 2.0
		add_child(shop)
	var vendor_sites := [Vector3(-196.0, 0, -103), Vector3(196.0, 0, -74), Vector3(196.0, 0, -52)]
	for index in vendor_sites.size():
		var at: Vector3 = vendor_sites[index]
		var vendor := STALL.instantiate()
		vendor.position = at
		add_child(vendor)
		_box(Vector3(2.35, 1.4, 1.5), at + Vector3(0, 0.8, 0), Color(0, 0, 0, 0), true, "VendorObstacle%d" % index)


func _build_destination() -> void:
	_box(Vector3(DESTINATION_SIZE.x + 1.0, 0.07, DESTINATION_SIZE.y + 1.0), DESTINATION + Vector3(0, -0.035, 0), Color("525b5d"), false)
	var paint := Color("f4d65e")
	for edge in [-1.0, 1.0]:
		_box(Vector3(0.18, 0.022, DESTINATION_SIZE.y), DESTINATION + Vector3(edge * DESTINATION_SIZE.x * 0.5, 0.031, 0), paint, false)
		_box(Vector3(DESTINATION_SIZE.x, 0.022, 0.18), DESTINATION + Vector3(0, 0.031, edge * DESTINATION_SIZE.y * 0.5), paint, false)
	# A roadside venue board is readable from the cockpit without a HUD waypoint.
	_box(Vector3(0.18, 1.75, 5.5), Vector3(219.0, 3.45, 221), Color("223f4b"), false)
	for z in [218.9, 223.1]:
		_box(Vector3(0.2, 2.65, 0.2), Vector3(219.0, 1.32, z), Color("566a6b"), false)
	var venue_label := Label3D.new()
	venue_label.text = "MOLO PLAZA"
	venue_label.font_size = 110
	venue_label.pixel_size = 0.006
	venue_label.modulate = Color("f9e5a7")
	venue_label.double_sided = true
	venue_label.position = Vector3(218.86, 3.45, 221)
	venue_label.rotation.y = -PI / 2.0
	add_child(venue_label)


func _build_bounds() -> void:
	for x in [-264.0, 264.0]:
		_box(Vector3(0.6, 1.4, 640), Vector3(x, 0.7, 0), Color("54745e"), true, "Boundary")
	for z in [-318.0, 318.0]:
		_box(Vector3(530, 1.4, 0.6), Vector3(0, 0.7, z), Color("54745e"), true, "Boundary")


func _sign(words: String, at: Vector3, yaw: float) -> void:
	_box(Vector3(0.10, 2.4, 0.10), at + Vector3(0, -1.0, 0), Color("465257"), false)
	var label := Label3D.new()
	label.text = words
	label.font_size = 52
	label.pixel_size = 0.0024
	label.modulate = Color("f8e7ad")
	label.double_sided = true
	label.position = at
	label.rotation.y = yaw
	add_child(label)


func _cone(radius: float, height: float, at: Vector3, color: Color) -> void:
	var cone := CylinderMesh.new()
	cone.top_radius = 0.08
	cone.bottom_radius = radius
	cone.height = height
	cone.radial_segments = 8
	var visual := MeshInstance3D.new()
	visual.mesh = cone
	visual.position = at
	visual.material_override = _material(color)
	add_child(visual)


func _box(size: Vector3, at: Vector3, color: Color, collider: bool, box_name: String = "") -> void:
	if color.a > 0.0:
		var visual := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = size
		visual.mesh = mesh
		visual.material_override = _material(color)
		visual.position = at
		add_child(visual)
	if collider:
		var body := StaticBody3D.new()
		body.name = box_name
		body.position = at
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
		add_child(body)


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.91
	return material
