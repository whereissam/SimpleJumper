extends Node
# Autoload singleton for playing sound effects.
# Register as autoload "Audio" in Project Settings.

const SFX := {
	# Player
	"jump":        "res://assets/audio/digital/phaseJump1.ogg",
	"double_jump": "res://assets/audio/digital/phaseJump3.ogg",
	"dash":        "res://assets/audio/digital/phaserUp2.ogg",
	"land":        "res://assets/audio/impact/footstep_concrete_000.ogg",
	"wall_slide":  "res://assets/audio/impact/footstep_wood_000.ogg",
	"hit":         "res://assets/audio/impact/impactPunch_heavy_001.ogg",
	"death":       "res://assets/audio/digital/lowDown.ogg",
	"respawn":     "res://assets/audio/digital/powerUp4.ogg",

	# Items
	"coin":        "res://assets/audio/interface/confirmation_002.ogg",
	"powerup":     "res://assets/audio/digital/powerUp2.ogg",
	"shield_break":"res://assets/audio/interface/glass_004.ogg",

	# World
	"checkpoint":  "res://assets/audio/interface/maximize_006.ogg",
	"portal":      "res://assets/audio/digital/phaserDown2.ogg",
	"trampoline":  "res://assets/audio/digital/pepSound3.ogg",

	# Enemies
	"stomp":       "res://assets/audio/impact/impactSoft_heavy_002.ogg",
	"shoot":       "res://assets/audio/digital/laser3.ogg",
	"bullet_hit":  "res://assets/audio/impact/impactGeneric_light_002.ogg",

	# Hazards
	"spike_hit":   "res://assets/audio/impact/impactMetal_light_001.ogg",
	"crumble":     "res://assets/audio/impact/impactPlank_medium_002.ogg",

	# UI
	"level_complete": "res://assets/audio/digital/threeTone1.ogg",
	"select":      "res://assets/audio/interface/select_002.ogg",
}

var _cache : Dictionary = {}
var _players : Array = []
const MAX_PLAYERS := 12  # Max simultaneous sounds

func _ready() -> void:
	# Preload all sounds (skip missing files gracefully)
	for key in SFX:
		if ResourceLoader.exists(SFX[key]):
			_cache[key] = load(SFX[key])
		else:
			push_warning("AudioManager: missing sound file: " + SFX[key])

	# Create a pool of AudioStreamPlayers
	for i in MAX_PLAYERS:
		var asp := AudioStreamPlayer.new()
		asp.bus = "Master"
		add_child(asp)
		_players.append(asp)

func play(sound_name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not _cache.has(sound_name):
		return

	# Find a free player
	for asp in _players:
		var p := asp as AudioStreamPlayer
		if not p.playing:
			p.stream = _cache[sound_name]
			p.volume_db = volume_db
			p.pitch_scale = pitch
			p.play()
			return

	# All busy -- steal the first one
	var p := _players[0] as AudioStreamPlayer
	p.stream = _cache[sound_name]
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()
