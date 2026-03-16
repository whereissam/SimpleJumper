extends Node2D

# ── Colors ────────────────────────────────────────────────────────────────────
const BG_COLOR      := Color(0.07, 0.07, 0.16)
const PLAT_FILL     := Color(0.22, 0.68, 0.32)
const PLAT_TOP      := Color(0.38, 0.90, 0.46)
const COIN_COLOR    := Color(1.00, 0.82, 0.08)
const PLAYER_CLR    := Color(0.28, 0.55, 1.00)
const ENEMY_CLR     := Color(0.85, 0.22, 0.25)
const ENEMY_EYE     := Color(1.0, 1.0, 1.0)
const WALL_COLOR    := Color(0.30, 0.30, 0.45)
const MOVING_FILL   := Color(0.55, 0.35, 0.75)
const MOVING_TOP    := Color(0.72, 0.50, 0.90)
const SPIKE_COLOR   := Color(0.95, 0.25, 0.15)
const SAW_COLOR     := Color(0.6, 0.6, 0.6)
const SAW_INNER     := Color(0.35, 0.35, 0.35)
const CRUMBLE_FILL  := Color(0.65, 0.55, 0.30)
const CRUMBLE_TOP   := Color(0.80, 0.70, 0.40)
const DISAPPEAR_ON  := Color(0.3, 0.75, 0.85)
const DISAPPEAR_OFF := Color(0.15, 0.35, 0.42, 0.3)
const TRAMPOLINE_CLR := Color(1.0, 0.45, 0.15)
const TRAMPOLINE_PAD := Color(1.0, 0.7, 0.2)
const CHECKPOINT_CLR := Color(0.2, 0.85, 0.4)
const CHECKPOINT_ACT := Color(1.0, 0.9, 0.2)
const SHIELD_CLR    := Color(0.3, 0.9, 1.0, 0.4)
const SPEED_CLR     := Color(1.0, 0.55, 0.1)
const BULLET_CLR    := Color(1.0, 0.3, 0.3)
const PORTAL_CLR_A  := Color(0.4, 0.2, 0.9, 0.7)
const PORTAL_CLR_B  := Color(0.9, 0.4, 0.1, 0.7)
const PORTAL_GLOW_A := Color(0.6, 0.4, 1.0, 0.3)
const PORTAL_GLOW_B := Color(1.0, 0.6, 0.2, 0.3)

# ── Level data (loaded from LevelData.gd) ─────────────────────────────────────
var current_level  := 1
var level          : Dictionary
var platform_data  : Array
var moving_platform_data : Array
var wall_data      : Array
var crumble_data   : Array
var disappear_data : Array
var spike_data     : Array
var saw_data       : Array
var trampoline_data : Array
var checkpoint_data : Array
var powerup_data   : Array
var coin_positions : Array
var enemy_data     : Array
var shooter_data   : Array
var portal_data    : Array

# ── State ─────────────────────────────────────────────────────────────────────
var score          := 0
var total_coins    := 0
var score_label    : Label
var hp_label       : Label
var timer_label    : Label
var shield_label   : Label
var player_node    : CharacterBody2D
var elapsed_time   := 0.0
var level_complete := false
var bullets        : Array = []
var crumble_bodies : Array = []
var disappear_bodies : Array = []
var portal_pairs   : Array = []  # [{area_a, area_b, prompt_a, prompt_b}, ...]
var portal_cooldown := 0.0
var minimap_node   : Control    # Minimap container
var minimap_player : ColorRect  # Player dot on minimap

var level_label    : Label
var next_portal    : Area2D  # Appears when level is complete
var world_seed     := 0      # Random seed for this session
var seed_label     : Label

# ══════════════════════════════════════════════════════════════════════════════
func _ready() -> void:
	randomize()
	# Check if we're coming from a level switch or fresh start
	if _next_seed != 0:
		world_seed = _next_seed
		current_level = _next_level
		_next_seed = 0
	else:
		world_seed = randi() % 999999
	_load_level(current_level)
	_build_world()

func _load_level(num: int) -> void:
	level = LevelData.get_level(num, world_seed + num)
	platform_data        = level.get("platforms", [])
	moving_platform_data = level.get("moving", [])
	wall_data            = level.get("walls", [])
	crumble_data         = level.get("crumble", [])
	disappear_data       = level.get("disappear", [])
	spike_data           = level.get("spikes", [])
	saw_data             = level.get("saws", [])
	trampoline_data      = level.get("trampolines", [])
	checkpoint_data      = level.get("checkpoints", [])
	powerup_data         = level.get("powerups", [])
	coin_positions       = level.get("coins", [])
	enemy_data           = level.get("enemies", [])
	shooter_data         = level.get("shooters", [])
	portal_data          = level.get("portals", [])

