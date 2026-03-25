class_name DisappearPlatform extends StaticBody2D

var timer: float
var is_on: bool = true
var on_time: float
var off_time: float

func _physics_process(delta: float) -> void:
	timer -= delta

	if timer <= 0.0:
		is_on = not is_on
		timer = on_time if is_on else off_time
		for c in get_children():
			if c is CollisionShape2D:
				c.disabled = not is_on
		var fill_node := get_node_or_null("Fill")
		if fill_node:
			fill_node.modulate.a = 1.0 if is_on else 0.2

	# Warning blink before disappearing
	if is_on and timer < 0.5:
		var fill_node := get_node_or_null("Fill")
		if fill_node:
			fill_node.modulate.a = 1.0 if int(timer * 8) % 2 == 0 else 0.3
