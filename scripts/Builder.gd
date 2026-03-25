class_name Builder
const Colors = preload("res://scripts/Colors.gd")

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
	w.add_child(parallax)

	var far_layer := ParallaxLayer.new()
	far_layer.motion_scale = Vector2(0.15, 0.1)
	parallax.add_child(far_layer)

	for _i in 10:
		var s := Sprite2D.new()
		s.texture = Sprites.BG_SKY_MOUNT
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
		s.texture = Sprites.BG_SKY_CLOUD
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
			var s := Sprites.make_sprite(Sprites.BRICK, Vector2(wall_scale, wall_scale))
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
		cs.one_way_collision = true
	sb.add_child(cs)

	Sprites.tile_sprites(sb, float(pd[2]), float(pd[3]), Sprites.GRASS_TOP)

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

		Sprites.tile_sprites(ab, float(mp[2]), float(mp[3]), Sprites.WOOD_PLANK, Color(0.8, 0.6, 1.0))

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
static func make_crumble_platforms(w: Node2D, data: Array) -> Array[CrumblePlatform]:
	var bodies: Array[CrumblePlatform] = []
	for cd in data:
		var sb := CrumblePlatform.new()
		sb.position = Vector2(cd[0], cd[1])
		sb.origin_x = float(cd[0])
		sb.origin_y = float(cd[1])
		sb.width = float(cd[2])
		sb.height = float(cd[3])

		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size  = Vector2(cd[2], cd[3])
		cs.shape = rs
		sb.add_child(cs)

		Sprites.tile_sprites(sb, float(cd[2]), float(cd[3]), Sprites.CRATE)

		w.add_child(sb)
		bodies.append(sb)
	return bodies

# -- Ice Platforms (slippery) --------------------------------------------------
static func make_ice_platforms(w: Node2D, data: Array) -> Array[IcePlatform]:
	var bodies: Array[IcePlatform] = []
	for pd in data:
		var sb := IcePlatform.new()
		sb.position = Vector2(pd[0], pd[1])

		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size  = Vector2(pd[2], pd[3])
		cs.shape = rs
		cs.one_way_collision = true
		sb.add_child(cs)

		Sprites.tile_sprites(sb, float(pd[2]), float(pd[3]), Sprites.GRASS_TOP, Color(0.6, 0.9, 1.0))

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
		bodies.append(sb)
	return bodies

# -- Conveyor Belt Platforms ---------------------------------------------------
static func make_conveyors(w: Node2D, data: Array) -> Array[ConveyorPlatform]:
	var bodies: Array[ConveyorPlatform] = []
	for pd in data:
		var sb := ConveyorPlatform.new()
		sb.position = Vector2(pd[0], pd[1])
		sb.conveyor_dir = float(pd[4])

		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size  = Vector2(pd[2], pd[3])
		cs.shape = rs
		cs.one_way_collision = true
		sb.add_child(cs)

		Sprites.tile_sprites(sb, float(pd[2]), float(pd[3]), Sprites.GRASS_TOP, Color(1.0, 0.7, 0.3))

		# Direction arrows (scrolling)
		var arrow_dir := ">" if pd[4] > 0 else "<"
		var half_w := float(pd[2]) * 0.5
		for i in 3:
			var lbl := Label.new()
			lbl.text = arrow_dir
			lbl.add_theme_font_size_override("font_size", 14)
			lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
			var start_x := -half_w * 0.6 + i * half_w * 0.6 - 4
			lbl.position = Vector2(start_x, -float(pd[3]) * 0.8)
			sb.add_child(lbl)
			# Scroll arrow in conveyor direction, loop back
			var scroll_dist := half_w * 0.4
			var scroll_dir := float(pd[4])
			var atw := w.create_tween().set_loops()
			atw.tween_property(lbl, "position:x", start_x + scroll_dir * scroll_dist, 0.6).set_trans(Tween.TRANS_LINEAR)
			atw.tween_property(lbl, "modulate:a", 0.0, 0.1)
			atw.tween_callback(func(): lbl.position.x = start_x - scroll_dir * scroll_dist * 0.3)
			atw.tween_property(lbl, "modulate:a", 0.6, 0.1)
			# Stagger start
			atw.set_speed_scale(0.9 + i * 0.15)

		w.add_child(sb)
		bodies.append(sb)
	return bodies

