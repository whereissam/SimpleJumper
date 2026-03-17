class_name Builder
const Colors = preload("res://scripts/Colors.gd")
const Sprites = preload("res://scripts/Sprites.gd")

# -- Background (parallax with Kenney tiles) -----------------------------------
static func make_background(w: Node2D, level_data: Dictionary) -> void:
	var cl := CanvasLayer.new()
	cl.layer = -10
	w.add_child(cl)

	var bg := ColorRect.new()
	bg.color    = level_data.get("bg_color", Colors.BG_COLOR)
	bg.size     = Vector2(1280, 720)
	bg.position = Vector2.ZERO
	cl.add_child(bg)

	# Background tile layer (clouds/mountains)
	var bg_tiles : Array = [Sprites.BG_SKY_CLOUD, Sprites.BG_SKY_MOUNT]
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for _i in 12:
		var s := Sprite2D.new()
		s.texture = load(bg_tiles[rng.randi_range(0, 1)])
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.scale = Vector2(4, 4)
		s.modulate = Color(1, 1, 1, rng.randf_range(0.08, 0.2))
		s.position = Vector2(rng.randf_range(0, 1280), rng.randf_range(100, 550))
		cl.add_child(s)

	# Stars
	for _i in 50:
		var star := ColorRect.new()
		star.size     = Vector2(2, 2)
		star.color    = Color(1, 1, 1, rng.randf_range(0.15, 0.7))
		star.position = Vector2(rng.randf_range(0, 1280), rng.randf_range(0, 600))
		cl.add_child(star)

# -- Walls ---------------------------------------------------------------------
static func make_walls(w: Node2D, wall_data: Array) -> void:
	for wd in wall_data:
		var sb := StaticBody2D.new()
		sb.position = Vector2(wd[0], wd[1])

		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size  = Vector2(wd[2], wd[3])
		cs.shape = rs
		sb.add_child(cs)

		# Tile wall with brick sprites
		var tile_h := 18.0 * 3.0
		var num_v := maxi(int(float(wd[3]) / tile_h), 1)
		var num_h := maxi(int(float(wd[2]) / tile_h), 1)
		for row in num_v:
			for col in num_h:
				var s := Sprite2D.new()
				s.texture = load(Sprites.BRICK)
				s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				s.scale = Vector2(3, 3)
				s.position = Vector2(
					-float(wd[2]) * 0.5 + tile_h * 0.5 + col * tile_h,
					-float(wd[3]) * 0.5 + tile_h * 0.5 + row * tile_h
				)
				sb.add_child(s)

		w.add_child(sb)

# -- Static Platforms (Kenney grass tiles) -------------------------------------
static func make_platforms(w: Node2D, data: Array) -> void:
	for pd in data:
		_create_static_platform(w, pd)

static func _create_static_platform(w: Node2D, pd: Array) -> StaticBody2D:
	var sb := StaticBody2D.new()
	sb.position = Vector2(pd[0], pd[1])

	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size  = Vector2(pd[2], pd[3])
	cs.shape = rs
	sb.add_child(cs)

	# Tile with grass sprites
	var tile_w := 18.0 * 3.0  # 54px
	var num_tiles := maxi(int(float(pd[2]) / tile_w), 1)
	for i in num_tiles:
		var s := Sprite2D.new()
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if num_tiles == 1:
			s.texture = load(Sprites.GRASS_TOP)
		elif i == 0:
			s.texture = load(Sprites.GRASS_LEFT)
		elif i == num_tiles - 1:
			s.texture = load(Sprites.GRASS_RIGHT)
		else:
			s.texture = load(Sprites.GRASS_TOP)
		s.scale = Vector2(3, 3)
		s.position = Vector2(
			-float(pd[2]) * 0.5 + tile_w * 0.5 + i * tile_w,
			0
		)
		sb.add_child(s)

	w.add_child(sb)
	return sb

