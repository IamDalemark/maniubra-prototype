extends Node3D
## Original, fictional Iloilo-inspired palengke. One unit is one metre.

const SHOP = preload("res://scenes/props/shopfront.tscn")
const PALM = preload("res://scenes/props/palm.tscn")
const TRICYCLE = preload("res://scenes/props/tricycle.tscn")
const CONE = preload("res://scenes/props/traffic_cone.tscn")
const START := Vector3(-1.9, 0.05, -63.0)
const ROAD_WIDTH := 7.6
const CROSSWALK_Z := 36.0
const STALL_NAMES := ["BATCHOY", "PANCIT MAMI", "PRUTAS", "SIOMAI", "GULAY", "TINAPAY", "ISDA", "BANANA CUE", "BIBINGKA", "TAHO", "SARI-SARI", "UKAY-UKAY"]
const STALL_Z := [-43.0, -35.0, -26.0, -18.0, -9.0, 1.0, 8.0, 19.0, 24.0, 31.0, 43.0, 49.0]
const PALETTE := [Color("c55743"), Color("e4b848"), Color("397c75"), Color("507eb0")]
var _materials: Dictionary = {}


func _ready() -> void:
	_environment()
	_box(self, Vector3(106, 0.3, 190), Vector3(24, -0.20, 0), Color("a3916b"), "Ground")
	_roads()
	_buildings()
	for site in stall_sites():
		_stall(site)
	_market_hall()
	_street_details()
	_bounds()


static func stall_sites() -> Array[Dictionary]:
	var sites: Array[Dictionary] = []
	for index in STALL_NAMES.size():
		var side := -1.0 if index % 2 == 0 else 1.0
		sites.append({"id": "stall_%02d" % index, "title": STALL_NAMES[index], "position": Vector3(side * (4.15 if index % 3 == 0 else 4.05), 0.05, STALL_Z[index]), "side": side, "palette": index % 4})
	return sites


static func centreline() -> PackedVector3Array:
	var path := PackedVector3Array()
	for z in range(-60, 61, 20):
		path.append(Vector3(0, 0.05, z))
	_arc(path, Vector2(12, 60), PI, PI * 0.5)
	path.append(Vector3(24, 0.05, 72))
	path.append(Vector3(36, 0.05, 72))
	_arc(path, Vector2(36, 60), PI * 0.5, 0)
	for z in range(40, -61, -20):
		path.append(Vector3(48, 0.05, z))
	_arc(path, Vector2(36, -60), 0, -PI * 0.5)
	path.append(Vector3(24, 0.05, -72))
	path.append(Vector3(12, 0.05, -72))
	_arc(path, Vector2(12, -60), -PI * 0.5, -PI)
	path.remove_at(path.size() - 1) # The ribbon/path wraps to its first point.
	return path


static func _arc(path: PackedVector3Array, centre: Vector2, from: float, to: float) -> void:
	for step in range(1, 7):
		var angle := lerpf(from, to, float(step) / 6.0)
		path.append(Vector3(centre.x + cos(angle) * 12.0, 0.05, centre.y + sin(angle) * 12.0))


static func lane_path(reverse := false) -> PackedVector3Array:
	var path := centreline()
	if reverse:
		path.reverse()
	var lane := PackedVector3Array()
	for index in path.size():
		lane.append(path[index] + _right(path, index) * 1.9)
	return lane


static func _right(path: PackedVector3Array, index: int) -> Vector3:
	var direction := (path[(index + 1) % path.size()] - path[posmod(index - 1, path.size())]).normalized()
	return Vector3(-direction.z, 0, direction.x)


static func nearest_index(path: PackedVector3Array, at: Vector3) -> int:
	var best := 0
	for index in path.size():
		if path[index].distance_squared_to(at) < path[best].distance_squared_to(at):
			best = index
	return best


static func counterflow_direction(at: Vector3, forward: Vector3) -> int:
	# Only the straight, crowded frontage has this authored encounter.
	if absf(at.z) > 53.0 or absf(at.x) > ROAD_WIDTH * 0.5:
		return 0
	if forward.z > 0.75 and at.x > 0.55:
		return 1
	if forward.z < -0.75 and at.x < -0.55:
		return -1
	return 0


func _environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("9acbdc")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("fff0d4")
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_energy = 1.5
	sun.shadow_enabled = true
	add_child(sun)


