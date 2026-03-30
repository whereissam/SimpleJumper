class_name BossEnemy extends Area2D

signal fired(boss: BossEnemy)

var boss_speed: float
var boss_dir: float = 1.0
var boss_fire_timer: float
var boss_fire_interval: float
var boss_hp: int
var boss_max_hp: int
var boss_variant: int = 0  # 0=normal, 1=charger, 2=jumper

const PATROL_LEFT := 230.0
const PATROL_RIGHT := 1050.0

# Charger variant state
var _charge_timer := 0.0
var _is_charging := false
const CHARGE_SPEED := 500.0
const CHARGE_DURATION := 0.4
const CHARGE_COOLDOWN := 3.0

# Jumper variant state
var _jump_timer := 0.0
var _jump_vy := 0.0
var _base_y := 0.0
const JUMP_INTERVAL := 2.0
const JUMP_FORCE := -400.0
const BOSS_GRAVITY := 600.0

func _physics_process(delta: float) -> void:
	match boss_variant:
		0:
			_normal_movement(delta)
		1:
			_charger_movement(delta)
		2:
			_jumper_movement(delta)

	boss_fire_timer -= delta
	if boss_fire_timer <= 0.0:
		boss_fire_timer = boss_fire_interval
		fired.emit(self)

	# Animation
	var anim := get_node_or_null("Anim") as AnimatedSprite2D
	if anim:
		var anim_name := "walk_right" if boss_dir > 0 else "walk_left"
		if anim.animation != anim_name:
			anim.play(anim_name)
		# Charger flash when charging
		if boss_variant == 1 and _is_charging:
			anim.modulate = Color(1.5, 0.5, 0.5)
		elif boss_variant == 1 and not _is_charging and anim.modulate != Color.WHITE:
			anim.modulate = Color.WHITE

func _normal_movement(delta: float) -> void:
	position.x += boss_dir * boss_speed * delta
	if position.x > PATROL_RIGHT:
		boss_dir = -1.0
	elif position.x < PATROL_LEFT:
		boss_dir = 1.0

func _charger_movement(delta: float) -> void:
	if _is_charging:
		position.x += boss_dir * CHARGE_SPEED * delta
		_charge_timer -= delta
		if _charge_timer <= 0.0:
			_is_charging = false
			_charge_timer = CHARGE_COOLDOWN
	else:
		# Normal patrol until charge ready
		position.x += boss_dir * boss_speed * delta
		_charge_timer -= delta
		if _charge_timer <= 0.0:
			_is_charging = true
			_charge_timer = CHARGE_DURATION

	if position.x > PATROL_RIGHT:
		boss_dir = -1.0
		_is_charging = false
	elif position.x < PATROL_LEFT:
		boss_dir = 1.0
		_is_charging = false

func _jumper_movement(delta: float) -> void:
	if _base_y == 0.0:
		_base_y = position.y

	# Horizontal patrol
	position.x += boss_dir * boss_speed * delta
	if position.x > PATROL_RIGHT:
		boss_dir = -1.0
	elif position.x < PATROL_LEFT:
		boss_dir = 1.0

	# Jump logic
	_jump_timer -= delta
	if _jump_timer <= 0.0 and position.y >= _base_y:
		_jump_vy = JUMP_FORCE
		_jump_timer = JUMP_INTERVAL

	_jump_vy += BOSS_GRAVITY * delta
	position.y += _jump_vy * delta
	if position.y >= _base_y:
		position.y = _base_y
		_jump_vy = 0.0

func take_hit() -> int:
	boss_hp -= 1
	# Update HP bar
	var bar := get_node_or_null("BarFill") as ColorRect
	if bar:
		bar.size.x = 60.0 * boss_hp / boss_max_hp
	# Flash red
	var anim := get_node_or_null("Anim") as AnimatedSprite2D
	if anim:
		anim.modulate = Color(10, 0, 0)
		var tw := get_tree().create_tween()
		tw.tween_property(anim, "modulate", Color.WHITE, 0.15)
	return boss_hp
