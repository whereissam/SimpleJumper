extends CharacterBody2D

# ── Movement ─────────────────────────────────────────────────────────────────
const SPEED         := 295.0
const JUMP_VEL      := -550.0
const AIR_JUMP      := -470.0
const GRAVITY       := 1080.0
const MAX_JUMPS     := 2

# ── Dash ─────────────────────────────────────────────────────────────────────
const DASH_SPEED    := 700.0
const DASH_DURATION := 0.15
const DASH_COOLDOWN := 0.6

# ── Wall Jump ────────────────────────────────────────────────────────────────
const WALL_SLIDE_SPEED := 120.0
const WALL_JUMP_VEL    := Vector2(380.0, -480.0)

# ── State ────────────────────────────────────────────────────────────────────
var jumps_left     := MAX_JUMPS
var coyote_timer   := 0.0
var jump_buffer    := 0.0
var facing         := 1       # 1 = right, -1 = left

# Dash
var dash_timer     := 0.0
var dash_cooldown  := 0.0
var dash_dir       := 1
var is_dashing     := false

# Wall jump
var is_wall_sliding := false

# Health
var max_hp         := 3
var hp             := 3
var invincible     := 0.0
var blink_timer    := 0.0

# Power-ups
var has_shield     := false
var speed_boost    := 0.0     # Remaining boost time
const BOOST_MULT  := 1.6

# Checkpoint
var respawn_pos    := Vector2(640, 630)

# Visual nodes (set by World.gd)
var body_rect  : ColorRect
var eye_l      : ColorRect
var eye_r      : ColorRect
var pupil_l    : ColorRect
var pupil_r    : ColorRect
var mouth_rect : ColorRect
var shield_vis : Polygon2D   # Shield visual indicator
var cam_zoom   := 1.0        # Camera zoom level

signal hp_changed(new_hp: int)
signal player_died
signal shield_changed(has: bool)

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

	var current_speed := SPEED * (BOOST_MULT if speed_boost > 0.0 else 1.0)

	# ── Dash logic ────────────────────────────────────────────────────────
	dash_cooldown = maxf(dash_cooldown - delta, 0.0)

	if Input.is_action_just_pressed("dash") and dash_cooldown <= 0.0 and not is_dashing:
		is_dashing  = true
		dash_timer  = DASH_DURATION
		dash_dir    = facing
		dash_cooldown = DASH_COOLDOWN
		_spawn_dash_ghost()
		Audio.play("dash", -6.0)

	if is_dashing:
		dash_timer -= delta
		velocity.x  = dash_dir * DASH_SPEED
		velocity.y  = 0.0
		if dash_timer <= 0.0:
			is_dashing = false
		move_and_slide()
		return

	# ── Gravity & Coyote Time ─────────────────────────────────────────────
	if is_on_floor():
		jumps_left   = MAX_JUMPS
		coyote_timer = 0.13
		is_wall_sliding = false
	else:
		velocity.y  += GRAVITY * delta
		coyote_timer = maxf(coyote_timer - delta, 0.0)

	# ── Wall slide ────────────────────────────────────────────────────────
	is_wall_sliding = false
	if not is_on_floor() and is_on_wall():
		var dir := Input.get_axis("ui_left", "ui_right")
		if (dir > 0.0 and _wall_on_right()) or (dir < 0.0 and _wall_on_left()):
			is_wall_sliding = true
			velocity.y = minf(velocity.y, WALL_SLIDE_SPEED)
			jumps_left = 1

	# ── Jump input buffer ─────────────────────────────────────────────────
	if Input.is_action_just_pressed("ui_accept") \
	or Input.is_action_just_pressed("ui_up"):
		jump_buffer = 0.15
	jump_buffer = maxf(jump_buffer - delta, 0.0)

	# ── Execute jump ──────────────────────────────────────────────────────
	if jump_buffer > 0.0:
		if is_wall_sliding:
			var wall_dir := -1 if _wall_on_right() else 1
			velocity.x   = WALL_JUMP_VEL.x * wall_dir
			velocity.y   = WALL_JUMP_VEL.y
			jumps_left   = 0
			jump_buffer  = 0.0
			is_wall_sliding = false
			_spawn_jump_dust()
			Audio.play("jump", -4.0)
		elif coyote_timer > 0.0:
			velocity.y   = JUMP_VEL
			jumps_left   = MAX_JUMPS - 1
			coyote_timer = 0.0
			jump_buffer  = 0.0
			_spawn_jump_dust()
			Audio.play("jump", -4.0)
		elif jumps_left > 0:
			velocity.y  = AIR_JUMP
			jumps_left -= 1
			jump_buffer = 0.0
			_spawn_jump_dust()
			Audio.play("double_jump", -4.0, 1.2)

	# ── Horizontal movement ───────────────────────────────────────────────
	var dir := Input.get_axis("ui_left", "ui_right")
	if dir != 0.0:
		velocity.x = dir * current_speed
		facing = 1 if dir > 0.0 else -1
		_update_face_direction()
	else:
		velocity.x = move_toward(velocity.x, 0.0, current_speed * 6.0 * delta)

	move_and_slide()

	# ── Update sprite animation ───────────────────────────────────────────
	_update_animation()

	# ── Fall respawn ──────────────────────────────────────────────────────
	if position.y > 920.0:
		take_damage(1)
		position   = respawn_pos
		velocity   = Vector2.ZERO
		jumps_left = MAX_JUMPS

