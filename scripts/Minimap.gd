class_name Minimap
# Helper for building and updating the minimap overlay.

const MINIMAP_W    := 160.0
const MINIMAP_H    := 100.0
const MINIMAP_X    := 1100.0
const MINIMAP_Y    := 580.0
const WORLD_W      := 1400.0
const WORLD_H      := 750.0
const WORLD_OX     := -60.0
const WORLD_OY     := 50.0

# Builds the minimap and returns {node: Control, player_dot: ColorRect}
static func make_minimap(
	hud_layer: CanvasLayer,
	platform_data: Array,
	wall_data: Array,
	spike_data: Array,
	portal_data: Array,
	checkpoint_data: Array,
) -> Dictionary:
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
	var border_top := ColorRect.new()
	border_top.size = Vector2(MINIMAP_W, 1)
	border_top.color = Color(0.4, 0.4, 0.6, 0.6)
	minimap_node.add_child(border_top)

	var border_bot := ColorRect.new()
	border_bot.size = Vector2(MINIMAP_W, 1)
	border_bot.position = Vector2(0, MINIMAP_H - 1)
	border_bot.color = Color(0.4, 0.4, 0.6, 0.6)
	minimap_node.add_child(border_bot)

	var border_left := ColorRect.new()
	border_left.size = Vector2(1, MINIMAP_H)
	border_left.color = Color(0.4, 0.4, 0.6, 0.6)
	minimap_node.add_child(border_left)

	var border_right := ColorRect.new()
	border_right.size = Vector2(1, MINIMAP_H)
	border_right.position = Vector2(MINIMAP_W - 1, 0)
	border_right.color = Color(0.4, 0.4, 0.6, 0.6)
	minimap_node.add_child(border_right)

	# Static platforms
	for pd in platform_data:
		var r := ColorRect.new()
		var mx : float = _map_x(pd[0] - pd[2] * 0.5)
		var my : float = _map_y(pd[1] - pd[3] * 0.5)
		var mw : float = maxf(pd[2] / WORLD_W * MINIMAP_W, 2.0)
		var mh : float = maxf(pd[3] / WORLD_H * MINIMAP_H, 1.0)
		r.position = Vector2(mx, my)
		r.size = Vector2(mw, mh)
		r.color = Color(0.3, 0.7, 0.35, 0.8)
		minimap_node.add_child(r)

	# Walls
	for wd in wall_data:
		var r := ColorRect.new()
		r.position = Vector2(_map_x(wd[0] - wd[2] * 0.5), _map_y(wd[1] - wd[3] * 0.5))
		r.size = Vector2(maxf(wd[2] / WORLD_W * MINIMAP_W, 1.0), maxf(wd[3] / WORLD_H * MINIMAP_H, 2.0))
		r.color = Color(0.4, 0.4, 0.55, 0.7)
		minimap_node.add_child(r)

	# Spikes (as red dots)
	for sd in spike_data:
		var r := ColorRect.new()
		r.position = Vector2(_map_x(sd[0]) - 1, _map_y(sd[1]) - 1)
		r.size = Vector2(maxf(sd[2] * sd[3] / WORLD_W * MINIMAP_W, 2.0), 2)
		r.color = Color(1.0, 0.3, 0.2, 0.7)
		minimap_node.add_child(r)

	# Portals
	for pd in portal_data:
		var pa := ColorRect.new()
		pa.position = Vector2(_map_x(pd[0]) - 2, _map_y(pd[1]) - 3)
		pa.size = Vector2(4, 6)
		pa.color = Color(0.5, 0.3, 0.9, 0.8)
		minimap_node.add_child(pa)

		var pb := ColorRect.new()
		pb.position = Vector2(_map_x(pd[2]) - 2, _map_y(pd[3]) - 3)
		pb.size = Vector2(4, 6)
		pb.color = Color(0.9, 0.5, 0.2, 0.8)
		minimap_node.add_child(pb)

	# Checkpoints
	for cd in checkpoint_data:
		var r := ColorRect.new()
		r.position = Vector2(_map_x(cd[0]) - 1, _map_y(cd[1]) - 3)
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

# -- Coordinate mapping helpers ------------------------------------------------
static func _map_x(world_x: float) -> float:
	return clampf((world_x - WORLD_OX) / WORLD_W * MINIMAP_W, 0, MINIMAP_W)

static func _map_y(world_y: float) -> float:
	return clampf((world_y - WORLD_OY) / WORLD_H * MINIMAP_H, 0, MINIMAP_H)
