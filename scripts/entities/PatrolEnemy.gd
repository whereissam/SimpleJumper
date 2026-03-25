class_name PatrolEnemy extends Area2D

var patrol_center: float
var patrol_range: float
var patrol_speed: float
var direction: float = 1.0

func _physics_process(delta: float) -> void:
	position.x += direction * patrol_speed * delta

	if position.x > patrol_center + patrol_range:
		direction = -1.0
	elif position.x < patrol_center - patrol_range:
		direction = 1.0

	var anim := get_node_or_null("Anim") as AnimatedSprite2D
	if anim:
		var anim_name := "walk_right" if direction > 0 else "walk_left"
		if anim.animation != anim_name:
			anim.play(anim_name)
