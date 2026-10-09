extends Node3D
## Reusable, game-native 3D streetscape assets. These are visual props, not NPCs.

@export var kind := "shopfront"
@export var palette_index := 0


func _ready() -> void:
	match kind:
		"shopfront": _shopfront()
		"streetlamp": _streetlamp()
		"market_stall": _market_stall()
		"palm": _palm()
		"jeepney": _jeepney()
		"tricycle": _tricycle()
		"motorcycle": _motorcycle()
		_: push_error("Unknown city prop: " + kind)


func _shopfront() -> void:
	var plaster: Color = [Color("d9c9ad"), Color("c9d3c7"), Color("d9bfa9"), Color("c9d1d4")][palette_index % 4]
	var trim := Color("f5e9cf")
	var dark := Color("293d4a")
	var awning: Color = [Color("bd5c45"), Color("326f62"), Color("b88a39"), Color("4e6d96")][palette_index % 4]
	_box(Vector3(9.8, 7.1, 6.6), Vector3(0, 3.55, 0), plaster)
	_box(Vector3(10.25, 0.30, 7.05), Vector3(0, 7.21, 0), Color("534f4c"))
	_box(Vector3(10.10, 0.16, 6.90), Vector3(0, 7.45, 0), Color("b8a990"))
	_box(Vector3(10.1, 0.34, 0.28), Vector3(0, 3.27, 3.43), trim)
	_box(Vector3(10.0, 0.20, 0.42), Vector3(0, 0.18, 3.53), Color("7a756d"))
	for x in [-4.35, -1.45, 1.45, 4.35]:
		_box(Vector3(0.27, 3.1, 0.36), Vector3(x, 1.57, 3.51), trim)
		_box(Vector3(0.52, 0.18, 0.48), Vector3(x, 3.07, 3.52), Color("e8d9bd"))
	for x in [-2.9, 0.0, 2.9]:
		_box(Vector3(2.55, 2.30, 0.08), Vector3(x, 1.64, 3.38), dark)
		_box(Vector3(2.34, 2.08, 0.045), Vector3(x, 1.64, 3.44), Color("55717b"), 0.16)
		_box(Vector3(0.07, 2.2, 0.09), Vector3(x, 1.64, 3.49), Color("c9c8b2"))
		_box(Vector3(2.53, 0.12, 0.16), Vector3(x, 2.75, 3.53), trim)
		_box(Vector3(2.25, 0.32, 0.13), Vector3(x, 0.72, 3.53), Color("aa8764"))
	for x in [-3.55, -1.18, 1.18, 3.55]:
		_box(Vector3(1.55, 1.72, 0.10), Vector3(x, 5.30, 3.37), dark)
		_box(Vector3(1.37, 1.54, 0.045), Vector3(x, 5.30, 3.44), Color("7895a0"), 0.15)
		_box(Vector3(0.08, 1.70, 0.13), Vector3(x, 5.30, 3.49), trim)
		_box(Vector3(1.66, 0.11, 0.14), Vector3(x, 6.18, 3.52), trim)
		_box(Vector3(1.74, 0.12, 0.22), Vector3(x, 4.38, 3.60), Color("968069"))
	_box(Vector3(9.7, 0.12, 1.15), Vector3(0, 3.20, 4.00), awning)
	_box(Vector3(9.7, 0.18, 0.13), Vector3(0, 3.07, 4.51), Color("e9d59c"))
	for x in [-3.55, -1.18, 1.18, 3.55]:
		_box(Vector3(0.23, 0.32, 0.87), Vector3(x, 3.05, 4.01), trim)
	_box(Vector3(4.0, 0.65, 0.15), Vector3(0, 3.77, 3.54), Color("1d4449"))
	_text(["SARI-SARI", "PANADERIA", "KAPE", "MARKET"][palette_index % 4], Vector3(0, 3.62, 3.65), 64, Color("f4d98a"))
	for x in [-3.7, 3.7]:
		_box(Vector3(0.16, 1.9, 0.16), Vector3(x, 1.0, 4.66), Color("403d3c"))
		_sphere(Vector3(0.35, 0.62, 0.35), Vector3(x, 1.95, 4.66), Color("46795a"))


