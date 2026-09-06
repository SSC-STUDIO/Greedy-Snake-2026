extends TestCase
## The backdrop is the three authored Gothicvania plates on Parallax2D with
## enough repeat copies that a zoomed / shaken 640px view never sees a seam.

const LEVEL := "res://scenes/levels/Level01_Static.tscn"
const PLATES := {
	"Far": ["res://assets/env/parallax_sky.png", Vector2(0.08, 0.04), 1.9],
	"Mid": ["res://assets/env/parallax_mountains.png", Vector2(0.22, 0.06), 1.7],
	"Hills": ["res://assets/env/parallax_graveyard.png", Vector2(0.48, 0.1), 1.85],
}


func setup() -> void:
	WorldClock.reset()
	WorldClock.menu_hold = false


func teardown() -> void:
	WorldClock.reset()


func test_backdrop_is_a_canvas_layer_of_parallax2d_plates() -> void:
	var level := _load_level()
	if level == null:
		return
	var backdrop := level.get_node_or_null("ParallaxBackdrop") as CanvasLayer
	ok(backdrop != null, "backdrop is a CanvasLayer, not the deprecated ParallaxBackground")
	if backdrop == null:
		return
	ok(backdrop.layer < 0, "backdrop draws behind the play canvas")
	ok(not backdrop.follow_viewport_enabled, "Parallax2D does its own camera math")
	for name in PLATES:
		var layer := backdrop.get_node_or_null(name) as Parallax2D
		ok(layer != null, "%s is a Parallax2D" % name)
		if layer == null:
			continue
		var spec: Array = PLATES[name]
		eq(layer.scroll_scale, spec[1], "%s keeps the authored scroll" % name)
		ok(not layer.follow_viewport)
		var spr := layer.get_node_or_null("Sprite") as Sprite2D
		ok(spr != null and spr.texture != null, "%s carries the authored plate" % name)
		if spr == null or spr.texture == null:
			continue
		eq(String(spr.texture.resource_path), spec[0], "%s uses the original Gothicvania plate" % name)
		almost(spr.scale.x, float(spec[2]), 0.001, "%s plate scale" % name)
		eq(spr.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)
	for name in ["CloudFar", "CloudLow", "FarMountains", "MidGrove", "NearGround"]:
		ok(backdrop.get_node_or_null(name) == null, "%s stacked wash is gone" % name)
	ok(level.get_node_or_null("ParallaxBackdrop/Far/Sprite") != null)
	var order := []
	for child in backdrop.get_children():
		if child is Parallax2D:
			order.append(String(child.name))
	eq(order.slice(0, 3), ["Far", "Mid", "Hills"], "sky behind mountains behind graveyard")


func test_plates_repeat_enough_copies_to_cover_the_view() -> void:
	var level := _load_level()
	if level == null:
		return
	var backdrop := level.get_node("ParallaxBackdrop")
	for name in PLATES:
		var layer := backdrop.get_node(name) as Parallax2D
		var spr := layer.get_node("Sprite") as Sprite2D
		var tile := Level01Parallax.tile_width(spr)
		ok(tile >= 300.0, "%s tile is a full plate, not a strip" % name)
		ok(layer.repeat_size.x >= 1.0, "%s repeats along x" % name)
		ok(layer.repeat_size.x <= tile + 0.01, "%s repeat never exceeds the plate width (no gap)" % name)
		ok(layer.repeat_size.x >= tile - 1.01, "%s repeat is at most 1px under the plate (pixel snap overlap)" % name)
		ok(layer.repeat_times >= Level01Parallax.MIN_REPEAT_TIMES,
				"%s draws %d copies; ParallaxLayer's single mirror showed seams" % [name, layer.repeat_times])
		ok(float(layer.repeat_times) * layer.repeat_size.x >= 640.0 + Level01Parallax.COVER_PAD,
				"%s copies cover the 640 view plus pad" % name)
	eq(Level01Parallax.copies_for_view(326.0), 4, "mountains: ceil(768/326)=3 → floor of 4")
	eq(Level01Parallax.copies_for_view(120.0), 7, "narrow tiles need more copies")
	eq(Level01Parallax.copies_for_view(0.0), Level01Parallax.MIN_REPEAT_TIMES)


