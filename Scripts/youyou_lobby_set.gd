extends Node3D
## 马卡龙色卡通室内。只用基础网格和 CSG，柚柚站在地面中央。

const SceneNameBadge := preload("res://Scripts/scene_name_badge.gd")

const ROOM_W := 7.7
const ROOM_D := 11.2
const WALL_H := 3.42
const BACK_Z := -3.42
const DADO_H := 1.06
const ARCH_R := 1.28

const CREAM := Color(0.965, 0.945, 0.915)
const FLOOR := Color(0.73, 0.83, 0.91)
const CEIL := Color(0.73, 0.85, 0.95)
const DADO := Color(0.67, 0.81, 0.92)
const MINT := Color(0.69, 0.89, 0.82)
const MINT_DEEP := Color(0.58, 0.84, 0.78)
const LILAC := Color(0.80, 0.75, 0.90)
const LILAC_SOFT := Color(0.86, 0.82, 0.93)
const PINK := Color(0.86, 0.78, 0.90)
const SKY := Color(0.58, 0.80, 0.96)
const CLOUD := Color(0.97, 0.98, 1.0)
const WHITE := Color(0.98, 0.97, 0.95)
const BALL := Color(0.55, 0.78, 0.95)


func _ready() -> void:
	if get_tree().current_scene == self:
		SceneNameBadge.attach(self)
	_build()


func _build() -> void:
	_floor()
	_ceiling()
	_back_wall()
	_arch_frames()
	_sky()
	_side_walls()
	_columns()
	_wall_ornaments()
	_props()


func _floor() -> void:
	# 一整块 BoxMesh，纯色 StandardMaterial3D，无贴图、无分块，避免任何缝或网格感。
	_box("Floor", Vector3(ROOM_W + 0.8, 0.16, ROOM_D), Vector3(0, -0.08, 1.15), _polished_floor_mat())
	_box("BaseboardBack", Vector3(ROOM_W, 0.07, 0.08), Vector3(0, 0.035, BACK_Z + 0.16), _mat(WHITE, 0.62))
	_box("BaseboardLeft", Vector3(0.08, 0.07, ROOM_D * 0.72), Vector3(-ROOM_W * 0.5 + 0.16, 0.035, -0.7), _mat(WHITE, 0.62))
	_box("BaseboardRight", Vector3(0.08, 0.07, ROOM_D * 0.72), Vector3(ROOM_W * 0.5 - 0.16, 0.035, -0.7), _mat(WHITE, 0.62))


func _ceiling() -> void:
	_box("Ceiling", Vector3(ROOM_W + 0.4, 0.1, ROOM_D), Vector3(0, WALL_H + 0.05, 1.15), _mat(CEIL, 0.72))
	_box("CoveLeft", Vector3(0.42, 0.1, ROOM_D - 0.6), Vector3(-ROOM_W * 0.5 + 0.28, WALL_H - 0.08, 1.05), _mat(WHITE, 0.6))
	_box("CoveRight", Vector3(0.42, 0.1, ROOM_D - 0.6), Vector3(ROOM_W * 0.5 - 0.28, WALL_H - 0.08, 1.05), _mat(WHITE, 0.6))
	_box("CoveFront", Vector3(ROOM_W, 0.1, 0.42), Vector3(0, WALL_H - 0.08, 4.6), _mat(WHITE, 0.6))
	_box("CoveBack", Vector3(ROOM_W, 0.1, 0.36), Vector3(0, WALL_H - 0.08, BACK_Z + 0.35), _mat(WHITE, 0.6))
	var lamp_mat := _mat(Color(1, 0.99, 0.96), 0.4)
	lamp_mat.emission_enabled = true
	lamp_mat.emission = Color(1, 0.98, 0.94)
	lamp_mat.emission_energy_multiplier = 1.4
	for x in [-2.4, -0.8, 0.8, 2.4]:
		_cyl("CeilingLamp", 0.11, 0.11, 0.04, Vector3(x, WALL_H - 0.02, -0.35), lamp_mat)
		var lamp := OmniLight3D.new()
		lamp.name = "CeilingGlow"
		lamp.position = Vector3(x, WALL_H - 0.28, -0.35)
		lamp.light_color = Color(1, 0.97, 0.93)
		lamp.light_energy = 0.14
		lamp.omni_range = 3.4
		lamp.shadow_enabled = false
		add_child(lamp)


