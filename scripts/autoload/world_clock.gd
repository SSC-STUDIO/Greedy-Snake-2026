extends Node
## WorldClock autoload: cemetery day/night + a small gothic weather machine.
## Do not give this script a class_name — the autoload name is the API.
##
## Full cycle is 20 real minutes (day → night ≈ 10). Pause, Director playback,
## choice hold, fades, and the title menu freeze the clock so sky contrast
## never fights a fade or a pause overlay.

enum Phase { DAWN, DAY, DUSK, NIGHT }
enum Weather { HAZE, RAIN, FOG, EMBER_WIND }

signal phase_changed(phase: int)
signal weather_changed(weather: int)
signal clock_ticked(time_of_day: float, phase: int)

## 20 min around the clock; 昼→夜 lands near the 8–12 min brief.
const CYCLE_SECONDS := 1200.0
const DEFAULT_TIME := 0.28
const TITLE_TIME := 0.56
const TICK_INTERVAL := 0.25
const WEATHER_HOLD_MIN := 50.0
const WEATHER_HOLD_MAX := 110.0
const BLEND_MIN := 3.0
const BLEND_MAX := 8.0

## Playable luminance floor for MoodTint (never a black frame).
const NIGHT_TINT := Color(0.64, 0.60, 0.78)
const DAY_TINT := Color(0.955, 0.92, 1.0)
const DAWN_TINT := Color(0.86, 0.82, 0.94)
const DUSK_TINT := Color(0.80, 0.70, 0.76)

var time_of_day: float = DEFAULT_TIME
var phase: int = Phase.DAY
var weather: int = Weather.HAZE
var previous_weather: int = Weather.HAZE
var weather_blend: float = 1.0
var menu_hold: bool = false
## Test-only multiplier; gameplay stays at 1.
var time_scale: float = 1.0

var _weather_hold: float = 80.0
var _blend_duration: float = 5.0
var _tick_emit: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	phase = phase_at(time_of_day)
	_weather_hold = _rng.randf_range(WEATHER_HOLD_MIN, WEATHER_HOLD_MAX)
	_blend_duration = _rng.randf_range(BLEND_MIN, BLEND_MAX)


func _process(delta: float) -> void:
	if is_frozen():
		return
	tick(delta * time_scale)


func is_frozen() -> bool:
	if menu_hold:
		return true
	if not is_inside_tree():
		return false
	var tree := get_tree()
	if tree != null and tree.paused:
		return true
	if Director.playing or Director.choice_hold or Director.is_fading():
		return true
	return false


## Advance the clock. Used by _process and by tests (call while unfrozen).
func tick(delta: float) -> void:
	if delta <= 0.0:
		return
	time_of_day = fposmod(time_of_day + delta / CYCLE_SECONDS, 1.0)
	_refresh_phase()
	_tick_weather(delta)
	_tick_emit += delta
	if _tick_emit >= TICK_INTERVAL:
		_tick_emit = 0.0
		clock_ticked.emit(time_of_day, phase)


## Test helper: jump forward without waiting out the 20-minute cycle.
func advance(seconds: float) -> void:
	tick(maxf(0.0, seconds))


func set_time(t: float) -> void:
	time_of_day = fposmod(t, 1.0)
	_refresh_phase()
	clock_ticked.emit(time_of_day, phase)


func set_weather(next_weather: int, instant: bool = false) -> void:
	var w := _clamp_weather(next_weather)
	if instant:
		previous_weather = w
		weather = w
		weather_blend = 1.0
		weather_changed.emit(weather)
		return
	if w == weather and weather_blend >= 1.0:
		return
	previous_weather = weather
	weather = w
	weather_blend = 0.0
	_blend_duration = _rng.randf_range(BLEND_MIN, BLEND_MAX)
	weather_changed.emit(weather)


func set_weather_hold(seconds: float) -> void:
	_weather_hold = maxf(0.0, seconds)
	if weather_blend < 1.0:
		weather_blend = 1.0


