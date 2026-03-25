class_name Sprites
# Centralized sprite textures for Kenney Pixel Platformer tiles.
# Tiles are 18x18, Characters are 24x24. We scale ~3x for 1280x720 viewport.

const SCALE_TILE := Vector2(3, 3)    # 18x18 -> 54x54
const SCALE_CHAR := Vector2(2.5, 2.5) # 24x24 -> 60x60

# -- Player (green character) --
const PLAYER_IDLE_R   := preload("res://assets/kenney_pixel/Tiles/Characters/tile_0000.png")
const PLAYER_WALK1_R  := preload("res://assets/kenney_pixel/Tiles/Characters/tile_0001.png")
const PLAYER_WALK2_R  := preload("res://assets/kenney_pixel/Tiles/Characters/tile_0002.png")
const PLAYER_JUMP_R   := preload("res://assets/kenney_pixel/Tiles/Characters/tile_0003.png")
const PLAYER_FALL_R   := preload("res://assets/kenney_pixel/Tiles/Characters/tile_0004.png")
const PLAYER_IDLE_L   := preload("res://assets/kenney_pixel/Tiles/Characters/tile_0005.png")
const PLAYER_WALK1_L  := preload("res://assets/kenney_pixel/Tiles/Characters/tile_0006.png")
const PLAYER_WALK2_L  := preload("res://assets/kenney_pixel/Tiles/Characters/tile_0007.png")
const PLAYER_JUMP_L   := preload("res://assets/kenney_pixel/Tiles/Characters/tile_0008.png")
const PLAYER_FALL_L   := preload("res://assets/kenney_pixel/Tiles/Characters/tile_0009.png")

# -- Enemy (red character) --
const ENEMY_IDLE_R    := preload("res://assets/kenney_pixel/Tiles/Characters/tile_0010.png")
const ENEMY_WALK1_R   := preload("res://assets/kenney_pixel/Tiles/Characters/tile_0011.png")
const ENEMY_WALK2_R   := preload("res://assets/kenney_pixel/Tiles/Characters/tile_0012.png")
const ENEMY_IDLE_L    := preload("res://assets/kenney_pixel/Tiles/Characters/tile_0015.png")
const ENEMY_WALK1_L   := preload("res://assets/kenney_pixel/Tiles/Characters/tile_0016.png")
const ENEMY_WALK2_L   := preload("res://assets/kenney_pixel/Tiles/Characters/tile_0017.png")

# -- Jumping enemy (yellow character) --
const JUMPER_WALK1_R  := preload("res://assets/kenney_pixel/Tiles/Characters/tile_0020.png")
const JUMPER_WALK2_R  := preload("res://assets/kenney_pixel/Tiles/Characters/tile_0021.png")
const JUMPER_WALK3_R  := preload("res://assets/kenney_pixel/Tiles/Characters/tile_0022.png")
const JUMPER_WALK1_L  := preload("res://assets/kenney_pixel/Tiles/Characters/tile_0025.png")
const JUMPER_WALK2_L  := preload("res://assets/kenney_pixel/Tiles/Characters/tile_0026.png")

# -- Platform tiles --
const GRASS_TOP       := preload("res://assets/kenney_pixel/Tiles/tile_0000.png")
const GRASS_MID       := preload("res://assets/kenney_pixel/Tiles/tile_0019.png")
const GRASS_LEFT      := preload("res://assets/kenney_pixel/Tiles/tile_0018.png")
const GRASS_RIGHT     := preload("res://assets/kenney_pixel/Tiles/tile_0001.png")

# -- Items --
const COIN            := preload("res://assets/kenney_pixel/Tiles/tile_0151.png")
const HEART           := preload("res://assets/kenney_pixel/Tiles/tile_0067.png")
const DIAMOND         := preload("res://assets/kenney_pixel/Tiles/tile_0144.png")

# -- Hazards --
const SPIKE_UP        := preload("res://assets/kenney_pixel/Tiles/tile_0065.png")
const SPIKE_RIGHT     := preload("res://assets/kenney_pixel/Tiles/tile_0066.png")
const SAW             := preload("res://assets/kenney_pixel/Tiles/tile_0070.png")

