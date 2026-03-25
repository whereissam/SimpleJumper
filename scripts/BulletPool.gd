class_name BulletPool
extends Node
## Reuses bullet nodes instead of instantiating/freeing each time.

var _pool: Array[Bullet] = []
var _active: Array[Bullet] = []
var _on_hit: Callable

const POOL_SIZE := 20

func setup(on_bullet_hit: Callable) -> void:
	_on_hit = on_bullet_hit
	for i in POOL_SIZE:
		var b := _create_bullet()
		_deactivate(b)
		_pool.append(b)

func fire(pos: Vector2, dir: float, speed: float) -> Bullet:
	var b: Bullet
	if _pool.is_empty():
		b = _create_bullet()
	else:
		b = _pool.pop_back()
	b.position = pos
	b.bullet_dir = dir
	b.bullet_speed = speed
	b.lifetime = 5.0
	b.visible = true
	b.set_physics_process(true)
	b.monitoring = true
	_active.append(b)
	return b

func release(b: Bullet) -> void:
	_deactivate(b)
	_active.erase(b)
	_pool.append(b)

func release_all() -> void:
	for b in _active:
		_deactivate(b)
		_pool.append(b)
	_active.clear()

func _create_bullet() -> Bullet:
	var b := Bullet.new()

	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	cs.shape = circle
	b.add_child(cs)

	var s := Sprites.make_sprite(Sprites.DIAMOND, Vector2(1.0, 1.0))
	s.modulate = Color(1.0, 0.3, 0.2)
	b.add_child(s)

	b.body_entered.connect(_on_body_hit.bind(b))
	b.expired.connect(_on_expired)
	add_child(b)
	return b

func _on_expired(b: Bullet) -> void:
	release(b)

func _deactivate(b: Bullet) -> void:
	b.visible = false
	b.set_physics_process(false)
	b.monitoring = false
	b.position = Vector2(-9999, -9999)

func _on_body_hit(body: Node2D, bullet: Bullet) -> void:
	if _on_hit.is_valid():
		_on_hit.call(body, bullet)
	release(bullet)