func reset() -> void:
	time_of_day = DEFAULT_TIME
	phase = phase_at(time_of_day)
	weather = Weather.HAZE
	previous_weather = Weather.HAZE
	weather_blend = 1.0
	_weather_hold = _rng.randf_range(WEATHER_HOLD_MIN, WEATHER_HOLD_MAX)
	_blend_duration = _rng.randf_range(BLEND_MIN, BLEND_MAX)
	_tick_emit = 0.0
	time_scale = 1.0


func hold_for_menu() -> void:
	menu_hold = true
	set_time(TITLE_TIME)
	set_weather(Weather.HAZE, true)


func release_menu() -> void:
	menu_hold = false


func snapshot() -> Dictionary:
	return {
		"time_of_day": time_of_day,
		"weather": weather_id(),
		"phase": phase_id(),
	}


func apply_snapshot(data: Dictionary) -> void:
	set_time(float(data.get("time_of_day", DEFAULT_TIME)))
	set_weather(weather_from_id(String(data.get("weather", "haze"))), true)


func phase_at(t: float) -> int:
	var x := fposmod(t, 1.0)
	if x < 0.12:
		return Phase.DAWN
	if x < 0.50:
		return Phase.DAY
	if x < 0.62:
		return Phase.DUSK
	return Phase.NIGHT


func phase_id() -> String:
	match phase:
		Phase.DAWN:
			return "dawn"
		Phase.DUSK:
			return "dusk"
		Phase.NIGHT:
			return "night"
		_:
			return "day"


func phase_label() -> String:
	match phase:
		Phase.DAWN:
			return "黎明"
		Phase.DUSK:
			return "黄昏"
		Phase.NIGHT:
			return "夜晚"
		_:
			return "白昼"


func weather_id() -> String:
	match weather:
		Weather.RAIN:
			return "rain"
		Weather.FOG:
			return "fog"
		Weather.EMBER_WIND:
			return "ember_wind"
		_:
			return "haze"


func weather_from_id(id: String) -> int:
	match id:
		"rain":
			return Weather.RAIN
		"fog":
			return Weather.FOG
		"ember_wind":
			return Weather.EMBER_WIND
		_:
			return Weather.HAZE


func weather_label() -> String:
	return _weather_label(weather)


func _weather_label(w: int) -> String:
	match w:
		Weather.RAIN:
			return "雨"
		Weather.FOG:
			return "浓雾"
		Weather.EMBER_WIND:
			return "余烬风"
		_:
			return "薄雾"


func hud_line() -> String:
	return "%s · %s" % [weather_label(), phase_label()]


func mood_tint() -> Color:
	var a := _phase_tint(phase)
	var b := _weather_mul(_blend_weather())
	return Color(a.r * b.r, a.g * b.g, a.b * b.b, 1.0)


func mood_luminance() -> float:
	var c := mood_tint()
	return (c.r + c.g + c.b) / 3.0


func fog_far_alpha() -> float:
	return _fog_alpha(0.13, 0.22, 0.34, 0.16)


func fog_near_alpha() -> float:
	return _fog_alpha(0.20, 0.32, 0.46, 0.22)


func silhouette_modulate() -> Color:
	var faded := 1.0
	var w := _blend_weather()
	if w == Weather.FOG:
		faded = 0.52
	elif w == Weather.RAIN:
		faded = 0.78
	elif w == Weather.EMBER_WIND:
		faded = 0.90
	if phase == Phase.NIGHT:
		faded *= 0.82
	return Color(1, 1, 1, clampf(faded, 0.40, 1.0))


func sky_modulate() -> Color:
	match phase:
		Phase.DAWN:
			return Color(0.90, 0.86, 1.0)
		Phase.DUSK:
			return Color(1.02, 0.82, 0.78)
		Phase.NIGHT:
			return Color(0.72, 0.70, 0.92)
		_:
			return Color(1, 1, 1)


func nest_light_energy() -> float:
	match phase:
		Phase.NIGHT:
			return 1.05
		Phase.DUSK:
			return 0.70
		Phase.DAWN:
			return 0.34
		_:
			return 0.14


