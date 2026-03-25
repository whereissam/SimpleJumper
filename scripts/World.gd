extends Node2D

const Colors  = preload("res://scripts/Colors.gd")
const Builder = preload("res://scripts/Builder.gd")
const Portals = preload("res://scripts/Portals.gd")
const Minimap = preload("res://scripts/Minimap.gd")

# -- Constants -----------------------------------------------------------------
const PLAYER_SPAWN      := Vector2(640, 630)
const FALL_DEATH_Y      := 920.0
const PORTAL_COOLDOWN   := 0.5
const VIEWPORT_WIDTH    := 1280
const VIEWPORT_HEIGHT   := 720
const HAZARD_BOUNCE     := -250.0
const ENEMY_KNOCKBACK_X := 250.0
const ENEMY_KNOCKBACK_Y := -200.0
const BOSS_KNOCKBACK_X  := 350.0
const BOSS_STOMP_OFFSET := 20.0
const ENEMY_STOMP_OFFSET := 8.0
const SPEED_BOOST_DURATION := 5.0
const BULLET_BOUNCE_Y   := -150.0

# -- Level data (loaded from LevelData.gd) ------------------------------------
var current_level  := 1
var level          : Dictionary
var platform_data  : Array
var moving_platform_data : Array
var wall_data      : Array
var spike_data     : Array
var saw_data       : Array
var trampoline_data : Array
var checkpoint_data : Array
var powerup_data   : Array
var coin_positions : Array
var enemy_data     : Array
var portal_data    : Array
var key_data       : Array
var require_keys   := 0
var keys_collected := 0

# -- Typed entity arrays (replace get_children() scanning) ---------------------
var patrol_enemies  : Array[PatrolEnemy] = []
var jumping_enemies : Array[JumpingEnemy] = []
var shooters        : Array[Shooter] = []
var crumble_bodies  : Array[CrumblePlatform] = []
var ice_platforms   : Array[IcePlatform] = []
var conveyors       : Array[ConveyorPlatform] = []
var wind_zones      : Array[WindZone] = []
var boss_node       : BossEnemy

# -- HUD nodes -----------------------------------------------------------------
var score          := 0
var total_coins    := 0
var score_label    : Label
var hp_label       : Label
var timer_label    : Label
var shield_label   : Label
var key_label      : Label
var shield_icon    : Sprite2D
var hp_container   : Node
var minimap_node   : Control
var minimap_player : ColorRect

# -- State ---------------------------------------------------------------------
var player_node    : Player
var elapsed_time   := 0.0
var level_complete := false
var portal_pairs   : Array = []
var portal_cooldown_timer := 0.0
var player_in_portals : Array = []
var player_near_exit  := false

var level_label    : Label
var next_portal    : Area2D
var world_seed     := 0
var pause_menu       : CanvasLayer
var vignette_rect    : ColorRect
var dash_lines_layer : CanvasLayer


# ==============================================================================
func _ready() -> void:
	var transition := GameState.consume_transition()
	if not transition.is_empty():
		world_seed = transition["seed"]
		current_level = transition["level"]
	else:
		world_seed = randi() % 999999
	_load_level(current_level)
	_build_world()

func _load_level(num: int) -> void:
	level = LevelData.get_level(num, world_seed + num)
	platform_data        = level.get("platforms", [])
	moving_platform_data = level.get("moving", [])
	wall_data            = level.get("walls", [])
	spike_data           = level.get("spikes", [])
	saw_data             = level.get("saws", [])
	trampoline_data      = level.get("trampolines", [])
	checkpoint_data      = level.get("checkpoints", [])
	powerup_data         = level.get("powerups", [])
	coin_positions       = level.get("coins", [])
	enemy_data           = level.get("enemies", [])
	portal_data          = level.get("portals", [])
	key_data             = level.get("keys", [])
	require_keys         = level.get("require_keys", 0)
	var crumble_data : Array = level.get("crumble", [])
	var disappear_data : Array = level.get("disappear", [])
	var ice_data : Array = level.get("ice", [])
	var conveyor_data : Array = level.get("conveyors", [])
	var jumper_data : Array = level.get("jumpers", [])
	var wind_zone_data : Array = level.get("wind_zones", [])
	var shooter_data : Array = level.get("shooters", [])
	var boss_data : Array = level.get("boss", [])

	# Store arrays for _build_world (used once, no need as member vars)
	level["_crumble"] = crumble_data
	level["_disappear"] = disappear_data
	level["_ice"] = ice_data
	level["_conveyors"] = conveyor_data
	level["_jumpers"] = jumper_data
	level["_wind_zones"] = wind_zone_data
	level["_shooters"] = shooter_data
	level["_boss"] = boss_data

