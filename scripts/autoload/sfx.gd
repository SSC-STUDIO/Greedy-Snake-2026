extends Node
## Sfx autoload: tiny pooled sound-effect player keyed by short names.
## Files live under assets/kenney_clean/audio/*.ogg (CC0, Kenney),
## renamed copies picked from the Kenney "Audio (295 files)" bundle.
## Loads are guarded so the suite stays green even before/without assets.

const POOL_SIZE := 10
const BASE_DB := -9.0

## key -> curated CC0 sound (see assets/external/CREDITS.md for sources).
const LIBRARY := {
	&"swing": "res://assets/kenney_clean/audio/swing.ogg",
	&"hit_flesh": "res://assets/kenney_clean/audio/hit_flesh.ogg",
	&"hurt": "res://assets/kenney_clean/audio/hurt.ogg",
	&"parry": "res://assets/kenney_clean/audio/parry.ogg",
	&"dash": "res://assets/kenney_clean/audio/dash.ogg",
	&"jump": "res://assets/kenney_clean/audio/jump.ogg",
	&"spit": "res://assets/kenney_clean/audio/spit.ogg",
	&"pickup": "res://assets/kenney_clean/audio/pickup.ogg",
	&"insert": "res://assets/kenney_clean/audio/insert.ogg",
	&"gate": "res://assets/kenney_clean/audio/gate.ogg",
	&"ui_move": "res://assets/kenney_clean/audio/ui_move.ogg",
	&"ui_select": "res://assets/kenney_clean/audio/ui_select.ogg",
	&"ui_back": "res://assets/kenney_clean/audio/ui_back.ogg",
	&"ui_denied": "res://assets/kenney_clean/audio/ui_denied.ogg",
}

var _pool: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		set_process(false)
		return
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = &"Master"
		p.volume_db = BASE_DB
		add_child(p)
		_pool.append(p)


func play(key: StringName, pitch_jitter: float = 0.08) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var stream := _resolve_stream(key)
	if stream == null:
		return
	for p in _pool:
		if not p.playing:
			p.stream = stream
			p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
			p.play()
			return


## Lazily resolve + cache; missing files degrade to silence, not errors.
func _resolve_stream(key: StringName) -> AudioStream:
	if _streams.has(key):
		return _streams[key]
	var path: String = LIBRARY.get(key, "")
	var stream: AudioStream = null
	if path != "" and ResourceLoader.exists(path):
		stream = load(path) as AudioStream
	# One-shot SFX must never loop; each stream type spells it differently.
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	elif stream is AudioStreamOggVorbis:
		stream.loop = false
	_streams[key] = stream
	return stream