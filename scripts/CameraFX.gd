class_name CameraFX
## Camera cinematic effects: intro pan, boss tracking, exit reveal, death cam, bounds.

var _player: Player
var _cam: Camera2D
var _world: Node2D
var _intro_done := false
var _boss_tracking := false
var _original_zoom := Vector2.ONE
var _cinematic_active := false

# Camera bounds (computed from level data)
var level_left   := -100
var level_right  := 1380
var level_top    := -600
var level_bottom := 750

func setup(player: Player, world: Node2D) -> void:
	_player = player
	_world = world
	_cam = player.get_node_or_null("Camera2D") as Camera2D
	if _cam:
		_original_zoom = _cam.zoom

## Compute camera bounds from platform data so camera doesn't show empty space.
func compute_bounds(platform_data: Array, wall_data: Array) -> void:
	if platform_data.is_empty():
		return
	var min_x := 99999.0
	var max_x := -99999.0
	var min_y := 99999.0
	var max_y := -99999.0
	for p in platform_data:
		var px : float = p[0]
		var py : float = p[1]
		var pw : float = p[2]
		min_x = minf(min_x, px - pw * 0.5)
		max_x = maxf(max_x, px + pw * 0.5)
		min_y = minf(min_y, py - 40)
		max_y = maxf(max_y, py + 40)
	for w in wall_data:
		var wx : float = w[0]
		min_x = minf(min_x, wx - 20)
		max_x = maxf(max_x, wx + 20)
	# Add padding so camera doesn't clip edges
	level_left   = int(min_x - 120)
	level_right  = int(max_x + 120)
	level_top    = int(min_y - 200)
	level_bottom = 750  # Keep ground visible
	if _cam:
		_cam.limit_left   = level_left
		_cam.limit_right  = level_right
		_cam.limit_top    = level_top
		_cam.limit_bottom = level_bottom

## Level start: zoom out for overview, then zoom into player.
func play_intro() -> void:
	if not _cam or not _player:
		_intro_done = true
		return
	_cinematic_active = true
	# Disable smoothing so we can control position directly
	_cam.position_smoothing_enabled = false
	_cam.zoom = Vector2(0.55, 0.55)

	var tw := _world.create_tween()
	tw.tween_interval(0.6)
	tw.tween_property(_cam, "zoom", _original_zoom, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(_on_intro_done)

func _on_intro_done() -> void:
	if _cam:
		_cam.position_smoothing_enabled = true
	_intro_done = true
	_cinematic_active = false

## Brief camera pan to a target position, then back to player.
func cinematic_pan_to(target_pos: Vector2) -> void:
	if not _cam or not _player or _cinematic_active:
		return
	_cinematic_active = true
	var old_smoothing := _cam.position_smoothing_enabled
	_cam.position_smoothing_enabled = true
	var old_speed := _cam.position_smoothing_speed
	_cam.position_smoothing_speed = 4.0

	# Temporarily reparent camera to world for free movement
	var cam_global := _cam.global_position
	_cam.get_parent().remove_child(_cam)
	_world.add_child(_cam)
	_cam.global_position = cam_global

	# Create a marker at target
	var marker := Node2D.new()
	marker.global_position = target_pos
	_world.add_child(marker)

	# Pan to target
	var tw := _world.create_tween()
	tw.tween_property(_cam, "global_position", target_pos, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.tween_interval(0.5)
	# Pan back
	tw.tween_callback(_return_cam_to_player.bind(old_speed))
	tw.tween_interval(0.4)
	tw.tween_callback(marker.queue_free)
	tw.tween_callback(func(): _cinematic_active = false)

func _return_cam_to_player(restore_speed: float) -> void:
	if not _cam or not _player or not is_instance_valid(_player):
		return
	# Only reparent if camera is currently on world (not already on player)
	if _cam.get_parent() != _player:
		_cam.get_parent().remove_child(_cam)
		_player.add_child(_cam)
	_cam.position = Vector2.ZERO
	_cam.position_smoothing_speed = restore_speed

## Zoom out to show full level on level complete.
func play_level_complete_zoom() -> void:
	if not _cam or _cinematic_active:
		return
	var tw := _world.create_tween()
	tw.tween_property(_cam, "zoom", Vector2(0.6, 0.6), 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

## Boss tracking: zoom out to keep both player and boss visible.
func start_boss_tracking() -> void:
	_boss_tracking = true

func stop_boss_tracking() -> void:
	if not _boss_tracking:
		return
	_boss_tracking = false
	if _cam:
		var tw := _world.create_tween()
		tw.tween_property(_cam, "zoom", _original_zoom, 0.5).set_trans(Tween.TRANS_QUAD)

func update_boss_tracking(boss_pos: Vector2) -> void:
	if not _boss_tracking or not _cam or not _player or _cinematic_active:
		return
	var dist := _player.global_position.distance_to(boss_pos)
	# Zoom out proportional to distance, min 0.55x
	var target_zoom := clampf(1.0 - (dist - 200.0) / 800.0, 0.55, 1.0)
	_cam.zoom = _cam.zoom.lerp(Vector2(target_zoom, target_zoom), 0.05)

## Death camera: brief slow-mo + slight zoom.
func play_death_cam() -> void:
	if not _cam:
		return
	# Slow-mo
	Engine.time_scale = 0.4
	var tw := _world.create_tween().set_ignore_time_scale(true)
	tw.tween_property(_cam, "zoom", _original_zoom * 1.3, 0.3)
	tw.tween_interval(0.3)
	tw.tween_callback(_restore_death_cam)

func _restore_death_cam() -> void:
	Engine.time_scale = 1.0
	if _cam:
		var tw := _world.create_tween()
		tw.tween_property(_cam, "zoom", _original_zoom, 0.2)
