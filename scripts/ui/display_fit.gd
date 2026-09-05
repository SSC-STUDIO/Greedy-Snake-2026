class_name DisplayFit
extends Object
## Rustgrave 全分辨率与多比例自适应控制器。
##
## 基础逻辑视口：1280x720 (16:9)
## 支持 3 种缩放呈现模式：
## - FIT_ADAPTIVE: 自适应铺满 (Keep Aspect + Fractional) — 1080p, 1440p, 4K 满屏无黑边，非 16:9 留对称窄黑边；
## - FIT_EXPAND: 视野扩展 (Expand Aspect) — 16:10 (Steam Deck) 和 21:9 超宽屏动态拓宽视野，零黑边；
## - FIT_INTEGER: 点对点整数缩放 (Pixel Perfect) — 严格整倍率 (1x/2x/3x)，适合追求纯粹像素颗粒的玩家。

const VIEW_W := 1280
const VIEW_H := 720

enum FitMode {
	ADAPTIVE = 0,   ## 自适应铺满 (Keep Aspect + Fractional)
	EXPAND = 1,     ## 视野扩展 (Expand Aspect)
	INTEGER = 2,    ## 点对点整数 (Integer Scale)
}

const PRESET_RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),   ## 720p HD (16:9)
	Vector2i(1920, 1080),  ## 1080p FHD (16:9)
	Vector2i(2560, 1440),  ## 1440p 2K (16:9)
	Vector2i(3840, 2160),  ## 4K UHD (16:9)
	Vector2i(1280, 800),   ## Steam Deck (16:10)
	Vector2i(1920, 1200),  ## WUXGA (16:10)
	Vector2i(2560, 1080),  ## 21:9 WFHD
	Vector2i(3440, 1440),  ## 21:9 UWQHD
	Vector2i(1024, 768),   ## 4:3 XGA
]

static var _current_fit_mode: FitMode = FitMode.ADAPTIVE


static func _get_root_window(win: Window = null) -> Window:
	if win != null:
		return win
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		return (loop as SceneTree).root
	return null


static func apply(win: Window = null) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	apply_fit_mode(_current_fit_mode, win)


static func apply_fit_mode(mode: FitMode, win: Window = null) -> void:
	# World rendering is always presented at the largest centered integer scale.
	# Keep the legacy enum inputs accepted, but normalize them to the pixel-safe
	# mode so menus and saved preferences cannot reintroduce fractional scaling.
	_current_fit_mode = FitMode.INTEGER
	var root := _get_root_window(win)
	if root == null or DisplayServer.get_name() == "headless":
		return

	match FitMode.INTEGER:
		FitMode.ADAPTIVE:
			root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
			root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
			root.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
		FitMode.EXPAND:
			root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
			root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
			root.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
		FitMode.INTEGER:
			root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
			root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
			root.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER


static func get_fit_mode() -> FitMode:
	return _current_fit_mode


static func fit_mode_label(mode: FitMode = _current_fit_mode) -> String:
	match mode:
		FitMode.ADAPTIVE:
			return "画面: 自适应铺满"
		FitMode.EXPAND:
			return "画面: 视野扩展"
		FitMode.INTEGER:
			return "画面: 点对点整数"
	return "画面: 自适应铺满"


static func cycle_fit_mode(win: Window = null) -> String:
	var next_val := (int(_current_fit_mode) + 1) % 3
	apply_fit_mode(next_val as FitMode, win)
	return fit_mode_label()


static func toggle_fullscreen() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if is_fullscreen():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)


static func is_fullscreen() -> bool:
	var mode := DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN \
			or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


static func fullscreen_label() -> String:
	return "窗 口" if is_fullscreen() else "全 屏"


static func get_window_size() -> Vector2i:
	if DisplayServer.get_name() == "headless":
		return Vector2i(VIEW_W, VIEW_H)
	return DisplayServer.window_get_size()


static func get_aspect_ratio_name(size: Vector2i = Vector2i.ZERO) -> String:
	if size == Vector2i.ZERO:
		size = get_window_size()
	if size.y <= 0:
		return "16:9"
	var ratio := float(size.x) / float(size.y)
	if absf(ratio - (16.0 / 9.0)) < 0.05:
		return "16:9"
	elif absf(ratio - (16.0 / 10.0)) < 0.05:
		return "16:10 (Deck/掌机)"
	elif absf(ratio - (21.0 / 9.0)) < 0.15 or ratio > 2.2:
		return "21:9 (超宽带鱼屏)"
	elif absf(ratio - (4.0 / 3.0)) < 0.05:
		return "4:3 (复古方屏)"
	return "%.2f:1" % ratio


static func get_resolution_string() -> String:
	var sz := get_window_size()
	return "%d×%d  %s" % [sz.x, sz.y, get_aspect_ratio_name(sz)]


static func apply_resolution(res: Vector2i, win: Window = null) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if is_fullscreen():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(res)
	var screen_idx := DisplayServer.window_get_current_screen()
	var screen_rect := DisplayServer.screen_get_usable_rect(screen_idx)
	var pos := screen_rect.position + (screen_rect.size - res) / 2
	DisplayServer.window_set_position(pos)
	apply_fit_mode(_current_fit_mode, win)
