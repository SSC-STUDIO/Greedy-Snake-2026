class_name DisplayFit
extends Object
## Integer-scale 1280x720 onto 1440p (2x) and 4K (3x). Not an Autoload.

const VIEW_W := 1280
const VIEW_H := 720


static func apply() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)


static func toggle_fullscreen() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if is_fullscreen():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


static func is_fullscreen() -> bool:
	var mode := DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN \
			or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


static func fullscreen_label() -> String:
	return "窗 口" if is_fullscreen() else "全 屏"