func _build_world() -> void:
	_make_background()
	_make_walls()
	_make_platforms()
	_make_moving_platforms()
	_make_crumble_platforms()
	_make_disappear_platforms()
	_make_spikes()
	_make_saw_blades()
	_make_trampolines()
	_make_checkpoints()
	_make_portals()
	_make_powerups()
	_make_coins()
	_make_enemies()
	_make_shooters()
	_make_player()
	_make_hud()

func _process(delta: float) -> void:
	if not player_node or not timer_label:
		return
	portal_cooldown = maxf(portal_cooldown - delta, 0.0)
	_check_portal_input()
	_update_minimap()
	# Check exit portal
	if player_near_exit and Input.is_action_just_pressed("ui_down"):
		player_near_exit = false
		_go_next_level()
		return
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
	bg.color    = level.get("bg_color", BG_COLOR)
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

# ── Walls ─────────────────────────────────────────────────────────────────────
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

# ── Crumbling Platforms ───────────────────────────────────────────────────────
func _make_crumble_platforms() -> void:
	for cd in crumble_data:
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
		fill.color     = CRUMBLE_FILL
		sb.add_child(fill)

		var top        := ColorRect.new()
		top.name       = "Top"
		top.size       = Vector2(cd[2], 4)
		top.position   = Vector2(-cd[2] * 0.5, -cd[3] * 0.5)
		top.color      = CRUMBLE_TOP
		sb.add_child(top)

		# Crack lines (decorative)
		for i in 3:
			var crack := ColorRect.new()
			crack.size = Vector2(2, cd[3] * 0.6)
			crack.position = Vector2(-cd[2] * 0.3 + i * cd[2] * 0.25, -cd[3] * 0.3)
			crack.color = Color(0.45, 0.38, 0.2, 0.5)
			sb.add_child(crack)

		add_child(sb)
		crumble_bodies.append(sb)

# ── Disappearing Platforms ────────────────────────────────────────────────────
func _make_disappear_platforms() -> void:
	for dd in disappear_data:
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
		fill.color     = DISAPPEAR_ON
		sb.add_child(fill)

		# Blinking border
		var border     := ColorRect.new()
		border.name    = "Border"
		border.size    = Vector2(dd[2] + 4, dd[3] + 4)
		border.position = Vector2(-dd[2] * 0.5 - 2, -dd[3] * 0.5 - 2)
		border.color   = Color(0.3, 0.75, 0.85, 0.25)
		border.z_index = -1
		sb.add_child(border)

		add_child(sb)
		disappear_bodies.append(sb)

# ── Spikes ────────────────────────────────────────────────────────────────────
func _make_spikes() -> void:
	for sd in spike_data:
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
			poly.color = SPIKE_COLOR
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

			area.body_entered.connect(_on_hazard_hit.bind(area))
			add_child(area)

# ── Saw Blades ────────────────────────────────────────────────────────────────
func _make_saw_blades() -> void:
	for sd in saw_data:
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
		outer.color = SAW_COLOR
		area.add_child(outer)

		# Inner circle
		var inner := Polygon2D.new()
		var ipts := PackedVector2Array()
		for i in 12:
			var a := i * TAU / 12.0
			ipts.append(Vector2(cos(a) * r * 0.35, sin(a) * r * 0.35))
		inner.polygon = ipts
		inner.color = SAW_INNER
		area.add_child(inner)

		area.body_entered.connect(_on_hazard_hit.bind(area))
		add_child(area)

		# Movement + spin
		var axis     : String = sd[3]
		var dist     : float  = sd[4]
		var spd      : float  = sd[5]
		var duration : float  = dist / spd

		var tw := create_tween().set_loops()
		if axis == "x":
			tw.tween_property(area, "position:x", sd[0] + dist, duration)
			tw.tween_property(area, "position:x", sd[0] - dist, duration * 2.0)
			tw.tween_property(area, "position:x", float(sd[0]), duration)
		else:
			tw.tween_property(area, "position:y", sd[1] + dist, duration)
			tw.tween_property(area, "position:y", sd[1] - dist, duration * 2.0)
			tw.tween_property(area, "position:y", float(sd[1]), duration)

		# Spin
		var spin_tw := create_tween().set_loops()
		spin_tw.tween_property(area, "rotation", TAU, 0.8)

func _on_hazard_hit(body: Node2D, _hazard: Area2D) -> void:
	if body == player_node:
		player_node.take_damage(1)
		# Small knockback upward
		player_node.velocity.y = -250

# ── Trampolines ──────────────────────────────────────────────────────────────
func _make_trampolines() -> void:
	for td in trampoline_data:
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
		base.color = TRAMPOLINE_CLR
		area.add_child(base)

		# Bouncy pad on top
		var pad := ColorRect.new()
		pad.name = "Pad"
		pad.size = Vector2(44, 5)
		pad.position = Vector2(-22, -10)
		pad.color = TRAMPOLINE_PAD
		area.add_child(pad)

		# Spring coils (decorative)
		for i in 3:
			var coil := ColorRect.new()
			coil.size = Vector2(3, 8)
			coil.position = Vector2(-12 + i * 10, -4)
			coil.color = Color(0.8, 0.35, 0.1)
			area.add_child(coil)

		area.body_entered.connect(_on_trampoline_hit.bind(area))
		add_child(area)