# -- Moving Platforms ----------------------------------------------------------
static func make_moving_platforms(w: Node2D, data: Array) -> void:
	for mp in data:
		var ab := AnimatableBody2D.new()
		ab.position = Vector2(mp[0], mp[1])

		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size  = Vector2(mp[2], mp[3])
		cs.shape = rs
		ab.add_child(cs)

		# Use wood plank sprites for moving platforms
		var tile_w := 18.0 * 3.0
		var num_tiles := maxi(int(float(mp[2]) / tile_w), 1)
		for i in num_tiles:
			var s := Sprite2D.new()
			s.texture = load(Sprites.WOOD_PLANK)
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.scale = Vector2(3, 3)
			s.modulate = Color(0.8, 0.6, 1.0)  # Purple tint to distinguish
			s.position = Vector2(
				-float(mp[2]) * 0.5 + tile_w * 0.5 + i * tile_w,
				0
			)
			ab.add_child(s)

		w.add_child(ab)

		var axis     : String = mp[4]
		var dist     : float  = mp[5]
		var spd      : float  = mp[6]
		var duration : float  = dist / spd

		var tw := w.create_tween().set_loops()
		if axis == "x":
			tw.tween_property(ab, "position:x", mp[0] + dist, duration)
			tw.tween_property(ab, "position:x", mp[0] - dist, duration * 2.0)
			tw.tween_property(ab, "position:x", float(mp[0]), duration)
		else:
			tw.tween_property(ab, "position:y", mp[1] + dist, duration)
			tw.tween_property(ab, "position:y", mp[1] - dist, duration * 2.0)
			tw.tween_property(ab, "position:y", float(mp[1]), duration)

# -- Crumbling Platforms -------------------------------------------------------
static func make_crumble_platforms(w: Node2D, data: Array) -> Array:
	var crumble_bodies : Array = []
	for cd in data:
		var sb := StaticBody2D.new()
		sb.position = Vector2(cd[0], cd[1])
		sb.set_meta("crumble", true)
		sb.set_meta("crumble_timer", -1.0)
		sb.set_meta("respawn_timer", -1.0)
		sb.set_meta("origin_x", float(cd[0]))
		sb.set_meta("origin_y", float(cd[1]))
		sb.set_meta("width", float(cd[2]))
		sb.set_meta("height", float(cd[3]))

		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size  = Vector2(cd[2], cd[3])
		cs.shape = rs
		sb.add_child(cs)

		# Crate sprites for crumbling platforms
		var tile_w := 18.0 * 3.0
		var num_tiles := maxi(int(float(cd[2]) / tile_w), 1)
		for i in num_tiles:
			var s := Sprite2D.new()
			s.texture = load(Sprites.CRATE)
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.scale = Vector2(3, 3)
			s.position = Vector2(
				-float(cd[2]) * 0.5 + tile_w * 0.5 + i * tile_w,
				0
			)
			sb.add_child(s)

		w.add_child(sb)
		crumble_bodies.append(sb)
	return crumble_bodies

# -- Disappearing Platforms ----------------------------------------------------
static func make_disappear_platforms(w: Node2D, data: Array) -> Array:
	var disappear_bodies : Array = []
	for dd in data:
		var sb := StaticBody2D.new()
		sb.position = Vector2(dd[0], dd[1])
		sb.set_meta("disappear", true)
		sb.set_meta("on_time", float(dd[4]))
		sb.set_meta("off_time", float(dd[5]))
		sb.set_meta("phase", float(dd[6]))
		sb.set_meta("timer", float(dd[6]))
		sb.set_meta("is_on", true)

		var cs := CollisionShape2D.new()
		cs.name = "Col"
		var rs := RectangleShape2D.new()
		rs.size  = Vector2(dd[2], dd[3])
		cs.shape = rs
		sb.add_child(cs)

		var fill       := ColorRect.new()
		fill.name      = "Fill"
		fill.size      = Vector2(dd[2], dd[3])
		fill.position  = Vector2(-dd[2] * 0.5, -dd[3] * 0.5)
		fill.color     = Colors.DISAPPEAR_ON
		sb.add_child(fill)

		var border     := ColorRect.new()
		border.name    = "Border"
		border.size    = Vector2(dd[2] + 4, dd[3] + 4)
		border.position = Vector2(-dd[2] * 0.5 - 2, -dd[3] * 0.5 - 2)
		border.color   = Color(0.3, 0.75, 0.85, 0.25)
		border.z_index = -1
		sb.add_child(border)

		w.add_child(sb)
		disappear_bodies.append(sb)
	return disappear_bodies