func _roads() -> void:
	var path := centreline()
	_ribbon(path, ROAD_WIDTH, 0, 0.006, Color("4b5154"), "MarketRoad")
	for side in [-1.0, 1.0]:
		_ribbon(path, 3.8, side * 5.9, 0.032, Color("b7b09d"), "Sidewalk")
		_ribbon(path, 0.08, side * 3.65, 0.028, Color("e8e0c8"), "EdgePaint")
	for index in path.size():
		var start := path[index]
		var end := path[(index + 1) % path.size()]
		var length := start.distance_to(end)
		var direction := (end - start).normalized()
		for distance in range(0, int(length), 5):
			var mark := _box(self, Vector3(0.10, 0.014, minf(2.3, length - distance)), start + direction * (distance + 1.15) + Vector3(0, -0.016, 0), Color("e1bb53"))
			mark.rotation.y = atan2(direction.x, direction.z)
	for stripe in 7:
		_box(self, Vector3(7.1, 0.014, 0.48), Vector3(0, 0.03, CROSSWALK_Z + (stripe - 3) * 0.75), Color("f2eddb"))
	# Shallow visual patches communicate a worn road without destabilising the car.
	for at in [Vector3(-2.4, 0.032, -12), Vector3(2.8, 0.032, 20), Vector3(49.8, 0.032, -30)]:
		_box(self, Vector3(0.85, 0.012, 1.25), at, Color("333e40"))


func _ribbon(path: PackedVector3Array, width: float, offset: float, height: float, color: Color, label: String) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in path.size():
		var next := (index + 1) % path.size()
		var a := path[index] + _right(path, index) * (offset - width * 0.5)
		var b := path[index] + _right(path, index) * (offset + width * 0.5)
		var c := path[next] + _right(path, next) * (offset - width * 0.5)
		var d := path[next] + _right(path, next) * (offset + width * 0.5)
		for point in [a, c, b, b, c, d]:
			point.y = height
			surface.add_vertex(point)
	surface.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.name = label
	mesh.mesh = surface.commit()
	mesh.material_override = _material(color)
	add_child(mesh)


func _buildings() -> void:
	for side in [-1.0, 1.0]:
		for index in 11:
			var shop := SHOP.instantiate()
			shop.position = Vector3(side * 11.6, 0, -53.0 + index * 10.5)
			shop.rotation.y = -side * PI * 0.5
			shop.palette_index = (index + (1 if side > 0 else 0)) % 4
			add_child(shop)
			_box(self, Vector3(6.5, 6.9, 9.8), shop.position + Vector3(0, 3.45, 0), Color(0, 0, 0, 0), "ShopCollision")
			# Corrugated metal roof and small window air conditioners.
			for rib in 10:
				_box(self, Vector3(6.8, 0.07, 0.055), shop.position + Vector3(0, 7.65, -4.5 + rib), Color("809092"))
			_box(self, Vector3(0.50, 0.42, 0.95), shop.position + Vector3(-side * 3.4, 4.45, -2.2), Color("c5c8bc"))
			if index % 3 == 1:
				_laundry(Vector3(side * 7.9, 4.1, shop.position.z))
	for index in 9:
		var shop := SHOP.instantiate()
		shop.palette_index = (index + 2) % 4
		shop.position = Vector3(60.0, 0, -45 + index * 11)
		shop.rotation.y = -PI * 0.5
		add_child(shop)
		_box(self, Vector3(6.5, 6.9, 9.8), shop.position + Vector3(0, 3.45, 0), Color(0, 0, 0, 0), "ShopCollision")