# -- Disappearing Platforms ----------------------------------------------------
static func make_disappear_platforms(w: Node2D, data: Array) -> Array[DisappearPlatform]:
	var bodies: Array[DisappearPlatform] = []
	for dd in data:
		var sb := DisappearPlatform.new()
		sb.position = Vector2(dd[0], dd[1])
		sb.on_time = float(dd[4])
		sb.off_time = float(dd[5])
		sb.timer = float(dd[6])

		var cs := CollisionShape2D.new()
		cs.name = "Col"
		var rs := RectangleShape2D.new()
		rs.size  = Vector2(dd[2], dd[3])
		cs.shape = rs
		sb.add_child(cs)

		# Tiled sprites with cyan tint (disappearing visual)
		var fill_container := Node2D.new()
		fill_container.name = "Fill"
		var dscale := float(dd[3]) / 18.0
		var dtile_w := 18.0 * dscale
		var dnum := maxi(int(float(dd[2]) / dtile_w), 1)
		for i in dnum:
			var s := Sprites.make_sprite(Sprites.GRASS_TOP, Vector2(dscale, dscale))
			s.modulate = Color(0.4, 0.9, 1.0)
			s.position = Vector2(
				-float(dd[2]) * 0.5 + dtile_w * 0.5 + i * dtile_w, 0
			)
			fill_container.add_child(s)
		sb.add_child(fill_container)

		w.add_child(sb)
		bodies.append(sb)
	return bodies

# -- Spikes (Kenney spike sprite) ----------------------------------------------
static func make_spikes(w: Node2D, data: Array, on_hazard: Callable) -> void:
	for sd in data:
		var count   : int   = sd[2]
		var spacing : float = sd[3]
		var start_x : float = sd[0] - (count - 1) * spacing * 0.5

		for i in count:
			var area := Area2D.new()
			area.position = Vector2(start_x + i * spacing, sd[1])

			var cs := CollisionShape2D.new()
			var tri := ConvexPolygonShape2D.new()
			tri.points = PackedVector2Array([
				Vector2(0, -14), Vector2(-8, 0), Vector2(8, 0),
			])
			cs.shape = tri
			area.add_child(cs)

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

		var cs := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = sd[2]
		cs.shape = circle
		area.add_child(cs)

		var s := Sprites.make_saw_sprite()
		area.add_child(s)

		# Positional buzz sound
		var buzz := AudioStreamPlayer2D.new()
		buzz.stream = Sprites.SAW_BUZZ
		buzz.volume_db = -18.0
		buzz.max_distance = 300.0
		buzz.autoplay = true
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

		var cs := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(40, 12)
		cs.shape = rect
		area.add_child(cs)

		var spring := Sprites.make_sprite(Sprites.SPRING, Vector2(2.5, 2.5))
		spring.modulate = Colors.TRAMPOLINE_CLR
		spring.position = Vector2(0, -2)
		area.add_child(spring)

		area.body_entered.connect(on_tramp.bind(area))
		w.add_child(area)

# -- Checkpoints ---------------------------------------------------------------
static func make_checkpoints(w: Node2D, data: Array, on_check: Callable) -> void:
	for cd in data:
		var area := Area2D.new()
		area.position = Vector2(cd[0], cd[1])
		area.set_meta("activated", false)
		area.add_to_group("checkpoints")

		var cs := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(16, 40)
		cs.shape = rect
		area.add_child(cs)

		var pole := Sprites.make_sprite(Sprites.FLAG_POST, Vector2(3, 3))
		pole.position = Vector2(0, -15)
		area.add_child(pole)

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
		area.add_to_group("powerups")

		var cs := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 12.0
		cs.shape = circle
		area.add_child(cs)

		var is_shield : bool = pd[2] == "shield"
		var s := Sprites.make_sprite(Sprites.HEART if is_shield else Sprites.DIAMOND)
		area.add_child(s)

		# Sparkle trail (cyan for shield, orange for speed)
		var trail_color := Color(0.3, 0.9, 1.0, 0.7) if is_shield else Color(1.0, 0.55, 0.1, 0.7)
		var trail := _make_sparkle_particles(trail_color, 3, 0.6)
		area.add_child(trail)

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
		area.add_to_group("coins")

		var cs     := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 24.0
		cs.shape = circle
		area.add_child(cs)

		var s := Sprites.make_coin_sprite()
		s.name = "CoinSprite"
		area.add_child(s)

		var float_tw := w.create_tween().set_loops()
		float_tw.tween_property(area, "position:y", pos.y - 6.0, 0.8).set_trans(Tween.TRANS_SINE)
		float_tw.tween_property(area, "position:y", pos.y + 6.0, 0.8).set_trans(Tween.TRANS_SINE)

		# Coin spin (horizontal scale oscillation)
		var spin_tw := w.create_tween().set_loops()
		spin_tw.tween_property(s, "scale:x", -Sprites.SCALE_TILE.x, 0.3).set_trans(Tween.TRANS_SINE)
		spin_tw.tween_property(s, "scale:x", Sprites.SCALE_TILE.x, 0.3).set_trans(Tween.TRANS_SINE)

		area.body_entered.connect(on_coin.bind(area))
		w.add_child(area)

