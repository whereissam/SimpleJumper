extends Node2D
## Title screen with Play, Level Select, and Quit buttons.

const Colors = preload("res://scripts/Colors.gd")

const VIEWPORT_WIDTH  := 1280
const VIEWPORT_HEIGHT := 720

var _buttons: Array[Dictionary] = []
var _selected: int = 0

func _ready() -> void:
	_build_background()
	_build_title()
	_build_menu()
	_build_footer()
	Audio.start_music()

func _build_background() -> void:
	var cl := CanvasLayer.new()
	cl.layer = -10
	add_child(cl)

	var bg := ColorRect.new()
	bg.color = Colors.BG_COLOR
	bg.size = Vector2(VIEWPORT_WIDTH + 200, VIEWPORT_HEIGHT + 200)
	bg.position = Vector2(-100, -100)
	cl.add_child(bg)

	# Decorative stars
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for _i in 80:
		var star := ColorRect.new()
		star.size = Vector2(2, 2)
		star.color = Color(1, 1, 1, rng.randf_range(0.1, 0.6))
		star.position = Vector2(rng.randf_range(0, VIEWPORT_WIDTH), rng.randf_range(0, VIEWPORT_HEIGHT))
		cl.add_child(star)

func _build_title() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 1
	add_child(cl)

	var title := Label.new()
	title.text = "SIMPLE JUMPER"
	title.position = Vector2(340, 120)
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(1.0, 0.95, 0.55))
	cl.add_child(title)

	# Subtitle
	var sub := Label.new()
	sub.text = "A procedural platformer"
	sub.position = Vector2(460, 205)
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", Color(0.6, 0.65, 0.8))
	cl.add_child(sub)

	# Animated player sprite
	var player_sprite := Sprites.make_player_animated()
	player_sprite.scale = Vector2(4, 4)
	player_sprite.position = Vector2(640, 370)
	player_sprite.play("run_right")
	add_child(player_sprite)

	# Bounce the sprite
	var tw := create_tween().set_loops()
	tw.tween_property(player_sprite, "position:y", 355.0, 0.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(player_sprite, "position:y", 370.0, 0.4).set_trans(Tween.TRANS_SINE)

func _build_menu() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 2
	cl.name = "MenuLayer"
	add_child(cl)

	var menu_items := ["PLAY", "DAILY CHALLENGE", "ENDLESS", "SHOP", "LEVEL SELECT", "QUIT"]
	var start_y := 440

	for i in menu_items.size():
		var btn_bg := ColorRect.new()
		btn_bg.name = "BtnBg%d" % i
		btn_bg.size = Vector2(280, 45)
		btn_bg.position = Vector2(500, start_y + i * 60)
		btn_bg.color = Color(0.15, 0.15, 0.3, 0.8) if i != _selected else Color(0.25, 0.25, 0.5, 0.9)
		cl.add_child(btn_bg)

		var lbl := Label.new()
		lbl.name = "BtnLbl%d" % i
		lbl.text = menu_items[i]
		lbl.position = Vector2(560, start_y + i * 60 + 8)
		lbl.add_theme_font_size_override("font_size", 24)
		lbl.add_theme_color_override("font_color", Color(1, 1, 1) if i == _selected else Color(0.6, 0.6, 0.7))
		cl.add_child(lbl)

		# Selection arrow
		var arrow := Label.new()
		arrow.name = "Arrow%d" % i
		arrow.text = ">"
		arrow.position = Vector2(515, start_y + i * 60 + 8)
		arrow.add_theme_font_size_override("font_size", 24)
		arrow.add_theme_color_override("font_color", Color(1.0, 0.95, 0.55))
		arrow.visible = (i == _selected)
		cl.add_child(arrow)

		_buttons.append({"bg": btn_bg, "lbl": lbl, "arrow": arrow})

func _build_footer() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 1
	add_child(cl)

	var hint := Label.new()
	hint.text = "↑↓ Navigate    Enter/Space Select"
	hint.position = Vector2(460, 670)
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	cl.add_child(hint)

	# Seed display
	var seed_lbl := Label.new()
	seed_lbl.text = "Highest Level: %d" % GameState.save.highest_level
	seed_lbl.position = Vector2(20, 690)
	seed_lbl.add_theme_font_size_override("font_size", 14)
	seed_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	cl.add_child(seed_lbl)

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return

	var kb := event as InputEventKey
	match kb.keycode:
		KEY_UP:
			_select((_selected - 1 + _buttons.size()) % _buttons.size())
			Audio.play("select", -6.0)
		KEY_DOWN:
			_select((_selected + 1) % _buttons.size())
			Audio.play("select", -6.0)
		KEY_ENTER, KEY_SPACE:
			_activate(_selected)
		KEY_KP_ENTER:
			_activate(_selected)

func _select(idx: int) -> void:
	# Deselect old
	_buttons[_selected]["bg"].color = Color(0.15, 0.15, 0.3, 0.8)
	_buttons[_selected]["lbl"].add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	_buttons[_selected]["arrow"].visible = false

	_selected = idx

	# Select new
	_buttons[_selected]["bg"].color = Color(0.25, 0.25, 0.5, 0.9)
	_buttons[_selected]["lbl"].add_theme_color_override("font_color", Color(1, 1, 1))
	_buttons[_selected]["arrow"].visible = true

func _activate(idx: int) -> void:
	Audio.play("select", -4.0)
	match idx:
		0:  # PLAY
			_fade_to_scene("res://scenes/World.tscn")
		1:  # DAILY CHALLENGE
			GameState.queue_level_transition(1, GameState.daily_seed(), "daily")
			_fade_to_scene("res://scenes/World.tscn")
		2:  # ENDLESS
			GameState.queue_level_transition(1, randi() % 999999, "endless")
			_fade_to_scene("res://scenes/World.tscn")
		3:  # SHOP
			_fade_to_scene("res://scenes/Shop.tscn")
		4:  # LEVEL SELECT
			_fade_to_scene("res://scenes/LevelSelect.tscn")
		5:  # QUIT
			get_tree().quit()

func _fade_to_scene(scene_path: String) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.size = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cl := CanvasLayer.new()
	cl.layer = 100
	cl.add_child(overlay)
	add_child(cl)

	set_process_unhandled_input(false)
	var tw := create_tween()
	tw.tween_property(overlay, "color:a", 1.0, 0.3)
	tw.tween_callback(get_tree().change_scene_to_file.bind(scene_path))