func _stall(site: Dictionary) -> void:
	var stall := Node3D.new()
	stall.name = site.id
	stall.position = site.position
	add_child(stall)
	var side: float = site.side
	var color: Color = PALETTE[site.palette]
	_box(stall, Vector3(1.8, 0.8, 2.65), Vector3(0, 0.52, 0), color, "VendorObstacle_" + site.id)
	_box(stall, Vector3(1.93, 0.13, 2.8), Vector3(0, 1.0, 0), Color("8e7152"))
	for z in [-1.2, 1.2]:
		_box(stall, Vector3(0.10, 2.5, 0.10), Vector3(side * 0.82, 1.3, z), Color("d6c5a0"))
	# Tilted tarpaulin, striped edging, and a sign facing the departure approach.
	var roof := _box(stall, Vector3(2.5, 0.08, 3.25), Vector3(0, 2.65, 0), color)
	roof.rotation.z = side * 0.13
	_box(stall, Vector3(0.07, 0.26, 3.25), Vector3(-side * 1.22, 2.49, 0), Color("e9d38f"))
	_box(stall, Vector3(1.6, 0.48, 0.07), Vector3(0, 1.65, -1.39), Color("f2d5a0"))
	_text(stall, site.title, Vector3(0, 1.65, -1.44), PI, 0.0032, Color("6d392d"))
	for item in 8:
		var at := Vector3(-0.55 + (item % 2) * 0.70, 1.2, -0.94 + floori(float(item) / 2) * 0.62)
		_box(stall, Vector3(0.62, 0.20, 0.52), at + Vector3(0, -0.03, 0), Color("796044"))
		for piece in 3:
			_sphere(stall, Vector3(0.20, 0.18, 0.20), at + Vector3(-0.19 + piece * 0.19, 0.12, 0), Color("cf8f37") if item % 2 == 0 else Color("73a14c"))
	for bag in 3:
		_sphere(stall, Vector3(0.55, 0.8, 0.5), Vector3(side * 3.2, 0.4, -0.8 + bag * 0.65), Color("d6c09a"))
	_box(stall, Vector3(0.55, 0.50, 0.60), Vector3(side * 0.25, 0.27, 2.0), Color("587957"))


func _market_hall() -> void:
	_box(self, Vector3(21, 5.8, 61), Vector3(26, 2.9, 3), Color("c7b79c"), "MarketHall")
	_box(self, Vector3(24, 0.18, 64), Vector3(26, 6.0, 3), Color("6b8981"))
	for z in range(-25, 30, 8):
		_box(self, Vector3(0.08, 3.5, 5.7), Vector3(15.43, 2.0, z), Color("485a54"))
		_box(self, Vector3(2.4, 0.12, 6.5), Vector3(14.4, 3.85, z), Color("b45e4c"))
	_text(self, "PALENGKE SAN ISIDRO", Vector3(15.35, 5.0, -10), -PI * 0.5, 0.008, Color("fff0cc"))
	# A gateway above the road is an unmistakable local establishing shot.
	for side in [-1.0, 1.0]:
		_box(self, Vector3(0.36, 5.7, 0.36), Vector3(side * 6.9, 2.85, -45), Color("d1bfa0"), "MarketGatePost")
	_box(self, Vector3(14.2, 1.45, 0.32), Vector3(0, 5.7, -45), Color("39746c"))
	_text(self, "PALENGKE  •  ILOILO", Vector3(0, 5.87, -45.19), PI, 0.0066, Color("ffe4a0"))
	_text(self, "BATCHOY  •  PRUTAS  •  GULAY", Vector3(0, 5.38, -45.20), PI, 0.0033, Color("fff1db"))
	for index in 12:
		_box(self, Vector3(0.60, 0.14, 0.03), Vector3(-6.25 + index * 1.12, 4.88, -45), PALETTE[index % 4])


