class_name SaveData
extends Resource
## Persistent save data stored as a Godot resource.

@export var highest_level: int = 1
@export var total_coins: int = 0
@export var best_times: Dictionary = {}  # level_num (int) -> time in seconds (float)
@export var best_stars: Dictionary = {}  # level_num (int) -> star count (1-3)

const SAVE_PATH: String = "user://save.tres"

static func save_to_disk(data: SaveData) -> void:
	ResourceSaver.save(data, SAVE_PATH)

static func load_from_disk() -> SaveData:
	if ResourceLoader.exists(SAVE_PATH):
		var loaded := ResourceLoader.load(SAVE_PATH)
		if loaded is SaveData:
			return loaded as SaveData
	return SaveData.new()