func _streetlamp() -> void:
	var metal := Color("222f35")
	_cylinder(0.12, 5.8, Vector3(0, 2.9, 0), metal)
	_cylinder(0.27, 0.14, Vector3(0, 0.12, 0), metal)
	_box(Vector3(0.13, 0.13, 1.85), Vector3(0, 5.72, 0.87), metal)
	_box(Vector3(0.55, 0.14, 0.62), Vector3(0, 5.54, 1.75), metal)
	_box(Vector3(0.41, 0.11, 0.49), Vector3(0, 5.46, 1.75), Color("ffe5a3"), 0.3, true)
	_box(Vector3(0.55, 0.07, 0.66), Vector3(0, 5.39, 1.75), metal)


func _market_stall() -> void:
	var red := Color("c55643")
	var yellow := Color("e9b94e")
	_box(Vector3(2.35, 0.25, 1.25), Vector3(0, 1.08, 0), Color("866449"))
	_box(Vector3(2.20, 0.78, 1.05), Vector3(0, 0.58, 0), Color("3d6b66"))
	for x in [-0.93, 0.93]:
		for z in [-0.43, 0.43]:
			_box(Vector3(0.12, 0.95, 0.12), Vector3(x, 0.49, z), Color("49372c"))
	_cylinder(0.055, 2.60, Vector3(0, 2.36, 0), Color("e8dfc6"))
	for i in 8:
		var angle_a := float(i) * TAU / 8.0
		var angle_b := float(i + 1) * TAU / 8.0
		var a := Vector3(cos(angle_a) * 1.73, 2.76, sin(angle_a) * 1.73)
		var b := Vector3(cos(angle_b) * 1.73, 2.76, sin(angle_b) * 1.73)
		_triangle(Vector3(0, 3.28, 0), a, b, red if i % 2 == 0 else yellow)
	for i in 8:
		var x := -0.84 + float(i % 4) * 0.55
		var z := -0.28 + float(floori(float(i) / 4.0)) * 0.54
		_sphere(Vector3(0.22, 0.18, 0.22), Vector3(x, 1.30, z), Color("c78b35") if i % 2 == 0 else Color("79a04f"))


func _palm() -> void:
	var trunk := Color("806047")
	for i in 8:
		var h := 0.61
		var radius := 0.28 - float(i) * 0.017
		_cylinder(radius, h, Vector3(0, 0.34 + float(i) * 0.59, 0), trunk)
		_cylinder(radius + 0.035, 0.09, Vector3(0, 0.61 + float(i) * 0.59, 0), Color("9d7650"))
	for i in 9:
		var frond := Node3D.new()
		frond.position.y = 4.92
		frond.rotation.y = float(i) * TAU / 9.0
		add_child(frond)
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		var points := [Vector3(0, 0.16, 0.0), Vector3(-0.35, 0.34, 0.75), Vector3(0.35, 0.34, 0.75), Vector3(-0.43, 0.11, 1.48), Vector3(0.43, 0.11, 1.48), Vector3(-0.24, -0.28, 2.36), Vector3(0.24, -0.28, 2.36), Vector3(0, -0.66, 3.02)]
		for tri in [[0, 1, 2], [1, 3, 2], [2, 3, 4], [3, 5, 4], [4, 5, 6], [5, 7, 6]]:
			for vertex_index in tri:
				tool.add_vertex(points[vertex_index])
		tool.generate_normals()
		var mesh := MeshInstance3D.new()
		mesh.mesh = tool.commit()
		var leaf := _material(Color("3c8057") if i % 2 == 0 else Color("558e50"))
		leaf.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh.material_override = leaf
		frond.add_child(mesh)


