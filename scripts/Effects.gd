class_name Effects
## Static helper for spawning particle effects, overlays, and screen effects.
## Uses Colors class_name directly (no preload needed).

const VIEWPORT_WIDTH  := 1280
const VIEWPORT_HEIGHT := 720

# -- GPU particle burst (reusable) --------------------------------------------
static func spawn_burst(w: Node2D, pos: Vector2, color: Color, amount: int, speed: float, lifetime: float, pool: ParticlePool = null) -> void:
	var particles: GPUParticles2D
	if pool:
		particles = pool.acquire(pos, amount, lifetime)
	else:
		particles = GPUParticles2D.new()
		particles.position = pos
		particles.z_index = 10
		particles.amount = amount
		particles.lifetime = lifetime
		particles.one_shot = true
		particles.explosiveness = 1.0
		particles.emitting = true

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = speed * 0.5
	mat.initial_velocity_max = speed
	mat.gravity = Vector3(0, 200, 0)
	mat.scale_min = 3.0
	mat.scale_max = 6.0
	mat.color = color

	var gradient := Gradient.new()
	gradient.set_color(0, color)
	gradient.set_color(1, Color(color.r, color.g, color.b, 0.0))
	var grad_tex := GradientTexture1D.new()
	grad_tex.gradient = gradient
	mat.color_ramp = grad_tex

	particles.process_material = mat
	if not pool:
		w.add_child(particles)
		var tw := w.get_tree().create_tween()
		tw.tween_interval(lifetime + 0.1)
		tw.tween_callback(particles.queue_free)

# -- ColorRect sparkle burst --------------------------------------------------
static func spawn_sparkle_burst(w: Node2D, pos: Vector2, color: Color, count: int, radius: float) -> void:
	for i in count:
		var p := ColorRect.new()
		p.size = Vector2(4, 4)
		p.color = color
		p.position = pos
		p.z_index = 5
		w.add_child(p)

		var angle := i * TAU / count
		var target := pos + Vector2(cos(angle) * radius, sin(angle) * radius)
		var tw := w.get_tree().create_tween()
		tw.set_parallel(true)
		tw.tween_property(p, "position", target, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(p, "modulate:a", 0.0, 0.4)
		tw.set_parallel(false)
		tw.tween_callback(p.queue_free)

# -- Specific effect shortcuts ------------------------------------------------
static func spawn_coin_sparkle(w: Node2D, pos: Vector2, pool: ParticlePool = null) -> void:
	spawn_burst(w, pos, Color(1.0, 0.85, 0.1), 12, 80.0, 0.4, pool)

static func spawn_enemy_death(w: Node2D, pos: Vector2, pool: ParticlePool = null) -> void:
	spawn_burst(w, pos, Colors.ENEMY_CLR, 16, 120.0, 0.5, pool)

static func spawn_crumble(w: Node2D, pos: Vector2, pool: ParticlePool = null) -> void:
	spawn_burst(w, pos, Colors.CRUMBLE_FILL, 10, 60.0, 0.5, pool)

static func spawn_powerup_effect(w: Node2D, pos: Vector2, ptype: String) -> void:
	var color := Colors.SHIELD_CLR if ptype == "shield" else Colors.SPEED_CLR
	spawn_sparkle_burst(w, pos, color, 12, 35.0)

static func spawn_boss_death(w: Node2D, pos: Vector2, pool: ParticlePool = null) -> void:
	spawn_burst(w, pos, Colors.ENEMY_CLR, 32, 200.0, 0.7, pool)
	spawn_burst(w, pos, Color(1, 1, 1, 0.9), 16, 150.0, 0.4, pool)
	# Screen flash
	var flash := ColorRect.new()
	flash.color = Color(1, 0.3, 0.2, 0.5)
	flash.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cl := CanvasLayer.new()
	cl.layer = 50
	cl.add_child(flash)
	w.add_child(cl)
	var tw := w.get_tree().create_tween()
	tw.tween_property(flash, "color:a", 0.0, 0.3)
	tw.tween_callback(cl.queue_free)

# -- Death stats overlay ------------------------------------------------------
static func show_death_overlay(w: Node2D, death_count: int, score: int, total_coins: int, elapsed_time: float) -> void:
	var cl := CanvasLayer.new()
	cl.layer = 80
	w.add_child(cl)

	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.02, 0.02, 0.0)
	bg.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(bg)

	var mins := int(elapsed_time) / 60
	var secs := int(elapsed_time) % 60

	var text := Label.new()
	text.text = "Deaths: %d    Coins: %d / %d    Time: %02d:%02d" % [death_count, score, total_coins, mins, secs]
	text.position = Vector2(380, 340)
	text.add_theme_font_size_override("font_size", 22)
	text.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	text.modulate.a = 0.0
	cl.add_child(text)

	var tw := w.create_tween()
	tw.tween_property(bg, "color:a", 0.6, 0.3)
	tw.parallel().tween_property(text, "modulate:a", 1.0, 0.3)
	tw.tween_interval(1.0)
	tw.tween_property(bg, "color:a", 0.0, 0.3)
	tw.parallel().tween_property(text, "modulate:a", 0.0, 0.3)
	tw.tween_callback(cl.queue_free)

