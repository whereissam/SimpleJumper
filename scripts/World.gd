extends Node2D

# ── Colors ────────────────────────────────────────────────────────────────────
const BG_COLOR    := Color(0.07, 0.07, 0.16)
const PLAT_FILL   := Color(0.22, 0.68, 0.32)
const PLAT_TOP    := Color(0.38, 0.90, 0.46)
const COIN_COLOR  := Color(1.00, 0.82, 0.08)
const PLAYER_CLR  := Color(0.28, 0.55, 1.00)
const ENEMY_CLR   := Color(0.85, 0.22, 0.25)
const ENEMY_EYE   := Color(1.0, 1.0, 1.0)
const WALL_COLOR  := Color(0.30, 0.30, 0.45)
const MOVING_FILL := Color(0.55, 0.35, 0.75)
const MOVING_TOP  := Color(0.72, 0.50, 0.90)

# ── Platform data: [center_x, center_y, width, height] ───────────────────────
var platform_data := [
	[640, 692, 1600, 36],
	[210, 560,  200, 22],
	[450, 490,  170, 22],
	[680, 424,  210, 22],
	[900, 500,  170, 22],
	[1100, 416, 190, 22],
	[340, 348,  170, 22],
	[580, 282,  150, 22],
	[820, 218,  170, 22],
	[1040, 310, 170, 22],
	[620, 152,  250, 22],
]

# Moving platforms: [center_x, center_y, width, height, axis, distance, speed]
var moving_platform_data := [
	[160, 430, 120, 18, "x", 180, 80],
	[950, 250, 100, 18, "y", 100, 60],
]

# Walls (for wall jumping): [center_x, center_y, width, height]
var wall_data := [
	[70,  500, 28, 200],
	[1210, 500, 28, 200],
]

# Coin positions (above each platform)
var coin_positions := [
	Vector2(210,  522), Vector2(450,  452), Vector2(680,  386),
	Vector2(900,  462), Vector2(1100, 378), Vector2(340,  310),
	Vector2(580,  244), Vector2(820,  180), Vector2(1040, 272),
	Vector2(620,  114),
]

# Enemies: [x, y, patrol_range, speed]
var enemy_data := [
	[640, 670, 120, 60],
	[210, 538, 80, 45],
	[680, 402, 90, 50],
	[820, 196, 70, 40],
]

# ── State ─────────────────────────────────────────────────────────────────────
var score          := 0
var total_coins    := 0
var score_label    : Label
var hp_label       : Label
var timer_label    : Label
var player_node    : CharacterBody2D
var elapsed_time   := 0.0
var level_complete := false

# ══════════════════════════════════════════════════════════════════════════════
func _ready() -> void:
	_make_background()
	_make_walls()
	_make_platforms()
	_make_moving_platforms()
	_make_coins()
	_make_enemies()
	_make_player()
	_make_hud()

func _process(delta: float) -> void:
	if not level_complete:
		elapsed_time += delta
		var mins := int(elapsed_time) / 60
		var secs := int(elapsed_time) % 60
		var ms   := int(fmod(elapsed_time, 1.0) * 100)
		timer_label.text = "⏱  %02d:%02d.%02d" % [mins, secs, ms]

# ── Background ────────────────────────────────────────────────────────────────
func _make_background() -> void:
	var cl := CanvasLayer.new()
	cl.layer = -10
	add_child(cl)

	var bg := ColorRect.new()
	bg.color    = BG_COLOR
	bg.size     = Vector2(1280, 720)
	bg.position = Vector2.ZERO
	cl.add_child(bg)

	# Decorative stars
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for _i in 60:
		var star := ColorRect.new()
		star.size     = Vector2(2, 2)
		star.color    = Color(1, 1, 1, rng.randf_range(0.2, 0.85))
		star.position = Vector2(rng.randf_range(0, 1280), rng.randf_range(0, 600))
		cl.add_child(star)

# ── Walls (for wall jumping) ─────────────────────────────────────────────────
func _make_walls() -> void:
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
		fill.color     = WALL_COLOR
		sb.add_child(fill)

		add_child(sb)

# ── Platforms ─────────────────────────────────────────────────────────────────
func _make_platforms() -> void:
	for pd in platform_data:
		_create_static_platform(pd, PLAT_FILL, PLAT_TOP)

func _create_static_platform(pd: Array, fill_color: Color, top_color: Color) -> StaticBody2D:
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

	add_child(sb)
	return sb

