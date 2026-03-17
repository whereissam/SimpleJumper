class_name Builder
const Colors = preload("res://scripts/Colors.gd")
const Sprites = preload("res://scripts/Sprites.gd")

# -- Background (parallax with Kenney tiles) -----------------------------------
static func make_background(w: Node2D, level_data: Dictionary) -> void:
	# Solid color background (CanvasLayer so it never moves)
	var cl := CanvasLayer.new()
	cl.layer = -10
	w.add_child(cl)

	var bg := ColorRect.new()
	bg.color    = level_data.get("bg_color", Colors.BG_COLOR)
	bg.size     = Vector2(2560, 1440)
	bg.position = Vector2(-640, -360)
	cl.add_child(bg)

	var rng := RandomNumberGenerator.new()
	rng.seed = 42

	# Stars on fixed background
	for _i in 60:
		var star := ColorRect.new()
		star.size     = Vector2(2, 2)
		star.color    = Color(1, 1, 1, rng.randf_range(0.15, 0.7))
		star.position = Vector2(rng.randf_range(0, 1280), rng.randf_range(0, 700))
		cl.add_child(star)

	# Parallax layer 1: far mountains (moves slowly)
	var parallax := ParallaxBackground.new()
	# ParallaxBackground doesn't support z_index; add it early so it renders behind
	w.add_child(parallax)

	var far_layer := ParallaxLayer.new()
	far_layer.motion_scale = Vector2(0.15, 0.1)
	parallax.add_child(far_layer)

	for _i in 10:
		var s := Sprite2D.new()
		s.texture = load(Sprites.BG_SKY_MOUNT)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.scale = Vector2(6, 6)
		s.modulate = Color(1, 1, 1, 0.12)
		s.position = Vector2(rng.randf_range(-200, 1500), rng.randf_range(300, 600))
		far_layer.add_child(s)

	# Parallax layer 2: mid clouds (moves moderately)
	var mid_layer := ParallaxLayer.new()
	mid_layer.motion_scale = Vector2(0.3, 0.15)
	parallax.add_child(mid_layer)

	for _i in 8:
		var s := Sprite2D.new()
		s.texture = load(Sprites.BG_SKY_CLOUD)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.scale = Vector2(5, 5)
		s.modulate = Color(1, 1, 1, rng.randf_range(0.06, 0.15))
		s.position = Vector2(rng.randf_range(-200, 1500), rng.randf_range(100, 500))
		mid_layer.add_child(s)

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

		# Scale bricks to fit wall width
		var wall_scale : float = float(wd[2]) / 18.0
		var brick_size : float = 18.0 * wall_scale
		var num_v := maxi(int(float(wd[3]) / brick_size), 1)
		for row in num_v:
			var s := Sprite2D.new()
			s.texture = load(Sprites.BRICK)
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.scale = Vector2(wall_scale, wall_scale)
			s.position = Vector2(
				0,
				-float(wd[3]) * 0.5 + brick_size * 0.5 + row * brick_size
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

	# Ground floor (height > 30) is solid; all other platforms are one-way
	var is_ground : bool = int(pd[3]) > 30

	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size  = Vector2(pd[2], pd[3])
	cs.shape = rs
	if not is_ground:
		cs.one_way_collision = true  # Can jump through from below
	sb.add_child(cs)

	# Scale sprites to match collision height exactly
	var plat_h : float = pd[3]
	var sprite_scale : float = plat_h / 18.0  # 18px is raw tile size
	var tile_w : float = 18.0 * sprite_scale
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
		s.scale = Vector2(sprite_scale, sprite_scale)
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

		# Scale sprites to match collision height
		var mp_h : float = mp[3]
		var mp_scale : float = mp_h / 18.0
		var tile_w : float = 18.0 * mp_scale
		var num_tiles := maxi(int(float(mp[2]) / tile_w), 1)
		for i in num_tiles:
			var s := Sprite2D.new()
			s.texture = load(Sprites.WOOD_PLANK)
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.scale = Vector2(mp_scale, mp_scale)
			s.modulate = Color(0.8, 0.6, 1.0)
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

		# Scale crate sprites to match collision
		var cd_h : float = cd[3]
		var cd_scale : float = cd_h / 18.0
		var tile_w : float = 18.0 * cd_scale
		var num_tiles := maxi(int(float(cd[2]) / tile_w), 1)
		for i in num_tiles:
			var s := Sprite2D.new()
			s.texture = load(Sprites.CRATE)
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.scale = Vector2(cd_scale, cd_scale)
			s.position = Vector2(
				-float(cd[2]) * 0.5 + tile_w * 0.5 + i * tile_w,
				0
			)
			sb.add_child(s)

		w.add_child(sb)
		crumble_bodies.append(sb)
	return crumble_bodies

# -- Ice Platforms (slippery) --------------------------------------------------
static func make_ice_platforms(w: Node2D, data: Array) -> void:
	for pd in data:
		var sb := StaticBody2D.new()
		sb.position = Vector2(pd[0], pd[1])
		sb.set_meta("ice", true)

		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size  = Vector2(pd[2], pd[3])
		cs.shape = rs
		cs.one_way_collision = true
		sb.add_child(cs)

		# Light blue tinted platform
		var plat_h : float = pd[3]
		var sprite_scale : float = plat_h / 18.0
		var tile_w : float = 18.0 * sprite_scale
		var num_tiles := maxi(int(float(pd[2]) / tile_w), 1)
		for i in num_tiles:
			var s := Sprite2D.new()
			s.texture = load(Sprites.GRASS_TOP)
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.scale = Vector2(sprite_scale, sprite_scale)
			s.modulate = Color(0.6, 0.9, 1.0)  # Ice blue tint
			s.position = Vector2(
				-float(pd[2]) * 0.5 + tile_w * 0.5 + i * tile_w, 0
			)
			sb.add_child(s)

		# Ice shine particles (decorative)
		for i in 3:
			var shine := ColorRect.new()
			shine.size = Vector2(4, 2)
			shine.color = Color(1, 1, 1, 0.5)
			shine.position = Vector2(
				randf_range(-float(pd[2]) * 0.4, float(pd[2]) * 0.4),
				-float(pd[3]) * 0.3
			)
			sb.add_child(shine)

		w.add_child(sb)

# -- Conveyor Belt Platforms ---------------------------------------------------
static func make_conveyors(w: Node2D, data: Array) -> void:
	for pd in data:
		var sb := StaticBody2D.new()
		sb.position = Vector2(pd[0], pd[1])
		sb.set_meta("conveyor", true)
		sb.set_meta("conveyor_dir", float(pd[4]))
		sb.set_meta("conveyor_speed", 120.0)

		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size  = Vector2(pd[2], pd[3])
		cs.shape = rs
		cs.one_way_collision = true
		sb.add_child(cs)

		# Orange tinted platform
		var plat_h : float = pd[3]
		var sprite_scale : float = plat_h / 18.0
		var tile_w : float = 18.0 * sprite_scale
		var num_tiles := maxi(int(float(pd[2]) / tile_w), 1)
		for i in num_tiles:
			var s := Sprite2D.new()
			s.texture = load(Sprites.GRASS_TOP)
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.scale = Vector2(sprite_scale, sprite_scale)
			s.modulate = Color(1.0, 0.7, 0.3)  # Orange conveyor tint
			s.position = Vector2(
				-float(pd[2]) * 0.5 + tile_w * 0.5 + i * tile_w, 0
			)
			sb.add_child(s)

		# Direction arrows
		var arrow_dir := ">" if pd[4] > 0 else "<"
		for i in 3:
			var lbl := Label.new()
			lbl.text = arrow_dir
			lbl.add_theme_font_size_override("font_size", 14)
			lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
			lbl.position = Vector2(
				-float(pd[2]) * 0.3 + i * float(pd[2]) * 0.3 - 4,
				-float(pd[3]) * 0.8
			)
			sb.add_child(lbl)

		w.add_child(sb)

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

		# Tiled sprites with cyan tint (disappearing visual)
		var plat_h : float = dd[3]
		var dscale : float = plat_h / 18.0
		var dtile_w : float = 18.0 * dscale
		var dnum := maxi(int(float(dd[2]) / dtile_w), 1)
		var fill_container := Node2D.new()
		fill_container.name = "Fill"
		for i in dnum:
			var s := Sprite2D.new()
			s.texture = load(Sprites.GRASS_TOP)
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.scale = Vector2(dscale, dscale)
			s.modulate = Color(0.4, 0.9, 1.0)  # Cyan tint
			s.position = Vector2(
				-float(dd[2]) * 0.5 + dtile_w * 0.5 + i * dtile_w, 0
			)
			fill_container.add_child(s)
		sb.add_child(fill_container)

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

		# Positional buzz sound
		var buzz := AudioStreamPlayer2D.new()
		var buzz_path := "res://assets/audio/impact/impactMetal_light_001.ogg"
		if ResourceLoader.exists(buzz_path):
			buzz.stream = load(buzz_path)
			buzz.volume_db = -18.0
			buzz.max_distance = 300.0
			buzz.autoplay = true
			# Loop the sound
			if buzz.stream is AudioStreamOggVorbis:
				(buzz.stream as AudioStreamOggVorbis).loop = true
			area.add_child(buzz)

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
# -- Jumping Enemies -----------------------------------------------------------
static func make_jumpers(w: Node2D, data: Array, on_enemy: Callable) -> void:
	for jd in data:
		var area := Area2D.new()
		area.position = Vector2(jd[0], jd[1])
		area.set_meta("patrol_center", float(jd[0]))
		area.set_meta("patrol_range", float(jd[4]))
		area.set_meta("patrol_speed", float(jd[5]))
		area.set_meta("direction", 1.0)
		area.set_meta("jumper", true)
		area.set_meta("jump_interval", float(jd[2]))
		area.set_meta("jump_force", float(jd[3]))
		area.set_meta("jump_timer", float(jd[2]))
		area.set_meta("jumper_vy", 0.0)

		var cs := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(30, 30)
		cs.shape = rect
		area.add_child(cs)

		# Yellow character (different from red patrol enemies)
		var anim := AnimatedSprite2D.new()
		anim.name = "Anim"
		anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var frames := SpriteFrames.new()
		frames.add_animation("walk_right")
		frames.set_animation_speed("walk_right", 6)
		frames.set_animation_loop("walk_right", true)
		frames.add_frame("walk_right", load(Sprites.CHAR + "tile_0020.png"))
		frames.add_frame("walk_right", load(Sprites.CHAR + "tile_0021.png"))
		frames.add_frame("walk_right", load(Sprites.CHAR + "tile_0022.png"))
		frames.add_animation("walk_left")
		frames.set_animation_speed("walk_left", 6)
		frames.set_animation_loop("walk_left", true)
		frames.add_frame("walk_left", load(Sprites.CHAR + "tile_0025.png"))
		frames.add_frame("walk_left", load(Sprites.CHAR + "tile_0026.png"))
		if frames.has_animation("default"):
			frames.remove_animation("default")
		anim.sprite_frames = frames
		anim.scale = Sprites.SCALE_CHAR
		anim.play("walk_right")
		area.add_child(anim)

		area.body_entered.connect(on_enemy.bind(area))
		w.add_child(area)

# -- Wind Zones ----------------------------------------------------------------
static func make_wind_zones(w: Node2D, data: Array) -> void:
	for wd in data:
		var area := Area2D.new()
		area.position = Vector2(wd[0], wd[1])
		area.set_meta("wind_zone", true)
		area.set_meta("wind_dir", float(wd[4]))
		area.set_meta("wind_strength", float(wd[5]))

		var cs := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(wd[2], wd[3])
		cs.shape = rect
		area.add_child(cs)

		# Visual: semi-transparent colored zone with arrow indicators
		var fill := ColorRect.new()
		fill.size = Vector2(wd[2], wd[3])
		fill.position = Vector2(-float(wd[2]) * 0.5, -float(wd[3]) * 0.5)
		fill.color = Color(0.4, 0.7, 1.0, 0.08)
		area.add_child(fill)

		# Arrow particles showing wind direction
		var arrow_char := ">" if wd[4] > 0 else "<"
		for i in 5:
			var lbl := Label.new()
			lbl.text = arrow_char + arrow_char
			lbl.add_theme_font_size_override("font_size", 18)
			lbl.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0, 0.2))
			lbl.position = Vector2(
				randf_range(-float(wd[2]) * 0.4, float(wd[2]) * 0.3),
				randf_range(-float(wd[3]) * 0.4, float(wd[3]) * 0.3)
			)
			area.add_child(lbl)

		w.add_child(area)