# ── Trampoline bounce ────────────────────────────────────────────────────────
func trampoline_bounce() -> void:
	velocity.y = JUMP_VEL * 1.5
	jumps_left = MAX_JUMPS

# ── Damage ───────────────────────────────────────────────────────────────────
func take_damage(amount: int) -> void:
	if invincible > 0.0:
		return
	if has_shield:
		has_shield = false
		invincible = 0.8
		blink_timer = 0.0
		shield_changed.emit(false)
		if shield_vis:
			shield_vis.visible = false
		_spawn_shield_break()
		Audio.play("shield_break", -2.0)
		return
	hp -= amount
	invincible  = 1.5
	blink_timer = 0.0
	Audio.play("hit", -2.0)
	camera_shake(5.0, 0.2)
	hp_changed.emit(hp)
	if hp <= 0:
		hp = max_hp
		position   = respawn_pos
		velocity   = Vector2.ZERO
		jumps_left = MAX_JUMPS
		invincible = 2.0
		Audio.play("death", -2.0)
		has_shield = false
		speed_boost = 0.0
		if shield_vis:
			shield_vis.visible = false
		shield_changed.emit(false)
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

func camera_shake(intensity: float = 4.0, duration: float = 0.2) -> void:
	var cam : Node = get_node_or_null("Camera2D")
	if not cam:
		return
	var tw := get_tree().create_tween()
	var steps := int(duration / 0.03)
	for i in steps:
		var offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tw.tween_property(cam, "offset", offset, 0.03)
	tw.tween_property(cam, "offset", Vector2.ZERO, 0.03)

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

	if not is_on_floor():
		if velocity.y < 0:
			asp.play("jump" + suffix)
		else:
			asp.play("fall" + suffix)
	elif absf(velocity.x) > 10.0:
		asp.play("run" + suffix)
	else:
		asp.play("idle" + suffix)

# ── Particle effects ────────────────────────────────────────────────────────
func _spawn_jump_dust() -> void:
	for i in 6:
		var dust := ColorRect.new()
		dust.size  = Vector2(4, 4)
		dust.color = Color(1, 1, 1, 0.6)
		dust.position = global_position + Vector2(randf_range(-15, 15), 20)
		dust.z_index = -1
		get_parent().add_child(dust)

		var tw := get_tree().create_tween()
		tw.set_parallel(true)
		tw.tween_property(dust, "position:y", dust.position.y - randf_range(15, 40), 0.35)
		tw.tween_property(dust, "modulate:a", 0.0, 0.35)
		tw.set_parallel(false)
		tw.tween_callback(dust.queue_free)

func _spawn_dash_ghost() -> void:
	if not body_rect:
		return
	var ghost := ColorRect.new()
	ghost.size     = Vector2(36, 50)
	ghost.position = global_position + Vector2(-18, -25)
	ghost.color    = Color(0.5, 0.7, 1.0, 0.5)
	ghost.z_index  = -1
	get_parent().add_child(ghost)

	var tw := get_tree().create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, 0.3)
	tw.tween_callback(ghost.queue_free)

func _spawn_shield_break() -> void:
	for i in 10:
		var shard := ColorRect.new()
		shard.size  = Vector2(4, 4)
		shard.color = Color(0.3, 0.9, 1.0, 0.8)
		shard.position = global_position + Vector2(randf_range(-20, 20), randf_range(-25, 15))
		shard.z_index = 5
		get_parent().add_child(shard)

		var angle := randf_range(0, TAU)
		var target := shard.position + Vector2(cos(angle) * 40, sin(angle) * 40)
		var tw := get_tree().create_tween()
		tw.set_parallel(true)
		tw.tween_property(shard, "position", target, 0.4)
		tw.tween_property(shard, "modulate:a", 0.0, 0.4)
		tw.set_parallel(false)
		tw.tween_callback(shard.queue_free)
