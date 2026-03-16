class_name LevelData

# Returns level config dictionary for the given level number (1-based)
static func get_level(num: int) -> Dictionary:
	match num:
		1: return _level_1()
		2: return _level_2()
		3: return _level_3()
		_: return generate_random(num)  # Level 4+ = random

static func total_levels() -> int:
	return 999  # Infinite random levels after 3

# ══════════════════════════════════════════════════════════════════════════════
# RANDOM LEVEL GENERATOR
# ══════════════════════════════════════════════════════════════════════════════
static func generate_random(num: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = num * 7919  # Deterministic per level number

	var difficulty : float = clampf((num - 3) * 0.15, 0.0, 1.0)  # 0.0 to 1.0

	# Generate platforms in a grid with random offsets
	var platforms : Array = [[640, 692, 1600, 36]]  # Ground always
	var coins : Array = []
	var enemies : Array = []
	var spikes : Array = []

	# 4 layers of platforms
	var layers := 4
	var per_layer := rng.randi_range(3, 5)

	for layer in layers:
		var base_y := 570 - layer * 120
		for i in per_layer:
			var x := 120 + i * (1040 / per_layer) + rng.randi_range(-40, 40)
			var y := base_y + rng.randi_range(-20, 20)
			var w := rng.randi_range(100, 200) - int(difficulty * 50)
			w = maxi(w, 80)
			platforms.append([x, y, w, 22])
			# Coin above each platform
			coins.append(Vector2(x, y - 38))

	# Top platform
	platforms.append([620, 130, 240 - int(difficulty * 60), 22])
	coins.append(Vector2(620, 92))

	# Enemies (more with difficulty)
	var num_enemies := 2 + int(difficulty * 4)
	for i in num_enemies:
		var idx := rng.randi_range(1, platforms.size() - 2)
		var ep : Array = platforms[idx]
		enemies.append([ep[0], ep[1] - 22, rng.randi_range(40, 80), 30 + int(difficulty * 30)])

	# Spikes (more with difficulty)
	var num_spike_groups := 1 + int(difficulty * 3)
	for i in num_spike_groups:
		var sx := rng.randi_range(200, 1100)
		spikes.append([sx, 680, rng.randi_range(2, 4), 20])

	# Saws
	var saws : Array = []
	var num_saws := int(difficulty * 2.5)
	for i in num_saws:
		var sx := rng.randi_range(200, 1100)
		var sy := rng.randi_range(250, 550)
		var axis := "x" if rng.randi() % 2 == 0 else "y"
		saws.append([sx, sy, rng.randi_range(12, 18), axis, rng.randi_range(40, 80), rng.randi_range(40, 70)])

	# Shooters
	var shooters : Array = []
	if difficulty > 0.3:
		shooters.append([rng.randi_range(30, 60), rng.randi_range(400, 600), 3.5 - difficulty, rng.randi_range(120, 180), 1])
	if difficulty > 0.6:
		shooters.append([rng.randi_range(1220, 1250), rng.randi_range(300, 500), 3.0 - difficulty * 0.5, rng.randi_range(140, 200), -1])

	# Moving platforms
	var moving : Array = []
	var num_moving := rng.randi_range(1, 3)
	for i in num_moving:
		var mx := rng.randi_range(150, 1100)
		var my := rng.randi_range(250, 550)
		var axis := "x" if rng.randi() % 2 == 0 else "y"
		moving.append([mx, my, rng.randi_range(80, 120), 18, axis, rng.randi_range(60, 140), rng.randi_range(40, 70)])

	# Crumble
	var crumble : Array = []
	if difficulty > 0.2:
		for i in rng.randi_range(1, 3):
			var idx := rng.randi_range(1, platforms.size() - 2)
			var cp : Array = platforms[idx]
			crumble.append([cp[0] + rng.randi_range(50, 100), cp[1] - 70, rng.randi_range(70, 100), 18])

	# Disappear
	var disappear : Array = []
	if difficulty > 0.3:
		for i in rng.randi_range(1, 2):
			var dx := rng.randi_range(150, 1100)
			var dy := rng.randi_range(250, 450)
			disappear.append([dx, dy, rng.randi_range(80, 100), 18, 2.5 - difficulty * 0.5, 1.0 + difficulty * 0.5, randf()])

	# Trampolines
	var trampolines : Array = [[80, 678], [1200, 678]]

	# Checkpoints
	var checkpoints : Array = []
	for i in 2:
		var idx := rng.randi_range(1, platforms.size() - 2)
		var cp : Array = platforms[idx]
		checkpoints.append([cp[0], cp[1] - 22])

	# Powerups
	var powerups : Array = []
	for i in rng.randi_range(2, 4):
		var idx := rng.randi_range(1, platforms.size() - 2)
		var pp : Array = platforms[idx]
		var ptype := "shield" if rng.randi() % 2 == 0 else "speed"
		powerups.append([pp[0], pp[1] - 30, ptype])

	# Portals
	var portals : Array = [[100, 670, 620, 108]]

	# Background colors get darker/redder with difficulty
	var bg := Color(0.07 + difficulty * 0.06, 0.05, 0.14 - difficulty * 0.06)

	return {
		"name": "Level %d - Random (%s)" % [num, ["Easy", "Medium", "Hard", "Extreme"][mini(int(difficulty * 3.99), 3)]],
		"bg_color": bg,
		"platforms": platforms,
		"moving": moving,
		"walls": [[40, 450, 28, 280], [1240, 450, 28, 280]],
		"crumble": crumble,
		"disappear": disappear,
		"spikes": spikes,
		"saws": saws,
		"trampolines": trampolines,
		"checkpoints": checkpoints,
		"powerups": powerups,
		"coins": coins,
		"enemies": enemies,
		"shooters": shooters,
		"portals": portals,
	}

# ══════════════════════════════════════════════════════════════════════════════
# LEVEL 1 -- Friendly / Tutorial
# ══════════════════════════════════════════════════════════════════════════════
static func _level_1() -> Dictionary:
	return {
		"name": "Level 1 - Green Hills",
		"bg_color": Color(0.07, 0.07, 0.16),
		"platforms": [
			[640, 692, 1600, 36],
			[180, 570, 250, 22],
			[460, 540, 220, 22],
			[740, 510, 240, 22],
			[1020, 540, 220, 22],
			[300, 420, 220, 22],
			[580, 380, 200, 22],
			[860, 400, 220, 22],
			[1120, 360, 200, 22],
			[200, 280, 200, 22],
			[480, 260, 180, 22],
			[760, 240, 200, 22],
			[1040, 270, 180, 22],
			[620, 150, 280, 22],
		],
		"moving": [
			[160, 470, 130, 18, "x", 120, 55],
			[950, 310, 120, 18, "y", 60, 40],
		],
		"walls": [
			[50, 480, 28, 240],
			[1230, 480, 28, 240],
		],
		"crumble": [
			[680, 320, 110, 18],
			[400, 190, 100, 18],
		],
		"disappear": [
			[150, 350, 110, 18, 3.0, 1.0, 0.0],
			[1050, 200, 100, 18, 3.0, 1.0, 1.5],
		],
		"spikes": [
			[300, 680, 3, 20],
			[1000, 680, 3, 20],
		],
		"saws": [
			[640, 440, 14, "y", 50, 40],
		],
		"trampolines": [
			[100, 678],
			[1180, 678],
			[580, 500],
			[860, 370],
		],
		"checkpoints": [
			[460, 518],
			[580, 358],
			[760, 218],
		],
		"powerups": [
			[740, 480, "shield"],
			[300, 392, "speed"],
			[620, 122, "shield"],
			[200, 252, "shield"],
		],
		"coins": [
			Vector2(180, 532), Vector2(460, 502), Vector2(740, 472),
			Vector2(1020, 502), Vector2(300, 382), Vector2(580, 342),
			Vector2(860, 362), Vector2(1120, 322), Vector2(200, 242),
			Vector2(480, 222), Vector2(760, 202), Vector2(1040, 232),
			Vector2(620, 112),
		],
		"enemies": [
			[350, 670, 80, 40],
			[740, 488, 60, 35],
			[860, 378, 50, 30],
		],
		"shooters": [
			[1230, 430, 3.5, 140, -1],
		],
		"portals": [
			[120, 670, 620, 128],
			[1100, 538, 200, 258],
		],
	}

# ══════════════════════════════════════════════════════════════════════════════
# LEVEL 2 -- Medium difficulty
# ══════════════════════════════════════════════════════════════════════════════
static func _level_2() -> Dictionary:
	return {
		"name": "Level 2 - Crimson Caves",
		"bg_color": Color(0.12, 0.05, 0.08),
		"platforms": [
			[640, 692, 1600, 36],
			# Layer 1
			[150, 580, 180, 22],
			[400, 550, 160, 22],
			[650, 520, 180, 22],
			[900, 560, 160, 22],
			[1120, 500, 170, 22],
			# Layer 2
			[250, 430, 160, 22],
			[500, 400, 150, 22],
			[750, 370, 170, 22],
			[1000, 410, 150, 22],
			# Layer 3
			[150, 300, 160, 22],
			[400, 270, 140, 22],
			[650, 240, 160, 22],
			[900, 280, 140, 22],
			[1100, 220, 150, 22],
			# Top
			[550, 140, 220, 22],
		],
		"moving": [
			[300, 490, 100, 18, "x", 150, 70],
			[800, 300, 90, 18, "y", 80, 55],
			[1050, 340, 80, 18, "x", 100, 80],
		],
		"walls": [
			[40, 450, 28, 280],
			[1240, 450, 28, 280],
		],
		"crumble": [
			[500, 330, 90, 18],
			[750, 200, 80, 18],
			[300, 210, 90, 18],
		],
		"disappear": [
			[200, 370, 90, 18, 2.5, 1.2, 0.0],
			[950, 170, 90, 18, 2.2, 1.3, 0.8],
			[600, 320, 80, 18, 2.0, 1.5, 1.5],
		],
		"spikes": [
			[400, 680, 4, 20],
			[800, 680, 4, 20],
			[650, 508, 3, 20],
			[1100, 488, 2, 20],
		],
		"saws": [
			[550, 460, 16, "y", 70, 55],
			[850, 450, 14, "x", 80, 65],
		],
		"trampolines": [
			[80, 678],
			[1200, 678],
			[750, 490],
		],
		"checkpoints": [
			[400, 528],
			[750, 348],
			[550, 118],
		],
		"powerups": [
			[650, 490, "shield"],
			[250, 402, "speed"],
			[550, 112, "shield"],
		],
		"coins": [
			Vector2(150, 542), Vector2(400, 512), Vector2(650, 482),
			Vector2(900, 522), Vector2(1120, 462), Vector2(250, 392),
			Vector2(500, 362), Vector2(750, 332), Vector2(1000, 372),
			Vector2(150, 262), Vector2(400, 232), Vector2(650, 202),
			Vector2(900, 242), Vector2(1100, 182), Vector2(550, 102),
		],
		"enemies": [
			[300, 670, 100, 55],
			[650, 498, 70, 45],
			[500, 378, 60, 50],
			[750, 348, 65, 40],
			[900, 258, 50, 45],
		],
		"shooters": [
			[40, 520, 2.8, 160, 1],
			[1240, 380, 3.0, 150, -1],
		],
		"portals": [
			[100, 670, 550, 118],
			[1120, 498, 150, 278],
		],
	}

# ══════════════════════════════════════════════════════════════════════════════
# LEVEL 3 -- Hard
# ══════════════════════════════════════════════════════════════════════════════
static func _level_3() -> Dictionary:
	return {
		"name": "Level 3 - Sky Fortress",
		"bg_color": Color(0.04, 0.06, 0.14),
		"platforms": [
			[640, 692, 1600, 36],
			# Scattered small platforms
			[120, 600, 140, 22],
			[350, 560, 130, 22],
			[550, 510, 120, 22],
			[780, 540, 130, 22],
			[1000, 500, 120, 22],
			[1180, 560, 130, 22],
			# Mid layer
			[200, 420, 130, 22],
			[430, 380, 120, 22],
			[680, 350, 130, 22],
			[920, 390, 120, 22],
			[1130, 340, 120, 22],
			# High layer
			[100, 270, 120, 22],
			[330, 240, 110, 22],
			[560, 210, 120, 22],
			[800, 250, 110, 22],
			[1050, 220, 120, 22],
			# Top
			[600, 120, 200, 22],
		],
		"moving": [
			[250, 480, 80, 18, "x", 130, 85],
			[700, 440, 70, 18, "y", 90, 70],
			[900, 300, 70, 18, "x", 120, 90],
			[450, 170, 70, 18, "y", 60, 50],
		],
		"walls": [
			[30, 420, 28, 320],
			[1250, 420, 28, 320],
		],
		"crumble": [
			[550, 440, 80, 18],
			[330, 310, 70, 18],
			[800, 180, 70, 18],
			[1050, 290, 70, 18],
		],
		"disappear": [
			[160, 340, 80, 18, 2.0, 1.5, 0.0],
			[460, 280, 80, 18, 1.8, 1.5, 0.6],
			[940, 160, 80, 18, 2.0, 1.2, 1.2],
			[720, 290, 70, 18, 1.5, 1.5, 0.3],
		],
		"spikes": [
			[350, 680, 5, 20],
			[700, 680, 5, 20],
			[1050, 680, 4, 20],
			[550, 498, 3, 20],
			[680, 338, 2, 20],
			[1130, 328, 2, 20],
		],
		"saws": [
			[450, 460, 16, "y", 80, 70],
			[850, 470, 14, "x", 90, 80],
			[300, 310, 13, "y", 60, 65],
		],
		"trampolines": [
			[60, 678],
			[1220, 678],
		],
		"checkpoints": [
			[550, 488],
			[680, 328],
			[600, 98],
		],
		"powerups": [
			[780, 510, "shield"],
			[200, 392, "speed"],
			[600, 92, "shield"],
		],
		"coins": [
			Vector2(120, 562), Vector2(350, 522), Vector2(550, 472),
			Vector2(780, 502), Vector2(1000, 462), Vector2(1180, 522),
			Vector2(200, 382), Vector2(430, 342), Vector2(680, 312),
			Vector2(920, 352), Vector2(1130, 302), Vector2(100, 232),
			Vector2(330, 202), Vector2(560, 172), Vector2(800, 212),
			Vector2(1050, 182), Vector2(600, 82),
		],
		"enemies": [
			[250, 670, 90, 60],
			[700, 670, 80, 55],
			[550, 488, 50, 50],
			[680, 328, 50, 45],
			[430, 358, 45, 55],
			[920, 368, 40, 50],
		],
		"shooters": [
			[30, 490, 2.5, 170, 1],
			[1250, 350, 2.2, 180, -1],
			[200, 248, 3.0, 150, 1],
		],
		"portals": [
			[80, 670, 600, 98],
		],
	}
