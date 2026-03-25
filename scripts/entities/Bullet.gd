class_name Bullet extends Area2D

signal expired(bullet: Bullet)

var bullet_dir: float
var bullet_speed: float
var lifetime: float = 5.0

func _physics_process(delta: float) -> void:
	position.x += bullet_dir * bullet_speed * delta
	lifetime -= delta
	if lifetime <= 0.0 or position.x < -50 or position.x > 1350:
		expired.emit(self)
