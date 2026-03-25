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

	# Steeper difficulty curve: Lv1=0.0, Lv3=0.3, Lv5=0.55, Lv8=0.85, Lv11=1.0
	var difficulty : float = clampf((num - 1) * 0.15, 0.0, 1.0)

	var platforms : Array = []
	var coins : Array = []
	var enemies : Array = []
	var spikes : Array = []
	var walls : Array = []

	# Pick a random layout style (9 styles total)
	var style := rng.randi_range(0, 8)

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
			# SPIRAL -- platforms wind outward from center
			var cx := 640.0
			var cy := 420.0
			var radius := 150.0
			var angle := rng.randf_range(0, TAU)
			for i in rng.randi_range(8, 13):
				var px := int(cx + cos(angle) * radius)
				var py := int(cy + sin(angle) * radius * 0.5)
				px = clampi(px, 100, 1180)
				py = clampi(py, 130, 650)
				var w := rng.randi_range(100, 190) - int(difficulty * 30)
				platforms.append([px, py, maxi(w, 80), 22])
				coins.append(Vector2(px, py - 38))
				angle += rng.randf_range(0.8, 1.4)
				radius += rng.randf_range(30, 60)
		2:
			# TOWERS -- 3-4 columns connected by bridges
			var num_towers := rng.randi_range(3, 4)
			var tower_xs : Array = []
			for t in num_towers:
				var tx := 100 + t * (1080 / (num_towers + 1)) + rng.randi_range(-30, 30)
				tower_xs.append(tx)
				var ty := 580
				var num_steps := rng.randi_range(3, 5)
				for s in num_steps:
					var w := rng.randi_range(120, 200) - int(difficulty * 30)
					var offset_x := rng.randi_range(-30, 30)
					var px := clampi(tx + offset_x, 80, 1200)
					platforms.append([px, ty, maxi(w, 90), 22])
					coins.append(Vector2(px, ty - 38))
					ty -= rng.randi_range(90, 130)
					if ty < 150:
						break
			# Bridges between adjacent towers at various heights
			for t in range(0, num_towers - 1):
				var num_bridges := rng.randi_range(1, 2)
				for b in num_bridges:
					var bx : int = (int(tower_xs[t]) + int(tower_xs[t + 1])) / 2 + rng.randi_range(-40, 40)
					var by := rng.randi_range(250, 550)
					platforms.append([bx, by, rng.randi_range(140, 240), 22])
					coins.append(Vector2(bx, by - 38))
		3:
			# SCATTERED -- random walk through the level
			var px := rng.randi_range(100, 400)
			var py := 580
			for i in rng.randi_range(10, 15):
				var w := rng.randi_range(100, 210) - int(difficulty * 40)
				platforms.append([px, py, maxi(w, 80), 22])
				coins.append(Vector2(px, py - 38))
				px += rng.randi_range(-180, 250)
				py -= rng.randi_range(60, 110)
				px = clampi(px, 80, 1200)
				if py < 150:
					py = rng.randi_range(400, 560)
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
			# ISLANDS -- clusters of platforms at different heights
			var num_islands := rng.randi_range(3, 5)
			for island in num_islands:
				var ix := 150 + island * (960 / num_islands) + rng.randi_range(-40, 40)
				var iy := rng.randi_range(200, 560)
				var island_size := rng.randi_range(2, 3)
				for p in island_size:
					# Spread platforms horizontally and step up vertically
					var ox := (p - island_size / 2) * rng.randi_range(100, 160)
					var oy := -p * rng.randi_range(50, 80)
					var w := rng.randi_range(100, 170) - int(difficulty * 20)
					var fx := clampi(ix + ox, 80, 1200)
					var fy := clampi(iy + oy, 130, 650)
					platforms.append([fx, fy, maxi(w, 80), 22])
					coins.append(Vector2(fx, fy - 38))

		6:
			# VERTICAL CLIMB -- zigzag upward, goal is at the very top
			var x := rng.randi_range(200, 1000)
			var y := 600
			var go_left := rng.randi() % 2 == 0
			for i in rng.randi_range(12, 20):
				var w := rng.randi_range(80, 180) - int(difficulty * 40)
				platforms.append([x, y, maxi(w, 70), 22])
				coins.append(Vector2(x, y - 38))
				y -= rng.randi_range(65, 100)
				if go_left:
					x -= rng.randi_range(80, 200)
				else:
					x += rng.randi_range(80, 200)
				x = clampi(x, 100, 1180)
				if x < 200:
					go_left = false
				elif x > 1000:
					go_left = true
				if y < -400:
					break

		7:
			# MAZE -- walled corridors with platforms at corridor intersections
			var corridor_y : Array[int] = [250, 400, 550]
			var corridor_x : Array[int] = [200, 500, 800, 1100]
			# Horizontal corridors (platforms)
			for cy in corridor_y:
				for i in range(0, corridor_x.size() - 1):
					if rng.randf() < 0.7:
						var cx : int = (corridor_x[i] + corridor_x[i + 1]) / 2
						var w := rng.randi_range(120, 200) - int(difficulty * 30)
						platforms.append([cx, cy, maxi(w, 80), 22])
						coins.append(Vector2(cx, cy - 38))
			# Vertical walls between corridors
			for cx in corridor_x:
				for i in range(0, corridor_y.size() - 1):
					if rng.randf() < 0.5:
						var wy : int = (corridor_y[i] + corridor_y[i + 1]) / 2
						walls.append([cx, wy, 24, rng.randi_range(80, 140)])
			# Extra platforms at intersections
			for cx in corridor_x:
				for cy in corridor_y:
					if rng.randf() < 0.6:
						platforms.append([cx, cy, rng.randi_range(60, 100), 22])
						if rng.randf() < 0.5:
							coins.append(Vector2(cx, cy - 38))

		8:
			# FLOATING ISLANDS -- large gaps, requires dash/double jump
			var num_islands := rng.randi_range(4, 6)
			for island in num_islands:
				var ix := 120 + island * (1040 / num_islands) + rng.randi_range(-40, 40)
				var iy := rng.randi_range(200, 580)
				# Main island platform
				var main_w := rng.randi_range(80, 140) - int(difficulty * 20)
				platforms.append([ix, iy, maxi(main_w, 60), 22])
				coins.append(Vector2(ix, iy - 38))
				# Small satellite platforms (1-2)
				for s in rng.randi_range(1, 2):
					var sx := ix + rng.randi_range(-120, 120)
					var sy := iy - rng.randi_range(60, 120)
					sx = clampi(sx, 80, 1200)
					sy = clampi(sy, 130, 650)
					var sw := rng.randi_range(40, 70) - int(difficulty * 10)
					platforms.append([sx, sy, maxi(sw, 35), 22])
					coins.append(Vector2(sx, sy - 38))

	# -- Step 1: Remove overlapping platforms --
	# Two platforms overlap if they're within 30px vertically and horizontally overlapping
	var clean : Array = [platforms[0]]  # Always keep ground
	for i in range(1, platforms.size()):
		var p : Array = platforms[i]
		var overlaps := false
		for j in range(0, clean.size()):
			var q : Array = clean[j]
			var dx : int = absi(int(p[0]) - int(q[0]))
			var dy : int = absi(int(p[1]) - int(q[1]))
			# Too close = overlap (need at least 55px vertical gap)
			if dx < (int(p[2]) + int(q[2])) / 2 + 10 and dy < 55:
				overlaps = true
				break
		if not overlaps:
			clean.append(p)
	platforms = clean

	# -- Step 2: Rebuild coins to match cleaned platforms --
	coins.clear()
	for i in range(1, platforms.size()):
		var p : Array = platforms[i]
		coins.append(Vector2(int(p[0]), int(p[1]) - 38))

	# -- Step 3: Add a top platform if none exists --
	var highest_y := 999
	var highest_x := 640
	for p in platforms:
		if int(p[1]) < highest_y and int(p[1]) < 680:
			highest_y = int(p[1])
			highest_x = int(p[0])
	if highest_y > 200:
		var top_x := clampi(highest_x + rng.randi_range(-100, 100), 200, 1080)
		var top_y := clampi(highest_y - rng.randi_range(70, 100), 130, 200)
		platforms.append([top_x, top_y, rng.randi_range(150, 250), 22])
		coins.append(Vector2(top_x, top_y - 38))

	# ── Enemies ──────────────────────────────────────────────────────────
	var num_enemies := 3 + int(difficulty * 8)
	for i in mini(num_enemies, platforms.size() - 1):
		var idx := rng.randi_range(1, platforms.size() - 1)
		var ep : Array = platforms[idx]
		if ep[2] > 80:
			enemies.append([ep[0], ep[1] - 22, rng.randi_range(25, int(ep[2] * 0.4)), 30 + int(difficulty * 50)])

	# ── Spikes ───────────────────────────────────────────────────────────
	var num_spike_groups := 2 + int(difficulty * 6)
	for i in num_spike_groups:
		if has_full_ground:
			var sx := rng.randi_range(150, 1130)
			if absi(sx - 640) > 100:
				spikes.append([sx, 680, rng.randi_range(2, 4), 20])
		if difficulty > 0.4 and rng.randf() < 0.3:
			var idx := rng.randi_range(1, platforms.size() - 1)
			var sp : Array = platforms[idx]
			spikes.append([sp[0], sp[1] - 12, rng.randi_range(1, 3), 18])

	# ── Saws [x, y, radius, pattern, dist, speed] ───────────────────────
	var saws : Array = []
	var num_saws := int(difficulty * 5)
	var patterns := ["x", "y", "circle", "figure8"]
	for i in num_saws:
		var sx := rng.randi_range(150, 1130)
		var sy := rng.randi_range(200, 600)
		var pattern : String = patterns[rng.randi_range(0, patterns.size() - 1)]
		saws.append([sx, sy, rng.randi_range(12, 18), pattern, rng.randi_range(40, 100), rng.randi_range(35, 75)])

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

	# ── Ice platforms [x, y, width, height] ──────────────────────────────
	var ice : Array = []
	if difficulty > 0.2:
		for i in rng.randi_range(1, 2 + int(difficulty * 2)):
			var ix := rng.randi_range(150, 1100)
			var iy := rng.randi_range(250, 580)
			ice.append([ix, iy, rng.randi_range(100, 180), 18])

	# ── Conveyor belts [x, y, width, height, direction] ──────────────────
	var conveyors : Array = []
	if difficulty > 0.3:
		for i in rng.randi_range(1, 2 + int(difficulty)):
			var cx := rng.randi_range(200, 1000)
			var cy := rng.randi_range(300, 600)
			var cdir := 1 if rng.randi() % 2 == 0 else -1
			conveyors.append([cx, cy, rng.randi_range(120, 220), 18, cdir])

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
	var style_names : Array = ["Zigzag", "Spiral", "Towers", "Scattered", "Staircase", "Islands", "Climb", "Maze", "Sky Islands"]
	var diff_idx := mini(int(difficulty * 3.99), 3)

	# ── Jumping enemies [x, y, jump_interval, jump_force, patrol_range, speed] ──
	var jumpers : Array = []
	if difficulty > 0.2:
		var num_jumpers := rng.randi_range(1, 2 + int(difficulty * 3))
		for i in num_jumpers:
			if platforms.size() > 2:
				var idx := rng.randi_range(1, platforms.size() - 1)
				var jp : Array = platforms[idx]
				if int(jp[2]) > 80:
					jumpers.append([jp[0], jp[1] - 22, rng.randf_range(1.2, 2.5), rng.randi_range(250, 400), rng.randi_range(30, 60), 35 + int(difficulty * 30)])

	# ── Wind zones [x, y, width, height, direction, strength] ────────────
	var wind_zones : Array = []
	if difficulty > 0.3:
		for i in rng.randi_range(1, 2 + int(difficulty)):
			var wx := rng.randi_range(200, 1000)
			var wy := rng.randi_range(200, 550)
			var wdir := 1 if rng.randi() % 2 == 0 else -1
			wind_zones.append([wx, wy, rng.randi_range(150, 300), rng.randi_range(100, 200), wdir, rng.randi_range(80, 180)])

	# ── Keys & locked exit (on medium+ difficulty) ───────────────────────
	var keys : Array = []
	var require_keys := 0
	if difficulty > 0.25:
		require_keys = rng.randi_range(1, 1 + int(difficulty * 2))
		for i in require_keys:
			if platforms.size() > 3:
				var idx := rng.randi_range(1, platforms.size() - 1)
				var kp : Array = platforms[idx]
				keys.append([kp[0] + rng.randi_range(-30, 30), kp[1] - 35])

	# ── Boss (on hard+ difficulty, replaces some enemies) ────────────────
	var boss : Array = []  # [x, y, hp, speed, fire_interval]
	if difficulty > 0.6:
		var boss_hp := 3 + int(difficulty * 4)
		var boss_x := rng.randi_range(400, 900)
		boss = [boss_x, 650, boss_hp, 40 + int(difficulty * 30), 1.5 - difficulty * 0.5]

	# ── Flying enemies [x, y, patrol_range, speed, wave_amp, wave_speed] ─
	var flyers : Array = []
	if difficulty > 0.4:
		var num_flyers := rng.randi_range(1, 1 + int(difficulty * 2))
		for i in num_flyers:
			var fx := rng.randi_range(200, 1080)
			var fy := rng.randi_range(180, 400)
			flyers.append([fx, fy, rng.randi_range(60, 150), 30 + int(difficulty * 40), rng.randi_range(30, 60), rng.randf_range(1.5, 3.0)])

	# ── Shielded enemies [x, y, patrol_range, speed, shield_hp] ──────────
	var shielded : Array = []
	if difficulty > 0.5:
		var num_shielded := rng.randi_range(1, 1 + int(difficulty))
		for i in num_shielded:
			if platforms.size() > 2:
				var idx := rng.randi_range(1, platforms.size() - 1)
				var sp : Array = platforms[idx]
				if int(sp[2]) > 80:
					shielded.append([sp[0], sp[1] - 22, rng.randi_range(30, int(sp[2] * 0.4)), 25 + int(difficulty * 35), 2])

	# ── Enemy spawners [x, y, interval, patrol_range, patrol_speed] ──────
	var spawners : Array = []
	if difficulty > 0.55:
		var num_spawners := rng.randi_range(1, 1 + int(difficulty))
		for i in num_spawners:
			if platforms.size() > 3:
				var idx := rng.randi_range(1, platforms.size() - 1)
				var sp : Array = platforms[idx]
				spawners.append([sp[0], sp[1] - 22, 4.0 - difficulty * 1.5, rng.randi_range(30, 60), 30 + int(difficulty * 30)])

	# ── Safe zones: remove hazards near portals and spawn point ──────────
	var safe_points : Array = [Vector2(640, 630)]  # Player spawn
	for pd in portals:
		safe_points.append(Vector2(pd[0], pd[1]))  # Portal entrance
		safe_points.append(Vector2(pd[2], pd[3]))  # Portal exit
	for chk in checkpoints:
		safe_points.append(Vector2(chk[0], chk[1]))

	const SAFE_RADIUS := 80
	# Filter enemies away from safe zones
	var safe_enemies : Array = []
	for e in enemies:
		var enemy_pos := Vector2(e[0], e[1])
		var too_close := false
		for sp in safe_points:
			if enemy_pos.distance_to(sp) < SAFE_RADIUS:
				too_close = true
				break
		if not too_close:
			safe_enemies.append(e)
	enemies = safe_enemies

	# Filter spikes away from safe zones
	var safe_spikes : Array = []
	for s in spikes:
		var spike_pos := Vector2(s[0], s[1])
		var too_close := false
		for sp in safe_points:
			if spike_pos.distance_to(sp) < SAFE_RADIUS:
				too_close = true
				break
		if not too_close:
			safe_spikes.append(s)
	spikes = safe_spikes

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
		"ice": ice,
		"conveyors": conveyors,
		"jumpers": jumpers,
		"wind_zones": wind_zones,
		"keys": keys,
		"require_keys": require_keys,
		"boss": boss,
		"flyers": flyers,
		"shielded": shielded,
		"spawners": spawners,
		"bonus_room": _generate_bonus_room(rng, difficulty, platforms),
	}

static func _generate_bonus_room(rng: RandomNumberGenerator, difficulty: float, platforms: Array) -> Dictionary:
	## 30% chance on medium+ difficulty. Returns empty dict if no bonus room.
	if difficulty < 0.25 or rng.randf() > 0.3 or platforms.size() < 4:
		return {}
	# Pick a random platform for the hidden entrance
	var idx := rng.randi_range(1, platforms.size() - 1)
	var ep : Array = platforms[idx]
	# Bonus room is off-screen above, with a platform and coins
	var room_x := rng.randi_range(300, 980)
	var room_y := -200
	var num_coins := 5 + int(difficulty * 8)
	return {
		"entrance_x": ep[0] + rng.randi_range(-20, 20),
		"entrance_y": ep[1] - 25,
		"room_x": room_x,
		"room_y": room_y,
		"num_coins": num_coins,
	}
