extends Node2D

const Colors  = preload("res://scripts/Colors.gd")
const Builder = preload("res://scripts/Builder.gd")
const Portals = preload("res://scripts/Portals.gd")
const Minimap = preload("res://scripts/Minimap.gd")

# -- Level data (loaded from LevelData.gd) ------------------------------------
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
var ice_data       : Array
var conveyor_data  : Array
var jumper_data    : Array
var wind_zone_data : Array
var key_data       : Array
var require_keys   := 0
var boss_data      : Array
var keys_collected := 0
var boss_node      : Area2D
var key_label      : Label

# -- State ---------------------------------------------------------------------
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
var portal_pairs   : Array = []
var portal_cooldown := 0.0
var minimap_node   : Control
var minimap_player : ColorRect
var hp_container   : Node

var level_label    : Label
var next_portal    : Area2D
var world_seed     := 0
var seed_label     : Label

var player_in_portals : Array = []
var player_near_exit  := false
var pause_menu       : CanvasLayer
var vignette_rect    : ColorRect
var dash_lines_layer : CanvasLayer

# Use a static to pass data between scene reloads
static var _next_level := 1
static var _next_seed  := 0

# ==============================================================================
func _ready() -> void:
	randomize()
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
	ice_data             = level.get("ice", [])
	conveyor_data        = level.get("conveyors", [])
	jumper_data          = level.get("jumpers", [])
	wind_zone_data       = level.get("wind_zones", [])
	key_data             = level.get("keys", [])
	require_keys         = level.get("require_keys", 0)
	boss_data            = level.get("boss", [])

func _build_world() -> void:
	Builder.make_background(self, level)
	Builder.make_walls(self, wall_data)
	Builder.make_platforms(self, platform_data)
	Builder.make_moving_platforms(self, moving_platform_data)
	Builder.make_ice_platforms(self, ice_data)
	Builder.make_conveyors(self, conveyor_data)
	crumble_bodies = Builder.make_crumble_platforms(self, crumble_data)
	disappear_bodies = Builder.make_disappear_platforms(self, disappear_data)
	Builder.make_spikes(self, spike_data, _on_hazard_hit)
	Builder.make_saw_blades(self, saw_data, _on_hazard_hit)
	Builder.make_trampolines(self, trampoline_data, _on_trampoline_hit)
	Builder.make_checkpoints(self, checkpoint_data, _on_checkpoint_hit)
	portal_pairs = Portals.make_portals(self, portal_data, _on_portal_body_entered, _on_portal_body_exited)
	Builder.make_powerups(self, powerup_data, _on_powerup_hit)

	# Coins -- set total_coins before creating HUD
	total_coins = coin_positions.size()
	Builder.make_coins(self, coin_positions, _on_coin_entered)

	Builder.make_enemies(self, enemy_data, _on_enemy_hit)
	Builder.make_jumpers(self, jumper_data, _on_enemy_hit)
	Builder.make_shooters(self, shooter_data)
	Builder.make_wind_zones(self, wind_zone_data)
	if key_data.size() > 0:
		Builder.make_keys(self, key_data, _on_key_collected)
	boss_node = Builder.make_boss(self, boss_data, _on_boss_hit)

	player_node = Builder.make_player(self)
	player_node.hp_changed.connect(_on_hp_changed)
	player_node.player_died.connect(_on_player_died)
	player_node.shield_changed.connect(_on_shield_changed)

	var hud := Builder.make_hud(self, total_coins, level, current_level)
	score_label  = hud["score_label"]
	hp_label     = hud["hp_label"]
	hp_container = hud["hp_container"]
	timer_label  = hud["timer_label"]
	shield_label = hud["shield_label"]
	level_label  = hud["level_label"]

	# Key counter (if level has keys)
	if require_keys > 0:
		key_label = Label.new()
		key_label.text = "🔑 0 / %d" % require_keys
		key_label.position = Vector2(20, 108)
		key_label.add_theme_font_size_override("font_size", 20)
		key_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.15))
		hud["hud_layer"].add_child(key_label)
	keys_collected = 0

	# Vignette overlay (shows on low HP)
	_create_vignette(hud["hud_layer"])

	# Speed lines (shows during dash)
	_create_dash_lines()

	# Pause key handler (always processes, even when paused)
	_setup_pause_handler()

	# Start background music
	Audio.start_music()

	# Fade in from black
	_fade_in()

	var mm := Minimap.make_minimap(
		hud["hud_layer"], platform_data, wall_data,
		spike_data, portal_data, checkpoint_data
	)
	minimap_node   = mm["node"]
	minimap_player = mm["player_dot"]