func _build_world() -> void:
	Builder.make_background(self, level)
	Builder.make_walls(self, wall_data)
	Builder.make_platforms(self, platform_data)
	Builder.make_moving_platforms(self, moving_platform_data)
	ice_platforms = Builder.make_ice_platforms(self, level["_ice"])
	conveyors = Builder.make_conveyors(self, level["_conveyors"])
	crumble_bodies = Builder.make_crumble_platforms(self, level["_crumble"])
	Builder.make_disappear_platforms(self, level["_disappear"])
	Builder.make_spikes(self, spike_data, _on_hazard_hit)
	Builder.make_saw_blades(self, saw_data, _on_hazard_hit)
	Builder.make_trampolines(self, trampoline_data, _on_trampoline_hit)
	Builder.make_checkpoints(self, checkpoint_data, _on_checkpoint_hit)
	portal_pairs = Portals.make_portals(self, portal_data, _on_portal_body_entered, _on_portal_body_exited)
	Builder.make_powerups(self, powerup_data, _on_powerup_hit)

	# Coins -- set total_coins before creating HUD
	total_coins = coin_positions.size()
	Builder.make_coins(self, coin_positions, _on_coin_entered)

	patrol_enemies = Builder.make_enemies(self, enemy_data, _on_enemy_hit)
	jumping_enemies = Builder.make_jumpers(self, level["_jumpers"], _on_enemy_hit)
	shooters = Builder.make_shooters(self, level["_shooters"])
	wind_zones = Builder.make_wind_zones(self, level["_wind_zones"])
	if key_data.size() > 0:
		Builder.make_keys(self, key_data, _on_key_collected)
	boss_node = Builder.make_boss(self, level["_boss"], _on_boss_hit)

	player_node = Builder.make_player(self)

	# Connect entity signals
	for shooter in shooters:
		shooter.fired.connect(_on_shooter_fired)
	if boss_node:
		boss_node.fired.connect(_on_boss_fired)
	for cb in crumble_bodies:
		cb.set_player(player_node)
		cb.crumbled.connect(_on_crumble_collapsed)
	player_node.hp_changed.connect(_on_hp_changed)
	player_node.player_died.connect(_on_player_died)
	player_node.shield_changed.connect(_on_shield_changed)

	var hud := Builder.make_hud(self, total_coins, level, current_level)
	score_label  = hud["score_label"]
	hp_label     = hud["hp_label"]
	hp_container = hud["hp_container"]
	timer_label  = hud["timer_label"]
	shield_label = hud["shield_label"]
	shield_icon  = hud["shield_icon"]
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

	_create_vignette(hud["hud_layer"])
	_create_dash_lines()
	_setup_pause_handler()
	Audio.start_music()
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
	portal_cooldown_timer = maxf(portal_cooldown_timer - delta, 0.0)
	Portals.check_portal_input(portal_pairs, player_in_portals, portal_cooldown_timer, player_node, _teleport_to)
	Minimap.update(minimap_player, player_node)

	if player_near_exit and Input.is_action_just_pressed("ui_down"):
		player_near_exit = false
		_go_next_level()
		return

	_update_vignette()
	_update_dash_lines()

	if not level_complete:
		elapsed_time += delta
		var mins := int(elapsed_time) / 60
		var secs := int(elapsed_time) % 60
		var ms   := int(fmod(elapsed_time, 1.0) * 100)
		timer_label.text = "⏱  %02d:%02d.%02d" % [mins, secs, ms]

# -- Physics (entities self-update, World handles platform effects) -------------
func _physics_process(delta: float) -> void:
	if not player_node:
		return

	# Ice & conveyor platform effects (require player reference)
	if player_node.is_on_floor():
		for ice in ice_platforms:
			if is_instance_valid(ice):
				ice.apply_ice(player_node, delta)
		for conv in conveyors:
			if is_instance_valid(conv):
				conv.apply_conveyor(player_node, delta)

	# Wind zones (require player reference)
	for zone in wind_zones:
		if is_instance_valid(zone):
			zone.apply_wind(player_node, delta)

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
	GameState.queue_level_transition(to_level, world_seed)
	_fade_and_reload()

