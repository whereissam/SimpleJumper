class_name LevelData

# Every level is randomly generated using seed + level number
# Level number controls difficulty (higher = harder)
static func get_level(num: int, seed_val: int = 0) -> Dictionary:
	return generate_random(num, seed_val)

static func total_levels() -> int:
	return 999  # Infinite levels

# ══════════════════════════════════════════════════════════════════════════════
# RANDOM LEVEL GENERATOR -- 6 layout styles, fully procedural
# ══════════════════════════════════════════════════════════════════════════════
static func generate_random(num: int, seed_val: int = 0) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val * 7919 + num * 1301

	var difficulty : float = clampf((num - 1) * 0.1, 0.0, 1.0)

	var platforms : Array = []
	var coins : Array = []
	var enemies : Array = []
	var spikes : Array = []

	# Pick a random layout style
	var style := rng.randi_range(0, 5)

	# Ground floor: sometimes full, sometimes with gaps
	var has_full_ground := rng.randf() > difficulty * 0.5
	if has_full_ground:
		platforms.append([640, 692, 1600, 36])
	else:
		platforms.append([200, 692, 350, 36])
		platforms.append([700, 692, 300, 36])
		platforms.append([1120, 692, 350, 36])

	match style:
		0:
			# ZIGZAG -- platforms alternate left-right going up
			var x := rng.randi_range(100, 300)
			var y := 600
			var going_right := true
			for i in rng.randi_range(8, 14):
				var w := rng.randi_range(100, 220) - int(difficulty * 40)
				platforms.append([x, y, maxi(w, 70), 22])
				coins.append(Vector2(x, y - 38))
				y -= rng.randi_range(60, 110)
				if going_right:
					x += rng.randi_range(150, 300)
					if x > 1100:
						going_right = false
				else:
					x -= rng.randi_range(150, 300)
					if x < 180:
						going_right = true
				x = clampi(x, 100, 1180)
				if y < 120:
					break
		1:
			# SPIRAL -- platforms wind around the center
			var cx := 640.0
			var cy := 400.0
			var radius := 100.0
			var angle := rng.randf_range(0, TAU)
			for i in rng.randi_range(10, 16):
				var px := int(cx + cos(angle) * radius)
				var py := int(cy + sin(angle) * radius * 0.6)
				px = clampi(px, 100, 1180)
				py = clampi(py, 130, 650)
				var w := rng.randi_range(90, 180) - int(difficulty * 30)
				platforms.append([px, py, maxi(w, 70), 22])
				coins.append(Vector2(px, py - 38))
				angle += rng.randf_range(0.6, 1.2)
				radius += rng.randf_range(20, 50)
		2:
			# TOWERS -- 2-4 vertical columns of platforms
			var num_towers := rng.randi_range(2, 4)
			for t in num_towers:
				var tx := 150 + t * (1000 / num_towers) + rng.randi_range(-60, 60)
				var ty := 600
				var num_steps := rng.randi_range(3, 6)
				for s in num_steps:
					var w := rng.randi_range(100, 180) - int(difficulty * 30)
					var offset_x := rng.randi_range(-50, 50)
					platforms.append([clampi(tx + offset_x, 80, 1200), ty, maxi(w, 70), 22])
					coins.append(Vector2(clampi(tx + offset_x, 80, 1200), ty - 38))
					ty -= rng.randi_range(70, 120)
					if ty < 130:
						break
			# Bridges between towers
			for i in rng.randi_range(1, 3):
				var bx := rng.randi_range(200, 1000)
				var by := rng.randi_range(250, 500)
				platforms.append([bx, by, rng.randi_range(150, 300), 22])
		3:
			# SCATTERED -- random walk through the level
			var px := rng.randi_range(100, 400)
			var py := 600
			for i in rng.randi_range(12, 18):
				var w := rng.randi_range(80, 200) - int(difficulty * 40)
				platforms.append([px, py, maxi(w, 65), 22])
				coins.append(Vector2(px, py - 38))
				px += rng.randi_range(-200, 300)
				py -= rng.randi_range(30, 100)
				px = clampi(px, 80, 1200)
				if py < 120:
					py = rng.randi_range(400, 600)
					px = rng.randi_range(100, 1100)
		4:
			# STAIRCASE -- ascending then descending
			var x := 100
			var y := 620
			var ascending := true
			for i in rng.randi_range(10, 16):
				var w := rng.randi_range(90, 170) - int(difficulty * 30)
				platforms.append([x, y, maxi(w, 65), 22])
				coins.append(Vector2(x, y - 38))
				x += rng.randi_range(120, 200)
				if ascending:
					y -= rng.randi_range(40, 80)
				else:
					y += rng.randi_range(40, 80)
				if y < 150:
					ascending = false
				if y > 620:
					ascending = true
				x = clampi(x, 80, 1200)
				y = clampi(y, 130, 640)
		5:
			# ISLANDS -- clusters of platforms grouped together
			var num_islands := rng.randi_range(3, 6)
			for island in num_islands:
				var ix := rng.randi_range(120, 1100)
				var iy := rng.randi_range(180, 580)
				var island_size := rng.randi_range(2, 4)
				for p in island_size:
					var ox := rng.randi_range(-80, 80)
					var oy := rng.randi_range(-50, 50)
					var w := rng.randi_range(80, 160) - int(difficulty * 20)
					var fx := clampi(ix + ox, 80, 1200)
					var fy := clampi(iy + oy, 130, 650)
					platforms.append([fx, fy, maxi(w, 60), 22])
					coins.append(Vector2(fx, fy - 38))

	# Always add a goal platform at the top
	var top_exists := false
	for p in platforms:
		if p[1] < 170:
			top_exists = true
			break
	if not top_exists:
		platforms.append([rng.randi_range(400, 800), rng.randi_range(120, 160), rng.randi_range(150, 250), 22])
		coins.append(Vector2(platforms[-1][0], platforms[-1][1] - 38))

	# ── Enemies ──────────────────────────────────────────────────────────
	var num_enemies := 2 + int(difficulty * 5)
	for i in mini(num_enemies, platforms.size() - 1):
		var idx := rng.randi_range(1, platforms.size() - 1)
		var ep : Array = platforms[idx]
		if ep[2] > 90:
			enemies.append([ep[0], ep[1] - 22, rng.randi_range(30, int(ep[2] * 0.4)), 25 + int(difficulty * 35)])

	# ── Spikes ───────────────────────────────────────────────────────────
	var num_spike_groups := 1 + int(difficulty * 4)
	for i in num_spike_groups:
		if has_full_ground:
			var sx := rng.randi_range(150, 1130)
			if absi(sx - 640) > 100:
				spikes.append([sx, 680, rng.randi_range(2, 4), 20])
		if difficulty > 0.4 and rng.randf() < 0.3:
			var idx := rng.randi_range(1, platforms.size() - 1)
			var sp : Array = platforms[idx]
			spikes.append([sp[0], sp[1] - 12, rng.randi_range(1, 3), 18])

	# ── Saws ─────────────────────────────────────────────────────────────
	var saws : Array = []
	var num_saws := int(difficulty * 3)
	for i in num_saws:
		var sx := rng.randi_range(150, 1130)
		var sy := rng.randi_range(200, 600)
		var axis := "x" if rng.randi() % 2 == 0 else "y"
		saws.append([sx, sy, rng.randi_range(12, 18), axis, rng.randi_range(40, 100), rng.randi_range(35, 75)])

	# ── Shooters ─────────────────────────────────────────────────────────
	var shooters : Array = []
	if difficulty > 0.3:
		var side := rng.randi_range(0, 1)
		if side == 0:
			shooters.append([rng.randi_range(20, 60), rng.randi_range(350, 600), 3.5 - difficulty, rng.randi_range(110, 180), 1])
		else:
			shooters.append([rng.randi_range(1220, 1260), rng.randi_range(350, 600), 3.5 - difficulty, rng.randi_range(110, 180), -1])
	if difficulty > 0.7:
		shooters.append([rng.randi_range(1220, 1260), rng.randi_range(250, 450), 2.5, rng.randi_range(150, 210), -1])

	# ── Moving platforms ─────────────────────────────────────────────────
	var moving : Array = []
	for i in rng.randi_range(1, 2 + int(difficulty * 2)):
		var mx := rng.randi_range(150, 1100)
		var my := rng.randi_range(200, 580)
		var axis := "x" if rng.randi() % 2 == 0 else "y"
		var dist := rng.randi_range(60, 160)
		var spd := rng.randi_range(35, 55 + int(difficulty * 30))
		moving.append([mx, my, rng.randi_range(70, 130), 18, axis, dist, spd])

	# ── Crumble ──────────────────────────────────────────────────────────
	var crumble : Array = []
	if difficulty > 0.15:
		for i in rng.randi_range(1, 2 + int(difficulty * 2)):
			var cx := rng.randi_range(150, 1100)
			var cy := rng.randi_range(250, 550)
			crumble.append([cx, cy, rng.randi_range(70, 110), 18])

	# ── Disappear ────────────────────────────────────────────────────────
	var disappear : Array = []
	if difficulty > 0.25:
		for i in rng.randi_range(1, 2):
			var dx := rng.randi_range(150, 1100)
			var dy := rng.randi_range(220, 480)
			var on_t := 3.0 - difficulty
			var off_t := 0.8 + difficulty * 0.8
			disappear.append([dx, dy, rng.randi_range(80, 110), 18, on_t, off_t, rng.randf()])

	# ── Trampolines ──────────────────────────────────────────────────────
	var trampolines : Array = []
	for i in rng.randi_range(1, 3):
		var tx := rng.randi_range(80, 1200)
		trampolines.append([tx, 678])
	if rng.randf() < 0.4 and platforms.size() > 2:
		var idx := rng.randi_range(1, platforms.size() - 1)
		var tp : Array = platforms[idx]
		trampolines.append([tp[0], tp[1] - 12])

	# ── Checkpoints ──────────────────────────────────────────────────────
	var checkpoints : Array = []
	for i in rng.randi_range(2, 3):
		if platforms.size() > 2:
			var idx := rng.randi_range(1, platforms.size() - 1)
			var cp : Array = platforms[idx]
			checkpoints.append([cp[0], cp[1] - 22])

	# ── Powerups ─────────────────────────────────────────────────────────
	var powerups : Array = []
	for i in rng.randi_range(2, 4):
		if platforms.size() > 2:
			var idx := rng.randi_range(1, platforms.size() - 1)
			var pp : Array = platforms[idx]
			var ptype := "shield" if rng.randi() % 2 == 0 else "speed"
			powerups.append([pp[0], pp[1] - 32, ptype])

	# ── Portals ──────────────────────────────────────────────────────────
	var portals : Array = []
	if platforms.size() > 3:
		var high_idx := 1
		for i in range(1, platforms.size()):
			var p : Array = platforms[i]
			var h : Array = platforms[high_idx]
			if p[1] < h[1]:
				high_idx = i
		var hp : Array = platforms[high_idx]
		portals.append([rng.randi_range(100, 300), 668, hp[0], hp[1] - 30])

	# ── Walls ────────────────────────────────────────────────────────────
	var walls : Array = []
	if rng.randf() < 0.6:
		walls.append([rng.randi_range(30, 60), rng.randi_range(380, 500), 28, rng.randi_range(180, 300)])
	if rng.randf() < 0.6:
		walls.append([rng.randi_range(1220, 1250), rng.randi_range(380, 500), 28, rng.randi_range(180, 300)])

	# ── Background color ─────────────────────────────────────────────────
	var bg_styles : Array = [
		Color(0.07, 0.07, 0.16),   # Deep blue
		Color(0.12, 0.05, 0.08),   # Dark red
		Color(0.04, 0.10, 0.08),   # Dark green
		Color(0.08, 0.04, 0.14),   # Purple
		Color(0.06, 0.08, 0.12),   # Steel blue
		Color(0.10, 0.06, 0.03),   # Brown
	]
	var bg : Color = bg_styles[rng.randi_range(0, bg_styles.size() - 1)]

	var diff_names : Array = ["Easy", "Medium", "Hard", "Extreme"]
	var style_names : Array = ["Zigzag", "Spiral", "Towers", "Scattered", "Staircase", "Islands"]
	var diff_idx := mini(int(difficulty * 3.99), 3)

	return {
		"name": "Lv.%d  %s  %s  #%d" % [num, diff_names[diff_idx], style_names[style], seed_val],
		"bg_color": bg,
		"platforms": platforms,
		"moving": moving,
		"walls": walls,
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
