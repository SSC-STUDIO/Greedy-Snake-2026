extends Node
## WorldClock autoload: cemetery day/night + a small gothic weather machine.
## Do not give this script a class_name — the autoload name is the API.
##
## Full cycle is 20 real minutes (day → night ≈ 10). Pause, Director playback,
## choice hold, fades, and the title menu freeze the clock so sky contrast
## never fights a fade or a pause overlay.

enum Phase { DAWN, DAY, DUSK, NIGHT }
enum Weather { HAZE, RAIN, FOG, EMBER_WIND, RUST_RAIN }
enum Zone { OUTDOORS, INDOORS }

signal phase_changed(phase: int)
signal weather_changed(weather: int)
signal zone_changed(zone: int)
signal clock_ticked(time_of_day: float, phase: int)
signal wind_changed(heading: float, speed: float)

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
## Indoor lock: warm furnace, never as dark as outdoor night.
const INDOOR_TINT := Color(0.90, 0.78, 0.66)
const RUST_RAIN_INTERVAL := 1.6
const RUST_RAIN_EXPOSE := 8.0
const BREEZE_BASE := 0.22
const INDOOR_WIND_FADE := 1.5
const HEADING_TURN := 42.0

var time_of_day: float = DEFAULT_TIME
var phase: int = Phase.DAY
var weather: int = Weather.HAZE
var previous_weather: int = Weather.HAZE
var weather_blend: float = 1.0
var zone: int = Zone.OUTDOORS
var menu_hold: bool = false
## Test-only multiplier; gameplay stays at 1.
var time_scale: float = 1.0
## -1 left / +1 right. Presentation nodes read wind_vector(), never sprites here.
var wind_heading: float = -1.0
var wind_speed: float = BREEZE_BASE
var gust: float = 1.0

var _weather_hold: float = 80.0
var _blend_duration: float = 5.0
var _tick_emit: float = 0.0
var _rust_accum: float = 0.0
var _zone_depth: int = 0
var _heading_target: float = -1.0
var _heading_hold: float = 48.0
var _gust_t: float = 0.0
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
	var scaled := delta * time_scale
	tick(scaled)
	_tick_hazards(scaled)


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
	_tick_wind(delta)
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
	menu_hold = false
	time_of_day = DEFAULT_TIME
	phase = phase_at(time_of_day)
	weather = Weather.HAZE
	previous_weather = Weather.HAZE
	weather_blend = 1.0
	_zone_depth = 0
	set_zone(Zone.OUTDOORS)
	wind_heading = -1.0
	_heading_target = -1.0
	_heading_hold = 48.0
	_gust_t = 0.0
	gust = 1.0
	_snap_wind_speed()
	_weather_hold = _rng.randf_range(WEATHER_HOLD_MIN, WEATHER_HOLD_MAX)
	_blend_duration = _rng.randf_range(BLEND_MIN, BLEND_MAX)
	_tick_emit = 0.0
	_rust_accum = 0.0
	time_scale = 1.0


func set_zone(next_zone: int) -> void:
	var z := Zone.INDOORS if next_zone == Zone.INDOORS else Zone.OUTDOORS
	if z == zone:
		return
	zone = z
	zone_changed.emit(zone)


func enter_zone(next_zone: int) -> void:
	_zone_depth += 1
	set_zone(next_zone)


func leave_zone() -> void:
	_zone_depth = maxi(0, _zone_depth - 1)
	if _zone_depth <= 0:
		set_zone(Zone.OUTDOORS)


func zone_id() -> String:
	return "indoors" if zone == Zone.INDOORS else "outdoors"


func isolate_ui_layer(layer: CanvasLayer) -> void:
	if layer == null:
		return
	layer.follow_viewport_enabled = false
	if layer.is_inside_tree():
		RenderingServer.canvas_set_modulate(layer.get_canvas(), Color.WHITE)
	for child in layer.get_children():
		if child is CanvasItem:
			(child as CanvasItem).modulate = Color.WHITE