# ── Moving Platforms ──────────────────────────────────────────────────────────
func _make_moving_platforms() -> void:
	for mp in moving_platform_data:
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
		fill.color     = MOVING_FILL
		ab.add_child(fill)

		var top_bar    := ColorRect.new()
		top_bar.size   = Vector2(mp[2], 4)
		top_bar.position = Vector2(-mp[2] * 0.5, -mp[3] * 0.5)
		top_bar.color  = MOVING_TOP
		ab.add_child(top_bar)

		add_child(ab)

		# Ping-pong animation
		var axis     : String = mp[4]
		var dist     : float  = mp[5]
		var spd      : float  = mp[6]
		var duration : float  = dist / spd

		var tw := create_tween().set_loops()
		if axis == "x":
			tw.tween_property(ab, "position:x", mp[0] + dist, duration)
			tw.tween_property(ab, "position:x", mp[0] - dist, duration * 2.0)
			tw.tween_property(ab, "position:x", float(mp[0]), duration)
		else:
			tw.tween_property(ab, "position:y", mp[1] + dist, duration)
			tw.tween_property(ab, "position:y", mp[1] - dist, duration * 2.0)
			tw.tween_property(ab, "position:y", float(mp[1]), duration)

# ── Coins ─────────────────────────────────────────────────────────────────────
func _make_coins() -> void:
	total_coins = coin_positions.size()
	for pos in coin_positions:
		var area := Area2D.new()
		area.position = pos

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
		poly.color   = COIN_COLOR
		area.add_child(poly)

		var dot      := Polygon2D.new()
		var dpts     := PackedVector2Array()
		for i in 8:
			var a := i * TAU / 8.0
			dpts.append(Vector2(cos(a) * 4.0, sin(a) * 4.0))
		dot.polygon = dpts
		dot.color   = Color(1.0, 0.95, 0.5)
		area.add_child(dot)

		# Floating animation
		var float_tw := create_tween().set_loops()
		float_tw.tween_property(area, "position:y", pos.y - 6.0, 0.8).set_trans(Tween.TRANS_SINE)
		float_tw.tween_property(area, "position:y", pos.y + 6.0, 0.8).set_trans(Tween.TRANS_SINE)

		area.body_entered.connect(_on_coin_entered.bind(area))
		add_child(area)

func _on_coin_entered(body: Node2D, coin: Area2D) -> void:
	if body != player_node:
		return
	_spawn_coin_sparkle(coin.global_position)
	coin.queue_free()
	score += 1
	if score >= total_coins:
		score_label.text = "🎉  All collected! Level complete!"
		level_complete = true
	else:
		score_label.text = "⭐  %d / %d" % [score, total_coins]

