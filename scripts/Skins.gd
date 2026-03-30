class_name Skins
## Skin definitions with stat modifiers.

# Each skin: {name, color_tint, cost, speed_mult, jump_mult, max_hp}
const CATALOG : Array = [
	{"id": "default",   "name": "Default",   "tint": Color.WHITE,             "cost": 0,   "speed": 1.0, "jump": 1.0, "hp": 3},
	{"id": "speedster", "name": "Speedster", "tint": Color(0.3, 0.8, 1.0),   "cost": 50,  "speed": 1.3, "jump": 0.95, "hp": 2},
	{"id": "tank",      "name": "Tank",      "tint": Color(0.8, 0.4, 0.3),   "cost": 75,  "speed": 0.8, "jump": 0.9, "hp": 5},
	{"id": "floaty",    "name": "Floaty",    "tint": Color(0.9, 0.7, 1.0),   "cost": 60,  "speed": 1.0, "jump": 1.2, "hp": 2},
	{"id": "golden",    "name": "Golden",    "tint": Color(1.0, 0.85, 0.15), "cost": 150, "speed": 1.1, "jump": 1.1, "hp": 3},
	{"id": "shadow",    "name": "Shadow",    "tint": Color(0.3, 0.3, 0.4),   "cost": 100, "speed": 1.15, "jump": 1.05, "hp": 3},
]

static func get_skin(skin_id: String) -> Dictionary:
	for s in CATALOG:
		if s["id"] == skin_id:
			return s
	return CATALOG[0]

static func apply_skin(player: Player, skin_id: String) -> void:
	var s := get_skin(skin_id)
	player.max_hp = s["hp"]
	player.hp = s["hp"]
	# Tint the player sprite
	var anim : Node = player.get_node_or_null("Anim")
	if anim:
		anim.modulate = s["tint"]
	# Store modifiers for physics
	player.set_meta("skin_speed_mult", s["speed"])
	player.set_meta("skin_jump_mult", s["jump"])
