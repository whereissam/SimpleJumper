extends Node
# Autoload singleton for playing sound effects and music.
# Register as autoload "Audio" in Project Settings.

const SFX := {
	# Player
	"jump":        "res://assets/audio/digital/phaseJump1.ogg",
	"double_jump": "res://assets/audio/digital/phaseJump3.ogg",
	"dash":        "res://assets/audio/digital/phaserUp2.ogg",
	"land":        "res://assets/audio/impact/footstep_concrete_000.ogg",
	"wall_slide":  "res://assets/audio/impact/footstep_wood_000.ogg",
	"hit":         "res://assets/audio/impact/impactPunch_heavy_001.ogg",
	"death":       "res://assets/audio/digital/phaserDown3.ogg",
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
const MAX_PLAYERS := 12

# Looping sound (wall slide)
var _loop_player : AudioStreamPlayer
var _loop_name   := ""

# Music
var _music_player : AudioStreamPlayer
var _music_playing := false

func _ready() -> void:
	# Preload all sounds
	for key in SFX:
		if ResourceLoader.exists(SFX[key]):
			_cache[key] = load(SFX[key])
		else:
			push_warning("AudioManager: missing sound file: " + SFX[key])

	# SFX pool
	for i in MAX_PLAYERS:
		var asp := AudioStreamPlayer.new()
		asp.bus = "Master"
		add_child(asp)
		_players.append(asp)

	# Dedicated loop player (for wall slide etc)
	_loop_player = AudioStreamPlayer.new()
	_loop_player.bus = "Master"
	_loop_player.volume_db = -12.0
	add_child(_loop_player)

	# Music player
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	_music_player.volume_db = -18.0
	add_child(_music_player)

func play(sound_name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not _cache.has(sound_name):
		return
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

# -- Looping sound (start/stop) ------------------------------------------------
func play_loop(sound_name: String, volume_db: float = -12.0) -> void:
	if _loop_name == sound_name and _loop_player.playing:
		return  # Already playing this loop
	if not _cache.has(sound_name):
		return
	_loop_name = sound_name
	_loop_player.stream = _cache[sound_name]
	_loop_player.volume_db = volume_db
	_loop_player.play()

func stop_loop() -> void:
	_loop_player.stop()
	_loop_name = ""

# -- Music (procedural chiptune) -----------------------------------------------
func start_music() -> void:
	if _music_playing:
		return
	_music_playing = true
	# Generate a simple procedural chiptune loop using AudioStreamGenerator
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050
	gen.buffer_length = 0.5
	_music_player.stream = gen
	_music_player.play()
	# Fill buffer in process
	set_process(true)

func stop_music() -> void:
	_music_playing = false
	_music_player.stop()
	set_process(false)

# Procedural chiptune notes
var _music_time := 0.0
var _note_idx := 0
const NOTES : Array = [262, 294, 330, 349, 392, 349, 330, 294, 262, 330, 392, 523, 392, 330, 294, 262]
const NOTE_DUR := 0.2

func _process(_delta: float) -> void:
	if not _music_playing:
		return
	var playback := _music_player.get_stream_playback()
	if playback == null:
		return
	var sb := playback as AudioStreamGeneratorPlayback
	var frames := sb.get_frames_available()
	for i in frames:
		_music_time += 1.0 / 22050.0
		if _music_time > NOTE_DUR:
			_music_time -= NOTE_DUR
			_note_idx = (_note_idx + 1) % NOTES.size()
		var freq : float = NOTES[_note_idx]
		# Square wave with volume envelope
		var phase := fmod(_music_time * freq, 1.0)
		var sample := 0.08 if phase < 0.5 else -0.08
		# Fade out at end of note
		var env := clampf(1.0 - _music_time / NOTE_DUR * 0.5, 0.3, 1.0)
		sample *= env
		sb.push_frame(Vector2(sample, sample))
