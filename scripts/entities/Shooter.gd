class_name Shooter extends StaticBody2D

signal fired(shooter: Shooter)

var fire_timer: float
var fire_interval: float
var shoot_dir: float
var bullet_speed: float

func _physics_process(delta: float) -> void:
	fire_timer -= delta
	if fire_timer <= 0.0:
		fire_timer = fire_interval
		fired.emit(self)