# -- Enemies (Kenney animated red character) -----------------------------------
static func make_enemies(w: Node2D, data: Array, on_enemy: Callable) -> Array[PatrolEnemy]:
	var enemies: Array[PatrolEnemy] = []
	for ed in data:
		var area := PatrolEnemy.new()
		area.position = Vector2(ed[0], ed[1])
		area.patrol_center = float(ed[0])
		area.patrol_range = float(ed[2])
		area.patrol_speed = float(ed[3])

		var cs   := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(30, 30)
		cs.shape  = rect
		area.add_child(cs)

		var anim := Sprites.make_enemy_animated()
		anim.name = "Anim"
		area.add_child(anim)

		area.body_entered.connect(on_enemy.bind(area))
		w.add_child(area)
		enemies.append(area)
	return enemies

# -- Jumping Enemies -----------------------------------------------------------
static func make_jumpers(w: Node2D, data: Array, on_enemy: Callable) -> Array[JumpingEnemy]:
	var jumpers: Array[JumpingEnemy] = []
	for jd in data:
		var area := JumpingEnemy.new()
		area.position = Vector2(jd[0], jd[1])
		area.patrol_center = float(jd[0])  # Used as spawn Y for ground clamping
		area.patrol_range = float(jd[4])
		area.patrol_speed = float(jd[5])
		area.jump_interval = float(jd[2])
		area.jump_force = float(jd[3])
		area.jump_timer = float(jd[2])

		var cs := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(30, 30)
		cs.shape = rect
		area.add_child(cs)

		var anim := Sprites.make_jumper_animated()
		anim.name = "Anim"
		area.add_child(anim)

		area.body_entered.connect(on_enemy.bind(area))
		w.add_child(area)
		jumpers.append(area)
	return jumpers

# -- Wind Zones ----------------------------------------------------------------
# -- Flying Enemies ------------------------------------------------------------
static func make_flyers(w: Node2D, data: Array, on_enemy: Callable) -> Array:
	var FlyerClass : GDScript = load("res://scripts/entities/FlyingEnemy.gd")
	var flyers: Array = []
	for fd in data:
		var area : Area2D = FlyerClass.new()
		area.position = Vector2(fd[0], fd[1])
		area.patrol_center_x = float(fd[0])
		area.patrol_center_y = float(fd[1])
		area.patrol_range = float(fd[2])
		area.patrol_speed = float(fd[3])
		area.wave_amplitude = float(fd[4])
		area.wave_speed = float(fd[5])

		var cs := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(30, 30)
		cs.shape = rect
		area.add_child(cs)

		var anim := Sprites.make_enemy_animated()
		anim.name = "Anim"
		anim.modulate = Color(0.6, 0.4, 1.0)  # Purple tint for flyers
		area.add_child(anim)

		area.body_entered.connect(on_enemy.bind(area))
		w.add_child(area)
		flyers.append(area)
	return flyers

# -- Shielded Enemies ----------------------------------------------------------
static func make_shielded(w: Node2D, data: Array, on_enemy: Callable) -> Array:
	var ShieldClass : GDScript = load("res://scripts/entities/ShieldedEnemy.gd")
	var shielded: Array = []
	for sd in data:
		var area : Area2D = ShieldClass.new()
		area.position = Vector2(sd[0], sd[1])
		area.patrol_center = float(sd[0])
		area.patrol_range = float(sd[2])
		area.patrol_speed = float(sd[3])
		area.shield_hp = int(sd[4])

		var cs := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(30, 30)
		cs.shape = rect
		area.add_child(cs)

		var anim := Sprites.make_enemy_animated()
		anim.name = "Anim"
		anim.modulate = Color(0.4, 0.8, 1.0)  # Blue tint for shielded
		area.add_child(anim)

		area.body_entered.connect(on_enemy.bind(area))
		w.add_child(area)
		shielded.append(area)
	return shielded

