class_name BossEnemy extends Area2D

signal fired(boss: BossEnemy)

var boss_speed: float
var boss_dir: float = 1.0
var boss_fire_timer: float
var boss_fire_interval: float
var boss_hp: int
var boss_max_hp: int

const PATROL_LEFT := 230.0
const PATROL_RIGHT := 1050.0

func _physics_process(delta: float) -> void:
	position.x += boss_dir * boss_speed * delta
	if position.x > PATROL_RIGHT:
		boss_dir = -1.0
	elif position.x < PATROL_LEFT:
		boss_dir = 1.0

	boss_fire_timer -= delta
	if boss_fire_timer <= 0.0:
		boss_fire_timer = boss_fire_interval
		fired.emit(self)

	# Animation
	var anim := get_node_or_null("Anim") as AnimatedSprite2D
	if anim:
		var anim_name := "walk_right" if boss_dir > 0 else "walk_left"
		if anim.animation != anim_name:
			anim.play(anim_name)

func take_hit() -> int:
	boss_hp -= 1
	# Update HP bar
	var bar := get_node_or_null("BarFill") as ColorRect
	if bar:
		bar.size.x = 60.0 * boss_hp / boss_max_hp
	# Flash red
	var anim := get_node_or_null("Anim") as AnimatedSprite2D
	if anim:
		anim.modulate = Color(10, 0, 0)
		var tw := get_tree().create_tween()
		tw.tween_property(anim, "modulate", Color.WHITE, 0.15)
	return boss_hp