func test_cover_layer_keeps_one_sprite_and_floors_the_step() -> void:
	var layer := Parallax2D.new()
	add_child(layer)
	var img := Image.create(192, 40, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.3, 0.2, 0.4, 1))
	var tex := ImageTexture.create_from_image(img)
	for i in 3:
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.centered = false
		spr.scale = Vector2(1.7, 1.7)
		spr.position = Vector2(i * 326.4, 0)
		layer.add_child(spr)
	Level01Parallax.cover_layer(layer, 640.0)
	var sprites := 0
	for child in layer.get_children():
		if child is Sprite2D:
			sprites += 1
	eq(sprites, 1, "hand-tiled duplicates collapse to one sprite; Parallax2D repeats it")
	almost(layer.repeat_size.x, 326.0, 0.01, "326.4 floors to 326 so snapped copies overlap instead of gapping")
	eq(layer.repeat_times, 4)
	ok(not layer.follow_viewport)


func test_extras_add_fog_silhouette_and_foreground_cover() -> void:
	var level := _load_level()
	if level == null:
		return
	var backdrop := level.get_node("ParallaxBackdrop")
	var fog_far := backdrop.get_node_or_null("FogFar") as Parallax2D
	var fog_near := backdrop.get_node_or_null("FogNear") as Parallax2D
	var sil := backdrop.get_node_or_null("NearSilhouette") as Parallax2D
	ok(fog_far != null and fog_near != null, "two fog bands drift between the plates")
	ok(sil != null, "near silhouette strip is planted")
	if fog_far != null and fog_near != null and sil != null:
		ok(fog_far.get_index() > backdrop.get_node("Hills").get_index(), "fog hangs in front of the graveyard plate")
		ok(sil.get_index() > fog_far.get_index() and fog_near.get_index() > sil.get_index(),
				"far fog, silhouettes, near fog")
		ok(fog_far.scroll_scale.x < sil.scroll_scale.x and sil.scroll_scale.x < fog_near.scroll_scale.x,
				"nearer strips scroll faster")
		ok(fog_far.repeat_times >= Level01Parallax.MIN_REPEAT_TIMES)
		ok(sil.repeat_times >= Level01Parallax.MIN_REPEAT_TIMES)
		almost(sil.repeat_size.x, Level01Parallax.SIL_SPAN, 0.01)
	var front := level.get_node_or_null("ParallaxForeground") as CanvasLayer
	ok(front != null and front.layer > 0, "foreground grass draws over the play canvas")
	var fore := level.get_node_or_null("ParallaxForeground/Foreground") as Parallax2D
	ok(fore != null, "foreground is a Parallax2D too")
	if fore != null:
		ok(fore.scroll_scale.x > 1.0, "foreground moves faster than the camera")
		ok(fore.repeat_times >= Level01Parallax.MIN_REPEAT_TIMES, "foreground also repeats enough copies")
	ok(level.get_node_or_null("MoodTint") is CanvasModulate)
	ok(level.get_node_or_null("MoonFill") is DirectionalLight2D)
	ok(level.get_node_or_null("WeatherFx") is WeatherFx)
	ok(level.get_node_or_null("CineFx") is CineFx)


func test_sky_and_fog_follow_the_clock() -> void:
	var host := Node2D.new()
	add_child(host)
	var backdrop := CanvasLayer.new()
	backdrop.name = "ParallaxBackdrop"
	host.add_child(backdrop)
	var far := Parallax2D.new()
	far.name = "Far"
	backdrop.add_child(far)
	var extras := Level01Parallax.new()
	add_child(extras)
	WorldClock.set_time(0.35)
	WorldClock.set_weather(WorldClock.Weather.HAZE, true)
	extras.build(host)
	var day := far.modulate
	var fog_near := backdrop.get_node_or_null("FogNear") as Parallax2D
	var fog_day := fog_near.modulate.a if fog_near != null else 0.0
	WorldClock.set_time(0.85)
	WorldClock.set_weather(WorldClock.Weather.FOG, true)
	extras._snap_atmosphere()
	ok(far.modulate.v < day.v, "night darkens the sky plate through the layer modulate")
	if fog_near != null:
		ok(fog_near.modulate.a > fog_day, "fog weather thickens the near band")
	WorldClock.wind_heading = 1.0
	WorldClock._heading_target = 1.0
	WorldClock._snap_wind_speed()
	var x0 := far.scroll_offset.x
	extras._process(0.5)
	ok(far.scroll_offset.x != x0, "wind drifts the sky through scroll_offset")


func _load_level() -> Node:
	var packed := load(LEVEL) as PackedScene
	ok(packed != null, "Level01_Static packs")
	if packed == null:
		return null
	var level := packed.instantiate()
	add_child(level)
	return level
