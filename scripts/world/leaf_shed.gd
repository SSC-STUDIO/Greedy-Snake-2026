class_name LeafShed
extends Node2D
## 树冠落叶：每隔几秒从冠层掉一片 2px 枯叶，随风侧漂、忽扁忽竖地翻，
## 落到脚线后化进土里。纯表现；坐标取整；headless 不生成。
## 挂在种树的图层上（不是摇摆枢轴下），叶子才不会跟着树一起摆。

const MAX_LEAVES := 3
## 枯叶 / 锈叶：要比紫黑的墓园底亮一档，2px 的叶子才读得出来。
const LEAF_TINTS: Array[Color] = [
	Color(0.66, 0.44, 0.22),
	Color(0.58, 0.36, 0.18),
	Color(0.70, 0.34, 0.20),
	Color(0.52, 0.48, 0.22),
]

## 冠层宽 / 冠层顶到脚线的高度（像素，按种植缩放后）。
var canopy: Vector2 = Vector2(80.0, 60.0)

var _accum := 0.0
var _next := 2.0
var _headless := false


func _ready() -> void:
	_headless = DisplayServer.get_name() == "headless"
	_next = randf_range(1.5, 4.0)


func _process(delta: float) -> void:
	if _headless or WorldClock.is_frozen():
		return
	_accum += delta
	if _accum < _next:
		return
	_accum = 0.0
	# 风大掉得勤：静风 1.8–4.2s 一片，满风约快一倍。一棵树同时最多 3 片。
	var gust := clampf(0.6 + absf(WorldClock.wind_vector().x) * 1.4, 0.6, 1.4)
	_next = randf_range(1.8, 4.2) / gust
	spawn_leaf()


func spawn_leaf() -> Leaf:
	if leaf_count() >= MAX_LEAVES:
		return null
	var leaf := Leaf.new()
	leaf.position = Vector2(
		randf_range(-canopy.x * 0.35, canopy.x * 0.35),
		-canopy.y * randf_range(0.5, 0.9))
	add_child(leaf)
	return leaf


func leaf_count() -> int:
	var n := 0
	for child in get_children():
		if child is Leaf and not child.is_queued_for_deletion():
			n += 1
	return n


## 一片叶：两块多边形交替显示模拟翻转（3×1 扁 / 1×2 竖），不旋转 2px 方块。
class Leaf extends Node2D:
	const FADE := 0.5

	var _pos := Vector2.ZERO
	var _vy := 16.0
	var _phase := 0.0
	var _t := 0.0
	var _landed := -1.0
	var _flat: Polygon2D
	var _tall: Polygon2D


	func _init() -> void:
		_vy = randf_range(12.0, 20.0)
		_phase = randf() * TAU
		var tint := LeafShed.LEAF_TINTS[randi_range(0, LeafShed.LEAF_TINTS.size() - 1)]
		_flat = Polygon2D.new()
		_flat.polygon = PackedVector2Array([
			Vector2(-1.5, -0.5), Vector2(1.5, -0.5), Vector2(1.5, 0.5), Vector2(-1.5, 0.5),
		])
		_flat.color = tint
		add_child(_flat)
		_tall = Polygon2D.new()
		_tall.polygon = PackedVector2Array([
			Vector2(-0.5, -1.0), Vector2(0.5, -1.0), Vector2(0.5, 1.0), Vector2(-0.5, 1.0),
		])
		_tall.color = tint.darkened(0.15)
		_tall.visible = false
		add_child(_tall)


	func _ready() -> void:
		_pos = position
		position = _pos.round()


	func landed() -> bool:
		return _landed >= 0.0


	func _process(delta: float) -> void:
		_t += delta
		if _landed >= 0.0:
			var k := (_t - _landed) / FADE
			if k >= 1.0:
				queue_free()
				return
			modulate.a = 1.0 - k
			return
		var wind := WorldClock.wind_vector().x * 26.0
		_pos.x += (wind + sin(_t * 3.1 + _phase) * 9.0) * delta
		_pos.y += _vy * delta
		if _pos.y >= 0.0:
			_pos.y = 0.0
			_landed = _t
			_flat.visible = true
			_tall.visible = false
		else:
			var flat := fmod(_t * 4.0 + _phase, 2.0) < 1.0
			_flat.visible = flat
			_tall.visible = not flat
		position = _pos.round()
