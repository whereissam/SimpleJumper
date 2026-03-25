class_name FlyingEnemy extends Area2D

var patrol_center_x: float
var patrol_center_y: float
var patrol_range: float
var patrol_speed: float
var wave_amplitude: float = 40.0
var wave_speed: float = 2.0
var direction: float = 1.0
var _time: float = 0.0

func _physics_process(delta: float) -> void:
	_time += delta

	# Horizontal patrol
	position.x += direction * patrol_speed * delta
	if position.x > patrol_center_x + patrol_range:
		direction = -1.0
	elif position.x < patrol_center_x - patrol_range:
		direction = 1.0

	# Sine wave vertical movement
	position.y = patrol_center_y + sin(_time * wave_speed) * wave_amplitude

	# Animation
	var anim := get_node_or_null("Anim") as AnimatedSprite2D
	if anim:
		var anim_name := "walk_right" if direction > 0 else "walk_left"
		if anim.animation != anim_name:
			anim.play(anim_name)