# -- Spikes (Kenney spike sprite) ----------------------------------------------
static func make_spikes(w: Node2D, data: Array, on_hazard: Callable) -> void:
	for sd in data:
		var count   : int   = sd[2]
		var spacing : float = sd[3]
		var start_x : float = sd[0] - (count - 1) * spacing * 0.5

		for i in count:
			var area := Area2D.new()
			area.position = Vector2(start_x + i * spacing, sd[1])
			area.set_meta("hazard", true)

			var cs := CollisionShape2D.new()
			var tri := ConvexPolygonShape2D.new()
			tri.points = PackedVector2Array([
				Vector2(0, -14), Vector2(-8, 0), Vector2(8, 0),
			])
			cs.shape = tri
			area.add_child(cs)

			# Kenney spike sprite
			var s := Sprites.make_spike_sprite()
			s.position = Vector2(0, -6)
			area.add_child(s)

			area.body_entered.connect(on_hazard.bind(area))
			w.add_child(area)

# -- Saw Blades (Kenney saw sprite) --------------------------------------------
static func make_saw_blades(w: Node2D, data: Array, on_hazard: Callable) -> void:
	for sd in data:
		var area := Area2D.new()
		area.position = Vector2(sd[0], sd[1])
		area.set_meta("hazard", true)

		var cs := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = sd[2]
		cs.shape = circle
		area.add_child(cs)

		# Kenney saw sprite
		var s := Sprites.make_saw_sprite()
		area.add_child(s)

		area.body_entered.connect(on_hazard.bind(area))
		w.add_child(area)

		# Movement
		var axis     : String = sd[3]
		var dist     : float  = sd[4]
		var spd      : float  = sd[5]
		var duration : float  = dist / spd

		var tw := w.create_tween().set_loops()
		if axis == "x":
			tw.tween_property(area, "position:x", sd[0] + dist, duration)
			tw.tween_property(area, "position:x", sd[0] - dist, duration * 2.0)
			tw.tween_property(area, "position:x", float(sd[0]), duration)
		else:
			tw.tween_property(area, "position:y", sd[1] + dist, duration)
			tw.tween_property(area, "position:y", sd[1] - dist, duration * 2.0)
			tw.tween_property(area, "position:y", float(sd[1]), duration)

		# Spin
		var spin_tw := w.create_tween().set_loops()
		spin_tw.tween_property(area, "rotation", TAU, 0.8)

# -- Trampolines ---------------------------------------------------------------
static func make_trampolines(w: Node2D, data: Array, on_tramp: Callable) -> void:
	for td in data:
		var area := Area2D.new()
		area.position = Vector2(td[0], td[1])
		area.set_meta("trampoline", true)

		var cs := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(40, 12)
		cs.shape = rect
		area.add_child(cs)

		var base := ColorRect.new()
		base.size = Vector2(40, 12)
		base.position = Vector2(-20, -6)
		base.color = Colors.TRAMPOLINE_CLR
		area.add_child(base)

		var pad := ColorRect.new()
		pad.name = "Pad"
		pad.size = Vector2(44, 5)
		pad.position = Vector2(-22, -10)
		pad.color = Colors.TRAMPOLINE_PAD
		area.add_child(pad)

		for i in 3:
			var coil := ColorRect.new()
			coil.size = Vector2(3, 8)
			coil.position = Vector2(-12 + i * 10, -4)
			coil.color = Color(0.8, 0.35, 0.1)
			area.add_child(coil)

		area.body_entered.connect(on_tramp.bind(area))
		w.add_child(area)

# -- Checkpoints ---------------------------------------------------------------
static func make_checkpoints(w: Node2D, data: Array, on_check: Callable) -> void:
	for cd in data:
		var area := Area2D.new()
		area.position = Vector2(cd[0], cd[1])
		area.set_meta("checkpoint", true)
		area.set_meta("activated", false)

		var cs := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(16, 40)
		cs.shape = rect
		area.add_child(cs)

		# Flag pole sprite
		var pole := Sprite2D.new()
		pole.texture = load(Sprites.FLAG_POST)
		pole.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		pole.scale = Vector2(3, 3)
		pole.position = Vector2(0, -15)
		area.add_child(pole)

		# Flag triangle
		var flag := Polygon2D.new()
		flag.name = "Flag"
		flag.polygon = PackedVector2Array([
			Vector2(2, -30), Vector2(18, -22), Vector2(2, -14),
		])
		flag.color = Colors.CHECKPOINT_CLR
		area.add_child(flag)

		area.body_entered.connect(on_check.bind(area))
		w.add_child(area)

