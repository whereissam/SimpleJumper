class_name Player
extends CharacterBody2D

# ── Movement ─────────────────────────────────────────────────────────────────
const SPEED         := 295.0
const JUMP_VEL      := -550.0
const AIR_JUMP      := -470.0
const GRAVITY       := 1080.0
var   max_jumps     := 2

# ── Dash ─────────────────────────────────────────────────────────────────────
const DASH_SPEED    := 700.0
var   dash_duration := 0.15
const DASH_COOLDOWN := 0.6

# ── Unlock thresholds ────────────────────────────────────────────────────────
const TRIPLE_JUMP_LEVEL := 5   # Unlock triple jump at level 5
const LONG_DASH_LEVEL   := 10  # Unlock longer dash at level 10
const LONG_DASH_DURATION := 0.25

# ── Wall Jump / Climb ────────────────────────────────────────────────────────
const WALL_SLIDE_SPEED := 120.0
const WALL_JUMP_VEL    := Vector2(380.0, -480.0)
const WALL_CLIMB_SPEED := -100.0

# ── Glider ───────────────────────────────────────────────────────────────────
const GLIDE_FALL_SPEED := 60.0
const GLIDE_H_BOOST    := 1.3

# ── Grapple ──────────────────────────────────────────────────────────────────
const GRAPPLE_SPEED    := 600.0
const GRAPPLE_RANGE    := 350.0

# ── Ground Pound ─────────────────────────────────────────────────────────────
const GROUND_POUND_SPEED := 800.0

# ── State ────────────────────────────────────────────────────────────────────
var jumps_left     := 2
var coyote_timer   := 0.0
var jump_buffer    := 0.0
var facing         := 1       # 1 = right, -1 = left

# Dash
var dash_timer     := 0.0
var dash_cooldown  := 0.0
var dash_dir       := 1
var is_dashing     := false

# Wall jump / climb
var is_wall_sliding := false
var is_wall_climbing := false

# Glider
var is_gliding := false

# Grapple
var is_grappling := false
var grapple_target := Vector2.ZERO
var grapple_line : Line2D

# Ground pound
var is_ground_pounding := false

# Drop-through
var drop_timer     := 0.0

# Crouch
var is_crouching   := false
const CROUCH_HEIGHT := 18.0   # Small enough to fit between platforms
const STAND_HEIGHT  := 50.0

# Health
var max_hp         := 3
var hp             := 3
var invincible     := 0.0
var blink_timer    := 0.0

# Power-ups
var has_shield     := false
var speed_boost    := 0.0     # Remaining boost time
const BOOST_MULT  := 1.6

# Combo system
var combo_count    := 0
var combo_timer    := 0.0
const COMBO_WINDOW := 2.0     # Seconds to chain next action before combo resets

# Checkpoint
var respawn_pos    := Vector2(640, 630)

# Visual nodes (set by Builder)
var shield_vis : Polygon2D   # Shield visual indicator
var cam_zoom   := 1.0        # Camera zoom level
var particle_pool : ParticlePool  # Shared particle pool (set by World)

# Squash & stretch
var was_on_floor   := true
var fall_speed_max := 0.0    # Track max fall speed for landing impact

# Camera look-ahead
var look_ahead_x   := 0.0
const LOOK_AHEAD_DIST  := 60.0
const LOOK_AHEAD_SPEED := 3.0
const FALL_DEATH_Y     := 920.0

# Invincibility durations
const INVINCIBLE_AFTER_HIT     := 1.5
const INVINCIBLE_AFTER_SHIELD  := 0.8
const INVINCIBLE_AFTER_RESPAWN := 2.0

# Crouch movement multiplier
const CROUCH_SPEED_MULT := 0.4
const PLAYER_FRAME_HEIGHT := 24.0

signal hp_changed(new_hp: int)
signal player_died
signal shield_changed(has: bool)
signal combo_changed(count: int, multiplier: float)
signal ground_pound_landed(pos: Vector2)

func apply_unlocks(highest_level: int) -> void:
	if highest_level >= TRIPLE_JUMP_LEVEL:
		max_jumps = 3
		jumps_left = 3
	if highest_level >= LONG_DASH_LEVEL:
		dash_duration = LONG_DASH_DURATION

