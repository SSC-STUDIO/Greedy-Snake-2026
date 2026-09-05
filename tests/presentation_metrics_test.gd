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
	eq(GameContext.route_scene("res://scenes/levels/Level01_Static.tscn"),
			"res://scenes/ui/GamePresentation.tscn")
	eq(GameCamera.ZOOM, 1.0)


func test_weather_particles_use_the_host_viewport() -> void:
	eq(PresentationMetrics.WORLD_SIZE, Vector2i(640, 360))
	var vp := SubViewport.new()
	vp.size = PresentationMetrics.WORLD_SIZE
	add_child(vp)
	var fx := WeatherFx.new()
	vp.add_child(fx)
	eq(fx._bounds(), Vector2(PresentationMetrics.WORLD_SIZE),
			"rain wraps inside the 640×360 world, not the 1280 UI window")


func test_level_registers_as_the_game_world() -> void:
	var presentation := Node.new()
	presentation.name = "GamePresentation"
	add_child(presentation)
	var viewport := Node.new()
	viewport.name = "WorldViewport"
	presentation.add_child(viewport)
	var level := Level01Static.new()
	level.name = "Level01_Static"
	level.run_slice = false
	viewport.add_child(level)
	ok(level.is_in_group("game_world"), "Level01 joins game_world before children ready")
	eq(GameContext.world_root(level), level)
	eq(GameContext.world_scene_path(level), GameContext.WORLD_PATH)
	var props := Node2D.new()
	props.name = "Props"
	level.add_child(props)
	var nest := Node2D.new()
	nest.name = "EmberNest"
	props.add_child(nest)
	eq(SaveData.persist_path(nest), "Props/EmberNest",
			"save keys stay scene-relative, not WorldViewport-prefixed")
