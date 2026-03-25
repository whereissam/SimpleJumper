extends Node
# Small always-processing node that listens for Escape to toggle pause.
# process_mode = ALWAYS is set by World.gd when creating this node.

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var kb := event as InputEventKey
		if kb.keycode == KEY_ESCAPE:
			var world : Node = get_meta("world")
			if world and world.has_method("_toggle_pause_menu"):
				world._toggle_pause_menu()
			get_viewport().set_input_as_handled()
		elif kb.keycode == KEY_M and get_tree().paused:
			get_tree().paused = false
			get_tree().change_scene_to_file("res://scenes/TitleScreen.tscn")
			get_viewport().set_input_as_handled()