func _unhandled_input(event: InputEvent) -> void:
	# Scroll wheel zoom
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				cam_zoom = clampf(cam_zoom + 0.1, 0.4, 2.0)
				_apply_zoom()
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				cam_zoom = clampf(cam_zoom - 0.1, 0.4, 2.0)
				_apply_zoom()

func _apply_zoom() -> void:
	var cam := get_node_or_null("Camera2D") as Camera2D
	if cam:
		cam.zoom = Vector2(cam_zoom, cam_zoom)

func _physics_process(delta: float) -> void:
	# ── Combo timer ───────────────────────────────────────────────────────
	if combo_count > 0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo_count = 0
			combo_changed.emit(0, 1.0)

	# ── Power-up timers ───────────────────────────────────────────────────
	if speed_boost > 0.0:
		speed_boost -= delta
		var anim_node : Node = get_node_or_null("Anim")
		if anim_node:
			anim_node.modulate = Color(1.0, 0.7, 0.3) if int(speed_boost * 6) % 2 == 0 else Color.WHITE
	else:
		var anim_node : Node = get_node_or_null("Anim")
		if anim_node and anim_node.modulate != Color.WHITE:
			anim_node.modulate = Color.WHITE

	# ── Invincibility blink ───────────────────────────────────────────────
	if invincible > 0.0:
		invincible -= delta
		blink_timer += delta * 20.0
		modulate.a = 0.3 if int(blink_timer) % 2 == 0 else 1.0
	elif modulate.a != 1.0:
		modulate.a = 1.0

	var skin_speed : float = get_meta("skin_speed_mult") if has_meta("skin_speed_mult") else 1.0
	var current_speed := SPEED * skin_speed * (BOOST_MULT if speed_boost > 0.0 else 1.0)

	# ── Dash logic ────────────────────────────────────────────────────────
	dash_cooldown = maxf(dash_cooldown - delta, 0.0)

	if Input.is_action_just_pressed("dash") and dash_cooldown <= 0.0 and not is_dashing:
		is_dashing  = true
		dash_timer  = dash_duration
		dash_dir    = facing
		dash_cooldown = DASH_COOLDOWN
		_spawn_dash_ghost()
		Audio.play("dash", -6.0)

	if is_dashing:
		dash_timer -= delta
		velocity.x  = dash_dir * DASH_SPEED
		velocity.y  = 0.0
		_spawn_dash_afterimage()
		if dash_timer <= 0.0:
			is_dashing = false
		move_and_slide()
		return

	# ── Gravity & Coyote Time ─────────────────────────────────────────────
	if is_on_floor():
		jumps_left   = max_jumps
		coyote_timer = 0.13
		is_wall_sliding = false
		is_gliding = false
		if is_grappling:
			_end_grapple()
	else:
		velocity.y  += GRAVITY * delta
		coyote_timer = maxf(coyote_timer - delta, 0.0)

	# ── Ground pound (X in air) ───────────────────────────────────────────
	if not is_on_floor() and not is_ground_pounding and Input.is_action_just_pressed("ground_pound"):
		is_ground_pounding = true
		velocity.x = 0.0
		velocity.y = GROUND_POUND_SPEED
		is_gliding = false
		is_grappling = false
	if is_ground_pounding:
		velocity.y = GROUND_POUND_SPEED
		if is_on_floor():
			is_ground_pounding = false
			camera_shake(6.0, 0.15)
			_spawn_landing_ring()
			Audio.play("land", -2.0)
			ground_pound_landed.emit(global_position + Vector2(0, 20))

	# ── Grapple (C key, aim toward mouse) ─────────────────────────────────
	if Input.is_action_just_pressed("grapple") and not is_grappling:
		var mouse := get_global_mouse_position()
		var dist := global_position.distance_to(mouse)
		if dist <= GRAPPLE_RANGE:
			is_grappling = true
			grapple_target = mouse
			is_gliding = false
			if not grapple_line:
				grapple_line = Line2D.new()
				grapple_line.width = 2.0
				grapple_line.default_color = Color(0.8, 0.8, 0.4, 0.8)
				grapple_line.z_index = 5
				get_parent().add_child(grapple_line)
	if is_grappling:
		var dir_to_target := (grapple_target - global_position).normalized()
		velocity = dir_to_target * GRAPPLE_SPEED
		if grapple_line:
			grapple_line.clear_points()
			grapple_line.add_point(global_position)
			grapple_line.add_point(grapple_target)
		if global_position.distance_to(grapple_target) < 20.0 or is_on_floor() or is_on_wall():
			_end_grapple()

	# ── Wall slide / Wall climb ───────────────────────────────────────────
	var was_wall_sliding := is_wall_sliding
	is_wall_sliding = false
	is_wall_climbing = false
	if not is_on_floor() and is_on_wall() and not is_grappling:
		var dir := Input.get_axis("ui_left", "ui_right")
		if (dir > 0.0 and _wall_on_right()) or (dir < 0.0 and _wall_on_left()):
			is_wall_sliding = true
			velocity.y = minf(velocity.y, WALL_SLIDE_SPEED)
			jumps_left = 1
			# Wall climb: hold Up while wall sliding
			if Input.is_action_pressed("ui_up"):
				is_wall_climbing = true
				velocity.y = WALL_CLIMB_SPEED
	# Wall slide sound
	if is_wall_sliding and not was_wall_sliding:
		Audio.play_loop("wall_slide", -14.0)
	elif not is_wall_sliding and was_wall_sliding:
		Audio.stop_loop()

	# ── Glider (hold jump while falling) ──────────────────────────────────
	var want_glide := not is_on_floor() and velocity.y > 0 and not is_wall_sliding \
		and not is_dashing and not is_ground_pounding and not is_grappling \
		and (Input.is_action_pressed("ui_accept") or Input.is_action_pressed("ui_up"))
	is_gliding = want_glide
	if is_gliding:
		velocity.y = minf(velocity.y, GLIDE_FALL_SPEED)

	# ── Jump input buffer ─────────────────────────────────────────────────
	if Input.is_action_just_pressed("ui_accept") \
	or Input.is_action_just_pressed("ui_up"):
		jump_buffer = 0.15
	jump_buffer = maxf(jump_buffer - delta, 0.0)

	# ── Down + Jump = drop through with downward push ────────────────────
	if jump_buffer > 0.0 and Input.is_action_pressed("ui_down") and is_on_floor():
		var col : Node = get_node_or_null("CollisionShape2D")
		if col:
			(col as CollisionShape2D).disabled = true
			drop_timer = 0.18
			position.y += 4
			velocity.y = 180.0
			jump_buffer = 0.0

	# ── Execute jump ──────────────────────────────────────────────────────
	elif jump_buffer > 0.0:
		var skin_jump : float = get_meta("skin_jump_mult") if has_meta("skin_jump_mult") else 1.0
		if is_wall_sliding:
			var wall_dir := -1 if _wall_on_right() else 1
			velocity.x   = WALL_JUMP_VEL.x * wall_dir
			velocity.y   = WALL_JUMP_VEL.y * skin_jump
			jumps_left   = 0
			jump_buffer  = 0.0
			is_wall_sliding = false
			_spawn_jump_dust()
			Audio.play("jump", -4.0)
		elif coyote_timer > 0.0:
			velocity.y   = JUMP_VEL * skin_jump
			jumps_left   = max_jumps - 1
			coyote_timer = 0.0
			jump_buffer  = 0.0
			_spawn_jump_dust()
			Audio.play("jump", -4.0)
		elif jumps_left > 0:
			velocity.y  = AIR_JUMP * skin_jump
			jumps_left -= 1
			jump_buffer = 0.0
			_spawn_jump_dust()
			Audio.play("double_jump", -4.0, 1.2)

	# ── Drop through one-way platforms ────────────────────────────────────
	if drop_timer > 0.0:
		drop_timer -= delta
		if drop_timer <= 0.0:
			var col : Node = get_node_or_null("CollisionShape2D")
			if col:
				(col as CollisionShape2D).disabled = false

	# ── Crouch (hold Down) ────────────────────────────────────────────────
	var want_crouch := Input.is_action_pressed("ui_down") and is_on_floor() and not is_dashing
	if want_crouch and not is_crouching:
		is_crouching = true
		_set_hitbox_height(CROUCH_HEIGHT)
	elif not want_crouch and is_crouching:
		is_crouching = false
		_set_hitbox_height(STAND_HEIGHT)

	# Down tap while crouching = drop through platform
	if Input.is_action_just_pressed("ui_down") and is_on_floor():
		var col : Node = get_node_or_null("CollisionShape2D")
		if col:
			(col as CollisionShape2D).disabled = true
			drop_timer = 0.15
			position.y += 2

	# ── Horizontal movement (slower when crouching) ───────────────────────
	var move_speed := current_speed * (CROUCH_SPEED_MULT if is_crouching else 1.0)
	var dir := Input.get_axis("ui_left", "ui_right")
	if dir != 0.0:
		velocity.x = dir * move_speed
		facing = 1 if dir > 0.0 else -1
		_update_face_direction()
	else:
		velocity.x = move_toward(velocity.x, 0.0, current_speed * 6.0 * delta)

	move_and_slide()

	# ── Update sprite animation ───────────────────────────────────────────
	_update_animation()

	# ── Squash & stretch ──────────────────────────────────────────────────
	_update_squash_stretch(delta)

	# ── Camera look-ahead ─────────────────────────────────────────────────
	_update_look_ahead(delta)

	# ── Fall respawn ──────────────────────────────────────────────────────
	if position.y > FALL_DEATH_Y:
		take_damage(1)
		position   = respawn_pos
		velocity   = Vector2.ZERO
		jumps_left = max_jumps

