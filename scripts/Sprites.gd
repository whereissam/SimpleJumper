class_name Sprites
# Centralized sprite paths for Kenney Pixel Platformer tiles.
# Tiles are 18x18, Characters are 24x24. We scale ~3x for 1280x720 viewport.

const SCALE_TILE := Vector2(3, 3)    # 18x18 -> 54x54
const SCALE_CHAR := Vector2(2.5, 2.5) # 24x24 -> 60x60

const BASE := "res://assets/kenney_pixel/Tiles/"
const CHAR := "res://assets/kenney_pixel/Tiles/Characters/"
const BG   := "res://assets/kenney_pixel/Tiles/Backgrounds/"

# -- Player (green character) --
const PLAYER_IDLE_R   := CHAR + "tile_0000.png"
const PLAYER_WALK1_R  := CHAR + "tile_0001.png"
const PLAYER_WALK2_R  := CHAR + "tile_0002.png"
const PLAYER_JUMP_R   := CHAR + "tile_0003.png"
const PLAYER_FALL_R   := CHAR + "tile_0004.png"
const PLAYER_IDLE_L   := CHAR + "tile_0005.png"
const PLAYER_WALK1_L  := CHAR + "tile_0006.png"
const PLAYER_WALK2_L  := CHAR + "tile_0007.png"
const PLAYER_JUMP_L   := CHAR + "tile_0008.png"
const PLAYER_FALL_L   := CHAR + "tile_0009.png"

# -- Enemy (red character) --
const ENEMY_IDLE_R    := CHAR + "tile_0010.png"
const ENEMY_WALK1_R   := CHAR + "tile_0011.png"
const ENEMY_WALK2_R   := CHAR + "tile_0012.png"
const ENEMY_IDLE_L    := CHAR + "tile_0015.png"
const ENEMY_WALK1_L   := CHAR + "tile_0016.png"
const ENEMY_WALK2_L   := CHAR + "tile_0017.png"

# -- Platform tiles --
const GRASS_TOP       := BASE + "tile_0000.png"  # Green grass top
const GRASS_MID       := BASE + "tile_0019.png"  # Green grass full
const GRASS_LEFT      := BASE + "tile_0018.png"  # Grass left edge
const GRASS_RIGHT     := BASE + "tile_0001.png"  # Grass right edge

# -- Items --
const COIN            := BASE + "tile_0151.png"  # Gold coin
const HEART           := BASE + "tile_0067.png"  # Blue heart
const DIAMOND         := BASE + "tile_0144.png"  # Purple heart / gem

# -- Hazards --
const SPIKE_UP        := BASE + "tile_0065.png"  # Red spike pointing up
const SPIKE_RIGHT     := BASE + "tile_0066.png"  # Red spike pointing right
const SAW             := BASE + "tile_0070.png"  # Gray saw blade

# -- World objects --
const CRATE           := BASE + "tile_0048.png"  # Brown crate
const WOOD_PLANK      := BASE + "tile_0049.png"  # Brown plank
const FLAG_POST       := BASE + "tile_0131.png"  # Vertical post
const BRICK           := BASE + "tile_0130.png"  # Red brick

# -- Backgrounds --
const BG_SKY1         := BG + "tile_0000.png"
const BG_SKY2         := BG + "tile_0001.png"
const BG_SKY_CLOUD    := BG + "tile_0008.png"
const BG_SKY_MOUNT    := BG + "tile_0011.png"
const BG_SAND1        := BG + "tile_0004.png"
const BG_SAND2        := BG + "tile_0005.png"
const BG_GREEN1       := BG + "tile_0006.png"
const BG_GREEN2       := BG + "tile_0007.png"

# -- Helper: create a Sprite2D from a tile path with proper scaling --
static func make_sprite(path: String, scl: Vector2 = SCALE_TILE) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(path)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # Pixel art crisp
	s.scale = scl
	return s