func hold_for_menu() -> void:
	menu_hold = true
	_zone_depth = 0
	set_zone(Zone.OUTDOORS)
	set_time(TITLE_TIME)
	set_weather(Weather.HAZE, true)
	_snap_wind_speed()


func release_menu() -> void:
	menu_hold = false


func snapshot() -> Dictionary:
	return {
		"time_of_day": time_of_day,
		"weather": weather_id(),
		"phase": phase_id(),
		"zone": zone_id(),
		"wind_heading": wind_heading,
	}


func apply_snapshot(data: Dictionary) -> void:
	set_time(float(data.get("time_of_day", DEFAULT_TIME)))
	set_weather(weather_from_id(String(data.get("weather", "haze"))), true)
	if String(data.get("zone", "outdoors")) == "indoors":
		set_zone(Zone.INDOORS)
	else:
		set_zone(Zone.OUTDOORS)
	var heading := float(data.get("wind_heading", wind_heading))
	wind_heading = -1.0 if heading < 0.0 else 1.0
	_heading_target = wind_heading
	_snap_wind_speed()


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
		Weather.RUST_RAIN:
			return "rust_rain"
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
		"rust_rain":
			return Weather.RUST_RAIN
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
		Weather.RUST_RAIN:
			return "锈雨"
		_:
			return "薄雾"


func hud_line() -> String:
	return "%s · %s" % [weather_label(), phase_label()]


func mood_tint() -> Color:
	if zone == Zone.INDOORS:
		return _indoor_tint()
	var a := _phase_tint(phase)
	var b := _weather_mul(_blend_weather())
	return Color(a.r * b.r, a.g * b.g, a.b * b.b, 1.0)


func _indoor_tint() -> Color:
	var b := _weather_mul(_blend_weather())
	var c := Color(INDOOR_TINT.r * b.r, INDOOR_TINT.g * b.g, INDOOR_TINT.b * b.b, 1.0)
	c.r = maxf(c.r, 0.78)
	c.g = maxf(c.g, 0.68)
	c.b = maxf(c.b, 0.56)
	return c


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
	elif w == Weather.RUST_RAIN:
		faded = 0.70
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


func weather_weight(kind: int) -> float:
	var from_w := 1.0 if previous_weather == kind else 0.0
	var to_w := 1.0 if weather == kind else 0.0
	return lerpf(from_w, to_w, clampf(weather_blend, 0.0, 1.0))


func weather_fx_allowed() -> bool:
	return zone == Zone.OUTDOORS and not menu_hold


func rain_opacity() -> float:
	if not weather_fx_allowed():
		return 0.0
	return clampf(weather_weight(Weather.RAIN) + weather_weight(Weather.RUST_RAIN), 0.0, 1.0)


func ember_wind_opacity() -> float:
	if not weather_fx_allowed():
		return 0.0
	return weather_weight(Weather.EMBER_WIND)


## 1 when rust rain is fully in; night also upgrades ordinary rain.
func rust_rain_mix() -> float:
	var rust := weather_weight(Weather.RUST_RAIN)
	if phase == Phase.NIGHT:
		rust = maxf(rust, weather_weight(Weather.RAIN) * 0.90)
	return rust


func is_rust_raining() -> bool:
	return rust_rain_mix() >= 0.45


func rust_rain_applies() -> bool:
	if is_frozen() or menu_hold:
		return false
	if zone != Zone.OUTDOORS:
		return false
	return is_rust_raining()


func apply_rust_rain_expose(player: Node = null) -> bool:
	if not rust_rain_applies():
		return false
	var p := player as Player
	if p == null:
		p = _find_player()
	if p == null or p.toxin == null or p.health == null:
		return false
	if p.health.current <= 0:
		return false
	p.toxin.expose(RUST_RAIN_EXPOSE)
	return true


func rain_audio_gain() -> float:
	var clear := maxf(weather_weight(Weather.RAIN) - rust_rain_mix(), 0.0)
	return _audio_gate(clear)


func rust_rain_audio_gain() -> float:
	return _audio_gate(rust_rain_mix())


