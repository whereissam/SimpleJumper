extends Node2D

const Bld = preload("res://scripts/Builder.gd")
const Ptl = preload("res://scripts/Portals.gd")
const Mmp = preload("res://scripts/Minimap.gd")

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
var gravity_zones   : Array[GravityZone] = []
var water_zones     : Array[WaterZone] = []
var destructibles   : Array[DestructibleBlock] = []
var flying_enemies  : Array = []
var shielded_enemies: Array = []
var spawners        : Array = []
var boss_node       : BossEnemy
var bullet_pool     : BulletPool
var particle_pool   : ParticlePool

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
var death_count    := 0
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
var camera_fx        : CameraFX
var combo_label      : Label
var game_mode        : String = ""  # "", "endless", "daily"
var renderer_25d     : Renderer25D
var is_25d           := false


# ==============================================================================
func _ready() -> void:
	var transition := GameState.consume_transition()
	if not transition.is_empty():
		world_seed = transition["seed"]
		current_level = transition["level"]
		game_mode = transition.get("mode", "")
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
	var flyer_data : Array = level.get("flyers", [])
	var shielded_data : Array = level.get("shielded", [])

	# Store arrays for _build_world (used once, no need as member vars)
	level["_crumble"] = crumble_data
	level["_disappear"] = disappear_data
	level["_ice"] = ice_data
	level["_conveyors"] = conveyor_data
	level["_jumpers"] = jumper_data
	level["_wind_zones"] = wind_zone_data
	level["_shooters"] = shooter_data
	level["_boss"] = boss_data
	level["_flyers"] = flyer_data
	level["_shielded"] = shielded_data
	level["_spawners"] = level.get("spawners", [])
	level["_destructibles"] = level.get("destructibles", [])
	level["_gravity_zones"] = level.get("gravity_zones", [])
	level["_water_zones"] = level.get("water_zones", [])