func _street_details() -> void:
	for z in [-48.0, -18.0, 12.0, 42.0]:
		for side in [-1.0, 1.0]:
			var at := Vector3(side * 7.1, 0, z)
			_box(self, Vector3(0.24, 8.5, 0.24), at + Vector3(0, 4.25, 0), Color("777d72"), "UtilityPole")
			_box(self, Vector3(0.14, 0.15, 2.2), at + Vector3(0, 7.5, 0), Color("605d50"))
			for wire in 3:
				_wire(at + Vector3(0, 7.55 + wire * 0.23, -0.7 + wire * 0.7), at + Vector3(0, 7.55 + wire * 0.23, 30 - 0.7 + wire * 0.7))
		_wire(Vector3(-7.1, 7.8, z), Vector3(7.1, 7.8, z))
	for z in [-38.0, 5.0, 47.0]:
		for index in 12:
			var x := -6.5 + index * 1.15
			var flag := _box(self, Vector3(0.5, 0.65, 0.025), Vector3(x, 4.8 - sin(float(index) / 11.0 * PI) * 0.65, z), PALETTE[index % 4])
			flag.rotation.z = 0.10 if index % 2 == 0 else -0.12
	# Philippine flag colours on a small shop flag, independent of branding.
	_box(self, Vector3(1.0, 0.30, 0.02), Vector3(-7.2, 4.5, -45), Color("304f98"))
	_box(self, Vector3(1.0, 0.30, 0.02), Vector3(-7.2, 4.2, -45), Color("c85146"))
	_box(self, Vector3(0.25, 0.6, 0.025), Vector3(-7.64, 4.35, -45.02), Color("f4edd6"))
	for at in [Vector3(-4.4, 0, -2), Vector3(4.4, 0, 13), Vector3(51.7, 0, -17)]:
		_box(self, Vector3(0.60, 0.65, 1.7), at + Vector3(0, 0.42, 0), Color("8f6344"), "VendorObstacle_Cart")
		_box(self, Vector3(0.85, 0.09, 1.9), at + Vector3(0, 0.82, 0), Color("cca05c"))
	for z in [-31.0, -28.5, -26.0, -23.5]:
		var cone := CONE.instantiate()
		cone.position = Vector3(51.1, 0.05, z)
		add_child(cone)
	_box(self, Vector3(0.5, 0.7, 4.0), Vector3(52, 0.4, -28), Color("d8b34e"), "VendorObstacle_Roadworks")
	_text(self, "INGAT!\nROAD WORK", Vector3(52, 1.45, -31), PI, 0.0035, Color("463c2d"))
	var parked := TRICYCLE.instantiate()
	parked.position = Vector3(4.7, 0, -11)
	parked.rotation.y = PI
	add_child(parked)
	_box(self, Vector3(1.5, 1.6, 2.2), parked.position + Vector3(0, 0.8, 0), Color(0, 0, 0, 0), "VendorObstacle_ParkedTricycle")
	for at in [Vector3(-7, 0, -68), Vector3(40, 0, 56), Vector3(54, 0, 63), Vector3(55, 0, -60)]:
		var palm := PALM.instantiate()
		palm.position = at
		add_child(palm)
	_text(self, "TRICYCLE TERMINAL", Vector3(7.6, 3.2, -11), -PI * 0.5, 0.004, Color("f1ddb0"))
	_text(self, "Dahan-dahan\nMaraming tao", Vector3(-5.9, 2.2, -48), PI, 0.004, Color("f9e6b8"))


func _laundry(at: Vector3) -> void:
	_wire(at + Vector3(0, 0.5, -2), at + Vector3(0, 0.5, 2))
	for item in 4:
		_box(self, Vector3(0.06, 0.9, 0.60), at + Vector3(0, 0, -1.3 + item * 0.85), PALETTE[item])


func _wire(start: Vector3, finish: Vector3) -> void:
	var length := start.distance_to(finish)
	for segment in 6:
		var a := start.lerp(finish, float(segment) / 6.0)
		var b := start.lerp(finish, float(segment + 1) / 6.0)
		a.y -= sin(float(segment) / 6.0 * PI) * length * 0.018
		b.y -= sin(float(segment + 1) / 6.0 * PI) * length * 0.018
		var wire := _box(self, Vector3(0.025, 0.025, a.distance_to(b)), (a + b) * 0.5, Color("333b3a"))
		wire.look_at(b, Vector3.UP)


func _bounds() -> void:
	for x in [-26.0, 74.0]:
		_box(self, Vector3(0.7, 2.0, 181), Vector3(x, 1.0, 0), Color("827e6a"), "Boundary")
	for z in [-91.0, 91.0]:
		_box(self, Vector3(101, 2.0, 0.7), Vector3(24, 1.0, z), Color("827e6a"), "Boundary")


func _box(parent: Node3D, size: Vector3, at: Vector3, color: Color, collider := "") -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	if color.a > 0:
		var mesh := BoxMesh.new()
		mesh.size = size
		visual.mesh = mesh
		visual.material_override = _material(color)
		visual.position = at
		parent.add_child(visual)
	if not collider.is_empty():
		var body := StaticBody3D.new()
		body.name = collider
		body.position = at
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
		parent.add_child(body)
	if color.a == 0:
		visual.free()
		return null
	return visual


func _sphere(parent: Node3D, size: Vector3, at: Vector3, color: Color) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 8
	mesh.rings = 4
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.scale = size
	visual.position = at
	visual.material_override = _material(color)
	parent.add_child(visual)


func _text(parent: Node3D, value: String, at: Vector3, angle: float, size: float, color: Color) -> void:
	var label := Label3D.new()
	label.text = value
	label.font_size = 64
	label.pixel_size = size
	label.modulate = color
	label.outline_modulate = Color("443b31")
	label.outline_size = 4
	label.position = at
	label.rotation.y = angle
	parent.add_child(label)


func _material(color: Color) -> StandardMaterial3D:
	if not _materials.has(color):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.9
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_materials[color] = material
	return _materials[color]
