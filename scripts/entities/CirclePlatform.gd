extends Node2D
## Drives an AnimatableBody2D along a circular path.

func _physics_process(delta: float) -> void:
	var target : AnimatableBody2D = get_meta("orbit_target")
	if not is_instance_valid(target):
		return
	var origin : Vector2 = get_meta("orbit_origin")
	var radius : float = get_meta("orbit_radius")
	var speed : float = get_meta("orbit_speed")
	var angle : float = get_meta("orbit_angle")

	angle += speed * delta
	set_meta("orbit_angle", angle)
	target.position = origin + Vector2(cos(angle) * radius, sin(angle) * radius * 0.6)
