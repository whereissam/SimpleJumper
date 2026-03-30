class_name GravityZone extends Area2D
## Area that flips gravity for the player while inside.

var zone_width: float
var zone_height: float

var _player_inside := false
var _player_ref: WeakRef

func setup_detection(player: CharacterBody2D) -> void:
	_player_ref = weakref(player)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	var player := _player_ref.get_ref() as Player if _player_ref else null
	if body == player:
		_player_inside = true

func _on_body_exited(body: Node2D) -> void:
	var player := _player_ref.get_ref() as Player if _player_ref else null
	if body == player:
		_player_inside = false

func _physics_process(delta: float) -> void:
	if not _player_inside:
		return
	var player := _player_ref.get_ref() as Player if _player_ref else null
	if player:
		# Reverse gravity: apply upward force that overcomes normal gravity + extra
		player.velocity.y -= Player.GRAVITY * delta * 2.2