# -- Power-ups -----------------------------------------------------------------
static func make_powerups(w: Node2D, data: Array, on_powerup: Callable) -> void:
	for pd in data:
		var area := Area2D.new()
		area.position = Vector2(pd[0], pd[1])
		area.set_meta("powerup_type", pd[2])

		var cs := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 12.0
		cs.shape = circle
		area.add_child(cs)

		var is_shield : bool = pd[2] == "shield"

		# Use heart sprite for shield, diamond for speed
		var s := Sprite2D.new()
		s.texture = load(Sprites.HEART if is_shield else Sprites.DIAMOND)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.scale = Sprites.SCALE_TILE
		area.add_child(s)

		# Float animation
		var ftw := w.create_tween().set_loops()
		ftw.tween_property(area, "position:y", pd[1] - 5.0, 0.7).set_trans(Tween.TRANS_SINE)
		ftw.tween_property(area, "position:y", pd[1] + 5.0, 0.7).set_trans(Tween.TRANS_SINE)

		area.body_entered.connect(on_powerup.bind(area))
		w.add_child(area)

# -- Coins (Kenney coin sprite) ------------------------------------------------
static func make_coins(w: Node2D, positions: Array, on_coin: Callable) -> void:
	for pos in positions:
		var area := Area2D.new()
		area.position = pos
		area.set_meta("coin", true)

		var cs     := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 14.0
		cs.shape = circle
		area.add_child(cs)

		# Kenney coin sprite
		var s := Sprites.make_coin_sprite()
		area.add_child(s)

		var float_tw := w.create_tween().set_loops()
		float_tw.tween_property(area, "position:y", pos.y - 6.0, 0.8).set_trans(Tween.TRANS_SINE)
		float_tw.tween_property(area, "position:y", pos.y + 6.0, 0.8).set_trans(Tween.TRANS_SINE)

		area.body_entered.connect(on_coin.bind(area))
		w.add_child(area)

# -- Enemies (Kenney animated red character) -----------------------------------
static func make_enemies(w: Node2D, data: Array, on_enemy: Callable) -> void:
	for ed in data:
		var area := Area2D.new()
		area.position = Vector2(ed[0], ed[1])
		area.set_meta("patrol_center", float(ed[0]))
		area.set_meta("patrol_range", float(ed[2]))
		area.set_meta("patrol_speed", float(ed[3]))
		area.set_meta("direction", 1.0)

		var cs   := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(30, 30)
		cs.shape  = rect
		area.add_child(cs)

		# Kenney animated enemy sprite
		var anim := Sprites.make_enemy_animated()
		anim.name = "Anim"
		area.add_child(anim)

		area.body_entered.connect(on_enemy.bind(area))
		w.add_child(area)

# -- Shooters ------------------------------------------------------------------
static func make_shooters(w: Node2D, data: Array) -> void:
	for sd in data:
		var sb := StaticBody2D.new()
		sb.position = Vector2(sd[0], sd[1])
		sb.set_meta("shooter", true)
		sb.set_meta("fire_interval", float(sd[2]))
		sb.set_meta("bullet_speed", float(sd[3]))
		sb.set_meta("shoot_dir", float(sd[4]))
		sb.set_meta("fire_timer", float(sd[2]) * 0.5)

		var body := ColorRect.new()
		body.size = Vector2(24, 24)
		body.position = Vector2(-12, -12)
		body.color = Color(0.5, 0.15, 0.15)
		sb.add_child(body)

		var barrel := ColorRect.new()
		barrel.size = Vector2(14, 8)
		if sd[4] > 0:
			barrel.position = Vector2(10, -4)
		else:
			barrel.position = Vector2(-24, -4)
		barrel.color = Color(0.65, 0.2, 0.2)
		sb.add_child(barrel)

		var eye := ColorRect.new()
		eye.size = Vector2(8, 4)
		eye.position = Vector2(-4, -6)
		eye.color = Color(1.0, 0.3, 0.1)
		sb.add_child(eye)

		w.add_child(sb)