# -- Per-frame -----------------------------------------------------------------
func _process(delta: float) -> void:
	if not player_node or not timer_label:
		return
	portal_cooldown = maxf(portal_cooldown - delta, 0.0)
	Portals.check_portal_input(portal_pairs, player_in_portals, portal_cooldown, player_node, _teleport_to)
	Minimap.update(minimap_player, player_node)
	# Check exit portal
	if player_near_exit and Input.is_action_just_pressed("ui_down"):
		player_near_exit = false
		_go_next_level()
		return
	# Vignette pulse on low HP
	_update_vignette()
	# Speed lines during dash
	_update_dash_lines()
	if not level_complete:
		elapsed_time += delta
		var mins := int(elapsed_time) / 60
		var secs := int(elapsed_time) % 60
		var ms   := int(fmod(elapsed_time, 1.0) * 100)
		timer_label.text = "⏱  %02d:%02d.%02d" % [mins, secs, ms]

# -- Physics (enemies, bullets, crumble, disappear) ----------------------------
func _physics_process(delta: float) -> void:
	if not player_node:
		return

	# Ice & conveyor platform effects
	if player_node.is_on_floor():
		var px := player_node.global_position.x
		var py := player_node.global_position.y
		for child in get_children():
			if child is StaticBody2D:
				if child.has_meta("ice"):
					var ix : float = child.position.x
					var iy : float = child.position.y
					if absf(px - ix) < 100 and absf(py - iy) < 30:
						# Reduce friction on ice
						player_node.velocity.x = move_toward(player_node.velocity.x, 0.0, 30.0 * delta)
				elif child.has_meta("conveyor"):
					var cx : float = child.position.x
					var cy : float = child.position.y
					if absf(px - cx) < 120 and absf(py - cy) < 30:
						var cdir : float = child.get_meta("conveyor_dir")
						var cspd : float = child.get_meta("conveyor_speed")
						player_node.velocity.x += cdir * cspd * delta

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

			# Flip enemy animation
			var enemy_anim : Node = child.get_node_or_null("Anim")
			if enemy_anim and enemy_anim is AnimatedSprite2D:
				var ea := enemy_anim as AnimatedSprite2D
				var anim_name := "walk_right" if dir > 0 else "walk_left"
				if ea.animation != anim_name:
					ea.play(anim_name)

	# Jumping enemies (patrol + jump on timer)
	for child in get_children():
		if child is Area2D and child.has_meta("jumper"):
			var jt : float = child.get_meta("jump_timer")
			var vy : float = child.get_meta("jumper_vy")
			jt -= delta
			if jt <= 0.0:
				jt = child.get_meta("jump_interval")
				vy = -child.get_meta("jump_force")
			# Apply gravity
			vy += 800.0 * delta
			child.position.y += vy * delta
			child.set_meta("jumper_vy", vy)
			child.set_meta("jump_timer", jt)
			# Don't fall below spawn Y (approximate ground)
			if child.position.y > float(child.get_meta("patrol_center")) + 50:
				child.position.y = float(child.get_meta("patrol_center")) + 50
				child.set_meta("jumper_vy", 0.0)

	# Wind zones (push player when overlapping)
	for child in get_children():
		if child is Area2D and child.has_meta("wind_zone"):
			var wpos : Vector2 = child.global_position
			var px := player_node.global_position.x
			var py := player_node.global_position.y
			# Check rough overlap
			if absf(px - wpos.x) < 160 and absf(py - wpos.y) < 120:
				var wdir : float = child.get_meta("wind_dir")
				var wstr : float = child.get_meta("wind_strength")
				player_node.velocity.x += wdir * wstr * delta

	# Boss behavior
	if boss_node and is_instance_valid(boss_node):
		var bspd : float = boss_node.get_meta("boss_speed")
		var bdir : float = boss_node.get_meta("boss_dir")
		boss_node.position.x += bdir * bspd * delta
		if boss_node.position.x > 1050:
			boss_node.set_meta("boss_dir", -1.0)
		elif boss_node.position.x < 230:
			boss_node.set_meta("boss_dir", 1.0)
		# Boss fire timer
		var bft : float = boss_node.get_meta("boss_fire_timer")
		bft -= delta
		if bft <= 0.0:
			bft = boss_node.get_meta("boss_fire_interval")
			# Fire bullet toward player
			var dir_to_player : float = sign(player_node.global_position.x - boss_node.global_position.x)
			if dir_to_player == 0:
				dir_to_player = 1.0
			var b := Builder.spawn_bullet(self, boss_node.global_position + Vector2(dir_to_player * 35, -10), dir_to_player, 200.0, _on_bullet_hit)
			bullets.append(b)
			Audio.play("shoot", -8.0)
		boss_node.set_meta("boss_fire_timer", bft)
		# Flip animation
		var boss_anim : Node = boss_node.get_node_or_null("Anim")
		if boss_anim and boss_anim is AnimatedSprite2D:
			var ba := boss_anim as AnimatedSprite2D
			var ban := "walk_right" if bdir > 0 else "walk_left"
			if ba.animation != ban:
				ba.play(ban)

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
				var b := Builder.spawn_bullet(self, child.global_position + offset, dir, spd, _on_bullet_hit)
				bullets.append(b)
				Audio.play("shoot", -10.0)
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
			ct -= delta
			sb.set_meta("crumble_timer", ct)
			sb.position.x = sb.get_meta("origin_x") + randf_range(-2, 2)
			if ct <= 0.0:
				sb.visible = false
				for c in sb.get_children():
					if c is CollisionShape2D:
						c.disabled = true
				sb.position.x = sb.get_meta("origin_x")
				sb.set_meta("respawn_timer", 3.0)
				_spawn_crumble_particles(Vector2(sb.get_meta("origin_x"), sb.get_meta("origin_y")), sb.get_meta("width"))
				Audio.play("crumble", -6.0)
			continue

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
				(fill_node as ColorRect).color = Colors.DISAPPEAR_ON if is_on else Colors.DISAPPEAR_OFF
			var border_node : Node = sb.get_node_or_null("Border")
			if border_node:
				border_node.visible = is_on

		# Warning blink before disappearing
		if is_on and timer < 0.5:
			var blink_fill : Node = sb.get_node_or_null("Fill")
			if blink_fill:
				(blink_fill as ColorRect).color = Colors.DISAPPEAR_ON if int(timer * 8) % 2 == 0 else Colors.DISAPPEAR_OFF

