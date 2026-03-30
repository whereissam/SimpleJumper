extends Node2D
## Shop screen for buying skins with coins.

const Colors = preload("res://scripts/Colors.gd")

const VIEWPORT_WIDTH  := 1280
const VIEWPORT_HEIGHT := 720

var _items: Array[Dictionary] = []
var _selected: int = 0
var _coin_label: Label

func _ready() -> void:
	_build_background()
	_build_ui()
	Audio.start_music()

func _build_background() -> void:
	var cl := CanvasLayer.new()
	cl.layer = -10
	add_child(cl)
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.04, 0.12)
	bg.size = Vector2(VIEWPORT_WIDTH + 200, VIEWPORT_HEIGHT + 200)
	bg.position = Vector2(-100, -100)
	cl.add_child(bg)

func _build_ui() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 1
	add_child(cl)

	# Title
	var title := Label.new()
	title.text = "SHOP"
	title.position = Vector2(570, 30)
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.15))
	cl.add_child(title)

	# Coins display
	_coin_label = Label.new()
	_coin_label.text = "Coins: %d" % GameState.save.shop_coins
	_coin_label.position = Vector2(530, 90)
	_coin_label.add_theme_font_size_override("font_size", 22)
	_coin_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	cl.add_child(_coin_label)

	# Skin cards
	var start_y := 140
	for i in Skins.CATALOG.size():
		var skin : Dictionary = Skins.CATALOG[i]
		var owned : bool = skin["id"] in GameState.save.owned_skins
		var active : bool = skin["id"] == GameState.save.active_skin

		var card := ColorRect.new()
		card.name = "Card%d" % i
		card.size = Vector2(500, 55)
		card.position = Vector2(390, start_y + i * 65)
		card.color = Color(0.2, 0.2, 0.35, 0.9) if i == _selected else Color(0.12, 0.12, 0.22, 0.8)
		cl.add_child(card)

		# Color swatch
		var swatch := ColorRect.new()
		swatch.size = Vector2(30, 30)
		swatch.position = Vector2(400, start_y + i * 65 + 12)
		swatch.color = skin["tint"]
		cl.add_child(swatch)

		# Name
		var name_lbl := Label.new()
		name_lbl.name = "Name%d" % i
		name_lbl.text = skin["name"]
		name_lbl.position = Vector2(440, start_y + i * 65 + 10)
		name_lbl.add_theme_font_size_override("font_size", 20)
		name_lbl.add_theme_color_override("font_color", Color.WHITE)
		cl.add_child(name_lbl)

		# Stats
		var stats_lbl := Label.new()
		stats_lbl.text = "SPD:%.1fx  JMP:%.1fx  HP:%d" % [skin["speed"], skin["jump"], skin["hp"]]
		stats_lbl.position = Vector2(570, start_y + i * 65 + 12)
		stats_lbl.add_theme_font_size_override("font_size", 14)
		stats_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
		cl.add_child(stats_lbl)

		# Status
		var status := Label.new()
		status.name = "Status%d" % i
		if active:
			status.text = "EQUIPPED"
			status.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
		elif owned:
			status.text = "OWNED"
			status.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
		else:
			status.text = "%d coins" % skin["cost"]
			status.add_theme_color_override("font_color", Color(1.0, 0.85, 0.15))
		status.position = Vector2(790, start_y + i * 65 + 10)
		status.add_theme_font_size_override("font_size", 18)
		cl.add_child(status)

		# Arrow
		var arrow := Label.new()
		arrow.name = "Arrow%d" % i
		arrow.text = ">"
		arrow.position = Vector2(395, start_y + i * 65 + 14)
		arrow.add_theme_font_size_override("font_size", 20)
		arrow.add_theme_color_override("font_color", Color(1.0, 0.95, 0.55))
		arrow.visible = (i == _selected)
		cl.add_child(arrow)

		_items.append({"card": card, "arrow": arrow, "status": status, "skin": skin})

	# Footer
	var hint := Label.new()
	hint.text = "↑↓ Navigate    Enter Buy/Equip    Esc Back"
	hint.position = Vector2(420, 660)
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	cl.add_child(hint)

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var kb := event as InputEventKey
	match kb.keycode:
		KEY_UP:
			_select((_selected - 1 + _items.size()) % _items.size())
			Audio.play("select", -6.0)
		KEY_DOWN:
			_select((_selected + 1) % _items.size())
			Audio.play("select", -6.0)
		KEY_ENTER, KEY_SPACE, KEY_KP_ENTER:
			_activate(_selected)
		KEY_ESCAPE:
			_fade_to_scene("res://scenes/TitleScreen.tscn")

func _select(idx: int) -> void:
	_items[_selected]["card"].color = Color(0.12, 0.12, 0.22, 0.8)
	_items[_selected]["arrow"].visible = false
	_selected = idx
	_items[_selected]["card"].color = Color(0.2, 0.2, 0.35, 0.9)
	_items[_selected]["arrow"].visible = true

func _activate(idx: int) -> void:
	var skin : Dictionary = _items[idx]["skin"]
	var skin_id : String = skin["id"]
	var owned := skin_id in GameState.save.owned_skins

	if owned:
		# Equip
		GameState.save.active_skin = skin_id
		SaveData.save_to_disk(GameState.save)
		Audio.play("powerup", -4.0)
		_refresh_statuses()
	elif GameState.save.shop_coins >= skin["cost"]:
		# Buy
		GameState.save.shop_coins -= skin["cost"]
		GameState.save.owned_skins.append(skin_id)
		GameState.save.active_skin = skin_id
		SaveData.save_to_disk(GameState.save)
		Audio.play("level_complete", -4.0)
		_coin_label.text = "Coins: %d" % GameState.save.shop_coins
		_refresh_statuses()
	else:
		Audio.play("hit", -4.0)

func _refresh_statuses() -> void:
	for i in _items.size():
		var skin : Dictionary = _items[i]["skin"]
		var status : Label = _items[i]["status"]
		var skin_id : String = skin["id"]
		if skin_id == GameState.save.active_skin:
			status.text = "EQUIPPED"
			status.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
		elif skin_id in GameState.save.owned_skins:
			status.text = "OWNED"
			status.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
		else:
			status.text = "%d coins" % skin["cost"]
			status.add_theme_color_override("font_color", Color(1.0, 0.85, 0.15))

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