func _fade_in() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 1)
	overlay.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cl := CanvasLayer.new()
	cl.layer = 100
	cl.add_child(overlay)
	add_child(cl)

	var tw := create_tween()
	tw.tween_property(overlay, "color:a", 0.0, 0.4)
	tw.tween_callback(cl.queue_free)

func _fade_and_reload() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cl := CanvasLayer.new()
	cl.layer = 100
	cl.add_child(overlay)
	add_child(cl)

	var tw := create_tween()
	tw.tween_property(overlay, "color:a", 1.0, 0.25)
	tw.tween_callback(get_tree().reload_current_scene)

func _go_next_level() -> void:
	GameState.complete_level(current_level, elapsed_time)
	current_level += 1
	_switch_level(current_level)

# -- Signal callbacks ----------------------------------------------------------
func _on_hazard_hit(body: Node2D, _hazard: Area2D) -> void:
	if body == player_node:
		player_node.take_damage(1)
		player_node.velocity.y = HAZARD_BOUNCE

func _on_trampoline_hit(body: Node2D, trampoline: Area2D) -> void:
	if body != player_node:
		return
	player_node.trampoline_bounce()
	Audio.play("trampoline", -4.0)
	var orig_scale := trampoline.scale
	var tw := create_tween()
	tw.tween_property(trampoline, "scale", Vector2(1.3, 0.4), 0.05)
	tw.tween_property(trampoline, "scale", Vector2(0.85, 1.3), 0.1).set_trans(Tween.TRANS_ELASTIC)
	tw.tween_property(trampoline, "scale", orig_scale, 0.15).set_trans(Tween.TRANS_ELASTIC)

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
		# Flag wave animation (looping gentle oscillation)
		var wave := create_tween().set_loops()
		wave.tween_property(flag, "skew", 0.15, 0.5).set_trans(Tween.TRANS_SINE)
		wave.tween_property(flag, "skew", -0.15, 0.5).set_trans(Tween.TRANS_SINE)

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
	if score >= total_coins and keys_collected >= require_keys and not level_complete:
		level_complete = true
		score_label.text = "Complete! Go to EXIT portal!"
		_spawn_exit_portal()
		Audio.play("level_complete", -2.0)
	_spawn_sparkle_burst(key_area.global_position, Color(1.0, 0.85, 0.15, 0.9), 8, 30.0)

func _on_boss_hit(body: Node2D, boss: Area2D) -> void:
	if body != player_node:
		return
	var boss_enemy := boss as BossEnemy
	if player_node.velocity.y > 0 and player_node.global_position.y < boss.global_position.y - BOSS_STOMP_OFFSET:
		var remaining_hp := boss_enemy.take_hit()
		player_node.stomp_bounce()
		Audio.play("stomp", -2.0)
		_freeze_frame(0.08)
		player_node.camera_shake(6.0, 0.2)
		if remaining_hp <= 0:
			_spawn_boss_death_effect(boss.global_position)
			player_node.camera_shake(8.0, 0.3)
			_freeze_frame(0.12)
			_kill_enemy(boss)
			boss_node = null
			Audio.play("level_complete", -2.0)
	else:
		player_node.take_damage(1)
		var knockback_dir := signf(player_node.global_position.x - boss.global_position.x)
		if knockback_dir == 0:
			knockback_dir = 1
		player_node.velocity.x = knockback_dir * BOSS_KNOCKBACK_X
		player_node.velocity.y = HAZARD_BOUNCE

func _on_powerup_hit(body: Node2D, powerup: Area2D) -> void:
	if body != player_node:
		return
	var ptype : String = powerup.get_meta("powerup_type")
	if ptype == "shield":
		player_node.grant_shield()
	else:
		player_node.grant_speed_boost(SPEED_BOOST_DURATION)

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
	if player_node.velocity.y > 0 and player_node.global_position.y < enemy.global_position.y - ENEMY_STOMP_OFFSET:
		_kill_enemy(enemy)
		player_node.stomp_bounce()
		Audio.play("stomp", -4.0)
		_freeze_frame(0.05)
	else:
		player_node.take_damage(1)
		var knockback_dir := signf(player_node.global_position.x - enemy.global_position.x)
		if knockback_dir == 0:
			knockback_dir = 1
		player_node.velocity.x = knockback_dir * ENEMY_KNOCKBACK_X
		player_node.velocity.y = ENEMY_KNOCKBACK_Y

