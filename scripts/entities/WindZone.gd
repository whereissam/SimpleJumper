class_name WindZone extends Area2D

var wind_dir: float
var wind_strength: float
var zone_width: float
var zone_height: float

func apply_wind(player: CharacterBody2D, delta: float) -> void:
	var px := player.global_position.x
	var py := player.global_position.y
	if absf(px - global_position.x) < zone_width * 0.5 and absf(py - global_position.y) < zone_height * 0.5:
		player.velocity.x += wind_dir * wind_strength * delta
