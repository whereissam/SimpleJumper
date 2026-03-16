class_name Portals
const Colors = preload("res://scripts/Colors.gd")
# Helper functions for portal creation, teleportation, and exit portal logic.

# -- Create all portal pairs ---------------------------------------------------
# Returns an array of dictionaries: [{area_a, area_b, prompt_a, prompt_b}, ...]
static func make_portals(w: Node2D, data: Array, on_body_entered: Callable, on_body_exited: Callable) -> Array:
	var portal_pairs : Array = []
	for pd in data:
		var pair := {}

		# Portal A
		pair["area_a"] = _create_portal(w, Vector2(pd[0], pd[1]), Colors.PORTAL_CLR_A, Colors.PORTAL_GLOW_A, on_body_entered, on_body_exited)
		pair["prompt_a"] = _create_portal_prompt(w, Vector2(pd[0], pd[1]))

		# Portal B
		pair["area_b"] = _create_portal(w, Vector2(pd[2], pd[3]), Colors.PORTAL_CLR_B, Colors.PORTAL_GLOW_B, on_body_entered, on_body_exited)
		pair["prompt_b"] = _create_portal_prompt(w, Vector2(pd[2], pd[3]))

		portal_pairs.append(pair)
	return portal_pairs

static func _create_portal(w: Node2D, pos: Vector2, color: Color, glow_color: Color, on_body_entered: Callable, on_body_exited: Callable) -> Area2D:
	var area := Area2D.new()
	area.position = pos
	area.set_meta("portal", true)

	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(30, 56)
	cs.shape = rect
	area.add_child(cs)

	# Outer glow (pulsing)
	var glow := Polygon2D.new()
	glow.name = "Glow"
	var gpts := PackedVector2Array()
	for i in 16:
		var a := i * TAU / 16.0
		gpts.append(Vector2(cos(a) * 22, sin(a) * 34))
	glow.polygon = gpts
	glow.color = glow_color
	area.add_child(glow)

	# Portal oval body
	var body := Polygon2D.new()
	var bpts := PackedVector2Array()
	for i in 16:
		var a := i * TAU / 16.0
		bpts.append(Vector2(cos(a) * 14, sin(a) * 26))
	body.polygon = bpts
	body.color = color
	area.add_child(body)

	# Inner swirl (smaller oval, lighter)
	var inner := Polygon2D.new()
	inner.name = "Inner"
	var ipts := PackedVector2Array()
	for i in 12:
		var a := i * TAU / 12.0
		ipts.append(Vector2(cos(a) * 7, sin(a) * 14))
	inner.polygon = ipts
	inner.color = Color(1, 1, 1, 0.25)
	area.add_child(inner)

	# Sparkle particles around portal (decorative dots)
	for i in 4:
		var dot := ColorRect.new()
		dot.size = Vector2(3, 3)
		var angle := i * TAU / 4.0 + 0.3
		dot.position = Vector2(cos(angle) * 18 - 1.5, sin(angle) * 30 - 1.5)
		dot.color = Color(1, 1, 1, 0.4)
		area.add_child(dot)

	area.monitoring = true
	area.body_entered.connect(on_body_entered.bind(area))
	area.body_exited.connect(on_body_exited.bind(area))
	w.add_child(area)

	# Glow pulse animation
	var tw := w.create_tween().set_loops()
	tw.tween_property(glow, "modulate:a", 0.4, 0.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(glow, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)

	# Inner rotation
	var spin := w.create_tween().set_loops()
	spin.tween_property(inner, "rotation", TAU, 3.0)

	return area

static func _create_portal_prompt(w: Node2D, pos: Vector2) -> Label:
	var label := Label.new()
	label.text = "↓ ENTER"
	label.position = pos + Vector2(-28, -50)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	label.visible = false
	w.add_child(label)
	return label

# -- Per-frame portal input check ----------------------------------------------
static func check_portal_input(
	portal_pairs: Array,
	player_in_portals: Array,
	portal_cooldown: float,
	player_node: CharacterBody2D,
	teleport_callable: Callable,
) -> void:
	if not player_node or portal_cooldown > 0.0:
		for pair in portal_pairs:
			pair["prompt_a"].visible = false
			pair["prompt_b"].visible = false
		return

	# Update prompt visibility
	for pair in portal_pairs:
		var area_a : Area2D = pair["area_a"]
		var area_b : Area2D = pair["area_b"]
		pair["prompt_a"].visible = area_a in player_in_portals
		pair["prompt_b"].visible = area_b in player_in_portals
		pair["prompt_a"].position = area_a.position + Vector2(-28, -50)
		pair["prompt_b"].position = area_b.position + Vector2(-28, -50)

	# Teleport with Down arrow
	if Input.is_action_just_pressed("ui_down") and player_in_portals.size() > 0:
		var current_portal : Area2D = player_in_portals[0]
		for pair in portal_pairs:
			if current_portal == pair["area_a"]:
				teleport_callable.call(pair["area_b"].global_position)
				return
			elif current_portal == pair["area_b"]:
				teleport_callable.call(pair["area_a"].global_position)
				return

# -- Teleport effect -----------------------------------------------------------
static func spawn_teleport_effect(w: Node2D, pos: Vector2) -> void:
	for i in 12:
		var p := ColorRect.new()
		p.size = Vector2(4, 4)
		p.color = Color(0.7, 0.5, 1.0, 0.9)
		p.position = pos + Vector2(randf_range(-5, 5), randf_range(-25, 25))
		p.z_index = 10
		w.add_child(p)

		var tw := w.get_tree().create_tween()
		tw.set_parallel(true)
		tw.tween_property(p, "position:y", p.position.y - randf_range(20, 50), 0.5)
		tw.tween_property(p, "position:x", p.position.x + randf_range(-15, 15), 0.5)
		tw.tween_property(p, "modulate:a", 0.0, 0.5)
		tw.set_parallel(false)
		tw.tween_callback(p.queue_free)

# -- Exit portal (next level) --------------------------------------------------
static func spawn_exit_portal(w: Node2D, on_entered: Callable) -> Area2D:
	var exit_pos := Vector2(640, 660)
	var next_portal := Area2D.new()
	next_portal.position = exit_pos
	next_portal.monitoring = true

	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(50, 70)
	cs.shape = rect
	next_portal.add_child(cs)

	# Big glowing portal
	var glow := Polygon2D.new()
	var gpts := PackedVector2Array()
	for i in 16:
		var a := i * TAU / 16.0
		gpts.append(Vector2(cos(a) * 30, sin(a) * 40))
	glow.polygon = gpts
	glow.color = Color(0.2, 1.0, 0.4, 0.3)
	next_portal.add_child(glow)

	var body := Polygon2D.new()
	var bpts := PackedVector2Array()
	for i in 16:
		var a := i * TAU / 16.0
		bpts.append(Vector2(cos(a) * 20, sin(a) * 32))
	body.polygon = bpts
	body.color = Color(0.2, 1.0, 0.5, 0.7)
	next_portal.add_child(body)

	var inner := Polygon2D.new()
	var ipts := PackedVector2Array()
	for i in 12:
		var a := i * TAU / 12.0
		ipts.append(Vector2(cos(a) * 10, sin(a) * 18))
	inner.polygon = ipts
	inner.color = Color(1, 1, 1, 0.3)
	next_portal.add_child(inner)

	# "NEXT LEVEL" label
	var lbl := Label.new()
	lbl.text = "↓ NEXT"
	lbl.position = Vector2(-24, -58)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
	next_portal.add_child(lbl)

	next_portal.body_entered.connect(on_entered)
	w.add_child(next_portal)

	# Pulse animation
	var tw := w.create_tween().set_loops()
	tw.tween_property(glow, "modulate:a", 0.4, 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(glow, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)

	var spin := w.create_tween().set_loops()
	spin.tween_property(inner, "rotation", TAU, 2.5)

	return next_portal