# -- Level complete overlay ---------------------------------------------------
static func show_level_complete(w: Node2D, stars: int, elapsed_time: float) -> void:
	var cl := CanvasLayer.new()
	cl.layer = 80
	w.add_child(cl)

	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.08, 0.02, 0.7)
	bg.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(bg)

	var title := Label.new()
	title.text = "LEVEL COMPLETE!"
	title.position = Vector2(440, 280)
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	cl.add_child(title)

	var star_labels := ["bronze", "silver", "GOLD"]
	var star_colors := [Color(0.8, 0.5, 0.2), Color(0.75, 0.75, 0.85), Color(1.0, 0.85, 0.1)]
	var star_text := ""
	for i in stars:
		star_text += "★ "

	var star_lbl := Label.new()
	star_lbl.text = "%s  %s" % [star_text.strip_edges(), star_labels[stars - 1]]
	star_lbl.position = Vector2(510, 330)
	star_lbl.add_theme_font_size_override("font_size", 28)
	star_lbl.add_theme_color_override("font_color", star_colors[stars - 1])
	cl.add_child(star_lbl)

	var mins := int(elapsed_time) / 60
	var secs := int(elapsed_time) % 60
	var ms := int(fmod(elapsed_time, 1.0) * 100)
	var time_lbl := Label.new()
	time_lbl.text = "Time: %02d:%02d.%02d" % [mins, secs, ms]
	time_lbl.position = Vector2(530, 375)
	time_lbl.add_theme_font_size_override("font_size", 20)
	time_lbl.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	cl.add_child(time_lbl)

# -- Pause menu ---------------------------------------------------------------
static func create_pause_menu(w: Node2D) -> CanvasLayer:
	var pause_menu := CanvasLayer.new()
	pause_menu.layer = 200
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	w.add_child(pause_menu)

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	pause_menu.add_child(overlay)

	var panel := ColorRect.new()
	panel.color = Color(0.1, 0.1, 0.2, 0.95)
	panel.size = Vector2(500, 480)
	panel.position = Vector2(390, 120)
	pause_menu.add_child(panel)

	var title := Label.new()
	title.text = "PAUSED"
	title.position = Vector2(555, 135)
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1, 0.95, 0.55))
	pause_menu.add_child(title)

	var controls : Array = [
		["Move", "Arrow Keys / ← →"],
		["Jump", "Space / Up Arrow"],
		["Double Jump", "Jump again in air"],
		["Dash", "Z"],
		["Ground Pound", "X (in air)"],
		["Grapple", "C (aim with mouse)"],
		["Glide", "Hold Jump while falling"],
		["Crouch", "Hold Down Arrow"],
		["Drop Through", "Tap Down on platform"],
		["Wall Slide", "Hold toward wall in air"],
		["Wall Climb", "Up while wall sliding"],
		["Wall Jump", "Jump while wall sliding"],
		["Portal", "Down Arrow near portal"],
		["Zoom", "Scroll Wheel"],
		["", ""],
		["Easy Map", "1"],
		["Medium Map", "2"],
		["Hard Map", "3"],
		["Extreme Map", "4"],
		["Reroll Map", "R"],
		["Next Level", "N"],
		["Prev Level", "B"],
		["Toggle 2.5D", "V"],
	]

	var y_pos := 185
	for entry in controls:
		if entry[0] == "":
			y_pos += 8
			continue
		var action_lbl := Label.new()
		action_lbl.text = entry[0]
		action_lbl.position = Vector2(420, y_pos)
		action_lbl.add_theme_font_size_override("font_size", 16)
		action_lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 1.0))
		pause_menu.add_child(action_lbl)

		var key_lbl := Label.new()
		key_lbl.text = entry[1]
		key_lbl.position = Vector2(620, y_pos)
		key_lbl.add_theme_font_size_override("font_size", 16)
		key_lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
		pause_menu.add_child(key_lbl)

		y_pos += 22

	var menu_lbl := Label.new()
	menu_lbl.text = "M  Main Menu"
	menu_lbl.position = Vector2(420, y_pos + 4)
	menu_lbl.add_theme_font_size_override("font_size", 16)
	menu_lbl.add_theme_color_override("font_color", Color(0.9, 0.5, 0.5))
	pause_menu.add_child(menu_lbl)

	var hint := Label.new()
	hint.text = "Press ESC to resume"
	hint.position = Vector2(510, y_pos + 15)
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	pause_menu.add_child(hint)

	return pause_menu
