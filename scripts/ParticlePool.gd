class_name ParticlePool
extends Node
## Reuses GPUParticles2D nodes instead of instantiating/freeing each time.

var _pool: Array[GPUParticles2D] = []
var _active: Array[GPUParticles2D] = []

const POOL_SIZE := 24

func setup() -> void:
	for i in POOL_SIZE:
		var p := GPUParticles2D.new()
		_deactivate(p)
		add_child(p)
		_pool.append(p)

## Acquire a particle node from the pool, configured and emitting.
## Caller must set process_material before or after calling this.
func acquire(pos: Vector2, amount: int, lifetime: float,
		explosiveness: float = 1.0, z_idx: int = 10) -> GPUParticles2D:
	var p: GPUParticles2D
	if _pool.is_empty():
		p = GPUParticles2D.new()
		add_child(p)
	else:
		p = _pool.pop_back()
	p.position = pos
	p.amount = amount
	p.lifetime = lifetime
	p.one_shot = true
	p.explosiveness = explosiveness
	p.z_index = z_idx
	p.visible = true
	p.emitting = true
	_active.append(p)

	# Auto-release after particles finish
	var tw := get_tree().create_tween()
	tw.tween_interval(lifetime + 0.1)
	tw.tween_callback(_release.bind(p))
	return p

func _release(p: GPUParticles2D) -> void:
	if p in _active:
		_deactivate(p)
		_active.erase(p)
		_pool.append(p)

func release_all() -> void:
	for p in _active:
		_deactivate(p)
		_pool.append(p)
	_active.clear()

func _deactivate(p: GPUParticles2D) -> void:
	p.emitting = false
	p.visible = false
	p.position = Vector2(-9999, -9999)
	p.process_material = null
