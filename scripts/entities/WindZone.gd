class_name WindZone extends Area2D

var wind_dir: float
var wind_strength: float
var zone_width: float
var zone_height: float

var _player_inside: bool = false
var _player_ref: WeakRef

func setup_detection(player: CharacterBody2D) -> void:
	_player_ref = weakref(player)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	var player : CharacterBody2D = _player_ref.get_ref() as CharacterBody2D if _player_ref else null
	if body == player:
		_player_inside = true

func _on_body_exited(body: Node2D) -> void:
	var player : CharacterBody2D = _player_ref.get_ref() as CharacterBody2D if _player_ref else null
	if body == player:
		_player_inside = false

func _physics_process(delta: float) -> void:
	if not _player_inside:
		return
	var player := _player_ref.get_ref() as CharacterBody2D if _player_ref else null
	if player:
		player.velocity.x += wind_dir * wind_strength * delta
