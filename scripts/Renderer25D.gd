class_name Renderer25D extends Node3D
## Overlays a 3D rendering layer on top of the 2D game.
## Creates MeshInstance3D proxies for 2D nodes and syncs positions each frame.
## The 2D sprites are hidden; only 3D meshes render.

const SCALE := 0.01  # 2D pixels -> 3D units (100px = 1 unit)
const DEPTH_PLAYER    := 0.0
const DEPTH_ENEMIES   := 0.05
const DEPTH_PLATFORMS := 0.1
const DEPTH_HAZARDS   := 0.02
const DEPTH_ITEMS     := -0.05
const DEPTH_BG        := 0.5

var _camera: Camera3D
var _env: WorldEnvironment
var _proxies: Dictionary = {}  # Node2D -> MeshInstance3D
var _hidden_nodes: Array = []  # Nodes we hid — only restore these
var _world_2d: Node2D
var _enabled := false

# Materials (cached for reuse)
var _mat_cache: Dictionary = {}

func setup(world: Node2D) -> void:
	_world_2d = world
	_build_3d_scene()
	_scan_and_create_proxies()
	_hide_2d_sprites()
	_enabled = true

func _build_3d_scene() -> void:
	# Environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.04, 0.04, 0.1)
	env.ambient_light_color = Color(0.6, 0.6, 0.8)
	env.ambient_light_energy = 0.5
	env.glow_enabled = true
	env.glow_intensity = 0.3
	env.glow_bloom = 0.15
	env.ssao_enabled = false
	env.fog_enabled = true
	env.fog_light_color = Color(0.15, 0.12, 0.25)
	env.fog_density = 0.005

	_env = WorldEnvironment.new()
	_env.environment = env
	add_child(_env)

	# Camera — slightly angled for 2.5D perspective
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	_camera.fov = 45.0
	_camera.near = 0.1
	_camera.far = 100.0
	# DOF
	var attrs := CameraAttributesPractical.new()
	attrs.dof_blur_far_enabled = true
	attrs.dof_blur_far_distance = 8.0
	attrs.dof_blur_far_transition = 4.0
	_camera.attributes = attrs
	add_child(_camera)

	# Directional light (main)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 25, 0)
	sun.light_color = Color(1.0, 0.95, 0.85)
	sun.light_energy = 0.7
	sun.shadow_enabled = true
	add_child(sun)

	# Fill light (softer, opposite side)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-30, -150, 0)
	fill.light_color = Color(0.4, 0.5, 0.8)
	fill.light_energy = 0.3
	fill.shadow_enabled = false
	add_child(fill)

