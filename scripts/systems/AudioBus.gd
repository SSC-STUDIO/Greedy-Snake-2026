extends Node

const GAME_BGM_PATH := "res://assets/audio/Greedy-Snake.mp3"
const BUTTON_PATH := "res://assets/audio/Button-Click.wav"
const EAT_PATH := "res://assets/audio/Impact.wav"
const DEATH_PATH := "res://assets/audio/Game-Over.wav"
const EXPLOSION_PATH := "res://assets/audio/Explosion.wav"
const ONE_SHOT_POOL_LIMIT := 12
const BGM_FADE_TIME := 0.45

var _bgm_player: AudioStreamPlayer
var _stream_cache := {}
var _one_shot_players: Array[AudioStreamPlayer] = []
var bgm_volume_value := 0.78
var sfx_volume_value := 0.9
var sound_on_value := true
var _bgm_tween: Tween
var _bgm_path := ""

func _ready() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BgmPlayer"
	_bgm_player.bus = "Master"
	add_child(_bgm_player)
	SettingsStore.bgm_volume_changed.connect(_on_bgm_volume_changed)
	SettingsStore.sfx_volume_changed.connect(_on_sfx_volume_changed)
	SettingsStore.sound_on_changed.connect(_on_sound_on_changed)

func play_game_bgm() -> void:
	_play_bgm_path(GAME_BGM_PATH)

func play_bgm() -> void:
	play_game_bgm()

func _play_bgm_path(path: String) -> void:
	if not _can_play_audio():
		return
	var stream := _load_stream(path)
	if stream == null:
		return
	stream.loop = true
	if _bgm_player.playing and _bgm_path == path and _bgm_player.stream == stream:
		_fade_bgm_to(_volume_db(bgm_volume_value), BGM_FADE_TIME * 0.5)
		return
	_bgm_path = path
	if _bgm_tween != null:
		_bgm_tween.kill()
	if _bgm_player.playing:
		_bgm_tween = create_tween()
		_bgm_tween.tween_property(_bgm_player, "volume_db", -80.0, BGM_FADE_TIME * 0.5)
		_bgm_tween.tween_callback(func() -> void:
			_bgm_player.stop()
			_bgm_player.stream = stream
			_bgm_player.volume_db = -80.0
			_bgm_player.play()
		)
		_bgm_tween.tween_property(_bgm_player, "volume_db", _volume_db(bgm_volume_value), BGM_FADE_TIME)
	else:
		_bgm_player.stream = stream
		_bgm_player.volume_db = -80.0
		_bgm_player.play()
		_fade_bgm_to(_volume_db(bgm_volume_value), BGM_FADE_TIME)

func stop_bgm() -> void:
	_bgm_path = ""
	if _bgm_tween != null:
		_bgm_tween.kill()
	if not _bgm_player.playing:
		_bgm_player.stream = null
		return
	_bgm_tween = create_tween()
	_bgm_tween.tween_property(_bgm_player, "volume_db", -80.0, BGM_FADE_TIME * 0.75)
	_bgm_tween.tween_callback(func() -> void:
		_bgm_player.stop()
		_bgm_player.stream = null
	)

func play_button() -> void:
	_play_one_shot(BUTTON_PATH)

func play_eat() -> void:
	_play_one_shot(EAT_PATH)

func play_death() -> void:
	_play_one_shot(DEATH_PATH)

func play_explosion() -> void:
	_play_one_shot(EXPLOSION_PATH)

func _on_bgm_volume_changed(value: float) -> void:
	bgm_volume_value = value
	if _bgm_player != null and _bgm_player.playing:
		_fade_bgm_to(_volume_db(bgm_volume_value), 0.18)

func _on_sfx_volume_changed(value: float) -> void:
	sfx_volume_value = value
	for player in _one_shot_players:
		player.volume_db = _volume_db(sfx_volume_value)

func _on_sound_on_changed(enabled: bool) -> void:
	sound_on_value = enabled

func _play_one_shot(path: String) -> void:
	if not _can_play_audio():
		return
	var stream := _load_stream(path)
	if stream == null:
		return
	var player := _get_one_shot_player()
	player.stream = stream
	player.bus = "Master"
	player.volume_db = _volume_db(sfx_volume_value)
	player.play()

func _load_stream(path: String) -> AudioStream:
	if _stream_cache.has(path):
		return _stream_cache[path]
	var stream: AudioStream = load(path)
	if stream != null:
		_stream_cache[path] = stream
	return stream

func _get_one_shot_player() -> AudioStreamPlayer:
	for player in _one_shot_players:
		if not player.playing:
			return player
	if _one_shot_players.size() < ONE_SHOT_POOL_LIMIT:
		var player := AudioStreamPlayer.new()
		player.name = "OneShotPlayer%d" % _one_shot_players.size()
		player.bus = "Master"
		add_child(player)
		_one_shot_players.append(player)
		return player
	var fallback := _one_shot_players[0]
	fallback.stop()
	return fallback

func _can_play_audio() -> bool:
	return sound_on_value and DisplayServer.get_name() != "headless"

func _fade_bgm_to(target_db: float, duration: float) -> void:
	if _bgm_player == null:
		return
	if _bgm_tween != null:
		_bgm_tween.kill()
	_bgm_tween = create_tween()
	_bgm_tween.tween_property(_bgm_player, "volume_db", target_db, duration)

func _volume_db(value: float) -> float:
	var clamped := clampf(value, 0.0, 1.0)
	return -80.0 if clamped <= 0.001 else linear_to_db(clamped)
