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

# Visual nodes (set by World.gd)
var body_rect  : ColorRect
var eye_l      : ColorRect
var eye_r      : ColorRect
var pupil_l    : ColorRect
var pupil_r    : ColorRect
var mouth_rect : ColorRect

signal hp_changed(new_hp: int)
signal player_died

func _physics_process(delta: float) -> void:
	# ── Invincibility blink ───────────────────────────────────────────────
	if invincible > 0.0:
		invincible -= delta
		blink_timer += delta * 20.0
		if body_rect:
			body_rect.modulate.a = 0.3 if int(blink_timer) % 2 == 0 else 1.0
	elif body_rect and body_rect.modulate.a != 1.0:
		body_rect.modulate.a = 1.0

	# ── Dash logic ────────────────────────────────────────────────────────
	dash_cooldown = maxf(dash_cooldown - delta, 0.0)

	if Input.is_action_just_pressed("dash") and dash_cooldown <= 0.0 and not is_dashing:
		is_dashing  = true
		dash_timer  = DASH_DURATION
		dash_dir    = facing
		dash_cooldown = DASH_COOLDOWN
		_spawn_dash_ghost()

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
			jumps_left = 1  # Allow wall jump

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
		elif coyote_timer > 0.0:
			velocity.y   = JUMP_VEL
			jumps_left   = MAX_JUMPS - 1
			coyote_timer = 0.0
			jump_buffer  = 0.0
			_spawn_jump_dust()
		elif jumps_left > 0:
			velocity.y  = AIR_JUMP
			jumps_left -= 1
			jump_buffer = 0.0
			_spawn_jump_dust()

	# ── Horizontal movement ───────────────────────────────────────────────
	var dir := Input.get_axis("ui_left", "ui_right")
	if dir != 0.0:
		velocity.x = dir * SPEED
		facing = 1 if dir > 0.0 else -1
		_update_face_direction()
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED * 6.0 * delta)

	move_and_slide()

	# ── Fall respawn ──────────────────────────────────────────────────────
	if position.y > 920.0:
		take_damage(1)
		position   = Vector2(640, 630)
		velocity   = Vector2.ZERO
		jumps_left = MAX_JUMPS

# ── Damage ───────────────────────────────────────────────────────────────────
func take_damage(amount: int) -> void:
	if invincible > 0.0:
		return
	hp -= amount
	invincible  = 1.5
	blink_timer = 0.0
	hp_changed.emit(hp)
	if hp <= 0:
		hp = max_hp
		position   = Vector2(640, 630)
		velocity   = Vector2.ZERO
		jumps_left = MAX_JUMPS
		invincible = 2.0
		player_died.emit()
		hp_changed.emit(hp)

func stomp_bounce() -> void:
	velocity.y = JUMP_VEL * 0.6

# ── Wall detection ───────────────────────────────────────────────────────────
func _wall_on_right() -> bool:
	return test_move(transform, Vector2(1, 0))

func _wall_on_left() -> bool:
	return test_move(transform, Vector2(-1, 0))

# ── Face direction ───────────────────────────────────────────────────────────
func _update_face_direction() -> void:
	if not pupil_l or not pupil_r:
		return
	if facing > 0:
		pupil_l.position = Vector2(-12 + 3, -14 + 3)
		pupil_r.position = Vector2(  3 + 3, -14 + 3)
	else:
		pupil_l.position = Vector2(-12 + 2, -14 + 3)
		pupil_r.position = Vector2(  3 + 2, -14 + 3)

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