func _scan_and_create_proxies() -> void:
	if not _world_2d:
		return

	# Player (skip if already proxied)
	var player := _find_node_by_class(_world_2d, "Player")
	if player and not _proxies.has(player):
		var mesh := _create_character_proxy(player, Color(0.2, 0.7, 0.3), DEPTH_PLAYER, Vector3(0.5, 0.7, 0.3))
		_proxies[player] = mesh

	# Platforms (StaticBody2D children with sprites)
	for node in _world_2d.get_children():
		if _proxies.has(node):
			continue
		if node is StaticBody2D and not node is DestructibleBlock:
			var size := _estimate_body_size(node)
			if size.x > 0:
				_proxies[node] = _create_box_proxy(node, _get_platform_color(node), DEPTH_PLATFORMS, Vector3(size.x * SCALE, size.y * SCALE, 0.3))
		elif node is DestructibleBlock:
			var db := node as DestructibleBlock
			_proxies[node] = _create_box_proxy(node, Color(0.6, 0.45, 0.3), DEPTH_PLATFORMS, Vector3(db.block_width * SCALE, db.block_height * SCALE, 0.25))

	# Enemies (Area2D with specific class names)
	for node in _world_2d.get_children():
		if _proxies.has(node):
			continue
		if node is PatrolEnemy:
			_proxies[node] = _create_character_proxy(node, Color(0.9, 0.25, 0.2), DEPTH_ENEMIES, Vector3(0.45, 0.55, 0.25))
		elif node is JumpingEnemy:
			_proxies[node] = _create_character_proxy(node, Color(0.9, 0.8, 0.2), DEPTH_ENEMIES, Vector3(0.45, 0.55, 0.25))
		elif node is FlyingEnemy:
			_proxies[node] = _create_character_proxy(node, Color(0.6, 0.3, 0.8), DEPTH_ENEMIES, Vector3(0.4, 0.4, 0.2))
		elif node is ShieldedEnemy:
			_proxies[node] = _create_character_proxy(node, Color(0.3, 0.5, 0.9), DEPTH_ENEMIES, Vector3(0.5, 0.6, 0.25))
		elif node is BossEnemy:
			_proxies[node] = _create_character_proxy(node, Color(0.8, 0.15, 0.1), DEPTH_ENEMIES, Vector3(0.9, 1.0, 0.4))

	# Coins
	for node in _world_2d.get_tree().get_nodes_in_group("coins"):
		if not _proxies.has(node):
			_proxies[node] = _create_gem_proxy(node, Color(1.0, 0.85, 0.15), DEPTH_ITEMS)

	# Spikes / saws (Area2D hazards)
	for node in _world_2d.get_children():
		if _proxies.has(node):
			continue
		if node is Area2D and node.has_meta("hazard"):
			_proxies[node] = _create_box_proxy(node, Color(0.8, 0.2, 0.2), DEPTH_HAZARDS, Vector3(0.3, 0.2, 0.15))

	# AnimatableBody2D (moving platforms)
	for node in _world_2d.get_children():
		if _proxies.has(node):
			continue
		if node is AnimatableBody2D:
			var size := _estimate_body_size(node)
			if size.x > 0:
				_proxies[node] = _create_box_proxy(node, Color(0.5, 0.4, 0.7), DEPTH_PLATFORMS, Vector3(size.x * SCALE, size.y * SCALE, 0.25))

	# Walls
	for node in _world_2d.get_children():
		if _proxies.has(node):
			continue
		if node is StaticBody2D and node.has_meta("wall"):
			var size := _estimate_body_size(node)
			if size.x > 0:
				_proxies[node] = _create_box_proxy(node, Color(0.35, 0.3, 0.45), DEPTH_PLATFORMS, Vector3(size.x * SCALE, size.y * SCALE, 0.4))

func _process(_delta: float) -> void:
	if not _enabled:
		return
	_sync_proxies()
	_update_camera()

func _sync_proxies() -> void:
	var to_remove : Array = []
	for node2d in _proxies:
		if not is_instance_valid(node2d):
			to_remove.append(node2d)
			continue
		var mesh : MeshInstance3D = _proxies[node2d]
		var n2d := node2d as Node2D
		mesh.position.x = n2d.global_position.x * SCALE
		mesh.position.y = -n2d.global_position.y * SCALE
		mesh.visible = n2d.visible
	for key in to_remove:
		var mesh : MeshInstance3D = _proxies[key]
		if is_instance_valid(mesh):
			mesh.queue_free()
		_proxies.erase(key)

func _update_camera() -> void:
	var player := _find_node_by_class(_world_2d, "Player")
	if not player or not is_instance_valid(player):
		return
	var px : float = player.global_position.x * SCALE
	var py : float = -player.global_position.y * SCALE
	# Camera behind and above, slight angle
	var target_pos := Vector3(px, py + 1.5, -5.0)
	_camera.position = _camera.position.lerp(target_pos, 0.08)
	_camera.look_at(Vector3(px, py, 0.0))

func _hide_2d_sprites() -> void:
	_hidden_nodes.clear()
	# Hide visuals on proxied nodes
	for node in _proxies:
		if not is_instance_valid(node):
			continue
		_hide_visuals_recursive(node)
	# Hide background (CanvasLayer -10)
	for child in _world_2d.get_children():
		if child is CanvasLayer and child.layer < 0:
			if child.visible:
				child.visible = false
				_hidden_nodes.append(child)