func drone_audio_gain() -> float:
	if menu_hold:
		return 0.0
	var g := 0.22
	if zone == Zone.INDOORS:
		g = 0.10
	g *= 0.85 + 0.15 * clampf(gust, 0.7, 1.25)
	if is_inside_tree():
		var tree := get_tree()
		if tree != null and tree.paused:
			g *= 0.35
	return g


func wind_vector() -> Vector2:
	return Vector2(wind_heading * wind_speed * gust, 0.0)


func sway_radians() -> float:
	return deg_to_rad(3.4) * wind_heading * wind_speed * gust


func is_breeze_active() -> bool:
	return wind_speed > 0.04


func weather_wind_speed() -> float:
	var s := BREEZE_BASE
	s += weather_weight(Weather.RAIN) * 0.28
	s += weather_weight(Weather.RUST_RAIN) * 0.32
	s += weather_weight(Weather.EMBER_WIND) * 0.48
	s -= weather_weight(Weather.FOG) * 0.10
	return clampf(s, 0.08, 0.85)


func _tick_wind(delta: float) -> void:
	if delta <= 0.0:
		return
	_gust_t += delta
	gust = clampf(0.92 + 0.18 * sin(_gust_t * 0.37) + 0.10 * sin(_gust_t * 0.91), 0.70, 1.25)
	_heading_hold -= delta
	if _heading_hold <= 0.0:
		if _rng.randf() < 0.55:
			_heading_target = -_heading_target
		_heading_hold = _rng.randf_range(36.0, 72.0)
	wind_heading = move_toward(wind_heading, _heading_target, delta / HEADING_TURN * 2.0)
	var target := 0.0 if (zone == Zone.INDOORS or menu_hold) else weather_wind_speed()
	var prev := wind_speed
	wind_speed = move_toward(wind_speed, target, delta / INDOOR_WIND_FADE)
	if absf(prev - wind_speed) > 0.04 or absf(wind_heading - _heading_target) < 0.01:
		wind_changed.emit(wind_heading, wind_speed)


func _snap_wind_speed() -> void:
	gust = 1.0
	if zone == Zone.INDOORS or menu_hold:
		wind_speed = 0.0
	else:
		wind_speed = weather_wind_speed()
	wind_changed.emit(wind_heading, wind_speed)


func _audio_gate(amount: float) -> float:
	if menu_hold:
		return 0.0
	var g := clampf(amount, 0.0, 1.0)
	if zone == Zone.INDOORS:
		g *= 0.12
	if is_inside_tree():
		var tree := get_tree()
		if tree != null and tree.paused:
			g *= 0.08
	return g


func _tick_hazards(delta: float) -> void:
	if not rust_rain_applies():
		_rust_accum = 0.0
		return
	_rust_accum += delta
	if _rust_accum < RUST_RAIN_INTERVAL:
		return
	_rust_accum = 0.0
	apply_rust_rain_expose()


func _find_player() -> Player:
	if not is_inside_tree():
		return null
	return get_tree().get_first_node_in_group("player") as Player


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
			if r < 0.42:
				next = Weather.FOG
			elif r < 0.64:
				next = Weather.HAZE
			elif r < 0.86:
				next = Weather.RUST_RAIN
			elif r < 0.95:
				next = Weather.RAIN
			else:
				next = Weather.EMBER_WIND
		Phase.DUSK, Phase.DAWN:
			if r < 0.30:
				next = Weather.FOG
			elif r < 0.56:
				next = Weather.HAZE
			elif r < 0.78:
				next = Weather.RAIN
			elif r < 0.92:
				next = Weather.RUST_RAIN
			else:
				next = Weather.EMBER_WIND
		_:
			if r < 0.48:
				next = Weather.HAZE
			elif r < 0.76:
				next = Weather.RAIN
			elif r < 0.88:
				next = Weather.FOG
			elif r < 0.96:
				next = Weather.RUST_RAIN
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
		Weather.RUST_RAIN:
			return Color(0.90, 0.84, 0.78)
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
		Weather.RUST_RAIN:
			return rain + 0.04
		_:
			return haze


func _clamp_weather(w: int) -> int:
	if w < 0 or w > Weather.RUST_RAIN:
		return Weather.HAZE
	return w
