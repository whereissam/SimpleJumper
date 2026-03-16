class_name Builder
const Colors = preload("res://scripts/Colors.gd")
# Helper functions that construct level elements and add them to the world node.
# Each function takes the world node (w) as the first parameter so it can
# call add_child and create_tween on it.

# -- Background ----------------------------------------------------------------
static func make_background(w: Node2D, level_data: Dictionary) -> void:
	var cl := CanvasLayer.new()
	cl.layer = -10
	w.add_child(cl)

	var bg := ColorRect.new()
	bg.color    = level_data.get("bg_color", Colors.BG_COLOR)
	bg.size     = Vector2(1280, 720)
	bg.position = Vector2.ZERO
	cl.add_child(bg)

	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for _i in 80:
		var star := ColorRect.new()
		star.size     = Vector2(2, 2)
		star.color    = Color(1, 1, 1, rng.randf_range(0.15, 0.85))
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

		var fill       := ColorRect.new()
		fill.size      = Vector2(wd[2], wd[3])
		fill.position  = Vector2(-wd[2] * 0.5, -wd[3] * 0.5)
		fill.color     = Colors.WALL_COLOR
		sb.add_child(fill)

		w.add_child(sb)

# -- Static Platforms ----------------------------------------------------------
static func make_platforms(w: Node2D, data: Array) -> void:
	for pd in data:
		_create_static_platform(w, pd, Colors.PLAT_FILL, Colors.PLAT_TOP)

static func _create_static_platform(w: Node2D, pd: Array, fill_color: Color, top_color: Color) -> StaticBody2D:
	var sb := StaticBody2D.new()
	sb.position = Vector2(pd[0], pd[1])

	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size  = Vector2(pd[2], pd[3])
	cs.shape = rs
	sb.add_child(cs)

	var fill       := ColorRect.new()
	fill.size      = Vector2(pd[2], pd[3])
	fill.position  = Vector2(-pd[2] * 0.5, -pd[3] * 0.5)
	fill.color     = fill_color
	sb.add_child(fill)

	var top        := ColorRect.new()
	top.size       = Vector2(pd[2], 5)
	top.position   = Vector2(-pd[2] * 0.5, -pd[3] * 0.5)
	top.color      = top_color
	sb.add_child(top)

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

		var fill       := ColorRect.new()
		fill.size      = Vector2(mp[2], mp[3])
		fill.position  = Vector2(-mp[2] * 0.5, -mp[3] * 0.5)
		fill.color     = Colors.MOVING_FILL
		ab.add_child(fill)

		var top_bar    := ColorRect.new()
		top_bar.size   = Vector2(mp[2], 4)
		top_bar.position = Vector2(-mp[2] * 0.5, -mp[3] * 0.5)
		top_bar.color  = Colors.MOVING_TOP
		ab.add_child(top_bar)

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

		var fill       := ColorRect.new()
		fill.name      = "Fill"
		fill.size      = Vector2(cd[2], cd[3])
		fill.position  = Vector2(-cd[2] * 0.5, -cd[3] * 0.5)
		fill.color     = Colors.CRUMBLE_FILL
		sb.add_child(fill)

		var top        := ColorRect.new()
		top.name       = "Top"
		top.size       = Vector2(cd[2], 4)
		top.position   = Vector2(-cd[2] * 0.5, -cd[3] * 0.5)
		top.color      = Colors.CRUMBLE_TOP
		sb.add_child(top)

		# Crack lines (decorative)
		for i in 3:
			var crack := ColorRect.new()
			crack.size = Vector2(2, cd[3] * 0.6)
			crack.position = Vector2(-cd[2] * 0.3 + i * cd[2] * 0.25, -cd[3] * 0.3)
			crack.color = Color(0.45, 0.38, 0.2, 0.5)
			sb.add_child(crack)

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

		# Blinking border
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

# -- Spikes --------------------------------------------------------------------
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
				Vector2(0, -14),
				Vector2(-8, 0),
				Vector2(8, 0),
			])
			cs.shape = tri
			area.add_child(cs)

			var poly := Polygon2D.new()
			poly.polygon = PackedVector2Array([
				Vector2(0, -14),
				Vector2(-8, 0),
				Vector2(8, 0),
			])
			poly.color = Colors.SPIKE_COLOR
			area.add_child(poly)

			# Highlight edge
			var highlight := Polygon2D.new()
			highlight.polygon = PackedVector2Array([
				Vector2(0, -14),
				Vector2(-3, -4),
				Vector2(3, -4),
			])
			highlight.color = Color(1.0, 0.5, 0.3, 0.6)
			area.add_child(highlight)

			area.body_entered.connect(on_hazard.bind(area))
			w.add_child(area)

