extends TestCase
## Logical viewport stays 1280x720; stretch is integer for 2x / 3x desktops.


func test_logical_viewport_stays_1280() -> void:
	eq(DisplayFit.VIEW_W, 1280)
	eq(DisplayFit.VIEW_H, 720)
	eq(int(ProjectSettings.get_setting("display/window/size/viewport_width")), 1280)
	eq(int(ProjectSettings.get_setting("display/window/size/viewport_height")), 720)


func test_stretch_mode_and_aspect() -> void:
	eq(String(ProjectSettings.get_setting("display/window/stretch/mode")), "canvas_items")
	eq(String(ProjectSettings.get_setting("display/window/stretch/aspect")), "keep")
	var scale_mode: Variant = ProjectSettings.get_setting("display/window/stretch/scale_mode")
	ok(String(scale_mode) in ["fractional", "integer"], "scale mode supports smooth scaling or integer")


func test_fit_modes_cycle() -> void:
	DisplayFit.apply_fit_mode(DisplayFit.FitMode.ADAPTIVE)
	eq(int(DisplayFit.get_fit_mode()), int(DisplayFit.FitMode.INTEGER))
	ok("整数" in DisplayFit.fit_mode_label(), "adaptive request remains pixel safe")
	DisplayFit.cycle_fit_mode()
	eq(int(DisplayFit.get_fit_mode()), int(DisplayFit.FitMode.INTEGER))
	ok("整数" in DisplayFit.fit_mode_label(), "cycle remains pixel safe")
	DisplayFit.cycle_fit_mode()
	eq(int(DisplayFit.get_fit_mode()), int(DisplayFit.FitMode.INTEGER))
	ok("整数" in DisplayFit.fit_mode_label(), "label matches integer")
	DisplayFit.cycle_fit_mode()
	eq(int(DisplayFit.get_fit_mode()), int(DisplayFit.FitMode.INTEGER))


func test_aspect_ratio_classification() -> void:
	eq(DisplayFit.get_aspect_ratio_name(Vector2i(1920, 1080)), "16:9")
	eq(DisplayFit.get_aspect_ratio_name(Vector2i(2560, 1440)), "16:9")
	eq(DisplayFit.get_aspect_ratio_name(Vector2i(1280, 800)), "16:10 (Deck/掌机)")
	eq(DisplayFit.get_aspect_ratio_name(Vector2i(2560, 1080)), "21:9 (超宽带鱼屏)")
	eq(DisplayFit.get_aspect_ratio_name(Vector2i(1024, 768)), "4:3 (复古方屏)")


func test_apply_is_safe_headless() -> void:
	DisplayFit.apply()
	ok(true, "headless apply is a no-op")
