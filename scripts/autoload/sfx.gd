extends Node
## Sfx autoload: tiny pooled sound-effect player keyed by short names.
## Files live under assets/external/kenney/audio/*.ogg (CC0, Kenney).
## Loads are guarded so the suite stays green even before/without assets.

const POOL_SIZE := 10
const BASE_DB := -9.0

## key -> file path inside the imported CC0 bundle.
const LIBRARY := {
	&"swing": "res://assets/external/kenney/audio/swing.ogg",
	&"hit_flesh": "res://assets/external/kenney/audio/hit_flesh.ogg",
	&"hurt": "res://assets/external/kenney/audio/hurt.ogg",
	&"parry": "res://assets/external/kenney/audio/parry.ogg",
	&"dash": "res://assets/external/kenney/audio/dash.ogg",
	&"jump": "res://assets/external/kenney/audio/jump.ogg",
	&"spit": "res://assets/external/kenney/audio/spit.ogg",
	&"pickup": "res://assets/external/kenney/audio/pickup.ogg",
	&"insert": "res://assets/external/kenney/audio/insert.ogg",
	&"gate": "res://assets/external/kenney/audio/gate.ogg",
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
	if stream != null:
		stream.loop_mode = AudioStreamWAV.LOOP_DISABLED if stream is AudioStreamWAV else stream.loop_mode
	_streams[key] = stream
	return stream