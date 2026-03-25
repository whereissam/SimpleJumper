extends Node2D
## Level select screen showing unlocked levels with best times.

const Colors = preload("res://scripts/Colors.gd")

const VIEWPORT_WIDTH  := 1280
const VIEWPORT_HEIGHT := 720
const COLS := 5
const ROWS := 4
const CELL_W := 180
const CELL_H := 100
const GRID_X := 160
const GRID_Y := 140
const LEVELS_PER_PAGE := COLS * ROWS

var _selected: int = 0
var _page: int = 0
var _cells: Array[Dictionary] = []
var _page_label: Label

func _ready() -> void:
	_build_background()
	_build_header()
	_build_grid()
	_build_footer()

func _build_background() -> void:
	var cl := CanvasLayer.new()
	cl.layer = -10
	add_child(cl)
	var bg := ColorRect.new()
	bg.color = Colors.BG_COLOR
	bg.size = Vector2(VIEWPORT_WIDTH + 200, VIEWPORT_HEIGHT + 200)
	bg.position = Vector2(-100, -100)
	cl.add_child(bg)

func _build_header() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 1
	cl.name = "Header"
	add_child(cl)

	var title := Label.new()
	title.text = "LEVEL SELECT"
	title.position = Vector2(480, 40)
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(1.0, 0.95, 0.55))
	cl.add_child(title)

	_page_label = Label.new()
	_page_label.position = Vector2(580, 90)
	_page_label.add_theme_font_size_override("font_size", 16)
	_page_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	cl.add_child(_page_label)

func _build_grid() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 2
	cl.name = "Grid"
	add_child(cl)

	_cells.clear()
	var highest := GameState.save.highest_level

	for i in LEVELS_PER_PAGE:
		var level_num := _page * LEVELS_PER_PAGE + i + 1
		var col := i % COLS
		var row := i / COLS

		var x := GRID_X + col * (CELL_W + 12)
		var y := GRID_Y + row * (CELL_H + 12)

		var unlocked := level_num <= highest
		var has_time : bool = GameState.save.best_times.has(level_num)

		var cell_bg := ColorRect.new()
		cell_bg.size = Vector2(CELL_W, CELL_H)
		cell_bg.position = Vector2(x, y)
		if i == _selected:
			cell_bg.color = Color(0.25, 0.25, 0.5, 0.9)
		elif unlocked:
			cell_bg.color = Color(0.15, 0.15, 0.3, 0.8)
		else:
			cell_bg.color = Color(0.1, 0.1, 0.15, 0.6)
		cl.add_child(cell_bg)

		var num_lbl := Label.new()
		num_lbl.text = str(level_num) if unlocked else "?"
		num_lbl.position = Vector2(x + 10, y + 8)
		num_lbl.add_theme_font_size_override("font_size", 28)
		num_lbl.add_theme_color_override("font_color", Color(1, 1, 1) if unlocked else Color(0.3, 0.3, 0.4))
		cl.add_child(num_lbl)

		var diff := clampf((level_num - 1) * 0.15, 0.0, 1.0)
		var diff_names := ["Easy", "Medium", "Hard", "Extreme"]
		var diff_colors := [Color(0.3, 0.85, 0.4), Color(1.0, 0.85, 0.2), Color(1.0, 0.4, 0.2), Color(1.0, 0.2, 0.2)]
		var diff_idx := mini(int(diff * 3.99), 3)

		if unlocked:
			var diff_lbl := Label.new()
			diff_lbl.text = diff_names[diff_idx]
			diff_lbl.position = Vector2(x + 10, y + 42)
			diff_lbl.add_theme_font_size_override("font_size", 14)
			diff_lbl.add_theme_color_override("font_color", diff_colors[diff_idx])
			cl.add_child(diff_lbl)

		if has_time:
			var time_val : float = GameState.save.best_times[level_num]
			var mins := int(time_val) / 60
			var secs := int(time_val) % 60
			var ms := int(fmod(time_val, 1.0) * 100)
			var time_lbl := Label.new()
			time_lbl.text = "%02d:%02d.%02d" % [mins, secs, ms]
			time_lbl.position = Vector2(x + 10, y + 62)
			time_lbl.add_theme_font_size_override("font_size", 16)
			time_lbl.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
			cl.add_child(time_lbl)
		elif unlocked:
			var no_time := Label.new()
			no_time.text = "no time"
			no_time.position = Vector2(x + 10, y + 62)
			no_time.add_theme_font_size_override("font_size", 14)
			no_time.add_theme_color_override("font_color", Color(0.35, 0.35, 0.45))
			cl.add_child(no_time)

		_cells.append({"bg": cell_bg, "level": level_num, "unlocked": unlocked})

	_update_page_label()

func _build_footer() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 1
	add_child(cl)

	var hint := Label.new()
	hint.text = "←→↑↓ Navigate    Enter Play    Esc Back    Q/E Page"
	hint.position = Vector2(370, 680)
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	cl.add_child(hint)

func _update_page_label() -> void:
	var total_pages := ceili(50.0 / LEVELS_PER_PAGE)
	_page_label.text = "Page %d / %d" % [_page + 1, total_pages]

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return

	var kb := event as InputEventKey
	match kb.keycode:
		KEY_RIGHT:
			_move_selection(1, 0)
		KEY_LEFT:
			_move_selection(-1, 0)
		KEY_DOWN:
			_move_selection(0, 1)
		KEY_UP:
			_move_selection(0, -1)
		KEY_ENTER, KEY_SPACE, KEY_KP_ENTER:
			_activate()
		KEY_ESCAPE:
			get_tree().change_scene_to_file("res://scenes/TitleScreen.tscn")
		KEY_E:
			_change_page(1)
		KEY_Q:
			_change_page(-1)

func _move_selection(dx: int, dy: int) -> void:
	var col := _selected % COLS
	var row := _selected / COLS
	col = clampi(col + dx, 0, COLS - 1)
	row = clampi(row + dy, 0, ROWS - 1)
	var new_idx := row * COLS + col
	if new_idx != _selected and new_idx < _cells.size():
		_cells[_selected]["bg"].color = Color(0.15, 0.15, 0.3, 0.8) if _cells[_selected]["unlocked"] else Color(0.1, 0.1, 0.15, 0.6)
		_selected = new_idx
		_cells[_selected]["bg"].color = Color(0.25, 0.25, 0.5, 0.9)
		Audio.play("select", -8.0)

func _activate() -> void:
	if _selected >= _cells.size():
		return
	var cell := _cells[_selected]
	if not cell["unlocked"]:
		return
	Audio.play("select", -4.0)
	GameState.queue_level_transition(cell["level"], randi() % 999999)
	_fade_to("res://scenes/World.tscn")

func _change_page(dir: int) -> void:
	var total_pages := ceili(50.0 / LEVELS_PER_PAGE)
	var new_page := clampi(_page + dir, 0, total_pages - 1)
	if new_page != _page:
		_page = new_page
		_selected = 0
		# Rebuild grid
		var grid := get_node_or_null("Grid")
		if grid:
			grid.queue_free()
		await get_tree().process_frame
		_build_grid()

func _fade_to(scene_path: String) -> void:
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