# ── Trampoline bounce ────────────────────────────────────────────────────────
func trampoline_bounce() -> void:
	velocity.y = JUMP_VEL * 1.5
	jumps_left = max_jumps

# ── Damage ───────────────────────────────────────────────────────────────────
func take_damage(amount: int) -> void:
	if invincible > 0.0:
		return
	if has_shield:
		has_shield = false
		invincible = INVINCIBLE_AFTER_SHIELD
		blink_timer = 0.0
		shield_changed.emit(false)
		if shield_vis:
			shield_vis.visible = false
		_spawn_shield_break()
		Audio.play("shield_break", -2.0)
		return
	hp -= amount
	invincible  = INVINCIBLE_AFTER_HIT
	blink_timer = 0.0
	Audio.play("hit", -2.0)
	camera_shake(5.0, 0.2)
	_hit_flash()
	hp_changed.emit(hp)
	if hp <= 0:
		hp = max_hp
		Audio.play("death", -2.0)
		has_shield = false
		speed_boost = 0.0
		if shield_vis:
			shield_vis.visible = false
		shield_changed.emit(false)
		# Death animation: spin + shrink + fade, then respawn
		_play_death_animation()

func _play_death_animation() -> void:
	# Disable control during death
	set_physics_process(false)
	velocity = Vector2.ZERO

	var anim : Node = get_node_or_null("Anim")
	if anim:
		# Pop up, spin, shrink, fade
		var tw := get_tree().create_tween()
		tw.set_parallel(true)
		tw.tween_property(self, "position:y", position.y - 80, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(anim, "rotation", TAU * 2, 0.6)
		tw.tween_property(anim, "scale", Vector2(0.1, 0.1), 0.6)
		tw.tween_property(anim, "modulate:a", 0.0, 0.5)
		tw.set_parallel(false)
		tw.tween_callback(_finish_death)
	else:
		_finish_death()

func _finish_death() -> void:
	# Reset visual state
	var anim : Node = get_node_or_null("Anim")
	if anim:
		anim.rotation = 0.0
		anim.scale = Sprites.SCALE_CHAR
		anim.modulate.a = 1.0

	# Respawn
	position   = respawn_pos
	velocity   = Vector2.ZERO
	jumps_left = max_jumps
	invincible = INVINCIBLE_AFTER_RESPAWN
	is_ground_pounding = false
	is_gliding = false
	_end_grapple()
	set_physics_process(true)
	player_died.emit()
	hp_changed.emit(hp)

func stomp_bounce() -> void:
	velocity.y = JUMP_VEL * 0.6
	camera_shake(3.0, 0.1)

func grant_shield() -> void:
	has_shield = true
	shield_changed.emit(true)
	if shield_vis:
		shield_vis.visible = true

func grant_speed_boost(duration: float) -> void:
	speed_boost = duration

func _end_grapple() -> void:
	is_grappling = false
	if grapple_line:
		grapple_line.queue_free()
		grapple_line = null

func add_combo() -> float:
	## Increments combo, resets timer, returns current multiplier.
	combo_count += 1
	combo_timer = COMBO_WINDOW
	var mult := get_combo_multiplier()
	combo_changed.emit(combo_count, mult)
	return mult

func get_combo_multiplier() -> float:
	## 1x at 0 combo, 1.5x at 2, 2x at 4, capped at 3x.
	return minf(1.0 + combo_count * 0.25, 3.0)

func reset_combo() -> void:
	if combo_count > 0:
		combo_count = 0
		combo_timer = 0.0
		combo_changed.emit(0, 1.0)

func camera_shake(intensity: float = 4.0, duration: float = 0.2) -> void:
	var cam := get_node_or_null("Camera2D") as Camera2D
	if not cam:
		return
	var tw := get_tree().create_tween()
	var steps := int(duration / 0.03)
	for i in steps:
		var shake_offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tw.tween_property(cam, "offset", shake_offset, 0.03)
	tw.tween_property(cam, "offset", Vector2.ZERO, 0.03)

func _hit_flash() -> void:
	# Brief white flash on all sprites
	var anim : Node = get_node_or_null("Anim")
	if anim:
		anim.modulate = Color(10, 10, 10)  # Super bright white
		var tw := get_tree().create_tween()
		tw.tween_property(anim, "modulate", Color.WHITE, 0.12)

func _set_hitbox_height(h: float) -> void:
	var col : Node = get_node_or_null("CollisionShape2D")
	if not col:
		return
	var cs := col as CollisionShape2D
	var new_shape := RectangleShape2D.new()
	new_shape.size = Vector2(36, h)
	cs.shape = new_shape
	# Shift collision AND sprite down equally so feet stay on ground.
	# Standing: shape centered at 0, bottom at +25.
	# Crouch: we want bottom still at +25, so center at 25 - h/2.
	var offset : float = (STAND_HEIGHT - h) * 0.5
	cs.position.y = offset
	_sync_anim_floor_anchor()

func _sync_anim_floor_anchor() -> void:
	var anim : Node = get_node_or_null("Anim")
	if not anim or not anim is AnimatedSprite2D:
		return

	var asp := anim as AnimatedSprite2D
	var hitbox_offset := 0.0
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col:
		hitbox_offset = col.position.y

	# AnimatedSprite2D scales from its center. Compensate vertically so the
	# sprite's feet stay planted when crouch/squash poses change its height.
	var extra_y := PLAYER_FRAME_HEIGHT * (Sprites.SCALE_CHAR.y - asp.scale.y) * 0.5
	asp.position.y = hitbox_offset + extra_y

func set_checkpoint(pos: Vector2) -> void:
	respawn_pos = pos

# ── Wall detection ───────────────────────────────────────────────────────────
func _wall_on_right() -> bool:
	return test_move(transform, Vector2(1, 0))

func _wall_on_left() -> bool:
	return test_move(transform, Vector2(-1, 0))

# ── Face direction (kept for compatibility) ───────────────────────────────────
func _update_face_direction() -> void:
	pass

# ── Sprite animation state ───────────────────────────────────────────────────
func _update_animation() -> void:
	var anim : Node = get_node_or_null("Anim")
	if not anim or not anim is AnimatedSprite2D:
		return
	var asp := anim as AnimatedSprite2D
	var suffix := "_right" if facing > 0 else "_left"

	if is_ground_pounding:
		asp.play("fall" + suffix)
		asp.scale = Sprites.SCALE_CHAR
		asp.rotation += 0.5  # Fast spin
	elif is_grappling:
		asp.play("jump" + suffix)
		asp.scale = Sprites.SCALE_CHAR
		# Tilt toward grapple target
		var angle_to := global_position.angle_to_point(grapple_target)
		asp.rotation = lerp_angle(asp.rotation, angle_to + PI, 0.2)
	elif is_wall_climbing:
		asp.play("wall" + suffix)
		asp.scale = Sprites.SCALE_CHAR
		asp.rotation = 0.0
	elif is_wall_sliding:
		asp.play("wall" + suffix)
		asp.scale = Sprites.SCALE_CHAR
		asp.rotation = 0.2 if facing > 0 else -0.2
	elif is_gliding:
		asp.play("fall" + suffix)
		# Spread wide, flatten vertically = parachute look
		asp.scale = Vector2(Sprites.SCALE_CHAR.x * 1.4, Sprites.SCALE_CHAR.y * 0.7)
		asp.rotation = 0.0
	elif not is_on_floor():
		if velocity.y < 0:
			asp.play("jump" + suffix)
		else:
			asp.play("fall" + suffix)
		asp.scale = Sprites.SCALE_CHAR
		asp.rotation = 0.0
	elif is_crouching:
		asp.play("idle" + suffix)
		asp.scale = Vector2(Sprites.SCALE_CHAR.x * 1.2, Sprites.SCALE_CHAR.y * 0.55)
		asp.rotation = 0.0
	elif absf(velocity.x) > 10.0:
		asp.play("run" + suffix)
		asp.scale = Sprites.SCALE_CHAR
		asp.rotation = 0.0
	else:
		asp.play("idle" + suffix)
		asp.scale = Sprites.SCALE_CHAR
		asp.rotation = 0.0

	_sync_anim_floor_anchor()

# ── Squash & stretch ─────────────────────────────────────────────────────────
func _update_squash_stretch(delta: float) -> void:
	var anim : Node = get_node_or_null("Anim")
	if not anim:
		return

	# Track fall speed for landing impact
	if not is_on_floor():
		fall_speed_max = maxf(fall_speed_max, velocity.y)

	# Landing: squash
	if is_on_floor() and not was_on_floor:
		var impact := clampf(fall_speed_max / 600.0, 0.0, 1.0)
		if impact > 0.15:
			var squash_x := 1.0 + impact * 0.4  # Wider
			var squash_y := 1.0 - impact * 0.3  # Shorter
			anim.scale = anim.scale * Vector2(squash_x, squash_y)
			var tw := get_tree().create_tween()
			tw.tween_property(anim, "scale", Sprites.SCALE_CHAR, 0.15).set_trans(Tween.TRANS_ELASTIC)
			if impact > 0.3:
				Audio.play("land", -8.0)
				_spawn_jump_dust()
				_spawn_landing_ring()
		fall_speed_max = 0.0

	# Jump: stretch
	if not is_on_floor() and was_on_floor and velocity.y < -100:
		anim.scale = Sprites.SCALE_CHAR * Vector2(0.8, 1.25)
		var tw := get_tree().create_tween()
		tw.tween_property(anim, "scale", Sprites.SCALE_CHAR, 0.2).set_trans(Tween.TRANS_QUAD)

	was_on_floor = is_on_floor()

# ── Camera look-ahead ────────────────────────────────────────────────────────
func _update_look_ahead(delta: float) -> void:
	var cam : Node = get_node_or_null("Camera2D")
	if not cam:
		return
	var target_x := facing * LOOK_AHEAD_DIST
	look_ahead_x = move_toward(look_ahead_x, target_x, LOOK_AHEAD_SPEED * delta * 60.0)
	# Don't override shake offset -- add look-ahead to x only
	cam.position = Vector2(look_ahead_x, -15)  # Slight upward offset too

# ── Particle effects ────────────────────────────────────────────────────────
func _spawn_jump_dust() -> void:
	var pos := global_position + Vector2(0, 20)
	var particles: GPUParticles2D
	if particle_pool:
		particles = particle_pool.acquire(pos, 8, 0.4, 0.9, -1)
	else:
		particles = GPUParticles2D.new()
		particles.emitting = true
		particles.one_shot = true
		particles.amount = 8
		particles.lifetime = 0.4
		particles.explosiveness = 0.9
		particles.z_index = -1
		particles.position = pos

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 45.0
	mat.initial_velocity_min = 40.0
	mat.initial_velocity_max = 100.0
	mat.gravity = Vector3(0, 80, 0)
	mat.scale_min = 2.0
	mat.scale_max = 4.0
	mat.color = Color(1.0, 1.0, 1.0, 0.6)
	var color_ramp := GradientTexture1D.new()
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 1.0, 1.0, 0.7))
	grad.set_color(1, Color(0.8, 0.8, 0.8, 0.0))
	color_ramp.gradient = grad
	mat.color_ramp = color_ramp
	particles.process_material = mat

	if not particle_pool:
		get_parent().add_child(particles)
		var tw := get_tree().create_tween()
		tw.tween_interval(0.5)
		tw.tween_callback(particles.queue_free)