# -- World objects --
const CRATE           := preload("res://assets/kenney_pixel/Tiles/tile_0048.png")
const WOOD_PLANK      := preload("res://assets/kenney_pixel/Tiles/tile_0049.png")
const FLAG_POST       := preload("res://assets/kenney_pixel/Tiles/tile_0131.png")
const BRICK           := preload("res://assets/kenney_pixel/Tiles/tile_0130.png")

# -- Backgrounds --
const BG_SKY1         := preload("res://assets/kenney_pixel/Tiles/Backgrounds/tile_0000.png")
const BG_SKY2         := preload("res://assets/kenney_pixel/Tiles/Backgrounds/tile_0001.png")
const BG_SKY_CLOUD    := preload("res://assets/kenney_pixel/Tiles/Backgrounds/tile_0008.png")
const BG_SKY_MOUNT    := preload("res://assets/kenney_pixel/Tiles/Backgrounds/tile_0011.png")
const BG_SAND1        := preload("res://assets/kenney_pixel/Tiles/Backgrounds/tile_0004.png")
const BG_SAND2        := preload("res://assets/kenney_pixel/Tiles/Backgrounds/tile_0005.png")
const BG_GREEN1       := preload("res://assets/kenney_pixel/Tiles/Backgrounds/tile_0006.png")
const BG_GREEN2       := preload("res://assets/kenney_pixel/Tiles/Backgrounds/tile_0007.png")

# -- Saw buzz sound --
const SAW_BUZZ        := preload("res://assets/audio/impact/impactMetal_light_001.ogg")

# -- Helper: create a Sprite2D from a texture with proper scaling --
static func make_sprite(tex: Texture2D, scl: Vector2 = SCALE_TILE) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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
	frames.add_frame("idle_right", PLAYER_IDLE_R)
	frames.add_frame("idle_right", PLAYER_WALK1_R)

	frames.add_animation("idle_left")
	frames.set_animation_speed("idle_left", 4)
	frames.set_animation_loop("idle_left", true)
	frames.add_frame("idle_left", PLAYER_IDLE_L)
	frames.add_frame("idle_left", PLAYER_WALK1_L)

	# Run
	frames.add_animation("run_right")
	frames.set_animation_speed("run_right", 8)
	frames.set_animation_loop("run_right", true)
	frames.add_frame("run_right", PLAYER_IDLE_R)
	frames.add_frame("run_right", PLAYER_WALK1_R)
	frames.add_frame("run_right", PLAYER_WALK2_R)

	frames.add_animation("run_left")
	frames.set_animation_speed("run_left", 8)
	frames.set_animation_loop("run_left", true)
	frames.add_frame("run_left", PLAYER_IDLE_L)
	frames.add_frame("run_left", PLAYER_WALK1_L)
	frames.add_frame("run_left", PLAYER_WALK2_L)

	# Jump
	frames.add_animation("jump_right")
	frames.set_animation_speed("jump_right", 1)
	frames.set_animation_loop("jump_right", false)
	frames.add_frame("jump_right", PLAYER_JUMP_R)

	frames.add_animation("jump_left")
	frames.set_animation_speed("jump_left", 1)
	frames.set_animation_loop("jump_left", false)
	frames.add_frame("jump_left", PLAYER_JUMP_L)

	# Fall
	frames.add_animation("fall_right")
	frames.set_animation_speed("fall_right", 1)
	frames.set_animation_loop("fall_right", false)
	frames.add_frame("fall_right", PLAYER_FALL_R)

	frames.add_animation("fall_left")
	frames.set_animation_speed("fall_left", 1)
	frames.set_animation_loop("fall_left", false)
	frames.add_frame("fall_left", PLAYER_FALL_L)

	# Wall slide (uses fall frame -- sprite will be rotated in Player.gd)
	frames.add_animation("wall_right")
	frames.set_animation_speed("wall_right", 1)
	frames.set_animation_loop("wall_right", false)
	frames.add_frame("wall_right", PLAYER_FALL_R)

	frames.add_animation("wall_left")
	frames.set_animation_speed("wall_left", 1)
	frames.set_animation_loop("wall_left", false)
	frames.add_frame("wall_left", PLAYER_FALL_L)

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
	frames.add_frame("walk_right", ENEMY_IDLE_R)
	frames.add_frame("walk_right", ENEMY_WALK1_R)
	frames.add_frame("walk_right", ENEMY_WALK2_R)

	frames.add_animation("walk_left")
	frames.set_animation_speed("walk_left", 5)
	frames.set_animation_loop("walk_left", true)
	frames.add_frame("walk_left", ENEMY_IDLE_L)
	frames.add_frame("walk_left", ENEMY_WALK1_L)
	frames.add_frame("walk_left", ENEMY_WALK2_L)

	if frames.has_animation("default"):
		frames.remove_animation("default")

	anim.sprite_frames = frames
	anim.scale = SCALE_CHAR
	anim.play("walk_right")
	return anim

