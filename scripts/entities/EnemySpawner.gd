class_name EnemySpawner extends Area2D

signal enemy_spawned(spawner: Area2D, enemy_pos: Vector2)

var spawn_interval: float = 4.0
var spawn_timer: float
var patrol_range: float = 60.0
var patrol_speed: float = 40.0
var max_spawned: int = 3
var _spawned_count: int = 0
var _pulse_time: float = 0.0

func _ready() -> void:
	spawn_timer = spawn_interval

func _physics_process(delta: float) -> void:
	_pulse_time += delta

	# Pulsing visual
	var fill := get_node_or_null("Fill") as ColorRect
	if fill:
		var pulse := 0.6 + sin(_pulse_time * 3.0) * 0.15
		fill.color = Color(0.9, 0.3, 0.9, pulse)

	spawn_timer -= delta
	if spawn_timer <= 0.0 and _spawned_count < max_spawned:
		spawn_timer = spawn_interval
		_spawned_count += 1
		enemy_spawned.emit(self, global_position + Vector2(0, -20))

func on_child_killed() -> void:
	_spawned_count = maxi(_spawned_count - 1, 0)