func _hide_visuals_recursive(node: Node) -> void:
	for child in node.get_children():
		if child is Sprite2D or child is AnimatedSprite2D or child is Polygon2D:
			if child.visible:
				child.visible = false
				_hidden_nodes.append(child)
		elif child is ColorRect and not child.get_parent() is CanvasLayer:
			if child.visible:
				child.visible = false
				_hidden_nodes.append(child)
		_hide_visuals_recursive(child)

func restore_2d_sprites() -> void:
	## Re-show only the nodes we actually hid.
	for node in _hidden_nodes:
		if is_instance_valid(node):
			node.visible = true
	_hidden_nodes.clear()

func rescan() -> void:
	## Rescan scene for new nodes and re-hide 2D sprites.
	_scan_and_create_proxies()
	_hide_2d_sprites()

# ── Proxy factory methods ────────────────────────────────────────────────────

func _create_box_proxy(node: Node2D, color: Color, depth: float, size: Vector3) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _get_material(color)
	mesh.position = Vector3(node.global_position.x * SCALE, -node.global_position.y * SCALE, depth)
	add_child(mesh)
	return mesh

func _create_character_proxy(node: Node2D, color: Color, depth: float, size: Vector3) -> MeshInstance3D:
	var root := MeshInstance3D.new()

	# Body
	var body_mesh := BoxMesh.new()
	body_mesh.size = size
	root.mesh = body_mesh
	root.material_override = _get_material(color)

	# Head (child)
	var head := MeshInstance3D.new()
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(size.x * 0.8, size.x * 0.8, size.z * 0.9)
	head.mesh = head_mesh
	head.material_override = _get_material(color.lightened(0.2))
	head.position = Vector3(0, size.y * 0.5 + size.x * 0.3, 0)
	root.add_child(head)

	# Eyes
	var eye_mat := _get_material(Color(0.1, 0.1, 0.1))
	for side in [-1, 1]:
		var eye := MeshInstance3D.new()
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = size.x * 0.1
		eye_mesh.height = size.x * 0.2
		eye.mesh = eye_mesh
		eye.material_override = eye_mat
		eye.position = Vector3(side * size.x * 0.2, size.y * 0.5 + size.x * 0.35, -size.z * 0.4)
		root.add_child(eye)

	root.position = Vector3(node.global_position.x * SCALE, -node.global_position.y * SCALE, depth)
	add_child(root)
	return root

func _create_gem_proxy(node: Node2D, color: Color, depth: float) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.3
	mesh.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.5
	mat.metallic = 0.8
	mat.roughness = 0.2
	mesh.material_override = mat
	mesh.position = Vector3(node.global_position.x * SCALE, -node.global_position.y * SCALE, depth)
	add_child(mesh)
	return mesh

func _get_material(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if _mat_cache.has(key):
		return _mat_cache[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.6
	mat.metallic = 0.1
	_mat_cache[key] = mat
	return mat

func _get_platform_color(node: Node2D) -> Color:
	# Try to detect platform type from child sprites or metadata
	for child in node.get_children():
		if child is Sprite2D:
			var s := child as Sprite2D
			if s.modulate != Color.WHITE:
				return s.modulate.darkened(0.2)
	return Color(0.3, 0.5, 0.25)  # Default grass green

func _estimate_body_size(node: Node2D) -> Vector2:
	for child in node.get_children():
		if child is CollisionShape2D:
			var shape := (child as CollisionShape2D).shape
			if shape is RectangleShape2D:
				return (shape as RectangleShape2D).size
			elif shape is CircleShape2D:
				var r := (shape as CircleShape2D).radius
				return Vector2(r * 2, r * 2)
	return Vector2.ZERO

func _find_node_by_class(root: Node, cls: String) -> Node2D:
	for child in root.get_children():
		if child.get_class() == cls or (child.get_script() and child.get_script().get_global_name() == cls):
			return child as Node2D
		var found := _find_node_by_class(child, cls)
		if found:
			return found
	return null