func _spawn_dash_ghost() -> void:
	var particles: GPUParticles2D
	if particle_pool:
		particles = particle_pool.acquire(global_position, 12, 0.35, 0.8, -1)
	else:
		particles = GPUParticles2D.new()
		particles.emitting = true
		particles.one_shot = true
		particles.amount = 12
		particles.lifetime = 0.35
		particles.explosiveness = 0.8
		particles.z_index = -1
		particles.position = global_position

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(-facing, 0, 0)
	mat.spread = 20.0
	mat.initial_velocity_min = 30.0
	mat.initial_velocity_max = 80.0
	mat.gravity = Vector3(0, 0, 0)
	mat.scale_min = 3.0
	mat.scale_max = 6.0
	var color_ramp := GradientTexture1D.new()
	var grad := Gradient.new()
	grad.set_color(0, Color(0.5, 0.7, 1.0, 0.6))
	grad.set_color(1, Color(0.3, 0.5, 1.0, 0.0))
	color_ramp.gradient = grad
	mat.color_ramp = color_ramp
	particles.process_material = mat

	if not particle_pool:
		get_parent().add_child(particles)
		var tw := get_tree().create_tween()
		tw.tween_interval(0.5)
		tw.tween_callback(particles.queue_free)

func _spawn_dash_afterimage() -> void:
	var anim : Node = get_node_or_null("Anim")
	if not anim or not anim is AnimatedSprite2D:
		return
	var asp := anim as AnimatedSprite2D
	var ghost := Sprite2D.new()
	ghost.texture = asp.sprite_frames.get_frame_texture(asp.animation, asp.frame)
	ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ghost.scale = asp.scale
	ghost.position = global_position
	ghost.modulate = Color(0.4, 0.6, 1.0, 0.5)
	ghost.z_index = -1
	get_parent().add_child(ghost)
	var tw := get_tree().create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, 0.15)
	tw.tween_callback(ghost.queue_free)

