extends RefCounted
class_name ResponsiveLayout

## 响应式布局工具 - 根据屏幕分辨率自动缩放 UI 尺寸

## 基准设计分辨率
const BASE_WIDTH := 1280.0
const BASE_HEIGHT := 720.0

## 当前缩放比例（基于宽度）
static var _scale: float = 1.0

## 更新缩放比例（应在场景初始化时调用）
static func update_scale() -> void:
	var main_loop := Engine.get_main_loop()
	if main_loop == null or not main_loop is SceneTree:
		_scale = 1.0
		return
	var tree := main_loop as SceneTree
	var viewport: Viewport = tree.root.get_viewport() if tree.root else null
	if viewport == null:
		_scale = 1.0
		return
	var current_width: float = viewport.get_visible_rect().size.x
	_scale = current_width / BASE_WIDTH

## 获取当前缩放比例
static func get_scale() -> float:
	return _scale

## 缩放尺寸值
static func scale(value: float) -> float:
	return value * _scale

## 缩放 Vector2 尺寸
static func scale_vector(size: Vector2) -> Vector2:
	return size * _scale

## 缩放字体大小（最小不低于指定值）
static func scale_font(base_size: int, min_size := 12) -> int:
	return maxi(roundi(float(base_size) * _scale), min_size)

## 缩放按钮尺寸
static func scale_button(width: float, height: float) -> Vector2:
	return Vector2(width * _scale, height * _scale)

## 缩放面板尺寸
static func scale_panel(width: float, height: float) -> Vector2:
	return Vector2(width * _scale, height * _scale)

## 缩放边距值
static func scale_margin(value: int) -> int:
	return roundi(float(value) * _scale)

## 缩放间距值
static func scale_separation(value: int) -> int:
	return roundi(float(value) * _scale)

## 获取当前屏幕尺寸
static func get_screen_size() -> Vector2:
	var main_loop := Engine.get_main_loop()
	if main_loop == null or not main_loop is SceneTree:
		return Vector2(BASE_WIDTH, BASE_HEIGHT)
	var tree := main_loop as SceneTree
	var viewport: Viewport = tree.root.get_viewport() if tree.root else null
	if viewport == null:
		return Vector2(BASE_WIDTH, BASE_HEIGHT)
	return viewport.get_visible_rect().size

## 获取当前宽高比
static func get_aspect_ratio() -> float:
	var size := get_screen_size()
	return size.x / size.y

## 判断是否为宽屏（宽高比 > 16:9）
static func is_widescreen() -> bool:
	return get_aspect_ratio() > (16.0 / 9.0)

## 判断是否为超宽屏（宽高比 > 21:9）
static func is_ultrawide() -> bool:
	return get_aspect_ratio() > (21.0 / 9.0)

## 判断是否为竖屏（宽高比 < 1）
static func is_portrait() -> bool:
	return get_aspect_ratio() < 1.0

## 获取安全的 UI 边距（考虑不同宽高比）
static func get_safe_margins() -> Dictionary:
	var screen := get_screen_size()
	var aspect := screen.x / screen.y
	var base_aspect := BASE_WIDTH / BASE_HEIGHT

	if aspect > base_aspect:
		# 宽屏：左右留白
		var excess := (screen.x - screen.y * base_aspect) * 0.5
		return {
			"left": excess,
			"right": excess,
			"top": 0.0,
			"bottom": 0.0
		}
	else:
		# 窄屏/竖屏：上下留白
		var excess := (screen.y - screen.x / base_aspect) * 0.5
		return {
			"left": 0.0,
			"right": 0.0,
			"top": excess,
			"bottom": excess
		}
