class_name DestructibleBlock extends StaticBody2D
## Block that shatters when the player dashes through it.

var block_width: float
var block_height: float
var _destroyed := false

signal destroyed(block: StaticBody2D)

func _ready() -> void:
	# Detect player dash collision via Area2D overlay
	var area := Area2D.new()
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(block_width + 8, block_height + 8)
	cs.shape = rect
	area.add_child(cs)
	area.body_entered.connect(_on_body_entered)
	add_child(area)

func _on_body_entered(body: Node2D) -> void:
	if _destroyed:
		return
	if body is Player and (body as Player).is_dashing:
		_destroyed = true
		destroyed.emit(self)
		# Disable collision immediately
		set_deferred("collision_layer", 0)
		# Shatter animation: scale down + fade
		var tw := get_tree().create_tween()
		tw.set_parallel(true)
		tw.tween_property(self, "scale", Vector2(0.1, 0.1), 0.2).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(self, "modulate:a", 0.0, 0.2)
		tw.set_parallel(false)
		tw.tween_callback(queue_free)