func _on_trampoline_hit(body: Node2D, trampoline: Area2D) -> void:
	if body != player_node:
		return
	player_node.trampoline_bounce()
	# Squash animation on pad
	var pad : Node = trampoline.get_node_or_null("Pad")
	if pad:
		var tw := create_tween()
		tw.tween_property(pad, "position:y", pad.position.y + 6, 0.05)
		tw.tween_property(pad, "position:y", pad.position.y, 0.15).set_trans(Tween.TRANS_ELASTIC)

# ── Checkpoints ───────────────────────────────────────────────────────────────
func _make_checkpoints() -> void:
	for cd in checkpoint_data:
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
		flag.color = CHECKPOINT_CLR
		area.add_child(flag)

		area.body_entered.connect(_on_checkpoint_hit.bind(area))
		add_child(area)

func _on_checkpoint_hit(body: Node2D, checkpoint: Area2D) -> void:
	if body != player_node:
		return
	if checkpoint.get_meta("activated"):
		return
	checkpoint.set_meta("activated", true)
	player_node.set_checkpoint(checkpoint.global_position + Vector2(0, -10))

	var flag : Node = checkpoint.get_node_or_null("Flag")
	if flag:
		(flag as Polygon2D).color = CHECKPOINT_ACT

	# Sparkle effect
	for i in 6:
		var spark := ColorRect.new()
		spark.size = Vector2(3, 3)
		spark.color = CHECKPOINT_ACT
		spark.position = checkpoint.global_position + Vector2(10, -22)
		spark.z_index = 5
		add_child(spark)

		var angle := i * TAU / 6.0
		var target := spark.position + Vector2(cos(angle) * 25, sin(angle) * 25)
		var tw := get_tree().create_tween()
		tw.set_parallel(true)
		tw.tween_property(spark, "position", target, 0.4)
		tw.tween_property(spark, "modulate:a", 0.0, 0.4)
		tw.set_parallel(false)
		tw.tween_callback(spark.queue_free)

# ── Power-ups ─────────────────────────────────────────────────────────────────
func _make_powerups() -> void:
	for pd in powerup_data:
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
		glow.color = (SHIELD_CLR if is_shield else SPEED_CLR) * Color(1, 1, 1, 0.3)
		area.add_child(glow)

		# Icon
		var icon := Polygon2D.new()
		if is_shield:
			# Shield shape
			icon.polygon = PackedVector2Array([
				Vector2(0, -10),
				Vector2(8, -5),
				Vector2(8, 3),
				Vector2(0, 10),
				Vector2(-8, 3),
				Vector2(-8, -5),
			])
			icon.color = SHIELD_CLR
		else:
			# Lightning bolt
			icon.polygon = PackedVector2Array([
				Vector2(-2, -10),
				Vector2(5, -2),
				Vector2(0, -1),
				Vector2(2, 10),
				Vector2(-5, 2),
				Vector2(0, 1),
			])
			icon.color = SPEED_CLR

		area.add_child(icon)

		# Float animation
		var ftw := create_tween().set_loops()
		ftw.tween_property(area, "position:y", pd[1] - 5.0, 0.7).set_trans(Tween.TRANS_SINE)
		ftw.tween_property(area, "position:y", pd[1] + 5.0, 0.7).set_trans(Tween.TRANS_SINE)

		area.body_entered.connect(_on_powerup_hit.bind(area))
		add_child(area)

func _on_powerup_hit(body: Node2D, powerup: Area2D) -> void:
	if body != player_node:
		return
	var ptype : String = powerup.get_meta("powerup_type")
	if ptype == "shield":
		player_node.grant_shield()
	else:
		player_node.grant_speed_boost(5.0)

	_spawn_powerup_effect(powerup.global_position, ptype)
	powerup.queue_free()