# -- Pause input is handled by a child node that always processes (see _ready)

# -- Input ---------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var kb := event as InputEventKey
		match kb.keycode:
			KEY_1:
				world_seed = randi() % 999999
				_switch_level(1)
			KEY_2:
				world_seed = randi() % 999999
				_switch_level(5)
			KEY_3:
				world_seed = randi() % 999999
				_switch_level(8)
			KEY_4:
				world_seed = randi() % 999999
				_switch_level(11)
			KEY_R:
				world_seed = randi() % 999999
				_switch_level(current_level)
			KEY_N:
				_switch_level(current_level + 1)
			KEY_B:
				if current_level > 1:
					_switch_level(current_level - 1)

# -- Level switching -----------------------------------------------------------
func _switch_level(to_level: int) -> void:
	_next_level = to_level
	_next_seed  = world_seed
	_fade_and_reload()

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
	tw.tween_property(overlay, "color:a", 0.0, 0.4)
	tw.tween_callback(cl.queue_free)

func _fade_and_reload() -> void:
	# Fade to black then reload
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.size = Vector2(1280, 720)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cl := CanvasLayer.new()
	cl.layer = 100
	cl.add_child(overlay)
	add_child(cl)

	var tw := create_tween()
	tw.tween_property(overlay, "color:a", 1.0, 0.25)
	tw.tween_callback(get_tree().reload_current_scene)

func _go_next_level() -> void:
	current_level += 1
	_switch_level(current_level)

# -- Signal callbacks ----------------------------------------------------------
func _on_hazard_hit(body: Node2D, _hazard: Area2D) -> void:
	if body == player_node:
		player_node.take_damage(1)
		player_node.velocity.y = -250

