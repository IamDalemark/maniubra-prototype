extends RigidBody3D
## Lightweight, reusable cone that can be knocked aside by the player car.


func _ready() -> void:
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.19
	shape.height = 0.56
	collision.shape = shape
	add_child(collision)

	var base := BoxMesh.new()
	base.size = Vector3(0.46, 0.055, 0.46)
	_add_mesh(base, Vector3(0, -0.27, 0), Color("242c2b"))
	var shell := CylinderMesh.new()
	shell.top_radius = 0.035
	shell.bottom_radius = 0.20
	shell.height = 0.56
	_add_mesh(shell, Vector3.ZERO, Color("e86a2c"))
	_band(0.20, 0.15, 0.13)
	_band(0.40, 0.095, 0.075)


func _band(height_from_ground: float, bottom_radius: float, top_radius: float) -> void:
	var band := CylinderMesh.new()
	band.bottom_radius = bottom_radius
	band.top_radius = top_radius
	band.height = 0.07
	_add_mesh(band, Vector3(0, height_from_ground - 0.28, 0), Color("f6eee0"))


func _add_mesh(mesh: Mesh, at: Vector3, color: Color) -> void:
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.72
	visual.material_override = material
	add_child(visual)