# -- Helper: create AnimatedSprite2D for jumping enemy --
static func make_jumper_animated() -> AnimatedSprite2D:
	var anim := AnimatedSprite2D.new()
	anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frames := SpriteFrames.new()

	frames.add_animation("walk_right")
	frames.set_animation_speed("walk_right", 6)
	frames.set_animation_loop("walk_right", true)
	frames.add_frame("walk_right", JUMPER_WALK1_R)
	frames.add_frame("walk_right", JUMPER_WALK2_R)
	frames.add_frame("walk_right", JUMPER_WALK3_R)

	frames.add_animation("walk_left")
	frames.set_animation_speed("walk_left", 6)
	frames.set_animation_loop("walk_left", true)
	frames.add_frame("walk_left", JUMPER_WALK1_L)
	frames.add_frame("walk_left", JUMPER_WALK2_L)

	if frames.has_animation("default"):
		frames.remove_animation("default")

	anim.sprite_frames = frames
	anim.scale = SCALE_CHAR
	anim.play("walk_right")
	return anim

# -- Helper: create boss AnimatedSprite2D (scaled up enemy) --
static func make_boss_animated() -> AnimatedSprite2D:
	var anim := AnimatedSprite2D.new()
	anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frames := SpriteFrames.new()

	frames.add_animation("walk_right")
	frames.set_animation_speed("walk_right", 4)
	frames.set_animation_loop("walk_right", true)
	frames.add_frame("walk_right", ENEMY_IDLE_R)
	frames.add_frame("walk_right", ENEMY_WALK1_R)
	frames.add_frame("walk_right", ENEMY_WALK2_R)

	frames.add_animation("walk_left")
	frames.set_animation_speed("walk_left", 4)
	frames.set_animation_loop("walk_left", true)
	frames.add_frame("walk_left", ENEMY_IDLE_L)
	frames.add_frame("walk_left", ENEMY_WALK1_L)
	frames.add_frame("walk_left", ENEMY_WALK2_L)

	if frames.has_animation("default"):
		frames.remove_animation("default")

	anim.sprite_frames = frames
	anim.scale = Vector2(4.0, 4.0)  # 2x bigger than normal enemies
	anim.play("walk_right")
	return anim

# -- Helper: tile a platform with sprites --
static func tile_sprites(parent: Node2D, width: float, height: float, tex: Texture2D, tint: Color = Color.WHITE) -> void:
	var sprite_scale := height / 18.0
	var tile_w := 18.0 * sprite_scale
	var num_tiles := maxi(int(width / tile_w), 1)
	for i in num_tiles:
		var s := Sprite2D.new()
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		# Use edge tiles for grass
		if tex == GRASS_TOP or tex == GRASS_LEFT or tex == GRASS_RIGHT:
			if num_tiles == 1:
				s.texture = GRASS_TOP
			elif i == 0:
				s.texture = GRASS_LEFT
			elif i == num_tiles - 1:
				s.texture = GRASS_RIGHT
			else:
				s.texture = GRASS_TOP
		else:
			s.texture = tex
		s.scale = Vector2(sprite_scale, sprite_scale)
		if tint != Color.WHITE:
			s.modulate = tint
		s.position = Vector2(
			-width * 0.5 + tile_w * 0.5 + i * tile_w,
			0
		)
		parent.add_child(s)

# -- Helper: spinning coin sprite --
static func make_coin_sprite() -> Sprite2D:
	return make_sprite(COIN)

# -- Helper: spike sprite --
static func make_spike_sprite() -> Sprite2D:
	return make_sprite(SPIKE_UP)

# -- Helper: saw blade sprite --
static func make_saw_sprite() -> Sprite2D:
	return make_sprite(SAW)