func _on_trampoline_hit(body: Node2D, trampoline: Area2D) -> void:
	if body != player_node:
		return
	player_node.trampoline_bounce()
	Audio.play("trampoline", -4.0)
	var pad : Node = trampoline.get_node_or_null("Pad")
	if pad:
		var tw := create_tween()
		tw.tween_property(pad, "position:y", pad.position.y + 6, 0.05)
		tw.tween_property(pad, "position:y", pad.position.y, 0.15).set_trans(Tween.TRANS_ELASTIC)

func _on_checkpoint_hit(body: Node2D, checkpoint: Area2D) -> void:
	if body != player_node:
		return
	if checkpoint.get_meta("activated"):
		return
	checkpoint.set_meta("activated", true)
	player_node.set_checkpoint(checkpoint.global_position + Vector2(0, -10))
	Audio.play("checkpoint", -4.0)

	var flag : Node = checkpoint.get_node_or_null("Flag")
	if flag:
		(flag as Polygon2D).color = Colors.CHECKPOINT_ACT

	# Sparkle effect
	for i in 6:
		var spark := ColorRect.new()
		spark.size = Vector2(3, 3)
		spark.color = Colors.CHECKPOINT_ACT
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

func _on_key_collected(body: Node2D, key_area: Area2D) -> void:
	if body != player_node:
		return
	key_area.queue_free()
	keys_collected += 1
	Audio.play("powerup", -4.0, 1.3)
	if key_label:
		key_label.text = "🔑 %d / %d" % [keys_collected, require_keys]
	# Check if level now complete
	if score >= total_coins and keys_collected >= require_keys and not level_complete:
		level_complete = true
		score_label.text = "Complete! Go to EXIT portal!"
		_spawn_exit_portal()
		Audio.play("level_complete", -2.0)
	# Sparkle effect
	var pos := key_area.global_position
	for i in 8:
		var spark := ColorRect.new()
		spark.size = Vector2(4, 4)
		spark.color = Color(1.0, 0.85, 0.15, 0.9)
		spark.position = pos
		spark.z_index = 5
		add_child(spark)
		var angle := i * TAU / 8.0
		var target := pos + Vector2(cos(angle) * 30, sin(angle) * 30)
		var tw := get_tree().create_tween()
		tw.set_parallel(true)
		tw.tween_property(spark, "position", target, 0.3)
		tw.tween_property(spark, "modulate:a", 0.0, 0.3)
		tw.set_parallel(false)
		tw.tween_callback(spark.queue_free)

func _on_boss_hit(body: Node2D, boss: Area2D) -> void:
	if body != player_node:
		return
	# Stomp from above = damage boss
	if player_node.velocity.y > 0 and player_node.global_position.y < boss.global_position.y - 20:
		var hp : int = boss.get_meta("boss_hp") - 1
		boss.set_meta("boss_hp", hp)
		player_node.stomp_bounce()
		Audio.play("stomp", -2.0)
		_freeze_frame(0.08)
		player_node.camera_shake(6.0, 0.2)
		# Update HP bar
		var bar : Node = boss.get_node_or_null("BarFill")
		if bar:
			var max_hp : int = boss.get_meta("boss_max_hp")
			(bar as ColorRect).size.x = 60.0 * hp / max_hp
		# Flash boss red
		var anim : Node = boss.get_node_or_null("Anim")
		if anim:
			anim.modulate = Color(10, 0, 0)
			var tw := get_tree().create_tween()
			tw.tween_property(anim, "modulate", Color.WHITE, 0.15)
		if hp <= 0:
			_kill_enemy(boss)
			boss_node = null
			Audio.play("level_complete", -2.0)
	else:
		# Side contact = player takes damage
		player_node.take_damage(1)
		var knockback_dir : float = sign(player_node.global_position.x - boss.global_position.x)
		if knockback_dir == 0:
			knockback_dir = 1
		player_node.velocity.x = knockback_dir * 350
		player_node.velocity.y = -250

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
	Audio.play("powerup", -4.0)

func _on_coin_entered(body: Node2D, coin: Area2D) -> void:
	if body != player_node:
		return
	_spawn_coin_sparkle(coin.global_position)
	coin.queue_free()
	score += 1
	Audio.play("coin", -6.0, randf_range(0.9, 1.1))
	var all_coins := score >= total_coins
	var all_keys := keys_collected >= require_keys
	if all_coins and all_keys:
		level_complete = true
		if current_level < LevelData.total_levels():
			score_label.text = "Complete! Go to EXIT portal!"
			_spawn_exit_portal()
			Audio.play("level_complete", -2.0)
		else:
			score_label.text = "ALL LEVELS COMPLETE! You win!"
	elif all_coins and not all_keys:
		score_label.text = "All coins! Find %d more keys!" % (require_keys - keys_collected)
	else:
		score_label.text = "  %d / %d" % [score, total_coins]