func _spawn_coin_sparkle(pos: Vector2) -> void:
	for i in 8:
		var spark := ColorRect.new()
		spark.size  = Vector2(3, 3)
		spark.color = Color(1.0, 0.9, 0.2, 0.9)
		spark.position = pos
		spark.z_index = 5
		add_child(spark)

		var angle := i * TAU / 8.0
		var target := pos + Vector2(cos(angle) * 30, sin(angle) * 30)
		var tw := get_tree().create_tween()
		tw.set_parallel(true)
		tw.tween_property(spark, "position", target, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(spark, "modulate:a", 0.0, 0.3)
		tw.set_parallel(false)
		tw.tween_callback(spark.queue_free)

# ── Enemies ───────────────────────────────────────────────────────────────────
func _make_enemies() -> void:
	for ed in enemy_data:
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

		# Enemy body
		var body      := ColorRect.new()
		body.size     = Vector2(30, 24)
		body.position = Vector2(-15, -12)
		body.color    = ENEMY_CLR
		area.add_child(body)

		# Left eye
		var el      := ColorRect.new()
		el.size     = Vector2(6, 6)
		el.position = Vector2(-10, -8)
		el.color    = ENEMY_EYE
		area.add_child(el)

		# Right eye
		var er      := ColorRect.new()
		er.size     = Vector2(6, 6)
		er.position = Vector2(4, -8)
		er.color    = ENEMY_EYE
		area.add_child(er)

		area.body_entered.connect(_on_enemy_hit.bind(area))
		add_child(area)

func _on_enemy_hit(body: Node2D, enemy: Area2D) -> void:
	if body != player_node:
		return
	# Stomp check: player above enemy and falling down
	if player_node.velocity.y > 0 and player_node.global_position.y < enemy.global_position.y - 8:
		_kill_enemy(enemy)
		player_node.stomp_bounce()
	else:
		player_node.take_damage(1)
		# Knockback
		var knockback_dir : float = sign(player_node.global_position.x - enemy.global_position.x)
		if knockback_dir == 0:
			knockback_dir = 1
		player_node.velocity.x = knockback_dir * 250
		player_node.velocity.y = -200

func _kill_enemy(enemy: Area2D) -> void:
	var pos := enemy.global_position
	for i in 6:
		var p := ColorRect.new()
		p.size  = Vector2(5, 5)
		p.color = ENEMY_CLR
		p.position = pos + Vector2(randf_range(-10, 10), randf_range(-10, 10))
		p.z_index = 5
		add_child(p)

		var tw := get_tree().create_tween()
		tw.set_parallel(true)
		tw.tween_property(p, "position:y", p.position.y - randf_range(20, 50), 0.4)
		tw.tween_property(p, "modulate:a", 0.0, 0.4)
		tw.set_parallel(false)
		tw.tween_callback(p.queue_free)

	enemy.queue_free()

# Enemy patrol movement
func _physics_process(delta: float) -> void:
	for child in get_children():
		if child is Area2D and child.has_meta("patrol_center"):
			var center : float = child.get_meta("patrol_center")
			var prange : float = child.get_meta("patrol_range")
			var spd    : float = child.get_meta("patrol_speed")
			var dir    : float = child.get_meta("direction")

			child.position.x += dir * spd * delta

			if child.position.x > center + prange:
				child.set_meta("direction", -1.0)
			elif child.position.x < center - prange:
				child.set_meta("direction", 1.0)

# ── Player ────────────────────────────────────────────────────────────────────
func _make_player() -> void:
	var p := CharacterBody2D.new()
	p.position = Vector2(640, 630)

	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size  = Vector2(36, 50)
	cs.shape = rs
	p.add_child(cs)

	# Body
	var body      := ColorRect.new()
	body.size     = Vector2(36, 50)
	body.position = Vector2(-18, -25)
	body.color    = PLAYER_CLR
	p.add_child(body)

	# Eyes
	var el := _add_eye(p, Vector2(-12, -14))
	var er := _add_eye(p, Vector2( 3,  -14))

	# Mouth
	var mouth      := ColorRect.new()
	mouth.size     = Vector2(20, 4)
	mouth.position = Vector2(-10, 8)
	mouth.color    = Color(0.1, 0.15, 0.35)
	p.add_child(mouth)

	# Camera (follows player)
	var cam := Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed   = 7.0
	p.add_child(cam)

	p.set_script(load("res://scripts/Player.gd"))

	# Set visual node references
	p.body_rect  = body
	p.eye_l      = el[0]
	p.eye_r      = er[0]
	p.pupil_l    = el[1]
	p.pupil_r    = er[1]
	p.mouth_rect = mouth

	p.hp_changed.connect(_on_hp_changed)
	p.player_died.connect(_on_player_died)

	add_child(p)
	player_node = p

func _add_eye(parent: Node2D, pos: Vector2) -> Array:
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

func _on_hp_changed(new_hp: int) -> void:
	hp_label.text = "❤️ " + "♥ ".repeat(new_hp) + "♡ ".repeat(3 - new_hp)

func _on_player_died() -> void:
	# Reset coins and score
	score = 0
	elapsed_time = 0.0
	level_complete = false
	score_label.text = "⭐  0 / %d" % total_coins

	# Remove all Area2D children (coins + enemies)
	var to_remove := []
	for child in get_children():
		if child is Area2D and child != player_node:
			to_remove.append(child)
	for child in to_remove:
		child.queue_free()

	# Respawn after one frame
	await get_tree().process_frame
	_make_coins()
	_make_enemies()

# ── HUD ───────────────────────────────────────────────────────────────────────
func _make_hud() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 10
	add_child(cl)

	# Score
	score_label          = Label.new()
	score_label.text     = "⭐  0 / %d" % total_coins
	score_label.position = Vector2(20, 16)
	score_label.add_theme_font_size_override("font_size", 26)
	score_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.55))
	cl.add_child(score_label)

	# Health
	hp_label          = Label.new()
	hp_label.text     = "❤️ ♥ ♥ ♥ "
	hp_label.position = Vector2(20, 52)
	hp_label.add_theme_font_size_override("font_size", 22)
	hp_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	cl.add_child(hp_label)

	# Timer
	timer_label          = Label.new()
	timer_label.text     = "⏱  00:00.00"
	timer_label.position = Vector2(1080, 16)
	timer_label.add_theme_font_size_override("font_size", 22)
	timer_label.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	cl.add_child(timer_label)

	# Controls hint
	var hint      := Label.new()
	hint.text     = "← →  Move    Space/↑  Jump (double jump)    Shift  Dash    Wall+Jump  Wall jump"
	hint.position = Vector2(20, 692)
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65, 0.65))
	cl.add_child(hint)