# -- Bullets -------------------------------------------------------------------
static func spawn_bullet(w: Node2D, pos: Vector2, dir: float, spd: float, on_bullet_hit: Callable) -> Area2D:
	var area := Area2D.new()
	area.position = pos
	area.set_meta("bullet", true)
	area.set_meta("bullet_dir", dir)
	area.set_meta("bullet_speed", spd)
	area.set_meta("lifetime", 5.0)

	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	cs.shape = circle
	area.add_child(cs)

	var poly := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 8:
		var a := i * TAU / 8.0
		pts.append(Vector2(cos(a) * 5, sin(a) * 5))
	poly.polygon = pts
	poly.color = Colors.BULLET_CLR
	area.add_child(poly)

	area.body_entered.connect(on_bullet_hit.bind(area))
	w.add_child(area)
	return area

# -- Player (Kenney animated green character) ----------------------------------
static func make_player(w: Node2D) -> CharacterBody2D:
	var p := CharacterBody2D.new()
	p.position = Vector2(640, 630)

	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size  = Vector2(36, 50)
	cs.shape = rs
	p.add_child(cs)

	# Kenney animated player sprite (replaces all ColorRect visuals)
	var anim := Sprites.make_player_animated()
	anim.name = "Anim"
	p.add_child(anim)

	# Shield visual
	var shield := Polygon2D.new()
	var spts := PackedVector2Array()
	for i in 6:
		var a := i * TAU / 6.0 - PI * 0.5
		spts.append(Vector2(cos(a) * 28, sin(a) * 32))
	shield.polygon = spts
	shield.color = Colors.SHIELD_CLR
	shield.visible = false
	p.add_child(shield)

	var cam := Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed   = 7.0
	cam.limit_left   = -100
	cam.limit_right  = 1380
	cam.limit_top    = -50
	cam.limit_bottom = 750
	p.add_child(cam)

	p.set_script(load("res://scripts/Player.gd"))

	# Old ColorRect refs are no longer needed, set to null
	p.body_rect  = null
	p.eye_l      = null
	p.eye_r      = null
	p.pupil_l    = null
	p.pupil_r    = null
	p.mouth_rect = null
	p.shield_vis = shield

	w.add_child(p)
	return p

# -- HUD -----------------------------------------------------------------------
static func make_hud(w: Node2D, total_coins: int, level_data: Dictionary, current_level: int) -> Dictionary:
	var cl := CanvasLayer.new()
	cl.layer = 10
	w.add_child(cl)

	var level_label := Label.new()
	level_label.text     = level_data.get("name", "Level %d" % current_level)
	level_label.position = Vector2(480, 16)
	level_label.add_theme_font_size_override("font_size", 20)
	level_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9, 0.7))
	cl.add_child(level_label)

	var score_label := Label.new()
	score_label.text     = "⭐  0 / %d" % total_coins
	score_label.position = Vector2(20, 16)
	score_label.add_theme_font_size_override("font_size", 26)
	score_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.55))
	cl.add_child(score_label)

	var hp_label := Label.new()
	hp_label.text     = "❤️ ♥ ♥ ♥ "
	hp_label.position = Vector2(20, 52)
	hp_label.add_theme_font_size_override("font_size", 22)
	hp_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	cl.add_child(hp_label)

	var shield_label := Label.new()
	shield_label.text     = ""
	shield_label.position = Vector2(20, 82)
	shield_label.add_theme_font_size_override("font_size", 18)
	shield_label.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	cl.add_child(shield_label)

	var timer_label := Label.new()
	timer_label.text     = "⏱  00:00.00"
	timer_label.position = Vector2(1080, 16)
	timer_label.add_theme_font_size_override("font_size", 22)
	timer_label.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	cl.add_child(timer_label)

	var hint := Label.new()
	hint.text     = "← → Move  Space Jump  Shift Dash  ↓ Portal  1 Easy  2 Med  3 Hard  4 Extreme  R Reroll  N/B +/- Lv"
	hint.position = Vector2(20, 692)
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65, 0.65))
	cl.add_child(hint)

	return {
		"score_label": score_label,
		"hp_label": hp_label,
		"timer_label": timer_label,
		"shield_label": shield_label,
		"level_label": level_label,
		"hud_layer": cl,
	}
