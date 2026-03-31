extends Node3D
## 3D reward hub room shown between levels after Lv10.
## Features low-poly environment, orbiting camera, depth-of-field, and lighting.

const ORBIT_SPEED := 0.3
const ORBIT_RADIUS := 8.0
const ORBIT_HEIGHT := 4.0

var _camera: Camera3D
var _angle := 0.0
var _timer := 0.0
var _duration := 4.0  # Seconds before auto-advancing

func _ready() -> void:
	_build_environment()
	_build_room()
	_build_player_model()
	_build_hud()
	# Fade in
	_fade_in()

func _process(delta: float) -> void:
	# Orbit camera
	_angle += ORBIT_SPEED * delta
	if _camera:
		_camera.position = Vector3(
			cos(_angle) * ORBIT_RADIUS,
			ORBIT_HEIGHT + sin(_angle * 0.5) * 0.5,
			sin(_angle) * ORBIT_RADIUS
		)
		_camera.look_at(Vector3(0, 1.5, 0))

	_timer += delta
	if _timer >= _duration:
		_advance()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var kb := event as InputEventKey
		if kb.keycode == KEY_SPACE or kb.keycode == KEY_ENTER or kb.keycode == KEY_KP_ENTER:
			_advance()

func _advance() -> void:
	set_process(false)
	set_process_unhandled_input(false)
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.size = Vector2(1280, 720)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cl := CanvasLayer.new()
	cl.layer = 100
	cl.add_child(overlay)
	add_child(cl)
	var tw := create_tween()
	tw.tween_property(overlay, "color:a", 1.0, 0.4)
	tw.tween_callback(get_tree().change_scene_to_file.bind("res://scenes/World.tscn"))
	# The transition is already queued in GameState, so World picks it up

func _build_environment() -> void:
	# World environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.06)
	env.ambient_light_color = Color(0.15, 0.12, 0.25)
	env.ambient_light_energy = 0.3
	env.glow_enabled = true
	env.glow_intensity = 0.4
	env.glow_bloom = 0.3

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	# Camera with depth-of-field
	_camera = Camera3D.new()
	_camera.position = Vector3(ORBIT_RADIUS, ORBIT_HEIGHT, 0)
	_camera.look_at(Vector3(0, 1.5, 0))
	_camera.fov = 50.0
	var cam_attrs := CameraAttributesPractical.new()
	cam_attrs.dof_blur_far_enabled = true
	cam_attrs.dof_blur_far_distance = 15.0
	cam_attrs.dof_blur_far_transition = 5.0
	_camera.attributes = cam_attrs
	add_child(_camera)

	# Directional light (sun-like)
	var dir_light := DirectionalLight3D.new()
	dir_light.rotation_degrees = Vector3(-45, 30, 0)
	dir_light.light_color = Color(1.0, 0.9, 0.7)
	dir_light.light_energy = 0.8
	dir_light.shadow_enabled = true
	add_child(dir_light)

	# Point lights for atmosphere
	_add_point_light(Vector3(-3, 3, -2), Color(0.3, 0.5, 1.0), 2.0)
	_add_point_light(Vector3(3, 2, 3), Color(1.0, 0.4, 0.2), 1.5)
	_add_point_light(Vector3(0, 4, 0), Color(0.8, 0.8, 1.0), 1.0)

func _add_point_light(pos: Vector3, color: Color, energy: float) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = 10.0
	add_child(light)

func _build_room() -> void:
	# Floor
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(12, 12)
	floor_mesh.mesh = plane
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.15, 0.12, 0.2)
	floor_mat.roughness = 0.8
	floor_mesh.material_override = floor_mat
	add_child(floor_mesh)

	# Pillars
	for i in 4:
		var angle := i * TAU / 4.0
		var pos := Vector3(cos(angle) * 4, 1.5, sin(angle) * 4)
		_add_pillar(pos)

	# Floating platform (center)
	var platform := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(3, 0.4, 3)
	platform.mesh = box
	platform.position = Vector3(0, 0.2, 0)
	var plat_mat := StandardMaterial3D.new()
	plat_mat.albedo_color = Color(0.25, 0.2, 0.35)
	plat_mat.roughness = 0.6
	plat_mat.metallic = 0.2
	platform.material_override = plat_mat
	add_child(platform)

	# Floating gems
	for i in 6:
		var gem_angle := i * TAU / 6.0
		var gem := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.15
		sphere.height = 0.3
		gem.mesh = sphere
		gem.position = Vector3(cos(gem_angle) * 2, 2.5, sin(gem_angle) * 2)
		var gem_mat := StandardMaterial3D.new()
		gem_mat.albedo_color = Color(1.0, 0.85, 0.15)
		gem_mat.emission_enabled = true
		gem_mat.emission = Color(1.0, 0.85, 0.15)
		gem_mat.emission_energy_multiplier = 2.0
		gem_mat.metallic = 0.9
		gem_mat.roughness = 0.1
		gem.material_override = gem_mat
		add_child(gem)
		# Bobbing animation
		var tw := create_tween().set_loops()
		tw.tween_property(gem, "position:y", 2.8, 1.0 + i * 0.1).set_trans(Tween.TRANS_SINE)
		tw.tween_property(gem, "position:y", 2.2, 1.0 + i * 0.1).set_trans(Tween.TRANS_SINE)

	# Particle-like floating stars (small spheres)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in 30:
		var star := MeshInstance3D.new()
		var ss := SphereMesh.new()
		ss.radius = rng.randf_range(0.03, 0.08)
		ss.height = ss.radius * 2
		star.mesh = ss
		star.position = Vector3(
			rng.randf_range(-6, 6),
			rng.randf_range(1, 6),
			rng.randf_range(-6, 6)
		)
		var star_mat := StandardMaterial3D.new()
		star_mat.albedo_color = Color(1, 1, 1)
		star_mat.emission_enabled = true
		star_mat.emission = Color(1, 1, 1, rng.randf_range(0.3, 1.0))
		star_mat.emission_energy_multiplier = rng.randf_range(0.5, 2.0)
		star.material_override = star_mat
		add_child(star)

