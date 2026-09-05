class_name DisplayFit
extends Object
## Rustgrave display: 1280×720 design UI, 640×360 world image, integer content rect.
## The root stays in canvas-items mode. GamePresentation owns the 640x360
## world image and PresentationMetrics owns its centered integer-sized rect;
## keeping both layers in viewport mode would scale the world a second time.

const VIEW_W := 1280
const VIEW_H := 720


static func apply() -> void:
	apply_game()


static func apply_menu() -> void:
	_set_root_scale(Window.CONTENT_SCALE_ASPECT_KEEP)


static func apply_game() -> void:
	# GamePresentation letterboxes the integer world rect itself. KEEP would
	# add a second set of bars around the 1280×720 canvas.
	_set_root_scale(Window.CONTENT_SCALE_ASPECT_IGNORE)


static func _set_root_scale(aspect: int) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		var root := (loop as SceneTree).root
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root.content_scale_aspect = aspect
		root.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL


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
