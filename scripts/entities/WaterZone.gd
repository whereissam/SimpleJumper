class_name WaterZone extends Area2D
## Area with water physics: slower movement, floating, oxygen timer.

var zone_width: float
var zone_height: float
var oxygen := 5.0
var max_oxygen := 5.0

var _player_inside := false
var _player_ref: WeakRef

signal oxygen_depleted

func setup_detection(player: CharacterBody2D) -> void:
	_player_ref = weakref(player)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	var player := _player_ref.get_ref() as Player if _player_ref else null
	if body == player:
		_player_inside = true
		oxygen = max_oxygen

func _on_body_exited(body: Node2D) -> void:
	var player := _player_ref.get_ref() as Player if _player_ref else null
	if body == player:
		_player_inside = false
		oxygen = max_oxygen

func _physics_process(delta: float) -> void:
	if not _player_inside:
		return
	var player := _player_ref.get_ref() as Player if _player_ref else null
	if not player:
		return

	# Water drag: slow horizontal movement and reduce gravity
	player.velocity.x *= 0.92
	player.velocity.y *= 0.85
	# Buoyancy: gentle upward push
	player.velocity.y -= 300.0 * delta

	# Allow "swimming" up with jump key
	if Input.is_action_pressed("ui_accept") or Input.is_action_pressed("ui_up"):
		player.velocity.y -= 500.0 * delta

	# Oxygen countdown
	oxygen -= delta
	if oxygen <= 0.0:
		oxygen = max_oxygen
		oxygen_depleted.emit()