func _on_enemy_hit(body: Node2D, enemy: Area2D) -> void:
	if body != player_node:
		return
	if player_node.velocity.y > 0 and player_node.global_position.y < enemy.global_position.y - 8:
		_kill_enemy(enemy)
		player_node.stomp_bounce()
		Audio.play("stomp", -4.0)
		_freeze_frame(0.05)
	else:
		player_node.take_damage(1)
		var knockback_dir : float = sign(player_node.global_position.x - enemy.global_position.x)
		if knockback_dir == 0:
			knockback_dir = 1
		player_node.velocity.x = knockback_dir * 250
		player_node.velocity.y = -200

func _on_bullet_hit(body: Node2D, bullet: Area2D) -> void:
	if body == player_node:
		player_node.take_damage(1)
		player_node.velocity.y = -150
		bullet.queue_free()
		bullets.erase(bullet)
		Audio.play("bullet_hit", -6.0)

func _on_portal_body_entered(body: Node2D, portal: Area2D) -> void:
	if body == player_node and portal not in player_in_portals:
		player_in_portals.append(portal)

func _on_portal_body_exited(body: Node2D, portal: Area2D) -> void:
	if body == player_node:
		player_in_portals.erase(portal)

func _on_exit_portal_entered(body: Node2D) -> void:
	if body == player_node:
		player_near_exit = true

func _on_hp_changed(new_hp: int) -> void:
	if hp_container:
		for i in 3:
			var heart : Node = hp_container.get_node_or_null("Heart%d" % i)
			if heart:
				(heart as Sprite2D).modulate = Color.WHITE if i < new_hp else Color(0.3, 0.3, 0.3, 0.4)

func _on_shield_changed(has: bool) -> void:
	shield_label.text = "🛡 SHIELD" if has else ""

func _on_player_died() -> void:
	score = 0
	elapsed_time = 0.0
	level_complete = false
	score_label.text = "  0 / %d" % total_coins

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
				(flag_node as Polygon2D).color = Colors.CHECKPOINT_CLR
	player_node.respawn_pos = Vector2(640, 630)

	await get_tree().process_frame
	Builder.make_coins(self, coin_positions, _on_coin_entered)
	Builder.make_enemies(self, enemy_data, _on_enemy_hit)
	Builder.make_powerups(self, powerup_data, _on_powerup_hit)

# -- Teleportation -------------------------------------------------------------
func _teleport_to(target: Vector2) -> void:
	portal_cooldown = 0.5
	player_in_portals.clear()
	Audio.play("portal", -4.0)
	Portals.spawn_teleport_effect(self, player_node.global_position)
	player_node.position = target + Vector2(0, -10)
	player_node.velocity = Vector2.ZERO
	player_node.invincible = 1.0  # Brief invincibility after teleport
	Portals.spawn_teleport_effect(self, target + Vector2(0, -10))

# -- Exit portal ---------------------------------------------------------------
func _spawn_exit_portal() -> void:
	next_portal = Portals.spawn_exit_portal(self, _on_exit_portal_entered)

# -- Particle effects ----------------------------------------------------------
func _spawn_powerup_effect(pos: Vector2, ptype: String) -> void:
	var color := Colors.SHIELD_CLR if ptype == "shield" else Colors.SPEED_CLR
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

func _kill_enemy(enemy: Area2D) -> void:
	var pos := enemy.global_position

	# Squash animation then destroy
	var anim : Node = enemy.get_node_or_null("Anim")
	if anim:
		var tw := get_tree().create_tween()
		tw.tween_property(anim, "scale", Vector2(3.5, 0.3), 0.1)
		tw.tween_callback(_spawn_enemy_death_particles.bind(pos))
		tw.tween_callback(enemy.queue_free)
	else:
		_spawn_enemy_death_particles(pos)
		enemy.queue_free()

