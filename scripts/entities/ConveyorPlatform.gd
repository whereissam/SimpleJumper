class_name ConveyorPlatform extends StaticBody2D

var conveyor_dir: float
var conveyor_speed: float = 120.0

func apply_conveyor(player: CharacterBody2D, delta: float) -> void:
	var px := player.global_position.x
	var py := player.global_position.y
	if absf(px - position.x) < 120 and absf(py - position.y) < 30:
		player.velocity.x += conveyor_dir * conveyor_speed * delta