# -- Wind Zones ----------------------------------------------------------------
static func make_wind_zones(w: Node2D, data: Array) -> Array[WindZone]:
	var zones: Array[WindZone] = []
	for wd in data:
		var area := WindZone.new()
		area.position = Vector2(wd[0], wd[1])
		area.wind_dir = float(wd[4])
		area.wind_strength = float(wd[5])
		area.zone_width = float(wd[2])
		area.zone_height = float(wd[3])

		var cs := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(wd[2], wd[3])
		cs.shape = rect
		area.add_child(cs)

		# Visual: semi-transparent zone + GPU particle streamlines
		var fill := ColorRect.new()
		fill.size = Vector2(wd[2], wd[3])
		fill.position = Vector2(-float(wd[2]) * 0.5, -float(wd[3]) * 0.5)
		fill.color = Color(0.4, 0.7, 1.0, 0.08)
		area.add_child(fill)

		# Particle streamlines flowing in wind direction
		var wind_particles := GPUParticles2D.new()
		wind_particles.amount = 12
		wind_particles.lifetime = 1.5
		wind_particles.emitting = true
		wind_particles.explosiveness = 0.0

		var wmat := ParticleProcessMaterial.new()
		wmat.direction = Vector3(float(wd[4]), 0, 0)
		wmat.spread = 10.0
		wmat.initial_velocity_min = float(wd[5]) * 0.4
		wmat.initial_velocity_max = float(wd[5]) * 0.8
		wmat.gravity = Vector3(0, 0, 0)
		wmat.scale_min = 1.0
		wmat.scale_max = 2.5
		wmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		wmat.emission_box_extents = Vector3(float(wd[2]) * 0.4, float(wd[3]) * 0.4, 0)

		var wgrad := Gradient.new()
		wgrad.set_color(0, Color(0.5, 0.8, 1.0, 0.3))
		wgrad.set_color(1, Color(0.5, 0.8, 1.0, 0.0))
		var wgrad_tex := GradientTexture1D.new()
		wgrad_tex.gradient = wgrad
		wmat.color_ramp = wgrad_tex

		wind_particles.process_material = wmat
		area.add_child(wind_particles)

		w.add_child(area)
		zones.append(area)
	return zones

# -- Keys (collectible) -------------------------------------------------------
static func make_keys(w: Node2D, data: Array, on_key: Callable) -> void:
	for kd in data:
		var area := Area2D.new()
		area.position = Vector2(kd[0], kd[1])

		var cs := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 20.0
		cs.shape = circle
		area.add_child(cs)

		var icon := Sprites.make_sprite(Sprites.KEY, Vector2(2.5, 2.5))
		icon.modulate = Color(1.0, 0.85, 0.15)
		area.add_child(icon)

		# Gold sparkle trail
		var trail := _make_sparkle_particles(Color(1.0, 0.85, 0.15, 0.8), 4, 0.8)
		area.add_child(trail)

		var ftw := w.create_tween().set_loops()
		ftw.tween_property(area, "position:y", kd[1] - 6.0, 0.6).set_trans(Tween.TRANS_SINE)
		ftw.tween_property(area, "position:y", kd[1] + 6.0, 0.6).set_trans(Tween.TRANS_SINE)

		var spin := w.create_tween().set_loops()
		spin.tween_property(icon, "rotation", TAU, 3.0)

		area.body_entered.connect(on_key.bind(area))
		w.add_child(area)

# -- Boss Enemy ----------------------------------------------------------------
static func make_boss(w: Node2D, data: Array, on_enemy: Callable) -> BossEnemy:
	if data.is_empty():
		return null
	var area := BossEnemy.new()
	area.position = Vector2(data[0], data[1])
	area.boss_hp = int(data[2])
	area.boss_max_hp = int(data[2])
	area.boss_speed = float(data[3])
	area.boss_fire_interval = float(data[4])
	area.boss_fire_timer = float(data[4])

	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(60, 60)
	cs.shape = rect
	area.add_child(cs)

	var anim := Sprites.make_boss_animated()
	anim.name = "Anim"
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