func nest_light_radius() -> float:
	match phase:
		Phase.NIGHT:
			return 88.0
		Phase.DUSK:
			return 72.0
		Phase.DAWN:
			return 56.0
		_:
			return 48.0


func rain_opacity() -> float:
	var from_rain := 1.0 if previous_weather == Weather.RAIN else 0.0
	var to_rain := 1.0 if weather == Weather.RAIN else 0.0
	return lerpf(from_rain, to_rain, clampf(weather_blend, 0.0, 1.0))


func _refresh_phase() -> void:
	var next := phase_at(time_of_day)
	if next == phase:
		return
	phase = next
	phase_changed.emit(phase)


func _tick_weather(delta: float) -> void:
	if weather_blend < 1.0:
		weather_blend = minf(1.0, weather_blend + delta / maxf(_blend_duration, 0.05))
		return
	_weather_hold -= delta
	if _weather_hold > 0.0:
		return
	# Cutscenes already freeze the whole clock; this is the extra latch so a
	# hold that expires on the first unfrozen frame cannot hard-cut weather.
	if Director.playing or Director.choice_hold or Director.is_fading():
		return
	set_weather(_pick_weather(), false)
	_weather_hold = _rng.randf_range(WEATHER_HOLD_MIN, WEATHER_HOLD_MAX)


func _pick_weather() -> int:
	var r := _rng.randf()
	var next := weather
	match phase:
		Phase.NIGHT:
			if r < 0.50:
				next = Weather.FOG
			elif r < 0.80:
				next = Weather.HAZE
			elif r < 0.95:
				next = Weather.RAIN
			else:
				next = Weather.EMBER_WIND
		Phase.DUSK, Phase.DAWN:
			if r < 0.32:
				next = Weather.FOG
			elif r < 0.62:
				next = Weather.HAZE
			elif r < 0.90:
				next = Weather.RAIN
			else:
				next = Weather.EMBER_WIND
		_:
			if r < 0.52:
				next = Weather.HAZE
			elif r < 0.84:
				next = Weather.RAIN
			elif r < 0.97:
				next = Weather.FOG
			else:
				next = Weather.EMBER_WIND
	if next == weather:
		next = Weather.HAZE if weather != Weather.HAZE else Weather.FOG
	return next


func _phase_tint(p: int) -> Color:
	match p:
		Phase.DAWN:
			return DAWN_TINT
		Phase.DUSK:
			return DUSK_TINT
		Phase.NIGHT:
			return NIGHT_TINT
		_:
			return DAY_TINT


func _weather_mul(w: int) -> Color:
	match w:
		Weather.RAIN:
			return Color(0.94, 0.95, 0.98)
		Weather.FOG:
			return Color(0.90, 0.90, 0.96)
		Weather.EMBER_WIND:
			return Color(1.04, 0.92, 0.86)
		_:
			return Color(1, 1, 1)


func _blend_weather() -> int:
	if weather_blend < 0.5:
		return previous_weather
	return weather


func _fog_alpha(haze: float, rain: float, fog: float, ember: float) -> float:
	var from_a := _weather_fog(previous_weather, haze, rain, fog, ember)
	var to_a := _weather_fog(weather, haze, rain, fog, ember)
	var a := lerpf(from_a, to_a, clampf(weather_blend, 0.0, 1.0))
	if phase == Phase.NIGHT:
		a += 0.06
	elif phase == Phase.DUSK or phase == Phase.DAWN:
		a += 0.03
	return clampf(a, 0.08, 0.55)


func _weather_fog(w: int, haze: float, rain: float, fog: float, ember: float) -> float:
	match w:
		Weather.RAIN:
			return rain
		Weather.FOG:
			return fog
		Weather.EMBER_WIND:
			return ember
		_:
			return haze


func _clamp_weather(w: int) -> int:
	if w < 0 or w > Weather.EMBER_WIND:
		return Weather.HAZE
	return w
