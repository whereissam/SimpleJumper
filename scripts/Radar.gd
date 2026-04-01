class_name Radar extends Control
## Circular radar HUD showing nearby entities relative to the player.
## Color-coded blips: red=enemy, yellow=coin, cyan=powerup, purple=portal, green=checkpoint.

const RADAR_RADIUS := 55.0   # Display radius in pixels
const RADAR_RANGE  := 400.0  # World range in pixels (how far radar "sees")
const RADAR_X      := 20.0   # Screen position
const RADAR_Y      := 570.0

var _player: Node2D
var _world: Node2D
var _blips: Array[Dictionary] = []  # {pos: Vector2, color: Color, size: float}

# Cached references
var _enemy_arrays: Array = []
var _coin_group := "coins"
var _boss_ref: WeakRef

func setup(player: Node2D, world: Node2D) -> void:
	_player = player
	_world = world
	position = Vector2(RADAR_X, RADAR_Y)
	size = Vector2(RADAR_RADIUS * 2 + 10, RADAR_RADIUS * 2 + 10)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	if not _player or not is_instance_valid(_player):
		return
	_gather_blips()
	queue_redraw()

func _draw() -> void:
	var center := Vector2(RADAR_RADIUS + 5, RADAR_RADIUS + 5)

	# Background circle
	draw_circle(center, RADAR_RADIUS + 2, Color(0.05, 0.05, 0.12, 0.7))
	# Border ring
	_draw_ring(center, RADAR_RADIUS + 2, Color(0.35, 0.35, 0.55, 0.6))
	# Range rings (25%, 50%, 75%)
	for i in [0.25, 0.5, 0.75]:
		_draw_ring(center, RADAR_RADIUS * i, Color(0.2, 0.2, 0.35, 0.3))
	# Crosshair
	draw_line(center + Vector2(-RADAR_RADIUS, 0), center + Vector2(RADAR_RADIUS, 0), Color(0.2, 0.2, 0.35, 0.25), 1.0)
	draw_line(center + Vector2(0, -RADAR_RADIUS), center + Vector2(0, RADAR_RADIUS), Color(0.2, 0.2, 0.35, 0.25), 1.0)

	# Player dot (center)
	draw_circle(center, 3.0, Color(0.3, 0.7, 1.0))

	# Entity blips
	for blip in _blips:
		var world_offset : Vector2 = blip["pos"] - _player.global_position
		var radar_pos := world_offset / RADAR_RANGE * RADAR_RADIUS
		# Clamp to circle
		if radar_pos.length() > RADAR_RADIUS:
			radar_pos = radar_pos.normalized() * RADAR_RADIUS
		draw_circle(center + radar_pos, blip["size"], blip["color"])

	# Label
	draw_string(ThemeDB.fallback_font, Vector2(0, -4), "RADAR", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.6, 0.6, 0.8, 0.6))

func _draw_ring(center: Vector2, radius: float, color: Color) -> void:
	var points := 32
	for i in points:
		var a1 := i * TAU / points
		var a2 := (i + 1) * TAU / points
		draw_line(
			center + Vector2(cos(a1) * radius, sin(a1) * radius),
			center + Vector2(cos(a2) * radius, sin(a2) * radius),
			color, 1.0
		)

func _gather_blips() -> void:
	_blips.clear()
	var ppos := _player.global_position

	# Enemies (red)
	_add_blips_from_array(_get_enemies(), ppos, Color(1.0, 0.25, 0.2, 0.9), 2.5)

	# Boss (large red)
	var boss := _world.get("boss_node")
	if boss and is_instance_valid(boss):
		var dist := (boss as Node2D).global_position.distance_to(ppos)
		if dist <= RADAR_RANGE * 1.5:
			_blips.append({"pos": (boss as Node2D).global_position, "color": Color(1.0, 0.1, 0.1, 1.0), "size": 4.0})

	# Coins (yellow)
	for node in _player.get_tree().get_nodes_in_group(_coin_group):
		var n := node as Node2D
		if n and n.global_position.distance_to(ppos) <= RADAR_RANGE:
			_blips.append({"pos": n.global_position, "color": Color(1.0, 0.85, 0.15, 0.8), "size": 2.0})

	# Powerups (cyan)
	for node in _player.get_tree().get_nodes_in_group("powerups"):
		var n := node as Node2D
		if n and n.global_position.distance_to(ppos) <= RADAR_RANGE:
			_blips.append({"pos": n.global_position, "color": Color(0.3, 0.9, 1.0, 0.9), "size": 2.5})

	# Hazards — saws, spikes (orange)
	for node in _world.get_children():
		if node is Area2D and node.has_meta("hazard"):
			var n := node as Node2D
			if n.global_position.distance_to(ppos) <= RADAR_RANGE:
				_blips.append({"pos": n.global_position, "color": Color(1.0, 0.5, 0.15, 0.7), "size": 2.0})

func _get_enemies() -> Array:
	var all : Array = []
	var pe = _world.get("patrol_enemies")
	if pe:
		all.append_array(pe)
	var je = _world.get("jumping_enemies")
	if je:
		all.append_array(je)
	var fe = _world.get("flying_enemies")
	if fe:
		all.append_array(fe)
	var se = _world.get("shielded_enemies")
	if se:
		all.append_array(se)
	return all

func _add_blips_from_array(arr: Array, ppos: Vector2, color: Color, sz: float) -> void:
	for node in arr:
		if not is_instance_valid(node):
			continue
		var n := node as Node2D
		if n and n.global_position.distance_to(ppos) <= RADAR_RANGE:
			_blips.append({"pos": n.global_position, "color": color, "size": sz})