func _back_wall() -> void:
	var wall := CSGBox3D.new()
	wall.name = "BackWall"
	wall.size = Vector3(ROOM_W, WALL_H, 0.2)
	wall.position = Vector3(0, WALL_H * 0.5, BACK_Z)
	wall.material = _mat(CREAM, 0.68)
	wall.use_collision = false
	var hole := CSGCylinder3D.new()
	hole.operation = CSGShape3D.OPERATION_SUBTRACTION
	hole.radius = ARCH_R + 0.02
	hole.height = 0.7
	hole.sides = 64
	hole.smooth_faces = true
	hole.rotation_degrees = Vector3(90, 0, 0)
	hole.position = Vector3(0, DADO_H - WALL_H * 0.5, 0)
	wall.add_child(hole)
	add_child(wall)
	_box("Dado", Vector3(ROOM_W, DADO_H, 0.42), Vector3(0, DADO_H * 0.5, BACK_Z + 0.06), _mat(DADO, 0.6))
	_box("DadoLip", Vector3(ROOM_W, 0.045, 0.5), Vector3(0, DADO_H + 0.01, BACK_Z + 0.08), _mat(WHITE, 0.55))


func _arch_frames() -> void:
	var center := Vector3(0, DADO_H, BACK_Z + 0.16)
	_arch_ring("ArchOuter", center + Vector3(0, 0, 0.0), 1.58, 1.40, 0.1, _mat(LILAC_SOFT, 0.55))
	_arch_ring("ArchMint", center + Vector3(0, 0, 0.08), 1.42, 1.26, 0.09, _mat(MINT, 0.5))
	_arch_ring("ArchInner", center + Vector3(0, 0, 0.15), 1.28, 1.14, 0.08, _mat(LILAC, 0.5))
	_box("ArchSill", Vector3(2.5, 0.06, 0.28), Vector3(0, DADO_H + 0.04, BACK_Z + 0.22), _mat(WHITE, 0.5))


func _sky() -> void:
	var sky := _mat(SKY, 1.0)
	sky.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_box("Sky", Vector3(2.5, 1.7, 0.06), Vector3(0, DADO_H + 0.72, BACK_Z - 0.28), sky)
	var cloud := _mat(CLOUD, 1.0)
	cloud.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var spots := [
		Vector3(-0.42, 0.55, 0.0), Vector3(-0.05, 0.68, 0.04), Vector3(0.38, 0.5, 0.0),
		Vector3(-0.7, 0.95, -0.02), Vector3(0.15, 1.05, 0.02), Vector3(0.62, 0.88, 0.0),
	]
	var scales := [Vector3(0.55, 0.32, 0.28), Vector3(0.7, 0.36, 0.3), Vector3(0.48, 0.28, 0.24), Vector3(0.42, 0.24, 0.22), Vector3(0.62, 0.3, 0.26), Vector3(0.36, 0.22, 0.2)]
	for i in spots.size():
		var mesh := SphereMesh.new()
		mesh.radius = 0.42
		mesh.height = 0.84
		mesh.material = cloud
		var node := MeshInstance3D.new()
		node.name = "Cloud%d" % i
		node.mesh = mesh
		node.position = Vector3(spots[i].x, DADO_H + spots[i].y, BACK_Z - 0.16 + spots[i].z)
		node.scale = scales[i]
		add_child(node)


func _side_walls() -> void:
	_window_wall("LeftWall", -1.0, true)
	_window_wall("RightWall", 1.0, false)