# -- Keys (collectible) -------------------------------------------------------
static func make_keys(w: Node2D, data: Array, on_key: Callable) -> void:
	for kd in data:
		var area := Area2D.new()
		area.position = Vector2(kd[0], kd[1])
		area.set_meta("key_item", true)

		var cs := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 20.0
		cs.shape = circle
		area.add_child(cs)

		# Key visual: yellow diamond shape
		var icon := Polygon2D.new()
		icon.polygon = PackedVector2Array([
			Vector2(0, -12), Vector2(10, 0), Vector2(0, 12), Vector2(-10, 0),
		])
		icon.color = Color(1.0, 0.85, 0.15)
		area.add_child(icon)

		# Inner dot
		var dot := Polygon2D.new()
		var pts := PackedVector2Array()
		for i in 6:
			var a := i * TAU / 6.0
			pts.append(Vector2(cos(a) * 4, sin(a) * 4))
		dot.polygon = pts
		dot.color = Color(1.0, 0.95, 0.5)
		area.add_child(dot)

		# Float animation
		var ftw := w.create_tween().set_loops()
		ftw.tween_property(area, "position:y", kd[1] - 6.0, 0.6).set_trans(Tween.TRANS_SINE)
		ftw.tween_property(area, "position:y", kd[1] + 6.0, 0.6).set_trans(Tween.TRANS_SINE)

		# Glow rotation
		var spin := w.create_tween().set_loops()
		spin.tween_property(icon, "rotation", TAU, 3.0)

		area.body_entered.connect(on_key.bind(area))
		w.add_child(area)