func _spawn_powerup_effect(pos: Vector2, ptype: String) -> void:
	var color := SHIELD_CLR if ptype == "shield" else SPEED_CLR
	for i in 12:
		var p := ColorRect.new()
		p.size = Vector2(4, 4)
		p.color = color
		p.position = pos
		p.z_index = 5
		add_child(p)

		var angle := i * TAU / 12.0
		var target := pos + Vector2(cos(angle) * 35, sin(angle) * 35)
		var tw := get_tree().create_tween()
		tw.set_parallel(true)
		tw.tween_property(p, "position", target, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(p, "modulate:a", 0.0, 0.4)
		tw.set_parallel(false)
		tw.tween_callback(p.queue_free)

# ── Portals (MapleStory style) ────────────────────────────────────────────────
func _make_portals() -> void:
	for pd in portal_data:
		var pair := {}

		# Portal A
		pair["area_a"] = _create_portal(Vector2(pd[0], pd[1]), PORTAL_CLR_A, PORTAL_GLOW_A)
		pair["prompt_a"] = _create_portal_prompt(Vector2(pd[0], pd[1]))

		# Portal B
		pair["area_b"] = _create_portal(Vector2(pd[2], pd[3]), PORTAL_CLR_B, PORTAL_GLOW_B)
		pair["prompt_b"] = _create_portal_prompt(Vector2(pd[2], pd[3]))

		portal_pairs.append(pair)

func _create_portal(pos: Vector2, color: Color, glow_color: Color) -> Area2D:
	var area := Area2D.new()
	area.position = pos
	area.set_meta("portal", true)

	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(30, 56)
	cs.shape = rect
	area.add_child(cs)

	# Outer glow (pulsing)
	var glow := Polygon2D.new()
	glow.name = "Glow"
	var gpts := PackedVector2Array()
	for i in 16:
		var a := i * TAU / 16.0
		gpts.append(Vector2(cos(a) * 22, sin(a) * 34))
	glow.polygon = gpts
	glow.color = glow_color
	area.add_child(glow)

	# Portal oval body
	var body := Polygon2D.new()
	var bpts := PackedVector2Array()
	for i in 16:
		var a := i * TAU / 16.0
		bpts.append(Vector2(cos(a) * 14, sin(a) * 26))
	body.polygon = bpts
	body.color = color
	area.add_child(body)

	# Inner swirl (smaller oval, lighter)
	var inner := Polygon2D.new()
	inner.name = "Inner"
	var ipts := PackedVector2Array()
	for i in 12:
		var a := i * TAU / 12.0
		ipts.append(Vector2(cos(a) * 7, sin(a) * 14))
	inner.polygon = ipts
	inner.color = Color(1, 1, 1, 0.25)
	area.add_child(inner)

	# Sparkle particles around portal (decorative dots)
	for i in 4:
		var dot := ColorRect.new()
		dot.size = Vector2(3, 3)
		var angle := i * TAU / 4.0 + 0.3
		dot.position = Vector2(cos(angle) * 18 - 1.5, sin(angle) * 30 - 1.5)
		dot.color = Color(1, 1, 1, 0.4)
		area.add_child(dot)

	area.monitoring = true
	area.body_entered.connect(_on_portal_body_entered.bind(area))
	area.body_exited.connect(_on_portal_body_exited.bind(area))
	add_child(area)

	# Glow pulse animation
	var tw := create_tween().set_loops()
	tw.tween_property(glow, "modulate:a", 0.4, 0.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(glow, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)

	# Inner rotation
	var spin := create_tween().set_loops()
	spin.tween_property(inner, "rotation", TAU, 3.0)

	return area

func _on_portal_body_entered(body: Node2D, portal: Area2D) -> void:
	if body == player_node and portal not in player_in_portals:
		player_in_portals.append(portal)

func _on_portal_body_exited(body: Node2D, portal: Area2D) -> void:
	if body == player_node:
		player_in_portals.erase(portal)

func _create_portal_prompt(pos: Vector2) -> Label:
	var label := Label.new()
	label.text = "↓ ENTER"
	label.position = pos + Vector2(-28, -50)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	label.visible = false
	add_child(label)
	return label

var player_in_portals : Array = []  # List of portal Area2Ds the player is currently inside

func _check_portal_input() -> void:
	if not player_node or portal_cooldown > 0.0:
		for pair in portal_pairs:
			pair["prompt_a"].visible = false
			pair["prompt_b"].visible = false
		return

	# Update prompt visibility
	for pair in portal_pairs:
		var area_a : Area2D = pair["area_a"]
		var area_b : Area2D = pair["area_b"]
		pair["prompt_a"].visible = area_a in player_in_portals
		pair["prompt_b"].visible = area_b in player_in_portals
		pair["prompt_a"].position = area_a.position + Vector2(-28, -50)
		pair["prompt_b"].position = area_b.position + Vector2(-28, -50)

	# Teleport with Down arrow
	if Input.is_action_just_pressed("ui_down") and player_in_portals.size() > 0:
		var current_portal : Area2D = player_in_portals[0]
		for pair in portal_pairs:
			if current_portal == pair["area_a"]:
				_teleport_to(pair["area_b"].global_position)
				return
			elif current_portal == pair["area_b"]:
				_teleport_to(pair["area_a"].global_position)
				return

func _teleport_to(target: Vector2) -> void:
	portal_cooldown = 0.5
	player_in_portals.clear()
	_spawn_teleport_effect(player_node.global_position)
	player_node.position = target + Vector2(0, -10)
	player_node.velocity = Vector2.ZERO
	_spawn_teleport_effect(target + Vector2(0, -10))

func _spawn_teleport_effect(pos: Vector2) -> void:
	for i in 12:
		var p := ColorRect.new()
		p.size = Vector2(4, 4)
		p.color = Color(0.7, 0.5, 1.0, 0.9)
		p.position = pos + Vector2(randf_range(-5, 5), randf_range(-25, 25))
		p.z_index = 10
		add_child(p)

		var tw := get_tree().create_tween()
		tw.set_parallel(true)
		tw.tween_property(p, "position:y", p.position.y - randf_range(20, 50), 0.5)
		tw.tween_property(p, "position:x", p.position.x + randf_range(-15, 15), 0.5)
		tw.tween_property(p, "modulate:a", 0.0, 0.5)
		tw.set_parallel(false)
		tw.tween_callback(p.queue_free)

# ── Coins ─────────────────────────────────────────────────────────────────────
func _make_coins() -> void:
	total_coins = coin_positions.size()
	for pos in coin_positions:
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
		level_complete = true
		if current_level < LevelData.total_levels():
			score_label.text = "🎉  Complete! Go to the EXIT portal for next level!"
			_spawn_exit_portal()
		else:
			score_label.text = "🏆  ALL LEVELS COMPLETE! You win!"
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

# ── Exit portal (next level) ─────────────────────────────────────────────────
func _spawn_exit_portal() -> void:
	# Place near player spawn on ground
	var exit_pos := Vector2(640, 660)
	next_portal = Area2D.new()
	next_portal.position = exit_pos
	next_portal.monitoring = true

	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(50, 70)
	cs.shape = rect
	next_portal.add_child(cs)

	# Big glowing portal
	var glow := Polygon2D.new()
	var gpts := PackedVector2Array()
	for i in 16:
		var a := i * TAU / 16.0
		gpts.append(Vector2(cos(a) * 30, sin(a) * 40))
	glow.polygon = gpts
	glow.color = Color(0.2, 1.0, 0.4, 0.3)
	next_portal.add_child(glow)

	var body := Polygon2D.new()
	var bpts := PackedVector2Array()
	for i in 16:
		var a := i * TAU / 16.0
		bpts.append(Vector2(cos(a) * 20, sin(a) * 32))
	body.polygon = bpts
	body.color = Color(0.2, 1.0, 0.5, 0.7)
	next_portal.add_child(body)

	var inner := Polygon2D.new()
	var ipts := PackedVector2Array()
	for i in 12:
		var a := i * TAU / 12.0
		ipts.append(Vector2(cos(a) * 10, sin(a) * 18))
	inner.polygon = ipts
	inner.color = Color(1, 1, 1, 0.3)
	next_portal.add_child(inner)

	# "NEXT LEVEL" label
	var lbl := Label.new()
	lbl.text = "↓ NEXT"
	lbl.position = Vector2(-24, -58)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
	next_portal.add_child(lbl)

	next_portal.body_entered.connect(_on_exit_portal_entered)
	add_child(next_portal)

	# Pulse animation
	var tw := create_tween().set_loops()
	tw.tween_property(glow, "modulate:a", 0.4, 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(glow, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)

	var spin := create_tween().set_loops()
	spin.tween_property(inner, "rotation", TAU, 2.5)

var player_near_exit := false

func _on_exit_portal_entered(body: Node2D) -> void:
	if body == player_node:
		player_near_exit = true

func _go_next_level() -> void:
	current_level += 1
	_switch_level(current_level)

# Use a static to pass data between scene reloads
static var _next_level := 1
static var _next_seed  := 0

func _switch_level(to_level: int) -> void:
	_next_level = to_level
	_next_seed  = world_seed
	get_tree().reload_current_scene()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var kb := event as InputEventKey
		match kb.keycode:
			KEY_1:
				# Random Easy map
				world_seed = randi() % 999999
				_switch_level(1)
			KEY_2:
				# Random Medium map
				world_seed = randi() % 999999
				_switch_level(5)
			KEY_3:
				# Random Hard map
				world_seed = randi() % 999999
				_switch_level(8)
			KEY_4:
				# Random Extreme map
				world_seed = randi() % 999999
				_switch_level(11)
			KEY_R:
				# Re-roll: new random seed, same difficulty
				world_seed = randi() % 999999
				_switch_level(current_level)
			KEY_N:
				# Next level (slightly harder)
				_switch_level(current_level + 1)
			KEY_B:
				# Back one level (easier)
				if current_level > 1:
					_switch_level(current_level - 1)

# ── Enemies (patrol) ─────────────────────────────────────────────────────────
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

		var body      := ColorRect.new()
		body.size     = Vector2(30, 24)
		body.position = Vector2(-15, -12)
		body.color    = ENEMY_CLR
		area.add_child(body)

		var el      := ColorRect.new()
		el.size     = Vector2(6, 6)
		el.position = Vector2(-10, -8)
		el.color    = ENEMY_EYE
		area.add_child(el)

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
	if player_node.velocity.y > 0 and player_node.global_position.y < enemy.global_position.y - 8:
		_kill_enemy(enemy)
		player_node.stomp_bounce()
	else:
		player_node.take_damage(1)
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

# ── Shooting Enemies ──────────────────────────────────────────────────────────
func _make_shooters() -> void:
	for sd in shooter_data:
		var sb := StaticBody2D.new()
		sb.position = Vector2(sd[0], sd[1])
		sb.set_meta("shooter", true)
		sb.set_meta("fire_interval", float(sd[2]))
		sb.set_meta("bullet_speed", float(sd[3]))
		sb.set_meta("shoot_dir", float(sd[4]))
		sb.set_meta("fire_timer", float(sd[2]) * 0.5)  # Start offset

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

		add_child(sb)

func _spawn_bullet(pos: Vector2, dir: float, spd: float) -> void:
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
	poly.color = BULLET_CLR
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

	area.body_entered.connect(_on_bullet_hit.bind(area))
	add_child(area)
	bullets.append(area)

func _on_bullet_hit(body: Node2D, bullet: Area2D) -> void:
	if body == player_node:
		player_node.take_damage(1)
		player_node.velocity.y = -150
		bullet.queue_free()
		bullets.erase(bullet)

# ── Physics process (enemies, bullets, crumble, disappear) ───────────────────
func _physics_process(delta: float) -> void:
	if not player_node:
		return

	# Patrol enemies
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

	# Shooting enemies
	for child in get_children():
		if child is StaticBody2D and child.has_meta("shooter"):
			var timer : float = child.get_meta("fire_timer")
			timer -= delta
			if timer <= 0.0:
				timer = child.get_meta("fire_interval")
				var dir : float = child.get_meta("shoot_dir")
				var spd : float = child.get_meta("bullet_speed")
				var offset := Vector2(dir * 20, 0)
				_spawn_bullet(child.global_position + offset, dir, spd)
			child.set_meta("fire_timer", timer)

	# Bullets
	var dead_bullets : Array = []
	for b in bullets:
		if not is_instance_valid(b):
			dead_bullets.append(b)
			continue
		var dir : float = b.get_meta("bullet_dir")
		var spd : float = b.get_meta("bullet_speed")
		var life : float = b.get_meta("lifetime")
		b.position.x += dir * spd * delta
		life -= delta
		b.set_meta("lifetime", life)
		if life <= 0.0 or b.position.x < -50 or b.position.x > 1350:
			b.queue_free()
			dead_bullets.append(b)
	for b in dead_bullets:
		bullets.erase(b)

	# Crumbling platforms
	for sb in crumble_bodies:
		if not is_instance_valid(sb):
			continue

		var ct : float = sb.get_meta("crumble_timer")
		var rt : float = sb.get_meta("respawn_timer")

		if rt > 0.0:
			# Respawning
			rt -= delta
			sb.set_meta("respawn_timer", rt)
			if rt <= 0.0:
				sb.visible = true
				for c in sb.get_children():
					if c is CollisionShape2D:
						c.disabled = false
				sb.set_meta("crumble_timer", -1.0)
			continue

		if ct > 0.0:
			# Counting down to crumble
			ct -= delta
			sb.set_meta("crumble_timer", ct)
			# Shake effect
			sb.position.x = sb.get_meta("origin_x") + randf_range(-2, 2)
			if ct <= 0.0:
				# Crumble!
				sb.visible = false
				for c in sb.get_children():
					if c is CollisionShape2D:
						c.disabled = true
				sb.position.x = sb.get_meta("origin_x")
				sb.set_meta("respawn_timer", 3.0)
				_spawn_crumble_particles(Vector2(sb.get_meta("origin_x"), sb.get_meta("origin_y")), sb.get_meta("width"))
			continue

		# Check if player is standing on it
		if ct < 0.0 and player_node.is_on_floor():
			var px := player_node.global_position.x
			var py := player_node.global_position.y
			var ox : float = sb.get_meta("origin_x")
			var oy : float = sb.get_meta("origin_y")
			var w  : float = sb.get_meta("width")
			if absf(px - ox) < w * 0.5 + 18 and absf(py - oy) < 40:
				sb.set_meta("crumble_timer", 0.5)

	# Disappearing platforms
	for sb in disappear_bodies:
		if not is_instance_valid(sb):
			continue
		var timer : float = sb.get_meta("timer")
		var is_on : bool  = sb.get_meta("is_on")
		timer -= delta
		sb.set_meta("timer", timer)

		if timer <= 0.0:
			is_on = not is_on
			sb.set_meta("is_on", is_on)
			sb.set_meta("timer", sb.get_meta("on_time") if is_on else sb.get_meta("off_time"))
			for c in sb.get_children():
				if c is CollisionShape2D:
					c.disabled = not is_on
			var fill_node : Node = sb.get_node_or_null("Fill")
			if fill_node:
				(fill_node as ColorRect).color = DISAPPEAR_ON if is_on else DISAPPEAR_OFF
			var border_node : Node = sb.get_node_or_null("Border")
			if border_node:
				border_node.visible = is_on

		# Warning blink before disappearing
		if is_on and timer < 0.5:
			var blink_fill : Node = sb.get_node_or_null("Fill")
			if blink_fill:
				(blink_fill as ColorRect).color = DISAPPEAR_ON if int(timer * 8) % 2 == 0 else DISAPPEAR_OFF

func _spawn_crumble_particles(pos: Vector2, w: float) -> void:
	for i in 8:
		var p := ColorRect.new()
		p.size = Vector2(6, 6)
		p.color = CRUMBLE_FILL
		p.position = pos + Vector2(randf_range(-w * 0.4, w * 0.4), 0)
		p.z_index = 5
		add_child(p)

		var tw := get_tree().create_tween()
		tw.set_parallel(true)
		tw.tween_property(p, "position:y", p.position.y + randf_range(30, 80), 0.5)
		tw.tween_property(p, "position:x", p.position.x + randf_range(-20, 20), 0.5)
		tw.tween_property(p, "modulate:a", 0.0, 0.5)
		tw.set_parallel(false)
		tw.tween_callback(p.queue_free)

# ── Player ────────────────────────────────────────────────────────────────────
func _make_player() -> void:
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
	body.color    = PLAYER_CLR
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
	shield.color = SHIELD_CLR
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

	p.hp_changed.connect(_on_hp_changed)
	p.player_died.connect(_on_player_died)
	p.shield_changed.connect(_on_shield_changed)

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

func _on_shield_changed(has: bool) -> void:
	shield_label.text = "🛡 SHIELD" if has else ""

func _on_player_died() -> void:
	score = 0
	elapsed_time = 0.0
	level_complete = false
	score_label.text = "⭐  0 / %d" % total_coins

	# Clean up dynamic objects
	var to_remove : Array = []
	for child in get_children():
		if child is Area2D:
			if child.has_meta("coin") or child.has_meta("patrol_center") or child.has_meta("bullet") or child.has_meta("powerup_type"):
				to_remove.append(child)
	for child in to_remove:
		child.queue_free()
	bullets.clear()

	# Reset crumble platforms
	for sb in crumble_bodies:
		if is_instance_valid(sb):
			sb.visible = true
			sb.position = Vector2(sb.get_meta("origin_x"), sb.get_meta("origin_y"))
			sb.set_meta("crumble_timer", -1.0)
			sb.set_meta("respawn_timer", -1.0)
			for c in sb.get_children():
				if c is CollisionShape2D:
					c.disabled = false

	# Reset checkpoints
	for child in get_children():
		if child is Area2D and child.has_meta("checkpoint"):
			child.set_meta("activated", false)
			var flag_node : Node = child.get_node_or_null("Flag")
			if flag_node:
				(flag_node as Polygon2D).color = CHECKPOINT_CLR
	player_node.respawn_pos = Vector2(640, 630)

	await get_tree().process_frame
	_make_coins()
	_make_enemies()
	_make_powerups()

# ── HUD ───────────────────────────────────────────────────────────────────────
func _make_hud() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 10
	add_child(cl)

	# Level name
	level_label          = Label.new()
	level_label.text     = level.get("name", "Level %d" % current_level)
	level_label.position = Vector2(480, 16)
	level_label.add_theme_font_size_override("font_size", 20)
	level_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9, 0.7))
	cl.add_child(level_label)

	score_label          = Label.new()
	score_label.text     = "⭐  0 / %d" % total_coins
	score_label.position = Vector2(20, 16)
	score_label.add_theme_font_size_override("font_size", 26)
	score_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.55))
	cl.add_child(score_label)

	hp_label          = Label.new()
	hp_label.text     = "❤️ ♥ ♥ ♥ "
	hp_label.position = Vector2(20, 52)
	hp_label.add_theme_font_size_override("font_size", 22)
	hp_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	cl.add_child(hp_label)

	shield_label          = Label.new()
	shield_label.text     = ""
	shield_label.position = Vector2(20, 82)
	shield_label.add_theme_font_size_override("font_size", 18)
	shield_label.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	cl.add_child(shield_label)

	timer_label          = Label.new()
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

	# ── Minimap ───────────────────────────────────────────────────────────
	_make_minimap(cl)