func _window_wall(wall_name: String, side: float, with_window: bool) -> void:
	var wall := CSGBox3D.new()
	wall.name = wall_name
	wall.size = Vector3(0.18, WALL_H, 9.2)
	wall.position = Vector3(side * (ROOM_W * 0.5 - 0.09), WALL_H * 0.5, 0.55)
	wall.material = _mat(CREAM if with_window else Color(0.90, 0.93, 0.97), 0.68)
	wall.use_collision = false
	if with_window:
		var stem := CSGBox3D.new()
		stem.operation = CSGShape3D.OPERATION_SUBTRACTION
		stem.size = Vector3(0.8, 1.35, 1.44)
		stem.position = Vector3(0, 1.55 - WALL_H * 0.5, -1.15)
		wall.add_child(stem)
		var cap := CSGCylinder3D.new()
		cap.operation = CSGShape3D.OPERATION_SUBTRACTION
		cap.radius = 0.72
		cap.height = 0.8
		cap.sides = 48
		cap.smooth_faces = true
		cap.rotation_degrees = Vector3(0, 0, 90)
		cap.position = Vector3(0, 2.15 - WALL_H * 0.5, -1.15)
		wall.add_child(cap)
	add_child(wall)
	if not with_window:
		_box("RightPanel", Vector3(0.06, 1.55, 1.7), Vector3(side * (ROOM_W * 0.5 - 0.2), 2.05, -1.35), _mat(Color(0.78, 0.87, 0.95), 0.58))
		return
	var frame_z := -0.6
	var x := side * (ROOM_W * 0.5 - 0.22)
	_box("WindowJambA", Vector3(0.1, 1.42, 0.1), Vector3(x, 1.52, frame_z - 0.76), _mat(LILAC, 0.52))
	_box("WindowJambB", Vector3(0.1, 1.42, 0.1), Vector3(x, 1.52, frame_z + 0.76), _mat(LILAC, 0.52))
	_arch_ring("WindowArch", Vector3(x, 2.15, frame_z), 0.9, 0.74, 0.1, _mat(LILAC, 0.52), Vector3(0, 90, 0))
	_arch_ring("WindowArchInner", Vector3(x, 2.15, frame_z), 0.76, 0.64, 0.08, _mat(WHITE, 0.48), Vector3(0, 90, 0))
	var sky := _mat(SKY, 1.0)
	sky.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_box("LeftSky", Vector3(0.08, 2.15, 1.55), Vector3(x + side * 0.2, 1.62, frame_z), sky)


func _columns() -> void:
	var shaft := _mat(MINT, 0.42)
	var cap := _mat(WHITE, 0.48)
	for x in [-2.28, 2.28]:
		_cyl("ColumnBase", 0.22, 0.22, 0.08, Vector3(x, 0.04, -2.55), cap)
		_cyl("Column", 0.125, 0.125, 2.86, Vector3(x, 1.51, -2.55), shaft)
		_cyl("ColumnNeck", 0.16, 0.16, 0.05, Vector3(x, 2.96, -2.55), cap)
		_cyl("ColumnCap", 0.2, 0.2, 0.07, Vector3(x, 3.02, -2.55), cap)


func _wall_ornaments() -> void:
	var bar := _mat(MINT_DEEP, 0.55)
	for x in [-1.95, 1.95]:
		_box("MintBar", Vector3(0.1, 1.15, 0.06), Vector3(x, 2.05, BACK_Z + 0.16), bar)
	_disc("DiscLilacL", 0.2, Vector3(-2.95, 2.15, BACK_Z + 0.16), _mat(LILAC, 0.55))
	_disc("DiscMintL", 0.13, Vector3(-3.25, 1.55, BACK_Z + 0.16), _mat(MINT, 0.55))
	_disc("DiscLilacR", 0.22, Vector3(3.05, 2.25, BACK_Z + 0.16), _mat(PINK, 0.55))
	_disc("DiscSmallR", 0.12, Vector3(3.35, 1.7, BACK_Z + 0.16), _mat(LILAC_SOFT, 0.55))
	_disc("RightWallDiscA", 0.28, Vector3(ROOM_W * 0.5 - 0.24, 2.35, 0.55), _mat(LILAC, 0.55), true)
	_disc("RightWallDiscB", 0.16, Vector3(ROOM_W * 0.5 - 0.24, 1.7, 1.15), _mat(PINK, 0.55), true)
	_disc("RightWallDiscC", 0.1, Vector3(ROOM_W * 0.5 - 0.24, 1.25, 1.45), _mat(LILAC_SOFT, 0.55), true)


