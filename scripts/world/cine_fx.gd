class_name CineFx
extends Node2D
## World-space depth dust / scrap plus a faint moon shaft.
## Presentation only — wind and zone come from WorldClock.

const FAR_COUNT := 12
const MID_COUNT := 10
const NEAR_COUNT := 6
const MOTE_PATH := "res://assets/ui/ember_motes.png"

var _far: Array[Sprite2D] = []
var _mid: Array[Sprite2D] = []
var _near: Array[Sprite2D] = []
var _shaft: Sprite2D
var _mote_tex: Texture2D
var _headless := false
var _mid_suppressed := false
var _view_half := Vector2(320.0, 180.0)


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
	_shaft.visible = false
	add_child(_shaft)
	if _headless:
		return
	# Pale dust may sit in the sky. Warm scrap stays on the ground band —
	# spawning at y=0..360 put orange motes on the moon (read as "sky fire").
	_spawn_layer(_far, FAR_COUNT, 0.70, Color(0.82, 0.84, 0.90, 0.28), 80.0, 260.0)
	_spawn_layer(_mid, MID_COUNT, 1.15, Color(0.82, 0.62, 0.44, 0.48), 230.0, 360.0)
	_spawn_layer(_near, NEAR_COUNT, 1.55, Color(0.94, 0.86, 0.74, 0.62), 250.0, 380.0)


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
		var show_shaft := _shaft.modulate.a > 0.004
		if _shaft.visible != show_shaft:
			_shaft.visible = show_shaft
	if _headless:
		return
	var cam := get_viewport().get_camera_2d()
	var origin := cam.get_screen_center_position() if cam != null else global_position
	_view_half = get_viewport().get_visible_rect().size * 0.5 / (cam.zoom if cam != null else Vector2.ONE)
	var rain_cut := 1.0 - WorldClock.rain_opacity() * 0.65
	var wind_vis := clampf(WorldClock.wind_speed * 2.4, 0.2, 1.0)
	_drift(_far, delta, wind, 18.0, origin, 0.22 * rain_cut * wind_vis, -120.0, 80.0)
	if mid_motes_allowed():
		if _mid_suppressed:
			_show_layer(_mid)
			_show_layer(_near)
			_mid_suppressed = false
		_drift(_mid, delta, wind, 52.0, origin, 0.42 * rain_cut * wind_vis, 20.0, 170.0)
		_drift(_near, delta, wind, 88.0, origin, 0.58 * rain_cut * wind_vis, 40.0, 180.0)
	elif not _mid_suppressed:
		_hide_layer(_mid)
		_hide_layer(_near)
		_mid_suppressed = true


func _spawn_layer(bucket: Array[Sprite2D], count: int, scale: float, col: Color, y_min: float, y_max: float) -> void:
	for i in count:
		var spr := Sprite2D.new()
		spr.texture = _mote_tex
		if _mote_tex != null and _mote_tex.get_width() >= 8:
			spr.hframes = 8
			spr.frame = randi() % 8
		spr.centered = true
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.scale = Vector2.ONE
		spr.set_meta("depth", scale)
		spr.modulate = col
		var cam := get_viewport().get_camera_2d()
		var center := cam.get_screen_center_position() if cam != null else Vector2(320, 180)
		var half := get_viewport().get_visible_rect().size * 0.5 / (cam.zoom if cam != null else Vector2.ONE)
		spr.position = Vector2(randf_range(center.x - half.x, center.x + half.x), randf_range(y_min, y_max))
		spr.set_meta("drift_position", spr.position)
		add_child(spr)
		bucket.append(spr)


func _drift(bucket: Array[Sprite2D], delta: float, wind: Vector2, speed: float, origin: Vector2, fade: float, y_lo: float, y_hi: float) -> void:
	for spr in bucket:
		var p: Vector2 = spr.get_meta("drift_position", spr.position)
		p.x += wind.x * speed * delta
		p.y += sin(p.x * 0.03 + p.y * 0.02) * 6.0 * delta
		if p.x < origin.x - _view_half.x - 24.0:
			p.x = origin.x + _view_half.x + 24.0
			p.y = origin.y + randf_range(y_lo, y_hi)
		elif p.x > origin.x + _view_half.x + 24.0:
			p.x = origin.x - _view_half.x - 24.0
			p.y = origin.y + randf_range(y_lo, y_hi)
		if p.y < origin.y + y_lo:
			p.y = origin.y + y_hi
		elif p.y > origin.y + y_hi:
			p.y = origin.y + y_lo
		spr.set_meta("drift_position", p)
		spr.position.x = roundf(p.x)
		spr.position.y = roundf(p.y)
		spr.modulate.a = fade
		if spr.hframes > 1 and randf() < delta * 4.0:
			spr.frame = (spr.frame + 1) % spr.hframes


func _hide_layer(bucket: Array[Sprite2D]) -> void:
	for spr in bucket:
		spr.visible = false
		spr.modulate.a = 0.0


func _show_layer(bucket: Array[Sprite2D]) -> void:
	for spr in bucket:
		spr.visible = true


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
