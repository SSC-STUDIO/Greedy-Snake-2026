extends TestCase
## Logical viewport stays 1280x720; stretch is integer for 2x / 3x desktops.


func test_logical_viewport_stays_1280() -> void:
	eq(DisplayFit.VIEW_W, 1280)
	eq(DisplayFit.VIEW_H, 720)
	eq(int(ProjectSettings.get_setting("display/window/size/viewport_width")), 1280)
	eq(int(ProjectSettings.get_setting("display/window/size/viewport_height")), 720)


func test_stretch_is_integer_keep() -> void:
	eq(String(ProjectSettings.get_setting("display/window/stretch/mode")), "viewport")
	eq(String(ProjectSettings.get_setting("display/window/stretch/aspect")), "keep")
	var scale_mode: Variant = ProjectSettings.get_setting("display/window/stretch/scale_mode")
	ok(String(scale_mode) == "integer" or int(scale_mode) == 1, "integer scale for 1440p / 4K")


func test_apply_is_safe_headless() -> void:
	DisplayFit.apply()
	ok(true, "headless apply is a no-op")