func _props() -> void:
	_cyl("PropPedestalLeft", 0.34, 0.34, 0.42, Vector3(-2.85, 0.21, -2.15), _mat(PINK, 0.5))
	var ball := SphereMesh.new()
	ball.radius = 0.2
	ball.height = 0.4
	ball.material = _mat(BALL, 0.38)
	var ball_node := MeshInstance3D.new()
	ball_node.name = "PropBall"
	ball_node.mesh = ball
	ball_node.position = Vector3(-3.25, 0.2, -1.45)
	add_child(ball_node)
	_cyl("PropPedestalRight", 0.42, 0.42, 0.36, Vector3(2.95, 0.18, -1.85), _mat(LILAC, 0.5))


func _arch_ring(node_name: String, center: Vector3, outer_r: float, inner_r: float, depth: float, mat: Material, rotation_degrees := Vector3.ZERO) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments := 36
	var outer_pts: Array[Vector2] = []
	var inner_pts: Array[Vector2] = []
	for i in segments + 1:
		var angle := PI - float(i) * PI / float(segments)
		outer_pts.append(Vector2(cos(angle) * outer_r, sin(angle) * outer_r))
		inner_pts.append(Vector2(cos(angle) * inner_r, sin(angle) * inner_r))
	for i in segments:
		var a0: Vector2 = outer_pts[i]
		var a1: Vector2 = outer_pts[i + 1]
		var b0: Vector2 = inner_pts[i]
		var b1: Vector2 = inner_pts[i + 1]
		_quad(st, _band(a0, 0.0), _band(a1, 0.0), _band(b1, 0.0), _band(b0, 0.0))
		_quad(st, _band(b0, depth), _band(b1, depth), _band(a1, depth), _band(a0, depth))
		_quad(st, _band(a0, depth), _band(a1, depth), _band(a1, 0.0), _band(a0, 0.0))
		_quad(st, _band(b0, 0.0), _band(b1, 0.0), _band(b1, depth), _band(b0, depth))
	var start_o: Vector2 = outer_pts[0]
	var start_i: Vector2 = inner_pts[0]
	var end_o: Vector2 = outer_pts[segments]
	var end_i: Vector2 = inner_pts[segments]
	_quad(st, _band(start_o, 0.0), _band(start_i, 0.0), _band(start_i, depth), _band(start_o, depth))
	_quad(st, _band(end_i, 0.0), _band(end_o, 0.0), _band(end_o, depth), _band(end_i, depth))
	st.generate_normals()
	var mesh := st.commit()
	var draw := mat.duplicate() as StandardMaterial3D
	draw.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_set_material(0, draw)
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.position = center
	node.rotation_degrees = rotation_degrees
	add_child(node)


func _band(point: Vector2, depth: float) -> Vector3:
	return Vector3(point.x, point.y, depth)


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)
	st.add_vertex(a)
	st.add_vertex(c)
	st.add_vertex(d)


func _box(node_name: String, size: Vector3, pos: Vector3, mat: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = mat
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.position = pos
	add_child(node)


func _cyl(node_name: String, radius_top: float, radius_bottom: float, height: float, pos: Vector3, mat: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius_top
	mesh.bottom_radius = radius_bottom
	mesh.height = height
	mesh.radial_segments = 32
	mesh.material = mat
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.position = pos
	add_child(node)


func _disc(node_name: String, radius: float, pos: Vector3, mat: Material, on_side_wall := false) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.04
	mesh.radial_segments = 32
	mesh.material = mat
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.position = pos
	node.rotation_degrees = Vector3(0, 0, 90) if on_side_wall else Vector3(90, 0, 0)
	add_child(node)


func _polished_floor_mat() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = FLOOR
	mat.roughness = 0.22
	mat.metallic = 0.0
	mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	return mat


func _mat(color: Color, roughness: float, metallic := 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	return mat
