class_name Minimap
# Helper for building and updating the minimap overlay.

const MINIMAP_W    := 160.0
const MINIMAP_H    := 100.0
const MINIMAP_X    := 1100.0
const MINIMAP_Y    := 580.0

# Dynamic bounds (calculated from platform data)
static var world_min_x := 0.0
static var world_min_y := 0.0
static var world_max_x := 1280.0
static var world_max_y := 720.0

# Builds the minimap and returns {node: Control, player_dot: ColorRect}
static func make_minimap(
	hud_layer: CanvasLayer,
	platform_data: Array,
	wall_data: Array,
	spike_data: Array,
	portal_data: Array,
	checkpoint_data: Array,
) -> Dictionary:
	# Calculate world bounds from all platform positions
	world_min_x = 9999.0
	world_min_y = 9999.0
	world_max_x = -9999.0
	world_max_y = -9999.0
	for pd in platform_data:
		var px : float = float(pd[0])
		var py : float = float(pd[1])
		var pw : float = float(pd[2])
		world_min_x = minf(world_min_x, px - pw * 0.5)
		world_max_x = maxf(world_max_x, px + pw * 0.5)
		world_min_y = minf(world_min_y, py - 20)
		world_max_y = maxf(world_max_y, py + 40)
	# Add padding
	world_min_x -= 50
	world_min_y -= 50
	world_max_x += 50
	world_max_y += 50

	var minimap_node := Control.new()
	minimap_node.position = Vector2(MINIMAP_X, MINIMAP_Y)
	minimap_node.size = Vector2(MINIMAP_W, MINIMAP_H)
	hud_layer.add_child(minimap_node)

	# Background
	var bg := ColorRect.new()
	bg.size = Vector2(MINIMAP_W, MINIMAP_H)
	bg.color = Color(0.05, 0.05, 0.12, 0.75)
	minimap_node.add_child(bg)

	# Borders
	for edge in [
		[0, 0, MINIMAP_W, 1],
		[0, MINIMAP_H - 1, MINIMAP_W, 1],
		[0, 0, 1, MINIMAP_H],
		[MINIMAP_W - 1, 0, 1, MINIMAP_H],
	]:
		var b := ColorRect.new()
		b.position = Vector2(edge[0], edge[1])
		b.size = Vector2(edge[2], edge[3])
		b.color = Color(0.4, 0.4, 0.6, 0.6)
		minimap_node.add_child(b)

	# Static platforms
	for pd in platform_data:
		var r := ColorRect.new()
		var mx : float = _map_x(float(pd[0]) - float(pd[2]) * 0.5)
		var my : float = _map_y(float(pd[1]))
		var mw : float = maxf(float(pd[2]) / (world_max_x - world_min_x) * MINIMAP_W, 2.0)
		r.position = Vector2(mx, my)
		r.size = Vector2(mw, 1.5)
		r.color = Color(0.3, 0.7, 0.35, 0.8)
		minimap_node.add_child(r)

	# Walls
	for wd in wall_data:
		var r := ColorRect.new()
		r.position = Vector2(_map_x(float(wd[0])), _map_y(float(wd[1]) - float(wd[3]) * 0.5))
		var mh : float = maxf(float(wd[3]) / (world_max_y - world_min_y) * MINIMAP_H, 2.0)
		r.size = Vector2(2, mh)
		r.color = Color(0.4, 0.4, 0.55, 0.7)
		minimap_node.add_child(r)

	# Spikes (as red dots)
	for sd in spike_data:
		var r := ColorRect.new()
		r.position = Vector2(_map_x(float(sd[0])) - 1, _map_y(float(sd[1])) - 1)
		r.size = Vector2(3, 2)
		r.color = Color(1.0, 0.3, 0.2, 0.7)
		minimap_node.add_child(r)

	# Portals
	for pd in portal_data:
		var pa := ColorRect.new()
		pa.position = Vector2(_map_x(float(pd[0])) - 2, _map_y(float(pd[1])) - 3)
		pa.size = Vector2(4, 6)
		pa.color = Color(0.5, 0.3, 0.9, 0.8)
		minimap_node.add_child(pa)

		var pb := ColorRect.new()
		pb.position = Vector2(_map_x(float(pd[2])) - 2, _map_y(float(pd[3])) - 3)
		pb.size = Vector2(4, 6)
		pb.color = Color(0.9, 0.5, 0.2, 0.8)
		minimap_node.add_child(pb)

	# Checkpoints
	for cd in checkpoint_data:
		var r := ColorRect.new()
		r.position = Vector2(_map_x(float(cd[0])) - 1, _map_y(float(cd[1])) - 3)
		r.size = Vector2(2, 5)
		r.color = Color(0.2, 0.85, 0.4, 0.8)
		minimap_node.add_child(r)

	# Label
	var lbl := Label.new()
	lbl.text = "MAP"
	lbl.position = Vector2(2, -16)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.8, 0.6))
	minimap_node.add_child(lbl)

	# Player dot (updated every frame)
	var minimap_player := ColorRect.new()
	minimap_player.size = Vector2(5, 5)
	minimap_player.color = Color(0.3, 0.6, 1.0, 1.0)
	minimap_player.z_index = 1
	minimap_node.add_child(minimap_player)

	return {"node": minimap_node, "player_dot": minimap_player}

# -- Update player dot position ------------------------------------------------
static func update(minimap_player_dot: ColorRect, player_node: Node2D) -> void:
	if not minimap_player_dot or not player_node:
		return
	minimap_player_dot.position = Vector2(
		_map_x(player_node.global_position.x) - 2.5,
		_map_y(player_node.global_position.y) - 2.5
	)

# -- Coordinate mapping helpers (dynamic bounds) -------------------------------
static func _map_x(wx: float) -> float:
	var range_x := world_max_x - world_min_x
	if range_x < 1:
		range_x = 1
	return clampf((wx - world_min_x) / range_x * MINIMAP_W, 0, MINIMAP_W)

static func _map_y(wy: float) -> float:
	var range_y := world_max_y - world_min_y
	if range_y < 1:
		range_y = 1
	return clampf((wy - world_min_y) / range_y * MINIMAP_H, 0, MINIMAP_H)