# ── Minimap ───────────────────────────────────────────────────────────────────
# World bounds: roughly x=0..1280, y=0..720
# Minimap: 160x100 in bottom-right corner
const MINIMAP_W    := 160.0
const MINIMAP_H    := 100.0
const MINIMAP_X    := 1100.0  # Position on screen
const MINIMAP_Y    := 580.0
const WORLD_W      := 1400.0  # Approximate world width
const WORLD_H      := 750.0   # Approximate world height
const WORLD_OX     := -60.0   # World origin offset x
const WORLD_OY     := 50.0    # World origin offset y

func _make_minimap(hud_layer: CanvasLayer) -> void:
	minimap_node = Control.new()
	minimap_node.position = Vector2(MINIMAP_X, MINIMAP_Y)
	minimap_node.size = Vector2(MINIMAP_W, MINIMAP_H)
	hud_layer.add_child(minimap_node)

	# Background
	var bg := ColorRect.new()
	bg.size = Vector2(MINIMAP_W, MINIMAP_H)
	bg.color = Color(0.05, 0.05, 0.12, 0.75)
	minimap_node.add_child(bg)

	# Border
	var border_top := ColorRect.new()
	border_top.size = Vector2(MINIMAP_W, 1)
	border_top.color = Color(0.4, 0.4, 0.6, 0.6)
	minimap_node.add_child(border_top)

	var border_bot := ColorRect.new()
	border_bot.size = Vector2(MINIMAP_W, 1)
	border_bot.position = Vector2(0, MINIMAP_H - 1)
	border_bot.color = Color(0.4, 0.4, 0.6, 0.6)
	minimap_node.add_child(border_bot)

	var border_left := ColorRect.new()
	border_left.size = Vector2(1, MINIMAP_H)
	border_left.color = Color(0.4, 0.4, 0.6, 0.6)
	minimap_node.add_child(border_left)

	var border_right := ColorRect.new()
	border_right.size = Vector2(1, MINIMAP_H)
	border_right.position = Vector2(MINIMAP_W - 1, 0)
	border_right.color = Color(0.4, 0.4, 0.6, 0.6)
	minimap_node.add_child(border_right)

	# Static platforms
	for pd in platform_data:
		var r := ColorRect.new()
		var mx : float = _map_x(pd[0] - pd[2] * 0.5)
		var my : float = _map_y(pd[1] - pd[3] * 0.5)
		var mw : float = maxf(pd[2] / WORLD_W * MINIMAP_W, 2.0)
		var mh : float = maxf(pd[3] / WORLD_H * MINIMAP_H, 1.0)
		r.position = Vector2(mx, my)
		r.size = Vector2(mw, mh)
		r.color = Color(0.3, 0.7, 0.35, 0.8)
		minimap_node.add_child(r)

	# Walls
	for wd in wall_data:
		var r := ColorRect.new()
		r.position = Vector2(_map_x(wd[0] - wd[2] * 0.5), _map_y(wd[1] - wd[3] * 0.5))
		r.size = Vector2(maxf(wd[2] / WORLD_W * MINIMAP_W, 1.0), maxf(wd[3] / WORLD_H * MINIMAP_H, 2.0))
		r.color = Color(0.4, 0.4, 0.55, 0.7)
		minimap_node.add_child(r)

	# Spikes (as red dots)
	for sd in spike_data:
		var r := ColorRect.new()
		r.position = Vector2(_map_x(sd[0]) - 1, _map_y(sd[1]) - 1)
		r.size = Vector2(maxf(sd[2] * sd[3] / WORLD_W * MINIMAP_W, 2.0), 2)
		r.color = Color(1.0, 0.3, 0.2, 0.7)
		minimap_node.add_child(r)

	# Portals
	for pd in portal_data:
		var pa := ColorRect.new()
		pa.position = Vector2(_map_x(pd[0]) - 2, _map_y(pd[1]) - 3)
		pa.size = Vector2(4, 6)
		pa.color = Color(0.5, 0.3, 0.9, 0.8)
		minimap_node.add_child(pa)

		var pb := ColorRect.new()
		pb.position = Vector2(_map_x(pd[2]) - 2, _map_y(pd[3]) - 3)
		pb.size = Vector2(4, 6)
		pb.color = Color(0.9, 0.5, 0.2, 0.8)
		minimap_node.add_child(pb)

	# Checkpoints
	for cd in checkpoint_data:
		var r := ColorRect.new()
		r.position = Vector2(_map_x(cd[0]) - 1, _map_y(cd[1]) - 3)
		r.size = Vector2(2, 5)
		r.color = Color(0.2, 0.85, 0.4, 0.8)
		minimap_node.add_child(r)

	# Label
	var lbl := Label.new()
	lbl.text = "MAP"
	lbl.position = Vector2(2, -16)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.8, 0.6))
	minimap_node.add_child(lbl)

	# Player dot (updated every frame)
	minimap_player = ColorRect.new()
	minimap_player.size = Vector2(5, 5)
	minimap_player.color = Color(0.3, 0.6, 1.0, 1.0)
	minimap_player.z_index = 1
	minimap_node.add_child(minimap_player)

func _map_x(world_x: float) -> float:
	return clampf((world_x - WORLD_OX) / WORLD_W * MINIMAP_W, 0, MINIMAP_W)

func _map_y(world_y: float) -> float:
	return clampf((world_y - WORLD_OY) / WORLD_H * MINIMAP_H, 0, MINIMAP_H)

func _update_minimap() -> void:
	if not minimap_player or not player_node:
		return
	minimap_player.position = Vector2(
		_map_x(player_node.global_position.x) - 2.5,
		_map_y(player_node.global_position.y) - 2.5
	)