func _add_pillar(pos: Vector3) -> void:
	var pillar := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.3
	cyl.bottom_radius = 0.4
	cyl.height = 3.0
	pillar.mesh = cyl
	pillar.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.25, 0.4)
	mat.roughness = 0.7
	mat.metallic = 0.1
	pillar.material_override = mat
	add_child(pillar)

func _build_player_model() -> void:
	# Low-poly player: body + head
	var player_root := Node3D.new()
	player_root.position = Vector3(0, 0.7, 0)
	add_child(player_root)

	# Body
	var body := MeshInstance3D.new()
	var body_box := BoxMesh.new()
	body_box.size = Vector3(0.6, 0.8, 0.4)
	body.mesh = body_box
	var body_mat := StandardMaterial3D.new()
	# Apply skin tint
	var skin := Skins.get_skin(GameState.save.active_skin)
	body_mat.albedo_color = skin["tint"] if skin["tint"] != Color.WHITE else Color(0.2, 0.6, 1.0)
	body_mat.roughness = 0.5
	body.material_override = body_mat
	player_root.add_child(body)

	# Head
	var head := MeshInstance3D.new()
	var head_box := BoxMesh.new()
	head_box.size = Vector3(0.5, 0.5, 0.45)
	head.mesh = head_box
	head.position = Vector3(0, 0.65, 0)
	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.9, 0.75, 0.55)
	head_mat.roughness = 0.6
	head.material_override = head_mat
	player_root.add_child(head)

	# Eyes
	for side in [-1, 1]:
		var eye := MeshInstance3D.new()
		var eye_sphere := SphereMesh.new()
		eye_sphere.radius = 0.06
		eye_sphere.height = 0.12
		eye.mesh = eye_sphere
		eye.position = Vector3(side * 0.12, 0.7, 0.22)
		var eye_mat := StandardMaterial3D.new()
		eye_mat.albedo_color = Color(0.1, 0.1, 0.1)
		eye.material_override = eye_mat
		player_root.add_child(eye)

	# Idle bobbing
	var tw := create_tween().set_loops()
	tw.tween_property(player_root, "position:y", 0.9, 0.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(player_root, "position:y", 0.7, 0.8).set_trans(Tween.TRANS_SINE)

	# Slow rotation
	var spin := create_tween().set_loops()
	spin.tween_property(player_root, "rotation:y", TAU, 6.0)

func _build_hud() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 10
	add_child(cl)

	var title := Label.new()
	title.text = "REWARD HUB"
	title.position = Vector2(510, 50)
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.15))
	cl.add_child(title)

	var level_lbl := Label.new()
	var transition : Dictionary = GameState.consume_transition()
	var lvl : int = int(transition.get("level", 0)) if not transition.is_empty() else 0
	# Re-queue the transition so World picks it up after reload
	if not transition.is_empty():
		GameState.queue_level_transition(transition["level"], transition["seed"], transition.get("mode", ""))
	level_lbl.text = "Entering Level %d" % lvl
	level_lbl.position = Vector2(520, 100)
	level_lbl.add_theme_font_size_override("font_size", 22)
	level_lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0))
	cl.add_child(level_lbl)

	var coins_lbl := Label.new()
	coins_lbl.text = "Coins: %d    Skin: %s" % [GameState.save.shop_coins, GameState.save.active_skin.capitalize()]
	coins_lbl.position = Vector2(470, 140)
	coins_lbl.add_theme_font_size_override("font_size", 18)
	coins_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	cl.add_child(coins_lbl)

	var hint := Label.new()
	hint.text = "Press Space to continue..."
	hint.position = Vector2(490, 650)
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	hint.modulate.a = 0.0
	cl.add_child(hint)

	# Fade hint in after a beat
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(hint, "modulate:a", 1.0, 0.5)

func _fade_in() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 1)
	overlay.size = Vector2(1280, 720)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cl := CanvasLayer.new()
	cl.layer = 100
	cl.add_child(overlay)
	add_child(cl)
	var tw := create_tween()
	tw.tween_property(overlay, "color:a", 0.0, 0.5)
	tw.tween_callback(cl.queue_free)