# -- Shooters ------------------------------------------------------------------
static func make_shooters(w: Node2D, data: Array) -> Array[Shooter]:
	var shooters: Array[Shooter] = []
	for sd in data:
		var sb := Shooter.new()
		sb.position = Vector2(sd[0], sd[1])
		sb.fire_interval = float(sd[2])
		sb.bullet_speed = float(sd[3])
		sb.shoot_dir = float(sd[4])
		sb.fire_timer = float(sd[2]) * 0.5

		var turret_tex: Texture2D = Sprites.ENEMY_IDLE_R if sd[4] > 0 else Sprites.ENEMY_IDLE_L
		var turret := Sprites.make_sprite(turret_tex, Sprites.SCALE_CHAR)
		turret.modulate = Color(1.0, 0.5, 0.5)
		sb.add_child(turret)

		var barrel := ColorRect.new()
		barrel.size = Vector2(12, 4)
		barrel.position = Vector2(8, -2) if sd[4] > 0 else Vector2(-20, -2)
		barrel.color = Color(0.8, 0.2, 0.1)
		sb.add_child(barrel)

		w.add_child(sb)
		shooters.append(sb)
	return shooters

# -- Bullets -------------------------------------------------------------------
static func spawn_bullet(w: Node2D, pos: Vector2, dir: float, spd: float, on_bullet_hit: Callable) -> Bullet:
	var area := Bullet.new()
	area.position = pos
	area.bullet_dir = dir
	area.bullet_speed = spd

	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	cs.shape = circle
	area.add_child(cs)

	var s := Sprites.make_sprite(Sprites.DIAMOND, Vector2(1.0, 1.0))
	s.modulate = Color(1.0, 0.3, 0.2)
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

	var anim := Sprites.make_player_animated()
	anim.name = "Anim"
	p.add_child(anim)

	# Shield visual (offset up so it doesn't clip below feet)
	var shield := Polygon2D.new()
	shield.position = Vector2(0, -5)
	var spts := PackedVector2Array()
	for i in 6:
		var a := i * TAU / 6.0 - PI * 0.5
		spts.append(Vector2(cos(a) * 26, sin(a) * 24))
	shield.polygon = spts
	shield.color = Colors.SHIELD_CLR
	shield.visible = false
	p.add_child(shield)

	var cam := Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed   = 7.0
	cam.limit_left   = -100
	cam.limit_right  = 1380
	cam.limit_top    = -600
	cam.limit_bottom = 750
	p.add_child(cam)

	p.set_script(load("res://scripts/Player.gd"))

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
	var coin_icon := Sprites.make_sprite(Sprites.COIN, Vector2(1.5, 1.5))
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
		var heart := Sprites.make_sprite(Sprites.HEART, Vector2(1.5, 1.5))
		heart.name = "Heart%d" % i
		heart.position = Vector2(i * 30, 0)
		hp_container.add_child(heart)
	cl.add_child(hp_container)

	var hp_label := Label.new()
	hp_label.text     = ""
	hp_label.position = Vector2(20, 52)
	hp_label.visible  = false
	cl.add_child(hp_label)

	# Shield icon (hidden until player has shield)
	var shield_icon := Sprites.make_sprite(Sprites.HEART, Vector2(1.5, 1.5))
	shield_icon.name = "ShieldIcon"
	shield_icon.modulate = Color(0.3, 0.9, 1.0)
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

# -- Reusable sparkle particle effect for floating items -----------------------
static func _make_sparkle_particles(color: Color, amount: int = 4, lifetime: float = 0.8) -> GPUParticles2D:
	var particles := GPUParticles2D.new()
	particles.amount = amount
	particles.lifetime = lifetime
	particles.emitting = true
	particles.explosiveness = 0.0

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 8.0
	mat.initial_velocity_max = 20.0
	mat.gravity = Vector3(0, -10, 0)
	mat.scale_min = 1.5
	mat.scale_max = 3.0

	var grad := Gradient.new()
	grad.set_color(0, color)
	grad.set_color(1, Color(color.r, color.g, color.b, 0.0))
	var grad_tex := GradientTexture1D.new()
	grad_tex.gradient = grad
	mat.color_ramp = grad_tex

	particles.process_material = mat
	return particles
