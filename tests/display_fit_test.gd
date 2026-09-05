extends TestCase


func test_logical_viewport_stays_1280() -> void:
	eq(DisplayFit.VIEW_W, 1280)
	eq(DisplayFit.VIEW_H, 720)
	eq(int(ProjectSettings.get_setting("display/window/size/viewport_width")), 1280)
	eq(int(ProjectSettings.get_setting("display/window/size/viewport_height")), 720)


func test_stretch_mode_and_aspect() -> void:
	eq(String(ProjectSettings.get_setting("display/window/stretch/mode")), "canvas_items")
	eq(String(ProjectSettings.get_setting("display/window/stretch/aspect")), "keep")


func test_apply_is_safe_headless() -> void:
	DisplayFit.apply()
	DisplayFit.apply_menu()
	DisplayFit.apply_game()
	ok(true, "headless apply is a no-op")
