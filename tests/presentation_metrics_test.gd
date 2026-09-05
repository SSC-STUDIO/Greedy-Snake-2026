extends TestCase


func test_standard_desktops_fill_with_world_texels() -> void:
	for item in [Vector3i(1280, 720, 2), Vector3i(1920, 1080, 3), Vector3i(2560, 1440, 4), Vector3i(3840, 2160, 6)]:
		var metrics := PresentationMetrics.calculate(Vector2i(item.x, item.y))
		eq(metrics["scale"], item.z)
		eq(metrics["physical_rect"], Rect2(0, 0, item.x, item.y))


func test_unusual_windows_have_integer_centered_content() -> void:
	var laptop := PresentationMetrics.calculate(Vector2i(1366, 768))
	eq(laptop["physical_rect"], Rect2(43, 24, 1280, 720))
	var deck := PresentationMetrics.calculate(Vector2i(1280, 800))
	eq(deck["physical_rect"], Rect2(0, 40, 1280, 720))
	var ultra := PresentationMetrics.calculate(Vector2i(3440, 1440))
	eq(ultra["physical_rect"], Rect2(440, 0, 2560, 1440))
	var small := PresentationMetrics.calculate(Vector2i(640, 360))
	eq(small["scale"], 1)


func test_ui_and_world_share_the_same_final_physical_rect() -> void:
	for size in [Vector2i(1366, 768), Vector2i(1920, 1080), Vector2i(1280, 800), Vector2i(3440, 1440), Vector2i(3841, 2161)]:
		var metrics := PresentationMetrics.calculate(size)
		var ui: Transform2D = metrics["ui_transform"]
		var canvas_rect: Rect2 = metrics["canvas_rect"]
		ok(ui.origin.is_equal_approx(canvas_rect.position), "UI starts at the world image")
		ok((ui * Vector2(PresentationMetrics.UI_SIZE)).is_equal_approx(canvas_rect.end), "UI covers the exact world image")
		var physical_scale := Vector2(size) / Vector2(PresentationMetrics.UI_SIZE)
		var physical: Rect2 = metrics["physical_rect"]
		ok((canvas_rect.position * physical_scale).is_equal_approx(physical.position))
		ok((canvas_rect.size * physical_scale).is_equal_approx(physical.size))


func test_scene_routing_keeps_the_authored_save_identifier() -> void:
	eq(GameContext.route_scene(GameContext.WORLD_PATH), "res://scenes/ui/GamePresentation.tscn")
	eq(GameContext.route_scene("res://scenes/ui/TitleScreen.tscn"), "res://scenes/ui/TitleScreen.tscn")


func test_native_ui_uses_pixel_filter_and_automatic_font_raster_size() -> void:
	ok(get_tree().root.canvas_item_default_texture_filter in [
		CanvasItem.TEXTURE_FILTER_NEAREST,
		Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST,
		3,
	], "root canvas keeps nearest pixel filtering")
	var font := load("res://assets/fonts/fusion-pixel-12px-proportional-zh_hans.ttf") as FontFile
	ok(font != null)
	if font != null:
		almost(font.oversampling, 0.0, 0.001, "font uses automatic oversampling for native UI")
