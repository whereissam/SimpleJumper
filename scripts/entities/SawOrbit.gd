extends Area2D
## Saw blade with circular or figure-8 orbit pattern.

var _time: float = 0.0

func _physics_process(delta: float) -> void:
	_time += delta
	var cx : float = get_meta("center_x")
	var cy : float = get_meta("center_y")
	var dist : float = get_meta("orbit_dist")
	var spd : float = get_meta("orbit_speed")
	var pattern : String = get_meta("pattern")

	var angle := _time * spd
	if pattern == "circle":
		position.x = cx + cos(angle) * dist
		position.y = cy + sin(angle) * dist
	else:  # figure8
		position.x = cx + cos(angle) * dist
		position.y = cy + sin(angle * 2.0) * dist * 0.5