func _jeepney() -> void:
	var blue := Color("285d91")
	var yellow := Color("edb62d")
	var chrome := Color("c6ced1")
	_box(Vector3(2.18, 0.96, 5.88), Vector3(0, 1.05, 0), blue, 0.47)
	_box(Vector3(2.08, 0.74, 5.2), Vector3(0, 1.89, -0.19), blue, 0.42)
	_box(Vector3(2.24, 0.15, 5.38), Vector3(0, 2.34, -0.12), chrome, 0.34)
	_box(Vector3(2.24, 0.13, 5.6), Vector3(0, 2.49, -0.12), yellow)
	for side in [-1.0, 1.0]:
		var x: float = side * 1.11
		_box(Vector3(0.055, 0.65, 4.65), Vector3(x, 1.87, -0.22), Color("173947"), 0.12)
		for z in [-1.86, -0.88, 0.10, 1.08]:
			_box(Vector3(0.09, 0.74, 0.09), Vector3(x, 1.88, z), chrome, 0.28)
		_box(Vector3(0.045, 0.19, 5.65), Vector3(side * 1.125, 1.19, 0), yellow)
		for z in [-1.91, 1.91]:
			var tire := _cylinder(0.43, 0.22, Vector3(side * 1.08, 0.43, z), Color("20262a"))
			tire.rotation.z = PI / 2.0
			var hub := _cylinder(0.23, 0.24, Vector3(side * 1.20, 0.43, z), chrome, 0.3)
			hub.rotation.z = PI / 2.0
	_box(Vector3(1.89, 0.60, 0.08), Vector3(0, 1.88, 2.86), Color("274d5e"), 0.11)
	_box(Vector3(1.46, 0.42, 0.08), Vector3(0, 1.93, 2.92), Color("688895"), 0.15)
	_box(Vector3(1.72, 0.36, 0.09), Vector3(0, 1.40, 2.97), chrome, 0.27)
	for x in [-0.67, -0.33, 0.0, 0.33, 0.67]:
		_box(Vector3(0.055, 0.28, 0.10), Vector3(x, 1.39, 3.02), Color("293b43"), 0.4)
	for x in [-0.80, 0.80]:
		_sphere(Vector3(0.24, 0.24, 0.12), Vector3(x, 1.37, 3.03), Color("ffe3a5"), 0.22, true)
	_box(Vector3(2.24, 0.16, 0.21), Vector3(0, 0.63, 3.08), chrome, 0.31)
	_box(Vector3(1.82, 0.31, 0.08), Vector3(0, 2.08, -3.00), Color("142f41"))
	_text("JEEPNEY", Vector3(0, 2.00, 3.10), 43, Color("f8d24b"))


func _tricycle() -> void:
	var body := Color("287971")
	var canopy := Color("e7c457")
	var metal := Color("ccd2c8")
	# Motorcycle and passenger sidecar remain separate silhouettes at driving distance.
	_box(Vector3(0.48, 0.38, 1.75), Vector3(0.52, 0.75, 0.02), body)
	_box(Vector3(0.50, 0.25, 0.54), Vector3(0.52, 1.04, -0.32), Color("242c30"))
	_box(Vector3(0.64, 0.34, 0.24), Vector3(0.52, 0.86, 0.92), metal, 0.36)
	_box(Vector3(0.92, 0.055, 0.08), Vector3(0.52, 1.22, 0.62), Color("2a3031"))
	for z in [-0.78, 0.83]:
		var tire := _cylinder(0.34, 0.16, Vector3(0.52, 0.35, z), Color("1c2327"))
		tire.rotation.z = PI / 2.0
		var hub := _cylinder(0.17, 0.18, Vector3(0.62, 0.35, z), metal, 0.35)
		hub.rotation.z = PI / 2.0
	_box(Vector3(1.12, 0.58, 1.65), Vector3(-0.47, 0.77, -0.06), body)
	_box(Vector3(1.22, 0.12, 1.87), Vector3(-0.47, 1.68, -0.07), canopy)
	for x in [-0.99, 0.05]:
		for z in [-0.77, 0.70]:
			_box(Vector3(0.09, 0.60, 0.09), Vector3(x, 1.36, z), metal, 0.35)
	for z in [-0.69, 0.46]:
		_box(Vector3(0.06, 0.55, 0.65), Vector3(-1.05, 1.34, z), Color("284b55"), 0.16)
	_box(Vector3(0.86, 0.51, 0.05), Vector3(-0.47, 1.35, 0.78), Color("63898a"), 0.17)
	_box(Vector3(0.82, 0.30, 0.06), Vector3(-0.47, 0.79, 0.80), canopy)
	var side_wheel := _cylinder(0.31, 0.18, Vector3(-0.86, 0.32, -0.52), Color("1c2327"))
	side_wheel.rotation.z = PI / 2.0
	_sphere(Vector3(0.18, 0.18, 0.12), Vector3(0.52, 0.91, 1.06), Color("ffe6ab"), 0.2, true)
	_text("TRICYCLE", Vector3(-0.47, 1.63, 0.87), 26, Color("173b43"))