func _on_bullet_hit(body: Node2D, bullet: Area2D) -> void:
	if body == player_node:
		player_node.take_damage(1)
		player_node.velocity.y = BULLET_BOUNCE_Y
		bullet.queue_free()
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
	shield_label.text = "SHIELD" if has else ""
	shield_label.visible = has
	if shield_icon:
		shield_icon.visible = has

func _on_player_died() -> void:
	score = 0
	elapsed_time = 0.0
	level_complete = false
	score_label.text = "  0 / %d" % total_coins

	# Clean up dynamic objects from typed arrays
	for enemy in patrol_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	patrol_enemies.clear()

	for jumper in jumping_enemies:
		if is_instance_valid(jumper):
			jumper.queue_free()
	jumping_enemies.clear()

	# Clean up bullets (they are children of self)
	for child in get_children():
		if child is Bullet:
			child.queue_free()

	# Clean up coins and powerups via groups
	for coin in get_tree().get_nodes_in_group("coins"):
		coin.queue_free()
	for powerup in get_tree().get_nodes_in_group("powerups"):
		powerup.queue_free()

	# Reset crumble platforms
	for sb in crumble_bodies:
		if is_instance_valid(sb):
			sb.reset()

	# Reset checkpoints
	for child in get_tree().get_nodes_in_group("checkpoints"):
		child.set_meta("activated", false)
		var flag_node : Node = child.get_node_or_null("Flag")
		if flag_node:
			(flag_node as Polygon2D).color = Colors.CHECKPOINT_CLR
	player_node.respawn_pos = PLAYER_SPAWN

	await get_tree().process_frame
	Builder.make_coins(self, coin_positions, _on_coin_entered)
	patrol_enemies = Builder.make_enemies(self, enemy_data, _on_enemy_hit)
	Builder.make_powerups(self, powerup_data, _on_powerup_hit)

# -- Entity signal callbacks ---------------------------------------------------
func _on_shooter_fired(shooter: Shooter) -> void:
	var offset := Vector2(shooter.shoot_dir * 20, 0)
	Builder.spawn_bullet(self, shooter.global_position + offset, shooter.shoot_dir, shooter.bullet_speed, _on_bullet_hit)
	Audio.play("shoot", -10.0)

func _on_boss_fired(boss: BossEnemy) -> void:
	var dir_to_player := signf(player_node.global_position.x - boss.global_position.x)
	if dir_to_player == 0:
		dir_to_player = 1.0
	Builder.spawn_bullet(self, boss.global_position + Vector2(dir_to_player * 35, -10), dir_to_player, 200.0, _on_bullet_hit)
	Audio.play("shoot", -8.0)

func _on_crumble_collapsed(platform: CrumblePlatform) -> void:
	_spawn_crumble_particles(Vector2(platform.origin_x, platform.origin_y), platform.width)
	Audio.play("crumble", -6.0)

# -- Teleportation -------------------------------------------------------------
func _teleport_to(target: Vector2) -> void:
	portal_cooldown_timer = PORTAL_COOLDOWN
	player_in_portals.clear()
	Audio.play("portal", -4.0)
	Portals.spawn_teleport_effect(self, player_node.global_position)
	player_node.position = target + Vector2(0, -10)
	player_node.velocity = Vector2.ZERO
	player_node.invincible = 1.0
	Portals.spawn_teleport_effect(self, target + Vector2(0, -10))

# -- Exit portal ---------------------------------------------------------------
func _spawn_exit_portal() -> void:
	next_portal = Portals.spawn_exit_portal(self, _on_exit_portal_entered)

# -- Particle effects ----------------------------------------------------------
func _spawn_powerup_effect(pos: Vector2, ptype: String) -> void:
	var color := Colors.SHIELD_CLR if ptype == "shield" else Colors.SPEED_CLR
	_spawn_sparkle_burst(pos, color, 12, 35.0)

