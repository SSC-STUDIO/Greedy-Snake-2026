class_name CineFx
extends Node2D
## World-space depth dust / scrap plus a faint moon shaft.
## Presentation only — wind and zone come from WorldClock.

const FAR_COUNT := 22
const MID_COUNT := 22
const NEAR_COUNT := 12
const MOTE_PATH := "res://assets/ui/ember_motes.png"

var _far: Array[Sprite2D] = []
var _mid: Array[Sprite2D] = []
var _near: Array[Sprite2D] = []
var _shaft: Sprite2D
var _mote_tex: Texture2D
var _headless := false


func _ready() -> void:
	z_index = 3
	_headless = DisplayServer.get_name() == "headless"
	_mote_tex = _load_motes()
	_shaft = Sprite2D.new()
	_shaft.name = "MoonShaft"
	_shaft.centered = true
	_shaft.texture = _make_shaft_tex()
	_shaft.position = Vector2(420, 80)
	_shaft.rotation = deg_to_rad(11.0)
	_shaft.modulate = Color(0.78, 0.82, 1.0, 0.0)
	_shaft.z_index = -4
	add_child(_shaft)
	if _headless:
		return
	_spawn_layer(_far, FAR_COUNT, 0.70, Color(0.82, 0.84, 0.90, 0.28))
	_spawn_layer(_mid, MID_COUNT, 1.15, Color(0.82, 0.62, 0.44, 0.48))
	_spawn_layer(_near, NEAR_COUNT, 1.55, Color(0.94, 0.86, 0.74, 0.62))


func mid_motes_allowed() -> bool:
	return WorldClock.weather_fx_allowed() and WorldClock.wind_speed > 0.05


func shaft_alpha() -> float:
	if WorldClock.menu_hold:
		return 0.0
	if WorldClock.zone == WorldClock.Zone.INDOORS:
		return 0.04
	match WorldClock.phase:
		WorldClock.Phase.NIGHT:
			return 0.20
		WorldClock.Phase.DUSK:
			return 0.12
		WorldClock.Phase.DAWN:
			return 0.08
		_:
			return 0.03


func _process(delta: float) -> void:
	var wind := WorldClock.wind_vector()
	if _shaft != null:
		_shaft.rotation = deg_to_rad(11.0) + wind.x * 0.08
		var a := shaft_alpha()
		_shaft.modulate.a = move_toward(_shaft.modulate.a, a, delta * 0.35)
	if _headless:
		return
	var cam := get_viewport().get_camera_2d()
	var origin := cam.global_position if cam != null else global_position
	_drift(_far, delta, wind, 18.0, origin, 0.22)
	if mid_motes_allowed():
		_drift(_mid, delta, wind, 52.0, origin, 0.42)
		_drift(_near, delta, wind, 88.0, origin, 0.58)
	else:
		_hide_layer(_mid)
		_hide_layer(_near)


func _spawn_layer(bucket: Array[Sprite2D], count: int, scale: float, col: Color) -> void:
	for i in count:
		var spr := Sprite2D.new()
		spr.texture = _mote_tex
		if _mote_tex != null and _mote_tex.get_width() >= 8:
			spr.hframes = 8
			spr.frame = randi() % 8
		spr.centered = true
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.scale = Vector2(scale, scale)
		spr.modulate = col
		spr.position = Vector2(randf() * 1280.0, randf() * 360.0)
		add_child(spr)
		bucket.append(spr)


func _drift(bucket: Array[Sprite2D], delta: float, wind: Vector2, speed: float, origin: Vector2, vis: float) -> void:
	var rain_cut := 1.0 - WorldClock.rain_opacity() * 0.65
	for spr in bucket:
		var p := spr.position
		p.x += wind.x * speed * delta
		p.y += sin(p.x * 0.03 + p.y * 0.02) * 6.0 * delta
		if p.x < origin.x - 420.0:
			p.x = origin.x + 420.0
			p.y = origin.y + randf_range(-160.0, 160.0)
		elif p.x > origin.x + 420.0:
			p.x = origin.x - 420.0
			p.y = origin.y + randf_range(-160.0, 160.0)
		spr.position = Vector2(roundf(p.x), roundf(p.y))
		spr.modulate.a = vis * rain_cut * clampf(WorldClock.wind_speed * 2.4, 0.2, 1.0)
		if spr.hframes > 1 and randf() < delta * 4.0:
			spr.frame = (spr.frame + 1) % spr.hframes


func _hide_layer(bucket: Array[Sprite2D]) -> void:
	for spr in bucket:
		if spr.modulate.a > 0.0:
			spr.modulate.a = 0.0


func _load_motes() -> Texture2D:
	if ResourceLoader.exists(MOTE_PATH):
		return load(MOTE_PATH) as Texture2D
	var img := Image.create(3, 3, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	img.set_pixel(1, 1, Color(1, 1, 1, 0.8))
	return ImageTexture.create_from_image(img)


func _make_shaft_tex() -> Texture2D:
	var img := Image.create(16, 96, false, Image.FORMAT_RGBA8)
	for y in 96:
		for x in 16:
			var cx := absf(float(x) - 7.5) / 8.0
			var along := 1.0 - float(y) / 96.0
			var a := clampf((1.0 - cx) * (1.0 - cx) * along * 0.55, 0.0, 0.55)
			img.set_pixel(x, y, Color(0.85, 0.88, 1.0, a))
	return ImageTexture.create_from_image(img)