# -- Boss Enemy ----------------------------------------------------------------
static func make_boss(w: Node2D, data: Array, on_enemy: Callable) -> Area2D:
	if data.is_empty():
		return null
	var area := Area2D.new()
	area.position = Vector2(data[0], data[1])
	area.set_meta("boss", true)
	area.set_meta("boss_hp", int(data[2]))
	area.set_meta("boss_max_hp", int(data[2]))
	area.set_meta("boss_speed", float(data[3]))
	area.set_meta("boss_fire_interval", float(data[4]))
	area.set_meta("boss_fire_timer", float(data[4]))
	area.set_meta("boss_dir", 1.0)
	area.set_meta("patrol_center", float(data[0]))  # For enemy hit detection

	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(60, 60)
	cs.shape = rect
	area.add_child(cs)

	# Big red enemy (scaled up)
	var anim := AnimatedSprite2D.new()
	anim.name = "Anim"
	anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frames := SpriteFrames.new()
	frames.add_animation("walk_right")
	frames.set_animation_speed("walk_right", 4)
	frames.set_animation_loop("walk_right", true)
	frames.add_frame("walk_right", load(Sprites.ENEMY_IDLE_R))
	frames.add_frame("walk_right", load(Sprites.ENEMY_WALK1_R))
	frames.add_frame("walk_right", load(Sprites.ENEMY_WALK2_R))
	frames.add_animation("walk_left")
	frames.set_animation_speed("walk_left", 4)
	frames.set_animation_loop("walk_left", true)
	frames.add_frame("walk_left", load(Sprites.ENEMY_IDLE_L))
	frames.add_frame("walk_left", load(Sprites.ENEMY_WALK1_L))
	frames.add_frame("walk_left", load(Sprites.ENEMY_WALK2_L))
	if frames.has_animation("default"):
		frames.remove_animation("default")
	anim.sprite_frames = frames
	anim.scale = Vector2(4.0, 4.0)  # 2x bigger than normal enemies
	anim.play("walk_right")
	area.add_child(anim)

	# HP bar above boss
	var bar_bg := ColorRect.new()
	bar_bg.name = "BarBg"
	bar_bg.size = Vector2(60, 6)
	bar_bg.position = Vector2(-30, -45)
	bar_bg.color = Color(0.2, 0.2, 0.2, 0.7)
	area.add_child(bar_bg)

	var bar_fill := ColorRect.new()
	bar_fill.name = "BarFill"
	bar_fill.size = Vector2(60, 6)
	bar_fill.position = Vector2(-30, -45)
	bar_fill.color = Color(0.9, 0.2, 0.15)
	area.add_child(bar_fill)

	area.body_entered.connect(on_enemy.bind(area))
	w.add_child(area)
	return area

