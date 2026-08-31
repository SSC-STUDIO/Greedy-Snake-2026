class_name WeatherFx
extends CanvasLayer
## Screen-space weather: rain / rust rain streaks + horizontal ember motes.
## Alpha follows WorldClock; indoor / title / menu hide particles.

const DROP_COUNT := 52
const FALL_SPEED := 240.0
const EMBER_COUNT := 20
const EMBER_PATH := "res://assets/ui/ember_motes.png"
const EMBER_FRAMES := 8
const EMBER_DRIFT := 78.0

var _drops: Array[Sprite2D] = []
var _embers: Array[Sprite2D] = []
var _alpha := 0.0
var _ember_alpha := 0.0
var _tex: Texture2D
var _ember_tex: Texture2D


func _ready() -> void:
	layer = 4
	follow_viewport_enabled = false
	if DisplayServer.get_name() == "headless":
		set_process(false)
		return
	_tex = _make_drop_tex()
	for i in DROP_COUNT:
		var spr := Sprite2D.new()
		spr.texture = _tex
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.centered = true
		spr.position = Vector2(randf() * 1280.0, randf() * 720.0)
		spr.modulate = Color(0.78, 0.84, 0.92, 0.0)
		add_child(spr)
		_drops.append(spr)
	_ember_tex = _load_ember_tex()
	for i in EMBER_COUNT:
		var spr := Sprite2D.new()
		spr.texture = _ember_tex
		if _ember_tex != null and _ember_tex.get_width() >= EMBER_FRAMES:
			spr.hframes = EMBER_FRAMES
			spr.frame = randi() % EMBER_FRAMES
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.centered = true
		spr.position = Vector2(randf() * 1280.0, randf() * 720.0)
		spr.modulate = Color(1.0, 0.62, 0.38, 0.0)
		spr.scale = Vector2(0.85, 0.85)
		add_child(spr)
		_embers.append(spr)


func _process(delta: float) -> void:
	var target := WorldClock.rain_opacity()
	_alpha = move_toward(_alpha, target, delta / 4.5)
	var rust := WorldClock.rust_rain_mix() if WorldClock.weather_fx_allowed() else 0.0
	var rain_col := Color(0.78, 0.84, 0.92).lerp(Color(0.80, 0.48, 0.34), clampf(rust, 0.0, 1.0))
	if _alpha <= 0.001 and target <= 0.0:
		for spr in _drops:
			if spr.modulate.a > 0.0:
				spr.modulate.a = 0.0
	else:
		var vis := _alpha * 0.58
		for spr in _drops:
			var p := spr.position
			p.y += FALL_SPEED * delta
			p.x += rain_wind_x() * delta
			if p.y > 728.0:
				p.y = -8.0
				p.x = randf() * 1280.0
			elif p.x < -8.0:
				p.x = 1288.0
			spr.position = Vector2(roundf(p.x), roundf(p.y))
			spr.modulate = Color(rain_col.r, rain_col.g, rain_col.b, vis)
	_tick_embers(delta)


func _tick_embers(delta: float) -> void:
	var target := WorldClock.ember_wind_opacity()
	_ember_alpha = move_toward(_ember_alpha, target, delta / 4.0)
	if _ember_alpha <= 0.001 and target <= 0.0:
		for spr in _embers:
			if spr.modulate.a > 0.0:
				spr.modulate.a = 0.0
		return
	var vis := _ember_alpha * 0.28
	for spr in _embers:
		var p := spr.position
		p.x += rain_wind_x() * (EMBER_DRIFT / 36.0) * delta
		p.y += sin(p.x * 0.04 + p.y * 0.01) * 10.0 * delta
		if p.x < -10.0:
			p.x = 1290.0
			p.y = randf() * 720.0
		elif p.y < -10.0:
			p.y = 728.0
		elif p.y > 730.0:
			p.y = -8.0
		spr.position = Vector2(roundf(p.x), roundf(p.y))
		if spr.hframes > 1 and randf() < delta * 6.0:
			spr.frame = (spr.frame + 1) % spr.hframes
		spr.modulate = Color(1.0, 0.62, 0.38, vis)


func rain_wind_x() -> float:
	var v := WorldClock.wind_vector().x
	if absf(v) < 0.02:
		return -36.0
	return v * 150.0


func _load_ember_tex() -> Texture2D:
	if ResourceLoader.exists(EMBER_PATH):
		var tex := load(EMBER_PATH) as Texture2D
		if tex != null:
			return tex
	return _make_ember_tex()


func _make_ember_tex() -> Texture2D:
	var img := Image.create(3, 3, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	img.set_pixel(1, 1, Color(1.0, 0.62, 0.34, 0.85))
	img.set_pixel(1, 0, Color(1.0, 0.78, 0.42, 0.45))
	img.set_pixel(0, 1, Color(0.90, 0.40, 0.22, 0.35))
	return ImageTexture.create_from_image(img)


func _make_drop_tex() -> Texture2D:
	var img := Image.create(2, 6, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	img.set_pixel(0, 0, Color(0.70, 0.78, 0.88, 0.25))
	img.set_pixel(1, 1, Color(0.82, 0.88, 0.94, 0.55))
	img.set_pixel(0, 2, Color(0.88, 0.92, 0.97, 0.70))
	img.set_pixel(1, 3, Color(0.85, 0.90, 0.96, 0.50))
	img.set_pixel(0, 4, Color(0.78, 0.84, 0.92, 0.28))
	img.set_pixel(1, 5, Color(0.72, 0.80, 0.90, 0.12))
	return ImageTexture.create_from_image(img)
