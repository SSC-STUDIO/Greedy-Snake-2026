class_name WeatherFx
extends CanvasLayer
## Screen-space pixel rain. Alpha follows WorldClock.rain_opacity();
## missing art degrades to generated 2×6 drops. No ColorRect rain sheets.

const DROP_COUNT := 52
const FALL_SPEED := 240.0
const WIND := 36.0

var _drops: Array[Sprite2D] = []
var _alpha := 0.0
var _tex: Texture2D


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


func _process(delta: float) -> void:
	var target := WorldClock.rain_opacity()
	_alpha = move_toward(_alpha, target, delta / 4.5)
	if _alpha <= 0.001 and target <= 0.0:
		for spr in _drops:
			if spr.modulate.a > 0.0:
				spr.modulate.a = 0.0
		return
	var vis := _alpha * 0.58
	for spr in _drops:
		var p := spr.position
		p.y += FALL_SPEED * delta
		p.x -= WIND * delta
		if p.y > 728.0:
			p.y = -8.0
			p.x = randf() * 1280.0
		elif p.x < -8.0:
			p.x = 1288.0
		spr.position = Vector2(roundf(p.x), roundf(p.y))
		spr.modulate = Color(0.78, 0.84, 0.92, vis)


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