# -- Coins (Kenney coin sprite) ------------------------------------------------
static func make_coins(w: Node2D, positions: Array, on_coin: Callable) -> void:
	for pos in positions:
		var area := Area2D.new()
		area.position = pos
		area.set_meta("coin", true)

		var cs     := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 24.0  # Bigger pickup radius
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

		# Use Kenney red character sprite as turret
		var turret_tex := Sprites.ENEMY_IDLE_R if sd[4] > 0 else Sprites.ENEMY_IDLE_L
		var turret := Sprite2D.new()
		turret.texture = load(turret_tex)
		turret.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		turret.scale = Sprites.SCALE_CHAR
		turret.modulate = Color(1.0, 0.5, 0.5)  # Lighter red tint
		sb.add_child(turret)

		# Barrel indicator
		var barrel := ColorRect.new()
		barrel.size = Vector2(12, 4)
		barrel.position = Vector2(8, -2) if sd[4] > 0 else Vector2(-20, -2)
		barrel.color = Color(0.8, 0.2, 0.1)
		sb.add_child(barrel)

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

	# Small red diamond sprite as bullet
	var s := Sprite2D.new()
	s.texture = load(Sprites.DIAMOND)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = Vector2(1.0, 1.0)  # Small
	s.modulate = Color(1.0, 0.3, 0.2)  # Red tint
	area.add_child(s)

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
	cam.limit_top    = -600  # Allow vertical climb maps
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

	# Coin icon next to score
	var coin_icon := Sprite2D.new()
	coin_icon.texture = load(Sprites.COIN)
	coin_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	coin_icon.scale = Vector2(1.5, 1.5)
	coin_icon.position = Vector2(34, 30)
	cl.add_child(coin_icon)

	var score_label := Label.new()
	score_label.text     = "  0 / %d" % total_coins
	score_label.position = Vector2(48, 16)
	score_label.add_theme_font_size_override("font_size", 26)
	score_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.55))
	cl.add_child(score_label)

	# Heart icons for HP display
	var hp_container := HBoxContainer.new()
	hp_container.name = "HpContainer"
	hp_container.position = Vector2(20, 52)
	for i in 3:
		var heart := Sprite2D.new()
		heart.name = "Heart%d" % i
		heart.texture = load(Sprites.HEART)
		heart.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		heart.scale = Vector2(1.5, 1.5)
		heart.position = Vector2(i * 30, 0)
		hp_container.add_child(heart)
	cl.add_child(hp_container)

	# Keep hp_label for compatibility but hide it (used for updates)
	var hp_label := Label.new()
	hp_label.text     = ""
	hp_label.position = Vector2(20, 52)
	hp_label.visible  = false
	cl.add_child(hp_label)

	# Shield icon (hidden until player has shield)
	var shield_icon := Sprite2D.new()
	shield_icon.name = "ShieldIcon"
	shield_icon.texture = load(Sprites.HEART)
	shield_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shield_icon.scale = Vector2(1.5, 1.5)
	shield_icon.modulate = Color(0.3, 0.9, 1.0)  # Cyan tint for shield
	shield_icon.position = Vector2(110, 62)
	shield_icon.visible = false
	cl.add_child(shield_icon)

	var shield_label := Label.new()
	shield_label.text     = ""
	shield_label.position = Vector2(124, 52)
	shield_label.add_theme_font_size_override("font_size", 16)
	shield_label.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	shield_label.visible = false
	cl.add_child(shield_label)

	var timer_label := Label.new()
	timer_label.text     = "⏱  00:00.00"
	timer_label.position = Vector2(1080, 16)
	timer_label.add_theme_font_size_override("font_size", 22)
	timer_label.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	cl.add_child(timer_label)

	var hint := Label.new()
	hint.text     = "← → Move  Space Jump  Z Dash  ↓ Crouch/Drop/Portal  1-4 Difficulty  R Reroll  N/B +/- Lv"
	hint.position = Vector2(20, 692)
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65, 0.65))
	cl.add_child(hint)

	return {
		"score_label": score_label,
		"hp_label": hp_label,
		"hp_container": hp_container,
		"timer_label": timer_label,
		"shield_label": shield_label,
		"shield_icon": shield_icon,
		"level_label": level_label,
		"hud_layer": cl,
	}
