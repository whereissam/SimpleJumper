class_name IcePlatform extends StaticBody2D

func apply_ice(player: CharacterBody2D, delta: float) -> void:
	var px := player.global_position.x
	var py := player.global_position.y
	if absf(px - position.x) < 100 and absf(py - position.y) < 30:
		player.velocity.x = move_toward(player.velocity.x, 0.0, 30.0 * delta)
