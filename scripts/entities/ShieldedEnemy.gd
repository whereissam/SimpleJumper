class_name ShieldedEnemy extends Area2D

var patrol_center: float
var patrol_range: float
var patrol_speed: float
var direction: float = 1.0
var shield_hp: int = 2
var _shield_node: Polygon2D

func _ready() -> void:
	# Create shield visual
	_shield_node = Polygon2D.new()
	_shield_node.name = "Shield"
	var pts := PackedVector2Array()
	for i in 8:
		var a := i * TAU / 8.0
		pts.append(Vector2(cos(a) * 20, sin(a) * 20))
	_shield_node.polygon = pts
	_shield_node.color = Color(0.3, 0.7, 1.0, 0.35)
	add_child(_shield_node)

func _physics_process(delta: float) -> void:
	position.x += direction * patrol_speed * delta

	if position.x > patrol_center + patrol_range:
		direction = -1.0
	elif position.x < patrol_center - patrol_range:
		direction = 1.0

	var anim := get_node_or_null("Anim") as AnimatedSprite2D
	if anim:
		var anim_name := "walk_right" if direction > 0 else "walk_left"
		if anim.animation != anim_name:
			anim.play(anim_name)

func take_stomp() -> bool:
	## Returns true if enemy should die.
	shield_hp -= 1
	if shield_hp <= 0:
		if _shield_node:
			_shield_node.visible = false
		return true
	# Flash shield on hit
	if _shield_node:
		_shield_node.color = Color(1, 1, 1, 0.7)
		var tw := get_tree().create_tween()
		tw.tween_property(_shield_node, "color", Color(0.3, 0.7, 1.0, 0.35), 0.2)
	return false