func _spawn_enemy_death_particles(pos: Vector2) -> void:
	for i in 8:
		var p := ColorRect.new()
		p.size  = Vector2(5, 5)
		p.color = Colors.ENEMY_CLR
		p.position = pos + Vector2(randf_range(-15, 15), randf_range(-10, 10))
		p.z_index = 5
		add_child(p)

		var angle := i * TAU / 8.0
		var target := pos + Vector2(cos(angle) * 35, sin(angle) * 35 - 20)
		var tw := get_tree().create_tween()
		tw.set_parallel(true)
		tw.tween_property(p, "position", target, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(p, "modulate:a", 0.0, 0.4)
		tw.set_parallel(false)
		tw.tween_callback(p.queue_free)

func _spawn_crumble_particles(pos: Vector2, w: float) -> void:
	for i in 8:
		var p := ColorRect.new()
		p.size = Vector2(6, 6)
		p.color = Colors.CRUMBLE_FILL
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

# -- Freeze frame (hit-stop) ---------------------------------------------------
func _freeze_frame(duration: float) -> void:
	get_tree().paused = true
	await get_tree().create_timer(duration, true, false, true).timeout
	if not pause_menu:  # Don't unpause if user opened menu during freeze
		get_tree().paused = false

func _setup_pause_handler() -> void:
	var handler := Node.new()
	handler.name = "PauseHandler"
	handler.process_mode = Node.PROCESS_MODE_ALWAYS
	handler.set_script(load("res://scripts/PauseHandler.gd"))
	handler.set_meta("world", self)
	add_child(handler)

# -- Pause menu ----------------------------------------------------------------
func _toggle_pause_menu() -> void:
	if pause_menu:
		pause_menu.queue_free()
		pause_menu = null
		get_tree().paused = false
		return

	get_tree().paused = true

	pause_menu = CanvasLayer.new()
	pause_menu.layer = 200
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pause_menu)

	# Dark overlay
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.size = Vector2(1280, 720)
	pause_menu.add_child(overlay)

	# Panel background
	var panel := ColorRect.new()
	panel.color = Color(0.1, 0.1, 0.2, 0.95)
	panel.size = Vector2(500, 480)
	panel.position = Vector2(390, 120)
	pause_menu.add_child(panel)

	# Title
	var title := Label.new()
	title.text = "PAUSED"
	title.position = Vector2(555, 135)
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1, 0.95, 0.55))
	pause_menu.add_child(title)

	# Controls list
	var controls : Array = [
		["Move", "Arrow Keys / ← →"],
		["Jump", "Space / Up Arrow"],
		["Double Jump", "Jump again in air"],
		["Dash", "Z"],
		["Crouch", "Hold Down Arrow"],
		["Drop Through", "Tap Down on platform"],
		["Wall Slide", "Hold toward wall in air"],
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

	# Resume hint
	var hint := Label.new()
	hint.text = "Press ESC to resume"
	hint.position = Vector2(510, y_pos + 15)
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	pause_menu.add_child(hint)

# -- Vignette (low HP warning) -------------------------------------------------
func _create_vignette(hud_layer: CanvasLayer) -> void:
	vignette_rect = ColorRect.new()
	vignette_rect.size = Vector2(1280, 720)
	vignette_rect.color = Color(0.8, 0.05, 0.05, 0.0)
	vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(vignette_rect)

func _update_vignette() -> void:
	if not vignette_rect or not player_node:
		return
	if player_node.hp <= 1:
		# Pulse red overlay when 1 HP
		var pulse := absf(sin(elapsed_time * 3.0)) * 0.2
		vignette_rect.color.a = pulse
	else:
		vignette_rect.color.a = 0.0

# -- Speed lines (dash effect) -------------------------------------------------
func _create_dash_lines() -> void:
	dash_lines_layer = CanvasLayer.new()
	dash_lines_layer.layer = 5
	dash_lines_layer.visible = false
	add_child(dash_lines_layer)

	# Create several horizontal speed line rects
	for i in 12:
		var line := ColorRect.new()
		line.size = Vector2(randf_range(80, 200), randf_range(1, 3))
		line.position = Vector2(randf_range(-50, 1280), randf_range(50, 670))
		line.color = Color(1, 1, 1, randf_range(0.1, 0.3))
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dash_lines_layer.add_child(line)

func _update_dash_lines() -> void:
	if not dash_lines_layer or not player_node:
		return
	dash_lines_layer.visible = player_node.is_dashing