func _motorcycle() -> void:
	var paint: Color = [Color("bd5141"), Color("376f9b")][palette_index % 2]
	var metal := Color("9da8a9")
	var dark := Color("252e32")
	_box(Vector3(0.28, 0.16, 1.26), Vector3(0, 0.55, 0), metal, 0.35)
	_box(Vector3(0.40, 0.32, 0.48), Vector3(0, 0.74, 0.26), paint, 0.5)
	_box(Vector3(0.40, 0.13, 0.85), Vector3(0, 0.95, -0.30), dark)
	_box(Vector3(0.34, 0.23, 0.40), Vector3(0, 0.69, -0.76), paint)
	for z in [-0.76, 0.82]:
		var tire := _cylinder(0.31, 0.13, Vector3(0, 0.32, z), dark)
		tire.rotation.z = PI * 0.5
		var hub := _cylinder(0.19, 0.15, Vector3(0, 0.32, z), metal, 0.35)
		hub.rotation.z = PI * 0.5
	for side in [-1.0, 1.0]:
		var fork := _box(Vector3(0.055, 0.67, 0.06), Vector3(side * 0.10, 0.62, 0.68), metal)
		fork.rotation.x = -0.22
		_box(Vector3(0.10, 0.08, 0.30), Vector3(side * 0.31, 0.48, -0.18), dark)
	_box(Vector3(0.67, 0.06, 0.08), Vector3(0, 1.15, 0.57), dark)
	_box(Vector3(0.34, 0.28, 0.15), Vector3(0, 1.0, 0.88), paint)
	_sphere(Vector3(0.25, 0.23, 0.08), Vector3(0, 1.02, 0.97), Color("fff4c7"), 0.25, true)
	_box(Vector3(0.20, 0.11, 0.04), Vector3(0, 0.72, -0.99), Color("de6752"), 0.3, true)
	# A helmeted rider with bent arms and legs gives a readable road-user silhouette.
	var torso := _box(Vector3(0.44, 0.52, 0.29), Vector3(0, 1.28, -0.12), Color("374854"))
	torso.rotation.x = 0.22
	_sphere(Vector3(0.47, 0.49, 0.46), Vector3(0, 1.72, 0.01), paint)
	_box(Vector3(0.39, 0.14, 0.055), Vector3(0, 1.74, 0.23), Color("253b45"), 0.2)
	for side in [-1.0, 1.0]:
		var upper_arm := _box(Vector3(0.13, 0.35, 0.14), Vector3(side * 0.27, 1.30, 0.18), Color("374854"))
		upper_arm.rotation.x = -0.75
		var forearm := _box(Vector3(0.12, 0.31, 0.13), Vector3(side * 0.28, 1.16, 0.41), Color("b68c69"))
		forearm.rotation.x = -1.1
		_box(Vector3(0.14, 0.09, 0.12), Vector3(side * 0.29, 1.16, 0.58), dark)
		var thigh := _box(Vector3(0.16, 0.42, 0.19), Vector3(side * 0.23, 0.95, -0.20), Color("466174"))
		thigh.rotation.x = -0.75
		var shin := _box(Vector3(0.15, 0.36, 0.17), Vector3(side * 0.26, 0.62, -0.05), Color("466174"))
		shin.rotation.x = 0.2
		_box(Vector3(0.18, 0.10, 0.30), Vector3(side * 0.28, 0.48, 0.05), dark)
		_box(Vector3(0.025, 0.30, 0.025), Vector3(side * 0.29, 1.31, 0.62), metal)
		_box(Vector3(0.18, 0.12, 0.035), Vector3(side * 0.29, 1.48, 0.62), dark)


func _box(size: Vector3, at: Vector3, color: Color, roughness := 0.75, glow := false) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	instance.material_override = _material(color, roughness, glow)
	add_child(instance)
	return instance


func _cylinder(radius: float, height: float, at: Vector3, color: Color, roughness := 0.8) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	instance.material_override = _material(color, roughness)
	add_child(instance)
	return instance


func _sphere(size: Vector3, at: Vector3, color: Color, roughness := 0.7, glow := false) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 8
	mesh.rings = 4
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	instance.scale = size
	instance.material_override = _material(color, roughness, glow)
	add_child(instance)
	return instance


func _triangle(a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for point in [a, b, c]:
		tool.add_vertex(point)
	tool.generate_normals()
	var instance := MeshInstance3D.new()
	instance.mesh = tool.commit()
	var material := _material(color)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	instance.material_override = material
	add_child(instance)


func _text(value: String, at: Vector3, size: int, color: Color) -> void:
	var label := Label3D.new()
	label.text = value
	label.position = at
	label.font_size = size
	label.pixel_size = 0.0026
	label.modulate = color
	add_child(label)


func _material(color: Color, roughness := 0.75, glow := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	if glow:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 0.8
	return material