func _spawn_shield_break() -> void:
	var particles: GPUParticles2D
	if particle_pool:
		particles = particle_pool.acquire(global_position, 16, 0.5, 1.0, 5)
	else:
		particles = GPUParticles2D.new()
		particles.emitting = true
		particles.one_shot = true
		particles.amount = 16
		particles.lifetime = 0.5
		particles.explosiveness = 1.0
		particles.z_index = 5
		particles.position = global_position

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 0, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 60.0
	mat.initial_velocity_max = 120.0
	mat.gravity = Vector3(0, 40, 0)
	mat.scale_min = 2.0
	mat.scale_max = 5.0
	var color_ramp := GradientTexture1D.new()
	var grad := Gradient.new()
	grad.set_color(0, Color(0.3, 0.95, 1.0, 0.9))
	grad.set_color(1, Color(0.1, 0.7, 0.9, 0.0))
	color_ramp.gradient = grad
	mat.color_ramp = color_ramp
	particles.process_material = mat

	if not particle_pool:
		get_parent().add_child(particles)
		var tw := get_tree().create_tween()
		tw.tween_interval(0.6)
		tw.tween_callback(particles.queue_free)

func _spawn_landing_ring() -> void:
	# Expanding ring effect at player feet
	var ring := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 24:
		var a := i * TAU / 24.0
		pts.append(Vector2(cos(a) * 8, sin(a) * 3))
	ring.polygon = pts
	ring.color = Color(1, 1, 1, 0.5)
	ring.position = global_position + Vector2(0, 22)
	ring.z_index = -1
	get_parent().add_child(ring)

	var tw := get_tree().create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector2(5, 3), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(ring, "modulate:a", 0.0, 0.25)
	tw.set_parallel(false)
	tw.tween_callback(ring.queue_free)
