extends Node

const GameConfigData := preload("res://scripts/data/GameConfig.gd")
const SAVE_PATH := "user://greedy_snake_2026_settings.cfg"

var volume := GameConfigData.DEFAULT_VOLUME
var bgm_volume := 0.78
var sfx_volume := 0.9
var difficulty := 1
var sound_on := true
var snake_speed := 1
var animations_on := true
var anti_aliasing_on := true
var fullscreen_on := false
var effects_quality := 2
var screen_shake_on := true
var minimap_on := true
var minimap_size := 1

func _ready() -> void:
	load_settings()
	_apply_window_mode()
	_apply_audio_volume()
	_apply_antialiasing()

func get_snapshot() -> Dictionary:
	return {
		"volume": volume,
		"bgm_volume": bgm_volume,
		"sfx_volume": sfx_volume,
		"difficulty": difficulty,
		"sound_on": sound_on,
		"snake_speed": snake_speed,
		"animations_on": animations_on,
		"anti_aliasing_on": anti_aliasing_on,
		"fullscreen_on": fullscreen_on,
		"effects_quality": effects_quality,
		"screen_shake_on": screen_shake_on,
		"minimap_on": minimap_on,
		"minimap_size": minimap_size,
	}

func load_settings() -> void:
	var config := ConfigFile.new()
	var result := config.load(SAVE_PATH)
	if result != OK:
		return

	volume = clampf(float(config.get_value("audio", "volume", volume)), 0.0, 1.0)
	bgm_volume = clampf(float(config.get_value("audio", "bgm_volume", bgm_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(config.get_value("audio", "sfx_volume", sfx_volume)), 0.0, 1.0)
	sound_on = bool(config.get_value("audio", "sound_on", sound_on))
	difficulty = GameConfigData.clamp_difficulty(int(config.get_value("game", "difficulty", difficulty)))
	snake_speed = GameConfigData.clamp_speed(int(config.get_value("game", "snake_speed", snake_speed)))
	animations_on = bool(config.get_value("display", "animations_on", animations_on))
	anti_aliasing_on = bool(config.get_value("display", "anti_aliasing_on", anti_aliasing_on))
	fullscreen_on = bool(config.get_value("display", "fullscreen_on", fullscreen_on))
	effects_quality = GameConfigData.clamp_effects_quality(int(config.get_value("display", "effects_quality", effects_quality)))
	screen_shake_on = bool(config.get_value("display", "screen_shake_on", screen_shake_on))
	minimap_on = bool(config.get_value("display", "minimap_on", minimap_on))
	minimap_size = GameConfigData.clamp_minimap_size(int(config.get_value("display", "minimap_size", minimap_size)))

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "volume", volume)
	config.set_value("audio", "bgm_volume", bgm_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "sound_on", sound_on)
	config.set_value("game", "difficulty", difficulty)
	config.set_value("game", "snake_speed", snake_speed)
	config.set_value("display", "animations_on", animations_on)
	config.set_value("display", "anti_aliasing_on", anti_aliasing_on)
	config.set_value("display", "fullscreen_on", fullscreen_on)
	config.set_value("display", "effects_quality", effects_quality)
	config.set_value("display", "screen_shake_on", screen_shake_on)
	config.set_value("display", "minimap_on", minimap_on)
	config.set_value("display", "minimap_size", minimap_size)
	config.save(SAVE_PATH)

func set_volume(value: float) -> void:
	volume = clampf(value, 0.0, 1.0)
	_apply_audio_volume()
	save_settings()

func set_bgm_volume(value: float) -> void:
	bgm_volume = clampf(value, 0.0, 1.0)
	AudioBus.refresh_volumes()
	save_settings()

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	AudioBus.refresh_volumes()
	save_settings()

func set_sound_on(enabled: bool) -> void:
	sound_on = enabled
	_apply_audio_volume()
	save_settings()

func set_difficulty(value: int) -> void:
	difficulty = GameConfigData.clamp_difficulty(value)
	save_settings()

func set_snake_speed(value: int) -> void:
	snake_speed = GameConfigData.clamp_speed(value)
	save_settings()

func set_animations_on(enabled: bool) -> void:
	animations_on = enabled
	save_settings()

func set_effects_quality(value: int) -> void:
	effects_quality = GameConfigData.clamp_effects_quality(value)
	save_settings()

func set_anti_aliasing_on(enabled: bool) -> void:
	anti_aliasing_on = enabled
	_apply_antialiasing()
	save_settings()

func set_fullscreen_on(enabled: bool) -> void:
	fullscreen_on = enabled
	_apply_window_mode()
	save_settings()

func set_screen_shake_on(enabled: bool) -> void:
	screen_shake_on = enabled
	save_settings()

func set_minimap_on(enabled: bool) -> void:
	minimap_on = enabled
	save_settings()

func set_minimap_size(value: int) -> void:
	minimap_size = GameConfigData.clamp_minimap_size(value)
	save_settings()

func reset_to_defaults() -> void:
	volume = GameConfigData.DEFAULT_VOLUME
	bgm_volume = 0.78
	sfx_volume = 0.9
	difficulty = 1
	sound_on = true
	snake_speed = 1
	animations_on = true
	anti_aliasing_on = true
	fullscreen_on = false
	effects_quality = 2
	screen_shake_on = true
	minimap_on = true
	minimap_size = 1
	_apply_window_mode()
	_apply_audio_volume()
	_apply_antialiasing()
	AudioBus.refresh_volumes()
	save_settings()

func _apply_audio_volume() -> void:
	var bus_index := AudioServer.get_bus_index("Master")
	if bus_index < 0:
		return
	var effective_volume := volume if sound_on else 0.0
	AudioServer.set_bus_volume_db(bus_index, -80.0 if effective_volume <= 0.001 else linear_to_db(effective_volume))

func _apply_window_mode() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen_on else DisplayServer.WINDOW_MODE_WINDOWED)

func _apply_antialiasing() -> void:
	var viewport := get_viewport()
	if viewport == null:
		return
	viewport.msaa_2d = Viewport.MSAA_4X if anti_aliasing_on else Viewport.MSAA_DISABLED
