class_name ConveyorPlatform extends StaticBody2D

var conveyor_dir: float
var conveyor_speed: float = 120.0

var _player_on: bool = false
var _player_ref: WeakRef

func setup_detection(player: CharacterBody2D) -> void:
	_player_ref = weakref(player)
	var area := Area2D.new()
	var cs := CollisionShape2D.new()
	for c in get_children():
		if c is CollisionShape2D and c.shape is RectangleShape2D:
			var rs := RectangleShape2D.new()
			rs.size = (c.shape as RectangleShape2D).size + Vector2(4, 10)
			cs.shape = rs
			break
	if not cs.shape:
		return
	area.add_child(cs)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	add_child(area)

func _on_body_entered(body: Node2D) -> void:
	var player : CharacterBody2D = _player_ref.get_ref() as CharacterBody2D if _player_ref else null
	if body == player:
		_player_on = true

func _on_body_exited(body: Node2D) -> void:
	var player : CharacterBody2D = _player_ref.get_ref() as CharacterBody2D if _player_ref else null
	if body == player:
		_player_on = false

func _physics_process(delta: float) -> void:
	if not _player_on:
		return
	var player := _player_ref.get_ref() as CharacterBody2D if _player_ref else null
	if player and player.is_on_floor():
		player.velocity.x += conveyor_dir * conveyor_speed * delta
