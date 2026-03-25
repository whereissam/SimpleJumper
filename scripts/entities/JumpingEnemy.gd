class_name JumpingEnemy extends Area2D

var patrol_center: float  # Used as spawn Y for ground clamping
var patrol_range: float
var patrol_speed: float
var direction: float = 1.0
var jump_interval: float
var jump_force: float
var jump_timer: float
var jumper_vy: float = 0.0

const GRAVITY := 800.0

func _physics_process(delta: float) -> void:
	# Patrol movement
	position.x += direction * patrol_speed * delta
	if position.x > patrol_center + patrol_range:
		direction = -1.0
	elif position.x < patrol_center - patrol_range:
		direction = 1.0

	# Jump logic
	jump_timer -= delta
	if jump_timer <= 0.0:
		jump_timer = jump_interval
		jumper_vy = -jump_force

	jumper_vy += GRAVITY * delta
	position.y += jumper_vy * delta

	# Don't fall below spawn Y
	if position.y > patrol_center + 50:
		position.y = patrol_center + 50
		jumper_vy = 0.0

	# Animation
	var anim := get_node_or_null("Anim") as AnimatedSprite2D
	if anim:
		var anim_name := "walk_right" if direction > 0 else "walk_left"
		if anim.animation != anim_name:
			anim.play(anim_name)
