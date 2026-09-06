class_name WindFx
extends Node2D
## 可见的风：随风横飞的尘屑 / 草屑 / 叶屑，从镜头的上风侧生成，穿过画面后消失。
## 密度读 WorldClock.wind_mote_density()（风速 + 阵风），室内 / 标题 / 冻结时为 0；
## 方向和速度读 wind_vector()，所以树摆、雨丝、雾带、云和这些尘屑永远同向同步。
## 纯表现，不进物理；坐标取整；headless 不生成。

const MAX_MOTES := 18
## px/s = BASE + |wind_vector.x| * PER_WIND；静风 0.28 → ≈90，余烬风 0.85 → ≈170。
const BASE_SPEED := 48.0
const SPEED_PER_WIND := 145.0
const SPAWN_PER_SECOND := 12.0
## 生成 / 消失在视口外这么多像素，进出都不会「凭空出现」。
const EDGE_PAD := 16.0

var _accum := 0.0
var _headless := false


func _ready() -> void:
	z_index = 1
	_headless = DisplayServer.get_name() == "headless"


func _process(delta: float) -> void:
	if _headless:
		return
	var density := WorldClock.wind_mote_density()
	if density <= 0.0:
		return
	_accum += delta * SPAWN_PER_SECOND * density
	while _accum >= 1.0:
		_accum -= 1.0
		if mote_count() < MAX_MOTES:
			spawn_mote(view_rect())


func mote_count() -> int:
	var n := 0
	for child in get_children():
		if child is Mote and not child.is_queued_for_deletion():
			n += 1
	return n


## World-space view of the camera that owns this viewport; a fixed 640×360
## box around the origin when no camera exists (tests).
func view_rect() -> Rect2:
	var vp := get_viewport()
	var cam := vp.get_camera_2d() if vp != null else null
	if cam == null:
		return Rect2(Vector2(-320.0, -180.0), Vector2(640.0, 360.0))
	var size := vp.get_visible_rect().size / cam.zoom
	return Rect2(cam.get_screen_center_position() - size * 0.5, size)


static func wind_heading() -> float:
	var h := signf(WorldClock.wind_vector().x)
	return h if h != 0.0 else -1.0


func spawn_mote(rect: Rect2) -> Mote:
	var heading := wind_heading()
	var mote := Mote.new()
	mote.heading = heading
	var x := rect.position.x - EDGE_PAD if heading > 0.0 else rect.end.x + EDGE_PAD
	var y := randf_range(rect.position.y + rect.size.y * 0.12, rect.position.y + rect.size.y * 0.92)
	mote.position = Vector2(x, y).round()
	mote.exit_x = rect.end.x + EDGE_PAD * 2.0 if heading > 0.0 else rect.position.x - EDGE_PAD * 2.0
	add_child(mote)
	return mote


## 一粒风屑：3×1 尘（灰）/ 2×1 草屑（暗绿）/ 2×2 叶屑（锈色）。横向随风，
## 竖向缓慢起伏；进场 0.3s 淡入，越过出口线即释放。
class Mote extends Node2D:
	const LIFE_MAX := 7.0

	var heading := -1.0
	var exit_x := 0.0
	var _pos := Vector2.ZERO
	var _t := 0.0
	var _phase := 0.0
	var _speed_k := 1.0
	var _drift_y := 0.0
	var _alpha := 0.55


	func _init() -> void:
		_phase = randf() * TAU
		_speed_k = randf_range(0.8, 1.25)
		_drift_y = randf_range(-6.0, 6.0)
		var poly := Polygon2D.new()
		var roll := randf()
		if roll < 0.55:
			poly.polygon = PackedVector2Array([Vector2(-1.5, -0.5), Vector2(1.5, -0.5), Vector2(1.5, 0.5), Vector2(-1.5, 0.5)])
			poly.color = Color(0.66, 0.62, 0.68)
			_alpha = 0.50
		elif roll < 0.85:
			poly.polygon = PackedVector2Array([Vector2(-1.0, -0.5), Vector2(1.0, -0.5), Vector2(1.0, 0.5), Vector2(-1.0, 0.5)])
			poly.color = Color(0.46, 0.54, 0.24)
			_alpha = 0.60
		else:
			poly.polygon = PackedVector2Array([Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)])
			poly.color = LeafShed.LEAF_TINTS[randi_range(0, LeafShed.LEAF_TINTS.size() - 1)]
			_alpha = 0.75
			_speed_k *= 0.85
		add_child(poly)
		modulate.a = 0.0


	func _ready() -> void:
		_pos = position


	func _process(delta: float) -> void:
		_t += delta
		var wind := WorldClock.wind_vector().x
		var speed := (WindFx.BASE_SPEED + absf(wind) * WindFx.SPEED_PER_WIND) * _speed_k
		_pos.x += heading * speed * delta
		_pos.y += (sin(_t * 2.6 + _phase) * 9.0 + _drift_y) * delta
		position = _pos.round()
		modulate.a = minf(_t / 0.3, 1.0) * _alpha
		var past := _pos.x > exit_x if heading > 0.0 else _pos.x < exit_x
		if past or _t > LIFE_MAX:
			queue_free()
