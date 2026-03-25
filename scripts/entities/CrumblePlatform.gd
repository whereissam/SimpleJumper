class_name CrumblePlatform extends StaticBody2D

signal crumbled(platform: CrumblePlatform)

var origin_x: float
var origin_y: float
var width: float
var height: float

var _crumble_timer: float = -1.0
var _respawn_timer: float = -1.0
var _player_ref: WeakRef

const CRUMBLE_DURATION := 0.5
const RESPAWN_DELAY := 3.0
const PLAYER_HALF_WIDTH := 18.0
const PLAYER_DETECT_HEIGHT := 40.0

func set_player(player: CharacterBody2D) -> void:
	_player_ref = weakref(player)

func _physics_process(delta: float) -> void:
	if _respawn_timer > 0.0:
		_respawn_timer -= delta
		if _respawn_timer <= 0.0:
			visible = true
			_set_collision_enabled(true)
			_crumble_timer = -1.0
		return

	if _crumble_timer > 0.0:
		_crumble_timer -= delta
		position.x = origin_x + randf_range(-2, 2)
		if _crumble_timer <= 0.0:
			visible = false
			_set_collision_enabled(false)
			position.x = origin_x
			_respawn_timer = RESPAWN_DELAY
			crumbled.emit(self)
		return

	if _crumble_timer < 0.0:
		var player := _player_ref.get_ref() as CharacterBody2D if _player_ref else null
		if player and player.is_on_floor():
			if absf(player.global_position.x - origin_x) < width * 0.5 + PLAYER_HALF_WIDTH \
			and absf(player.global_position.y - origin_y) < PLAYER_DETECT_HEIGHT:
				_crumble_timer = CRUMBLE_DURATION

func reset() -> void:
	visible = true
	position = Vector2(origin_x, origin_y)
	_crumble_timer = -1.0
	_respawn_timer = -1.0
	_set_collision_enabled(true)

func _set_collision_enabled(enabled: bool) -> void:
	for c in get_children():
		if c is CollisionShape2D:
			c.disabled = not enabled