# -- Saw Blades ----------------------------------------------------------------
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

		# Outer saw teeth
		var outer := Polygon2D.new()
		var pts := PackedVector2Array()
		var r : float = sd[2]
		for i in 16:
			var a := i * TAU / 16.0
			var rad := r if i % 2 == 0 else r * 0.7
			pts.append(Vector2(cos(a) * rad, sin(a) * rad))
		outer.polygon = pts
		outer.color = Colors.SAW_COLOR
		area.add_child(outer)

		# Inner circle
		var inner := Polygon2D.new()
		var ipts := PackedVector2Array()
		for i in 12:
			var a := i * TAU / 12.0
			ipts.append(Vector2(cos(a) * r * 0.35, sin(a) * r * 0.35))
		inner.polygon = ipts
		inner.color = Colors.SAW_INNER
		area.add_child(inner)

		area.body_entered.connect(on_hazard.bind(area))
		w.add_child(area)

		# Movement + spin
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

		# Base
		var base := ColorRect.new()
		base.size = Vector2(40, 12)
		base.position = Vector2(-20, -6)
		base.color = Colors.TRAMPOLINE_CLR
		area.add_child(base)

		# Bouncy pad on top
		var pad := ColorRect.new()
		pad.name = "Pad"
		pad.size = Vector2(44, 5)
		pad.position = Vector2(-22, -10)
		pad.color = Colors.TRAMPOLINE_PAD
		area.add_child(pad)

		# Spring coils (decorative)
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

		# Flag pole
		var pole := ColorRect.new()
		pole.size = Vector2(4, 40)
		pole.position = Vector2(-2, -30)
		pole.color = Color(0.5, 0.5, 0.5)
		area.add_child(pole)

		# Flag
		var flag := Polygon2D.new()
		flag.name = "Flag"
		flag.polygon = PackedVector2Array([
			Vector2(2, -30),
			Vector2(18, -22),
			Vector2(2, -14),
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

		# Outer glow
		var glow := Polygon2D.new()
		var gpts := PackedVector2Array()
		for i in 12:
			var a := i * TAU / 12.0
			gpts.append(Vector2(cos(a) * 16, sin(a) * 16))
		glow.polygon = gpts
		glow.color = (Colors.SHIELD_CLR if is_shield else Colors.SPEED_CLR) * Color(1, 1, 1, 0.3)
		area.add_child(glow)

		# Icon
		var icon := Polygon2D.new()
		if is_shield:
			icon.polygon = PackedVector2Array([
				Vector2(0, -10),
				Vector2(8, -5),
				Vector2(8, 3),
				Vector2(0, 10),
				Vector2(-8, 3),
				Vector2(-8, -5),
			])
			icon.color = Colors.SHIELD_CLR
		else:
			icon.polygon = PackedVector2Array([
				Vector2(-2, -10),
				Vector2(5, -2),
				Vector2(0, -1),
				Vector2(2, 10),
				Vector2(-5, 2),
				Vector2(0, 1),
			])
			icon.color = Colors.SPEED_CLR

		area.add_child(icon)

		# Float animation
		var ftw := w.create_tween().set_loops()
		ftw.tween_property(area, "position:y", pd[1] - 5.0, 0.7).set_trans(Tween.TRANS_SINE)
		ftw.tween_property(area, "position:y", pd[1] + 5.0, 0.7).set_trans(Tween.TRANS_SINE)

		area.body_entered.connect(on_powerup.bind(area))
		w.add_child(area)

# -- Coins ---------------------------------------------------------------------
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

		var poly := Polygon2D.new()
		var pts  := PackedVector2Array()
		for i in 12:
			var a := i * TAU / 12.0 - PI * 0.5
			pts.append(Vector2(cos(a) * 12.0, sin(a) * 12.0))
		poly.polygon = pts
		poly.color   = Colors.COIN_COLOR
		area.add_child(poly)

		var dot      := Polygon2D.new()
		var dpts     := PackedVector2Array()
		for i in 8:
			var a := i * TAU / 8.0
			dpts.append(Vector2(cos(a) * 4.0, sin(a) * 4.0))
		dot.polygon = dpts
		dot.color   = Color(1.0, 0.95, 0.5)
		area.add_child(dot)

		var float_tw := w.create_tween().set_loops()
		float_tw.tween_property(area, "position:y", pos.y - 6.0, 0.8).set_trans(Tween.TRANS_SINE)
		float_tw.tween_property(area, "position:y", pos.y + 6.0, 0.8).set_trans(Tween.TRANS_SINE)

		area.body_entered.connect(on_coin.bind(area))
		w.add_child(area)

# -- Enemies -------------------------------------------------------------------
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
		rect.size = Vector2(30, 24)
		cs.shape  = rect
		area.add_child(cs)

		var body      := ColorRect.new()
		body.size     = Vector2(30, 24)
		body.position = Vector2(-15, -12)
		body.color    = Colors.ENEMY_CLR
		area.add_child(body)

		var el      := ColorRect.new()
		el.size     = Vector2(6, 6)
		el.position = Vector2(-10, -8)
		el.color    = Colors.ENEMY_EYE
		area.add_child(el)

		var er      := ColorRect.new()
		er.size     = Vector2(6, 6)
		er.position = Vector2(4, -8)
		er.color    = Colors.ENEMY_EYE
		area.add_child(er)

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

		# Body (turret style)
		var body := ColorRect.new()
		body.size = Vector2(24, 24)
		body.position = Vector2(-12, -12)
		body.color = Color(0.5, 0.15, 0.15)
		sb.add_child(body)

		# Barrel
		var barrel := ColorRect.new()
		barrel.size = Vector2(14, 8)
		if sd[4] > 0:
			barrel.position = Vector2(10, -4)
		else:
			barrel.position = Vector2(-24, -4)
		barrel.color = Color(0.65, 0.2, 0.2)
		sb.add_child(barrel)

		# Eye (menacing)
		var eye := ColorRect.new()
		eye.size = Vector2(8, 4)
		eye.position = Vector2(-4, -6)
		eye.color = Color(1.0, 0.3, 0.1)
		sb.add_child(eye)

		w.add_child(sb)

# -- Bullets (spawned dynamically) ---------------------------------------------
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

	# Bullet visual
	var poly := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 8:
		var a := i * TAU / 8.0
		pts.append(Vector2(cos(a) * 5, sin(a) * 5))
	poly.polygon = pts
	poly.color = Colors.BULLET_CLR
	area.add_child(poly)

	# Inner glow
	var inner := Polygon2D.new()
	var ipts := PackedVector2Array()
	for i in 6:
		var a := i * TAU / 6.0
		ipts.append(Vector2(cos(a) * 2.5, sin(a) * 2.5))
	inner.polygon = ipts
	inner.color = Color(1.0, 0.8, 0.5)
	area.add_child(inner)

	area.body_entered.connect(on_bullet_hit.bind(area))
	w.add_child(area)
	return area

# -- Player --------------------------------------------------------------------
static func make_player(w: Node2D) -> CharacterBody2D:
	var p := CharacterBody2D.new()
	p.position = Vector2(640, 630)

	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size  = Vector2(36, 50)
	cs.shape = rs
	p.add_child(cs)

	var body      := ColorRect.new()
	body.size     = Vector2(36, 50)
	body.position = Vector2(-18, -25)
	body.color    = Colors.PLAYER_CLR
	p.add_child(body)

	var el := _add_eye(p, Vector2(-12, -14))
	var er := _add_eye(p, Vector2( 3,  -14))

	var mouth      := ColorRect.new()
	mouth.size     = Vector2(20, 4)
	mouth.position = Vector2(-10, 8)
	mouth.color    = Color(0.1, 0.15, 0.35)
	p.add_child(mouth)

	# Shield visual (hexagonal outline around player)
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

	p.body_rect  = body
	p.eye_l      = el[0]
	p.eye_r      = er[0]
	p.pupil_l    = el[1]
	p.pupil_r    = er[1]
	p.mouth_rect = mouth
	p.shield_vis = shield

	w.add_child(p)
	return p

static func _add_eye(parent: Node2D, pos: Vector2) -> Array:
	var white      := ColorRect.new()
	white.size     = Vector2(10, 10)
	white.position = pos
	white.color    = Color.WHITE
	parent.add_child(white)

	var pupil      := ColorRect.new()
	pupil.size     = Vector2(5, 5)
	pupil.position = pos + Vector2(3, 3)
	pupil.color    = Color(0.08, 0.08, 0.22)
	parent.add_child(pupil)

	return [white, pupil]

# -- HUD -----------------------------------------------------------------------
# Returns a dictionary with {score_label, hp_label, timer_label, shield_label, level_label, hud_layer}
static func make_hud(w: Node2D, total_coins: int, level_data: Dictionary, current_level: int) -> Dictionary:
	var cl := CanvasLayer.new()
	cl.layer = 10
	w.add_child(cl)

	# Level name
	var level_label          := Label.new()
	level_label.text     = level_data.get("name", "Level %d" % current_level)
	level_label.position = Vector2(480, 16)
	level_label.add_theme_font_size_override("font_size", 20)
	level_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9, 0.7))
	cl.add_child(level_label)

	var score_label          := Label.new()
	score_label.text     = "⭐  0 / %d" % total_coins
	score_label.position = Vector2(20, 16)
	score_label.add_theme_font_size_override("font_size", 26)
	score_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.55))
	cl.add_child(score_label)

	var hp_label          := Label.new()
	hp_label.text     = "❤️ ♥ ♥ ♥ "
	hp_label.position = Vector2(20, 52)
	hp_label.add_theme_font_size_override("font_size", 22)
	hp_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	cl.add_child(hp_label)

	var shield_label          := Label.new()
	shield_label.text     = ""
	shield_label.position = Vector2(20, 82)
	shield_label.add_theme_font_size_override("font_size", 18)
	shield_label.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	cl.add_child(shield_label)

	var timer_label          := Label.new()
	timer_label.text     = "⏱  00:00.00"
	timer_label.position = Vector2(1080, 16)
	timer_label.add_theme_font_size_override("font_size", 22)
	timer_label.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	cl.add_child(timer_label)

	var hint      := Label.new()
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