func _build_world() -> void:
	Bld.make_background(self, level)
	Bld.make_walls(self, wall_data)
	Bld.make_platforms(self, platform_data)
	Bld.make_moving_platforms(self, moving_platform_data)
	ice_platforms = Bld.make_ice_platforms(self, level["_ice"])
	conveyors = Bld.make_conveyors(self, level["_conveyors"])
	crumble_bodies = Bld.make_crumble_platforms(self, level["_crumble"])
	Bld.make_disappear_platforms(self, level["_disappear"])
	Bld.make_spikes(self, spike_data, _on_hazard_hit)
	Bld.make_saw_blades(self, saw_data, _on_hazard_hit)
	Bld.make_trampolines(self, trampoline_data, _on_trampoline_hit)
	Bld.make_checkpoints(self, checkpoint_data, _on_checkpoint_hit)
	portal_pairs = Ptl.make_portals(self, portal_data, _on_portal_body_entered, _on_portal_body_exited)
	Bld.make_powerups(self, powerup_data, _on_powerup_hit)

	# Coins -- set total_coins before creating HUD
	total_coins = coin_positions.size()
	Bld.make_coins(self, coin_positions, _on_coin_entered)

	# Particle pool (reuses GPUParticles2D nodes)
	particle_pool = ParticlePool.new()
	particle_pool.setup()
	add_child(particle_pool)

	# Bullet pool (must exist before shooters/boss)
	bullet_pool = BulletPool.new()
	bullet_pool.setup(_on_bullet_hit)
	add_child(bullet_pool)

	patrol_enemies = Bld.make_enemies(self, enemy_data, _on_enemy_hit)
	jumping_enemies = Bld.make_jumpers(self, level["_jumpers"], _on_enemy_hit)
	shooters = Bld.make_shooters(self, level["_shooters"])
	wind_zones = Bld.make_wind_zones(self, level["_wind_zones"])
	gravity_zones = Bld.make_gravity_zones(self, level["_gravity_zones"])
	water_zones = Bld.make_water_zones(self, level["_water_zones"])
	destructibles = Bld.make_destructibles(self, level["_destructibles"], _on_block_destroyed)
	flying_enemies = Bld.make_flyers(self, level["_flyers"], _on_enemy_hit)
	shielded_enemies = Bld.make_shielded(self, level["_shielded"], _on_shielded_hit)
	spawners = Bld.make_spawners(self, level["_spawners"], _on_spawner_hit)
	if key_data.size() > 0:
		Bld.make_keys(self, key_data, _on_key_collected)
	boss_node = Bld.make_boss(self, level["_boss"], _on_boss_hit)

	# Bonus room
	var bonus_data : Dictionary = level.get("bonus_room", {})
	if not bonus_data.is_empty():
		_build_bonus_room(bonus_data)

	player_node = Bld.make_player(self)
	player_node.particle_pool = particle_pool
	player_node.apply_unlocks(GameState.save.highest_level)
	Skins.apply_skin(player_node, GameState.save.active_skin)

	# Connect entity signals
	for shooter in shooters:
		shooter.fired.connect(_on_shooter_fired)
	if boss_node:
		boss_node.fired.connect(_on_boss_fired)
		if camera_fx:
			camera_fx.start_boss_tracking()
	for sp in spawners:
		sp.enemy_spawned.connect(_on_spawner_spawn)
	for cb in crumble_bodies:
		cb.set_player(player_node)
		cb.crumbled.connect(_on_crumble_collapsed)
	for ice in ice_platforms:
		ice.setup_detection(player_node)
	for conv in conveyors:
		conv.setup_detection(player_node)
	for zone in wind_zones:
		zone.setup_detection(player_node)
	for gz in gravity_zones:
		gz.setup_detection(player_node)
	for wz in water_zones:
		wz.setup_detection(player_node)
		wz.oxygen_depleted.connect(_on_water_oxygen_depleted)
	player_node.hp_changed.connect(_on_hp_changed)
	player_node.player_died.connect(_on_player_died)
	player_node.shield_changed.connect(_on_shield_changed)
	player_node.combo_changed.connect(_on_combo_changed)

	var hud := Bld.make_hud(self, total_coins, level, current_level)
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

	# Combo label
	combo_label = Label.new()
	combo_label.text = ""
	combo_label.position = Vector2(540, 10)
	combo_label.add_theme_font_size_override("font_size", 24)
	combo_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	combo_label.visible = false
	hud["hud_layer"].add_child(combo_label)

	# Best time display
	if GameState.save.best_times.has(current_level):
		var best : float = GameState.save.best_times[current_level]
		var bm := int(best) / 60
		var bs := int(best) % 60
		var bms := int(fmod(best, 1.0) * 100)
		var best_lbl := Label.new()
		best_lbl.text = "Best  %02d:%02d.%02d" % [bm, bs, bms]
		best_lbl.position = Vector2(1070, 42)
		best_lbl.add_theme_font_size_override("font_size", 14)
		best_lbl.add_theme_color_override("font_color", Color(0.5, 0.7, 0.5, 0.7))
		hud["hud_layer"].add_child(best_lbl)

	# Mode indicator
	if game_mode != "":
		var mode_lbl := Label.new()
		mode_lbl.text = game_mode.to_upper()
		mode_lbl.position = Vector2(580, 695)
		mode_lbl.add_theme_font_size_override("font_size", 16)
		var mode_color := Color(1.0, 0.6, 0.2) if game_mode == "daily" else Color(0.8, 0.3, 0.3)
		mode_lbl.add_theme_color_override("font_color", mode_color)
		hud["hud_layer"].add_child(mode_lbl)

	_create_vignette(hud["hud_layer"])
	_create_dash_lines()
	_setup_pause_handler()

	# Camera cinematics
	camera_fx = CameraFX.new()
	camera_fx.setup(player_node, self)
	camera_fx.compute_bounds(platform_data, wall_data)

	Audio.start_music()
	_fade_in()
	camera_fx.play_intro()

	var mm := Mmp.make_minimap(
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
	Ptl.check_portal_input(portal_pairs, player_in_portals, portal_cooldown_timer, player_node, _teleport_to)
	Mmp.update(minimap_player, player_node)

	if player_near_exit and Input.is_action_just_pressed("ui_down"):
		player_near_exit = false
		_go_next_level()
		return

	_update_vignette()
	_update_dash_lines()

	# Boss camera tracking
	if camera_fx and boss_node and is_instance_valid(boss_node):
		camera_fx.update_boss_tracking(boss_node.global_position)

	if not level_complete:
		elapsed_time += delta
		var mins := int(elapsed_time) / 60
		var secs := int(elapsed_time) % 60
		var ms   := int(fmod(elapsed_time, 1.0) * 100)
		timer_label.text = "⏱  %02d:%02d.%02d" % [mins, secs, ms]


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
			KEY_V:
				_toggle_25d()

# -- 2.5D toggle ---------------------------------------------------------------
func _toggle_25d() -> void:
	is_25d = not is_25d
	if is_25d:
		if not renderer_25d:
			renderer_25d = Renderer25D.new()
			add_child(renderer_25d)
			renderer_25d.setup(self)
		else:
			renderer_25d.visible = true
			renderer_25d.set_process(true)
		# Hide 2D camera
		var cam_2d := player_node.get_node_or_null("Camera2D") as Camera2D
		if cam_2d:
			cam_2d.enabled = false
	else:
		if renderer_25d:
			renderer_25d.visible = false
			renderer_25d.set_process(false)
		# Restore 2D visuals
		_restore_2d_sprites()
		var cam_2d := player_node.get_node_or_null("Camera2D") as Camera2D
		if cam_2d:
			cam_2d.enabled = true

func _restore_2d_sprites() -> void:
	# Re-show all hidden 2D sprites
	for child in get_children():
		if child is CanvasLayer and child.layer < 0:
			child.visible = true
	_restore_visuals_recursive(self)

func _restore_visuals_recursive(node: Node) -> void:
	for child in node.get_children():
		if child is Sprite2D or child is AnimatedSprite2D or child is Polygon2D:
			child.visible = true
		_restore_visuals_recursive(child)

# -- Level switching -----------------------------------------------------------
func _switch_level(to_level: int) -> void:
	GameState.queue_level_transition(to_level, world_seed, game_mode)
	# Show 3D hub room every 5 levels after Lv10
	if to_level >= 10 and to_level % 5 == 0 and game_mode == "":
		_fade_to_hub()
	else:
		_fade_and_reload()

func _fade_to_hub() -> void:
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
	tw.tween_callback(get_tree().change_scene_to_file.bind("res://scenes/HubRoom3D.tscn"))

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
	var stars := GameState.calc_stars(current_level, elapsed_time)
	Effects.show_level_complete(self, stars, elapsed_time)
	if camera_fx:
		camera_fx.play_level_complete_zoom()
	GameState.complete_level(current_level, elapsed_time)
	GameState.session_coins += score
	current_level += 1
	# Delay transition to show overlay
	await get_tree().create_timer(1.5).timeout
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
	Effects.spawn_sparkle_burst(self, key_area.global_position, Color(1.0, 0.85, 0.15, 0.9), 8, 30.0)

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
			Effects.spawn_boss_death(self, boss.global_position, particle_pool)
			player_node.camera_shake(8.0, 0.3)
			_freeze_frame(0.12)
			_kill_enemy(boss)
			boss_node = null
			if camera_fx:
				camera_fx.stop_boss_tracking()
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

	Effects.spawn_powerup_effect(self, powerup.global_position, ptype)
	powerup.queue_free()
	Audio.play("powerup", -4.0)

func _on_coin_entered(body: Node2D, coin: Area2D) -> void:
	if body != player_node:
		return
	Effects.spawn_coin_sparkle(self, coin.global_position, particle_pool)
	coin.queue_free()
	var mult := player_node.add_combo()
	score += maxi(1, int(mult))
	Audio.play("coin", -6.0, randf_range(0.9, 1.1))
	var all_coins := score >= total_coins
	var all_keys := keys_collected >= require_keys
	if all_coins and all_keys:
		level_complete = true
		if game_mode == "endless":
			score_label.text = "Next wave!"
			Audio.play("level_complete", -2.0)
			_go_next_level()
		elif current_level < LevelData.total_levels():
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
		player_node.add_combo()
		Audio.play("stomp", -4.0)
		_freeze_frame(0.05)
	else:
		player_node.take_damage(1)
		player_node.reset_combo()
		var knockback_dir := signf(player_node.global_position.x - enemy.global_position.x)
		if knockback_dir == 0:
			knockback_dir = 1
		player_node.velocity.x = knockback_dir * ENEMY_KNOCKBACK_X
		player_node.velocity.y = ENEMY_KNOCKBACK_Y

func _on_shielded_hit(body: Node2D, enemy: Area2D) -> void:
	if body != player_node:
		return
	if player_node.velocity.y > 0 and player_node.global_position.y < enemy.global_position.y - ENEMY_STOMP_OFFSET:
		if enemy.take_stomp():
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

func _on_bullet_hit(body: Node2D, _bullet: Area2D) -> void:
	if body == player_node:
		player_node.take_damage(1)
		player_node.velocity.y = BULLET_BOUNCE_Y
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

func _on_combo_changed(count: int, multiplier: float) -> void:
	if count < 2:
		combo_label.visible = false
	else:
		combo_label.visible = true
		combo_label.text = "COMBO x%d  (%.1fx)" % [count, multiplier]
		# Pop effect
		combo_label.scale = Vector2(1.3, 1.3)
		var tw := create_tween()
		tw.tween_property(combo_label, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_ELASTIC)

func _on_player_died() -> void:
	death_count += 1
	if camera_fx:
		camera_fx.play_death_cam()
	Effects.show_death_overlay(self, death_count, score, total_coins, elapsed_time)
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

	for flyer in flying_enemies:
		if is_instance_valid(flyer):
			flyer.queue_free()
	flying_enemies.clear()

	for se in shielded_enemies:
		if is_instance_valid(se):
			se.queue_free()
	shielded_enemies.clear()

	for sp in spawners:
		if is_instance_valid(sp):
			sp.queue_free()
	spawners.clear()

	# Return all pooled objects
	if particle_pool:
		particle_pool.release_all()
	if bullet_pool:
		bullet_pool.release_all()

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
	Bld.make_coins(self, coin_positions, _on_coin_entered)
	patrol_enemies = Bld.make_enemies(self, enemy_data, _on_enemy_hit)
	Bld.make_powerups(self, powerup_data, _on_powerup_hit)

# -- Entity signal callbacks ---------------------------------------------------
func _on_shooter_fired(shooter: Shooter) -> void:
	var offset := Vector2(shooter.shoot_dir * 20, 0)
	bullet_pool.fire(shooter.global_position + offset, shooter.shoot_dir, shooter.bullet_speed)
	Audio.play("shoot", -10.0)

func _on_boss_fired(boss: BossEnemy) -> void:
	var dir_to_player := signf(player_node.global_position.x - boss.global_position.x)
	if dir_to_player == 0:
		dir_to_player = 1.0
	bullet_pool.fire(boss.global_position + Vector2(dir_to_player * 35, -10), dir_to_player, 200.0)
	Audio.play("shoot", -8.0)

func _on_spawner_hit(body: Node2D, spawner: Area2D) -> void:
	if body != player_node:
		return
	if player_node.velocity.y > 0 and player_node.global_position.y < spawner.global_position.y - ENEMY_STOMP_OFFSET:
		_kill_enemy(spawner)
		spawners.erase(spawner)
		player_node.stomp_bounce()
		Audio.play("stomp", -2.0)
		_freeze_frame(0.08)
		player_node.camera_shake(5.0, 0.2)
	else:
		player_node.take_damage(1)
		var knockback_dir := signf(player_node.global_position.x - spawner.global_position.x)
		if knockback_dir == 0:
			knockback_dir = 1
		player_node.velocity.x = knockback_dir * ENEMY_KNOCKBACK_X
		player_node.velocity.y = ENEMY_KNOCKBACK_Y

func _on_spawner_spawn(spawner: Area2D, pos: Vector2) -> void:
	# Create a patrol enemy at the spawn position
	var spawn_data := [[int(pos.x), int(pos.y), spawner.patrol_range, spawner.patrol_speed]]
	var new_enemies := Bld.make_enemies(self, spawn_data, _on_enemy_hit)
	patrol_enemies.append_array(new_enemies)

func _on_crumble_collapsed(platform: CrumblePlatform) -> void:
	Effects.spawn_crumble(self, Vector2(platform.origin_x, platform.origin_y), particle_pool)
	Audio.play("crumble", -6.0)

func _on_block_destroyed(block: StaticBody2D) -> void:
	Effects.spawn_crumble(self, block.global_position, particle_pool)
	Audio.play("crumble", -4.0)
	destructibles.erase(block)

func _on_water_oxygen_depleted() -> void:
	if player_node:
		player_node.take_damage(1)

# -- Teleportation -------------------------------------------------------------
func _teleport_to(target: Vector2) -> void:
	portal_cooldown_timer = PORTAL_COOLDOWN
	player_in_portals.clear()
	Audio.play("portal", -4.0)
	Ptl.spawn_teleport_effect(self, player_node.global_position)
	player_node.position = target + Vector2(0, -10)
	player_node.velocity = Vector2.ZERO
	player_node.invincible = 1.0
	Ptl.spawn_teleport_effect(self, target + Vector2(0, -10))

# -- Exit portal ---------------------------------------------------------------
func _spawn_exit_portal() -> void:
	next_portal = Ptl.spawn_exit_portal(self, _on_exit_portal_entered)
	if camera_fx and next_portal:
		camera_fx.cinematic_pan_to(next_portal.global_position)

# -- Effects (delegated to Effects.gd) -----------------------------------------

func _kill_enemy(enemy: Area2D) -> void:
	var pos := enemy.global_position

	var anim : Node = enemy.get_node_or_null("Anim")
	if anim:
		var tw := get_tree().create_tween()
		tw.tween_property(anim, "scale", Vector2(3.5, 0.3), 0.1)
		tw.tween_callback(_on_enemy_death_fx.bind(pos))
		tw.tween_callback(enemy.queue_free)
	else:
		_on_enemy_death_fx(pos)
		enemy.queue_free()

	# Remove from typed arrays
	if enemy is PatrolEnemy:
		patrol_enemies.erase(enemy)
	elif enemy is JumpingEnemy:
		jumping_enemies.erase(enemy)
	elif enemy in flying_enemies:
		flying_enemies.erase(enemy)
	elif enemy in shielded_enemies:
		shielded_enemies.erase(enemy)

func _on_enemy_death_fx(pos: Vector2) -> void:
	Effects.spawn_enemy_death(self, pos, particle_pool)

func _build_bonus_room(data: Dictionary) -> void:
	var entrance_pos := Vector2(data["entrance_x"], data["entrance_y"])
	var room_pos := Vector2(data["room_x"], data["room_y"])
	var num_coins : int = data["num_coins"]

	# Hidden entrance portal (small, subtle green glow)
	var entrance := Ptl._create_portal(
		self, entrance_pos,
		Color(0.1, 0.8, 0.3, 0.4), Color(0.2, 1.0, 0.4, 0.15),
		_on_portal_body_entered, _on_portal_body_exited
	)
	entrance.scale = Vector2(0.6, 0.6)

	# Return portal in bonus room
	var exit := Ptl._create_portal(
		self, room_pos + Vector2(0, -10),
		Color(0.1, 0.8, 0.3, 0.4), Color(0.2, 1.0, 0.4, 0.15),
		_on_portal_body_entered, _on_portal_body_exited
	)

	portal_pairs.append({
		"area_a": entrance, "prompt_a": Ptl._create_portal_prompt(self, entrance_pos),
		"area_b": exit, "prompt_b": Ptl._create_portal_prompt(self, room_pos + Vector2(0, -10)),
	})

	# Bonus room platform
	Bld._create_static_platform(self, [data["room_x"], data["room_y"] + 30, 400, 22])

	# "BONUS" label
	var bonus_lbl := Label.new()
	bonus_lbl.text = "BONUS ROOM"
	bonus_lbl.position = room_pos + Vector2(-50, -60)
	bonus_lbl.add_theme_font_size_override("font_size", 20)
	bonus_lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4, 0.8))
	add_child(bonus_lbl)

	# Scatter coins in the bonus room
	var bonus_coins : Array = []
	for i in num_coins:
		var cx : int = int(data["room_x"]) + (i - num_coins / 2) * 30
		var cy : int = int(data["room_y"]) - 5
		bonus_coins.append(Vector2(cx, cy))
		coin_positions.append(Vector2(cx, cy))
	Bld.make_coins(self, bonus_coins, _on_coin_entered)
	total_coins += num_coins


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
	pause_menu = Effects.create_pause_menu(self)

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