# -- Helper: create AnimatedSprite2D for player --
static func make_player_animated() -> AnimatedSprite2D:
	var anim := AnimatedSprite2D.new()
	anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frames := SpriteFrames.new()

	# Idle
	frames.add_animation("idle_right")
	frames.set_animation_speed("idle_right", 4)
	frames.set_animation_loop("idle_right", true)
	frames.add_frame("idle_right", load(PLAYER_IDLE_R))
	frames.add_frame("idle_right", load(PLAYER_WALK1_R))

	frames.add_animation("idle_left")
	frames.set_animation_speed("idle_left", 4)
	frames.set_animation_loop("idle_left", true)
	frames.add_frame("idle_left", load(PLAYER_IDLE_L))
	frames.add_frame("idle_left", load(PLAYER_WALK1_L))

	# Run
	frames.add_animation("run_right")
	frames.set_animation_speed("run_right", 8)
	frames.set_animation_loop("run_right", true)
	frames.add_frame("run_right", load(PLAYER_IDLE_R))
	frames.add_frame("run_right", load(PLAYER_WALK1_R))
	frames.add_frame("run_right", load(PLAYER_WALK2_R))

	frames.add_animation("run_left")
	frames.set_animation_speed("run_left", 8)
	frames.set_animation_loop("run_left", true)
	frames.add_frame("run_left", load(PLAYER_IDLE_L))
	frames.add_frame("run_left", load(PLAYER_WALK1_L))
	frames.add_frame("run_left", load(PLAYER_WALK2_L))

	# Jump
	frames.add_animation("jump_right")
	frames.set_animation_speed("jump_right", 1)
	frames.set_animation_loop("jump_right", false)
	frames.add_frame("jump_right", load(PLAYER_JUMP_R))

	frames.add_animation("jump_left")
	frames.set_animation_speed("jump_left", 1)
	frames.set_animation_loop("jump_left", false)
	frames.add_frame("jump_left", load(PLAYER_JUMP_L))

	# Fall
	frames.add_animation("fall_right")
	frames.set_animation_speed("fall_right", 1)
	frames.set_animation_loop("fall_right", false)
	frames.add_frame("fall_right", load(PLAYER_FALL_R))

	frames.add_animation("fall_left")
	frames.set_animation_speed("fall_left", 1)
	frames.set_animation_loop("fall_left", false)
	frames.add_frame("fall_left", load(PLAYER_FALL_L))

	# Wall slide (uses jump frame -- sprite will be rotated in Player.gd)
	frames.add_animation("wall_right")
	frames.set_animation_speed("wall_right", 1)
	frames.set_animation_loop("wall_right", false)
	frames.add_frame("wall_right", load(PLAYER_FALL_R))

	frames.add_animation("wall_left")
	frames.set_animation_speed("wall_left", 1)
	frames.set_animation_loop("wall_left", false)
	frames.add_frame("wall_left", load(PLAYER_FALL_L))

	# Remove the default animation that SpriteFrames creates
	if frames.has_animation("default"):
		frames.remove_animation("default")

	anim.sprite_frames = frames
	anim.scale = SCALE_CHAR
	anim.play("idle_right")
	return anim

# -- Helper: create AnimatedSprite2D for enemy --
static func make_enemy_animated() -> AnimatedSprite2D:
	var anim := AnimatedSprite2D.new()
	anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frames := SpriteFrames.new()

	frames.add_animation("walk_right")
	frames.set_animation_speed("walk_right", 5)
	frames.set_animation_loop("walk_right", true)
	frames.add_frame("walk_right", load(ENEMY_IDLE_R))
	frames.add_frame("walk_right", load(ENEMY_WALK1_R))
	frames.add_frame("walk_right", load(ENEMY_WALK2_R))

	frames.add_animation("walk_left")
	frames.set_animation_speed("walk_left", 5)
	frames.set_animation_loop("walk_left", true)
	frames.add_frame("walk_left", load(ENEMY_IDLE_L))
	frames.add_frame("walk_left", load(ENEMY_WALK1_L))
	frames.add_frame("walk_left", load(ENEMY_WALK2_L))

	if frames.has_animation("default"):
		frames.remove_animation("default")

	anim.sprite_frames = frames
	anim.scale = SCALE_CHAR
	anim.play("walk_right")
	return anim

# -- Helper: tile a platform with grass sprites --
static func make_platform_visual(width: float, height: float) -> Node2D:
	var container := Node2D.new()
	var tile_size := 18.0 * SCALE_TILE.x  # 54px per tile after scaling
	var num_tiles := maxi(int(width / tile_size), 1)

	for i in num_tiles:
		var tile := Sprite2D.new()
		tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		# Left edge, middle, or right edge
		if num_tiles == 1:
			tile.texture = load(GRASS_TOP)
		elif i == 0:
			tile.texture = load(GRASS_LEFT)
		elif i == num_tiles - 1:
			tile.texture = load(GRASS_RIGHT)
		else:
			tile.texture = load(GRASS_TOP)
		tile.scale = SCALE_TILE
		tile.position = Vector2(
			-width * 0.5 + tile_size * 0.5 + i * tile_size,
			0
		)
		container.add_child(tile)

	return container

# -- Helper: spinning coin sprite --
static func make_coin_sprite() -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(COIN)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = SCALE_TILE
	return s

# -- Helper: spike sprite --
static func make_spike_sprite() -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(SPIKE_UP)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = SCALE_TILE
	return s

# -- Helper: saw blade sprite --
static func make_saw_sprite() -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(SAW)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = SCALE_TILE
	return s