func _spawn_sparkle_burst(pos: Vector2, color: Color, count: int, radius: float) -> void:
	for i in count:
		var p := ColorRect.new()
		p.size = Vector2(4, 4)
		p.color = color
		p.position = pos
		p.z_index = 5
		add_child(p)

		var angle := i * TAU / count
		var target := pos + Vector2(cos(angle) * radius, sin(angle) * radius)
		var tw := get_tree().create_tween()
		tw.set_parallel(true)
		tw.tween_property(p, "position", target, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(p, "modulate:a", 0.0, 0.4)
		tw.set_parallel(false)
		tw.tween_callback(p.queue_free)

func _spawn_coin_sparkle(pos: Vector2) -> void:
	_spawn_burst(pos, Color(1.0, 0.85, 0.1), 12, 80.0, 0.4)

func _spawn_burst(pos: Vector2, color: Color, amount: int, speed: float, lifetime: float) -> void:
	var particles := GPUParticles2D.new()
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
	add_child(particles)

	var tw := get_tree().create_tween()
	tw.tween_interval(lifetime + 0.1)
	tw.tween_callback(particles.queue_free)

func _kill_enemy(enemy: Area2D) -> void:
	var pos := enemy.global_position

	var anim : Node = enemy.get_node_or_null("Anim")
	if anim:
		var tw := get_tree().create_tween()
		tw.tween_property(anim, "scale", Vector2(3.5, 0.3), 0.1)
		tw.tween_callback(_spawn_enemy_death_particles.bind(pos))
		tw.tween_callback(enemy.queue_free)
	else:
		_spawn_enemy_death_particles(pos)
		enemy.queue_free()

	# Remove from typed arrays
	if enemy is PatrolEnemy:
		patrol_enemies.erase(enemy)
	elif enemy is JumpingEnemy:
		jumping_enemies.erase(enemy)

func _spawn_enemy_death_particles(pos: Vector2) -> void:
	_spawn_burst(pos, Colors.ENEMY_CLR, 16, 120.0, 0.5)

func _spawn_boss_death_effect(pos: Vector2) -> void:
	# Big red burst
	_spawn_burst(pos, Colors.ENEMY_CLR, 32, 200.0, 0.7)
	# White flash burst
	_spawn_burst(pos, Color(1, 1, 1, 0.9), 16, 150.0, 0.4)
	# Screen flash
	var flash := ColorRect.new()
	flash.color = Color(1, 0.3, 0.2, 0.5)
	flash.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cl := CanvasLayer.new()
	cl.layer = 50
	cl.add_child(flash)
	add_child(cl)
	var tw := get_tree().create_tween()
	tw.tween_property(flash, "color:a", 0.0, 0.3)
	tw.tween_callback(cl.queue_free)

func _spawn_crumble_particles(pos: Vector2, _w: float) -> void:
	_spawn_burst(pos, Colors.CRUMBLE_FILL, 10, 60.0, 0.5)

# -- Freeze frame (hit-stop) ---------------------------------------------------
func _freeze_frame(duration: float) -> void:
	get_tree().paused = true
	await get_tree().create_timer(duration, true, false, true).timeout
	if not pause_menu:
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

	var hint := Label.new()
	hint.text = "Press ESC to resume"
	hint.position = Vector2(510, y_pos + 15)
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	pause_menu.add_child(hint)

# -- Vignette (low HP warning) -------------------------------------------------
func _create_vignette(hud_layer: CanvasLayer) -> void:
	vignette_rect = ColorRect.new()
	vignette_rect.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	vignette_rect.color = Color(0.8, 0.05, 0.05, 0.0)
	vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(vignette_rect)

func _update_vignette() -> void:
	if not vignette_rect or not player_node:
		return
	if player_node.hp <= 1:
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

	for i in 12:
		var line := ColorRect.new()
		line.size = Vector2(randf_range(80, 200), randf_range(1, 3))
		line.position = Vector2(randf_range(-50, VIEWPORT_WIDTH), randf_range(50, 670))
		line.color = Color(1, 1, 1, randf_range(0.1, 0.3))
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dash_lines_layer.add_child(line)

func _update_dash_lines() -> void:
	if not dash_lines_layer or not player_node:
		return
	dash_lines_layer.visible = player_node.is_dashing
