extends Node
## Autoload singleton for persistent game state across scene reloads.

# -- Level transition data --
var next_level: int = 1
var next_seed: int = 0
var has_pending_transition: bool = false

# -- Session data (reset on return to menu) --
var session_coins: int = 0

# -- Save data --
var save: SaveData

func _ready() -> void:
	save = SaveData.load_from_disk()

func queue_level_transition(level: int, seed_val: int) -> void:
	next_level = level
	next_seed = seed_val
	has_pending_transition = true

func consume_transition() -> Dictionary:
	if has_pending_transition:
		has_pending_transition = false
		return {"level": next_level, "seed": next_seed}
	return {}

func complete_level(level: int, elapsed_time: float) -> void:
	save.highest_level = maxi(save.highest_level, level + 1)
	if not save.best_times.has(level) or elapsed_time < save.best_times[level]:
		save.best_times[level] = elapsed_time
	save.total_coins += session_coins
	session_coins = 0
	SaveData.save_to_disk(save)
