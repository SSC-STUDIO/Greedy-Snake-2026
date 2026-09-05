extends TestCase
## Level01 Far/FarMountains/Mid/MidGrove/Hills: AI-pixelized strips,
## integer scale, nearest filter. Legacy Far/Mid/Hills y and world size stay.


const LEVEL := "res://scenes/levels/Level01_Static.tscn"
const PX := {
	"Far": "res://assets/env/parallax_sky_px.png",
	"FarMountains": "res://assets/env/parallax_far_mountains_px.png",
	"Mid": "res://assets/env/parallax_mountains_px.png",
	"MidGrove": "res://assets/env/parallax_mid_grove_px.png",
	"Hills": "res://assets/env/parallax_graveyard_px.png",
}
const STRIP_ORDER := ["Far", "FarMountains", "Mid", "MidGrove", "Hills"]
## Pre-upsample world size (texel * non-integer scale). Authored three stay near this.
const LEGACY_WORLD := {
	"Far": Vector2(668.8, 425.6),
	"Mid": Vector2(326.4, 304.3),
	"Hills": Vector2(710.4, 227.55),
}
const LAYER_Y := {
	"Far": -24.0,
	"FarMountains": 128.0,
	"Mid": 154.0,
	"MidGrove": 168.0,
	"Hills": 168.0,
}
const MIN_PX := {
	"Far": Vector2(640, 400),
	"FarMountains": Vector2(512, 140),
	"Mid": Vector2(320, 280),
	"MidGrove": Vector2(512, 140),
	"Hills": Vector2(640, 200),
}


func test_pixel_strips_exist_and_are_dense() -> void:
	for name in STRIP_ORDER:
		var path: String = PX[name]
		ok(ResourceLoader.exists(path), "px strip missing %s" % path)
		var tex := load(path) as Texture2D
		ok(tex != null, "px strip loads %s" % path)
		if tex == null:
			continue
		var need: Vector2 = MIN_PX[name]
		ok(tex.get_width() >= int(need.x), "%s width %d < %s" % [
			path, tex.get_width(), need.x])
		ok(tex.get_height() >= int(need.y), "%s height %d < %s" % [
			path, tex.get_height(), need.y])


func test_five_strips_integer_scale_nearest_and_order() -> void:
	var level := _load_level()
	var prev_mx := -1.0
	for name in STRIP_ORDER:
		var layer := level.get_node("ParallaxBackdrop/%s" % name) as ParallaxLayer
		ok(layer != null, "%s layer present" % name)
		var spr := level.get_node("ParallaxBackdrop/%s/Sprite" % name) as Sprite2D
		ok(spr != null, "%s sprite present" % name)
		if layer == null or spr == null:
			continue
		ok(layer.motion_scale.x > prev_mx, "%s motion_scale.x %s increases" % [
			name, layer.motion_scale])
		prev_mx = layer.motion_scale.x
		ok(is_equal_approx(spr.scale.x, float(roundi(spr.scale.x))),
				"%s scale.x %s is integer" % [name, spr.scale])
		ok(is_equal_approx(spr.scale.y, float(roundi(spr.scale.y))),
				"%s scale.y %s is integer" % [name, spr.scale])
		ok(spr.scale.x >= 1.0 and spr.scale.x <= 2.0, "%s scale.x in 1..2" % name)
		eq(spr.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST,
				"%s stays NEAREST" % name)
		ok(spr.texture != null, "%s has a texture" % name)
		if spr.texture != null:
			var world_w := float(spr.texture.get_width()) * spr.scale.x
			almost(layer.motion_mirroring.x, world_w, 0.01,
					"%s mirroring matches world width" % name)
			ok(spr.texture.resource_path == PX[name],
					"%s uses %s" % [name, PX[name]])
	level.free()


func test_backdrop_composition_stays_near_legacy() -> void:
	var level := _load_level()
	for name in STRIP_ORDER:
		var spr := level.get_node("ParallaxBackdrop/%s/Sprite" % name) as Sprite2D
		ok(spr != null, "%s sprite present" % name)
		if spr == null or spr.texture == null:
			continue
		almost(spr.position.y, LAYER_Y[name], 0.01, "%s y stays %s" % [name, LAYER_Y[name]])
		if not LEGACY_WORLD.has(name):
			continue
		var world := Vector2(
				float(spr.texture.get_width()) * spr.scale.x,
				float(spr.texture.get_height()) * spr.scale.y)
		var legacy: Vector2 = LEGACY_WORLD[name]
		ok(world.x > legacy.x * 0.80 and world.x < legacy.x * 1.25,
				"%s world width %s near legacy %s" % [name, world, legacy])
		ok(world.y > legacy.y * 0.80 and world.y < legacy.y * 1.25,
				"%s world height %s near legacy %s" % [name, world, legacy])
	level.free()


func test_sky_moon_has_no_dark_cross() -> void:
	var tex := load("res://assets/env/parallax_sky_px.png") as Texture2D
	ok(tex != null, "sky plate loads")
	if tex == null:
		return
	var img := tex.get_image()
	ok(img != null, "sky image readable")
	if img == null:
		return
	var w := img.get_width()
	var h := img.get_height()
	var sx := 0
	var sy := 0
	var n := 0
	for y in range(h):
		for x in range(w):
			var c := img.get_pixel(x, y)
			if c.r > 0.70 and c.b > 0.28 and c.r >= c.g + 0.05:
				sx += x
				sy += y
				n += 1
	ok(n > 200, "sky still has a magenta moon")
	if n <= 200:
		return
	var cx := float(sx) / float(n)
	var cy := float(sy) / float(n)
	var dark := 0
	for y in range(maxi(0, int(cy) - 70), mini(h, int(cy) + 70)):
		for x in range(maxi(0, int(cx) - 70), mini(w, int(cx) + 70)):
			var dx := float(x) - cx
			var dy := float(y) - cy
			if dx * dx + dy * dy > 55.0 * 55.0:
				continue
			var c := img.get_pixel(x, y)
			var mx := maxf(c.r, maxf(c.g, c.b))
			if mx < 0.28 and c.r < 0.22:
				dark += 1
	ok(dark < 40, "moon disk has no dark cross / sword blob")


func test_mid_grove_is_keyed_not_a_black_box() -> void:
	var tex := load("res://assets/env/parallax_mid_grove_px.png") as Texture2D
	ok(tex != null)
	if tex == null:
		return
	var img := tex.get_image()
	ok(img != null)
	if img == null:
		return
	var w := img.get_width()
	var h := img.get_height()
	eq(w, 768)
	eq(h, 192)
	var opaque := 0
	var black := 0
	var mid_row := 0
	var foot_row := 0
	for y in range(h):
		for x in range(w):
			var c := img.get_pixel(x, y)
			if c.a < 0.5:
				continue
			opaque += 1
			if maxf(c.r, maxf(c.g, c.b)) < 0.08:
				black += 1
			if y == 96:
				mid_row += 1
			if y == h - 8:
				foot_row += 1
	ok(opaque < int(float(w * h) * 0.55), "grove stays sparse, not a filled wall")
	ok(black < int(float(opaque) * 0.08 + 1.0), "almost no dead-black fill around branches")
	ok(mid_row < w / 2, "branch band has transparent gaps")
	ok(foot_row < int(float(w) * 0.45), "feet band is not a full-width black slab")


func test_cloud_and_fog_plates_exist() -> void:
	ok(ResourceLoader.exists("res://assets/env/parallax_clouds_px.png"), "cloud far plate")
	ok(ResourceLoader.exists("res://assets/env/parallax_clouds_low_px.png"), "cloud low plate")
	ok(ResourceLoader.exists("res://assets/env/parallax_fog_px.png"), "pixel fog plate")
	var grove := load("res://assets/env/parallax_mid_grove_px.png") as Texture2D
	ok(grove != null, "MidGrove plate still loads")
	if grove != null:
		eq(grove.get_width(), 768, "MidGrove stays 768 wide")
		eq(grove.get_height(), 192, "MidGrove stays a short sparse strip")
	var fog := load("res://assets/env/parallax_fog_px.png") as Texture2D
	if fog != null:
		ok(fog.get_height() <= 96, "fog strip stays a low band, not a screen wash")
		ok(fog.get_width() >= 512, "fog strip is wide enough to tile")


func test_cloud_layers_sit_in_the_sky() -> void:
	var level := _load_level()
	var far := level.get_node("ParallaxBackdrop/Far") as ParallaxLayer
	var mountains := level.get_node("ParallaxBackdrop/FarMountains") as ParallaxLayer
	for name in ["CloudFar", "CloudLow"]:
		var layer := level.get_node("ParallaxBackdrop/%s" % name) as ParallaxLayer
		var spr := level.get_node("ParallaxBackdrop/%s/Sprite" % name) as Sprite2D
		ok(layer != null and spr != null, "%s authored" % name)
		if layer == null or spr == null or far == null or mountains == null:
			continue
		ok(layer.motion_scale.x > far.motion_scale.x, "%s slower than mountains, faster than sky" % name)
		ok(layer.motion_scale.x < mountains.motion_scale.x, "%s stays behind FarMountains" % name)
		ok(is_equal_approx(spr.scale.x, float(roundi(spr.scale.x))),
				"%s scale.x is integer" % name)
		eq(spr.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST, "%s NEAREST" % name)
		ok(spr.position.y < 90.0, "%s sits in the sky band" % name)
		if spr.texture != null:
			almost(layer.motion_mirroring.x, float(spr.texture.get_width()) * spr.scale.x, 0.01,
					"%s mirroring matches world width" % name)
	level.free()


func test_near_and_foreground_layers_exist() -> void:
	ok(ResourceLoader.exists("res://assets/env/parallax_near_ground_px.png"), "near-ground plate")
	ok(ResourceLoader.exists("res://assets/env/parallax_foreground_px.png"), "foreground plate")
	var level := _load_level()
	var hills := level.get_node("ParallaxBackdrop/Hills") as ParallaxLayer
	var near := level.get_node("ParallaxBackdrop/NearGround") as ParallaxLayer
	var near_spr := level.get_node("ParallaxBackdrop/NearGround/Sprite") as Sprite2D
	var fore := level.get_node("ParallaxForeground/Foreground") as ParallaxLayer
	var fore_spr := level.get_node("ParallaxForeground/Foreground/Sprite") as Sprite2D
	ok(near != null and near_spr != null, "NearGround authored")
	ok(fore != null and fore_spr != null, "Foreground authored")
	if hills != null and near != null:
		ok(near.motion_scale.x > hills.motion_scale.x, "NearGround faster than Hills")
		ok(near.motion_scale.x < 1.0, "NearGround stays behind the play layer")
	if fore != null:
		ok(fore.motion_scale.x > 1.0, "Foreground slides faster than the player")
		ok(fore.motion_scale.x <= 1.40, "Foreground is not a wild smear")
	for pair in [[near, near_spr, "NearGround"], [fore, fore_spr, "Foreground"]]:
		var layer: ParallaxLayer = pair[0]
		var spr: Sprite2D = pair[1]
		var name: String = pair[2]
		if layer == null or spr == null:
			continue
		ok(is_equal_approx(spr.scale.x, float(roundi(spr.scale.x))),
				"%s scale.x is integer" % name)
		eq(spr.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST, "%s NEAREST" % name)
		ok(spr.texture != null, "%s has a texture" % name)
		if spr.texture != null:
			almost(layer.motion_mirroring.x, float(spr.texture.get_width()) * spr.scale.x, 0.01,
					"%s mirroring matches world width" % name)
	if near_spr != null:
		ok(near_spr.position.y >= 230.0 and near_spr.position.y <= 280.0,
				"NearGround sits on the ground band")
	if fore_spr != null:
		ok(fore_spr.position.y >= 330.0, "Foreground hugs the dirt / screen lip")
		ok(fore_spr.modulate.a <= 0.85, "Foreground stays a veil, not a wall")
	var front := level.get_node_or_null("ParallaxForeground") as ParallaxBackground
	ok(front != null)
	if front != null:
		ok(front.layer > 0 and front.layer < 10, "Foreground draws in front of play, under HUD")
	level.free()


func test_near_strips_are_foliage_not_stone() -> void:
	for path: String in [
		"res://assets/env/parallax_near_ground_px.png",
		"res://assets/env/parallax_foreground_px.png",
	]:
		var low: String = path.to_lower()
		ok(not low.contains("stone") and not low.contains("statue"),
				"%s path is not a stone plate" % path)
		var tex := load(path) as Texture2D
		ok(tex != null, "%s loads" % path)
		if tex == null:
			continue
		var img := tex.get_image()
		ok(img != null, "%s image readable" % path)
		if img == null:
			continue
		if img.is_compressed():
			img.decompress()
		eq(_monument_blob_count(img), 0, "%s has no tombstone / rubble blobs" % path)
		ok(_foot_frac(img) < 0.50, "%s feet are not a sliding dirt road" % path)
	var level := _load_level()
	for spr_path: String in [
		"ParallaxBackdrop/NearGround/Sprite",
		"ParallaxForeground/Foreground/Sprite",
	]:
		var spr := level.get_node_or_null(spr_path) as Sprite2D
		ok(spr != null, "%s present" % spr_path)
		if spr == null or spr.texture == null:
			continue
		var rp: String = spr.texture.resource_path.to_lower()
		ok(not rp.contains("stone") and not rp.contains("statue"),
				"%s texture is not a stone asset" % spr_path)
		var layer := spr.get_parent()
		ok(Level01Env.find_sway(layer) == null, "%s layer has no WindSway" % spr_path)
		ok(Level01Env.find_sway(spr) == null, "%s sprite has no WindSway" % spr_path)
	level.free()


func test_near_plates_are_keyed_not_black_boxes() -> void:
	for path in [
		"res://assets/env/parallax_near_ground_px.png",
		"res://assets/env/parallax_foreground_px.png",
	]:
		var tex := load(path) as Texture2D
		ok(tex != null, "%s loads" % path)
		if tex == null:
			continue
		ok(tex.get_height() <= 96, "%s stays a low strip" % path)
		var img := tex.get_image()
		ok(img != null)
		if img == null:
			continue
		var w := img.get_width()
		var h := img.get_height()
		var opaque := 0
		var black := 0
		var mid_row := 0
		var foot_row := 0
		var mid_y := int(float(h) * 0.45)
		for y in range(h):
			for x in range(w):
				var c := img.get_pixel(x, y)
				if c.a < 0.5:
					continue
				opaque += 1
				if maxf(c.r, maxf(c.g, c.b)) < 0.08:
					black += 1
				if y == mid_y:
					mid_row += 1
				if y == h - 4:
					foot_row += 1
		ok(opaque < int(float(w * h) * 0.62), "%s stays sparse" % path)
		ok(black < int(float(opaque) * 0.08 + 1.0), "%s has no dead-black fill" % path)
		ok(mid_row < w, "%s mid band is not a solid slab" % path)
		ok(foot_row < w, "%s feet are not a full-width box" % path)
	var grove := load("res://assets/env/parallax_mid_grove_px.png") as Texture2D
	if grove != null:
		eq(grove.get_height(), 192, "MidGrove was not restacked into a wall")


func test_sky_units_are_small_and_seeded() -> void:
	var wash := SkyPlate.sky_wash()
	ok(wash != null, "night wash exists")
	eq(wash.get_height(), SkyPlate.SKY_H, "wash keeps the authored sky height")
	eq(wash.get_width(), 1, "wash has no repeated cloud fragment; separate stamps provide cloud detail")
	var src := load(SkyPlate.SKY_SRC) as Texture2D
	ok(src != null)
	if src != null:
		var src_img := src.get_image()
		var wash_img := SkyPlate.sky_wash_image()
		if src_img != null and wash_img != null:
			var a := src_img.get_pixel(4, 20)
			var b := wash_img.get_pixel(0, 20)
			ok(absf(a.r - b.r) < 0.08 and absf(a.b - b.b) < 0.08,
					"night wash is sampled from the authored sky, not a handmade ramp")
	var units := SkyPlate.cloud_units()
	ok(units.size() >= 3, "cloud stamps cut from the authored plates")
	var long_n := 0
	for tex in units:
		ok(tex.get_width() <= SkyPlate.UNIT_MAX, "cloud unit is a cut, not the 704 landscape")
		ok(tex.get_width() >= 16, "cloud unit has body")
		if tex.get_width() >= 80 and tex.get_width() > tex.get_height():
			long_n += 1
	ok(long_n >= 1, "at least one elongated magenta/purple cloud from the original plates")
	var fogs := SkyPlate.fog_units()
	ok(fogs.size() >= 1, "fog stamps cut from the authored fog plate")
	var moon := SkyPlate.moon_image()
	eq(moon.get_size(), Vector2i(56, 56), "authored moon is reduced offline to a secondary sky detail")
	ok(_alpha_sum(moon) > 200000, "moon retains its disk and authored texture")
	var a := SkyPlate.layout(42)
	var b := SkyPlate.layout(42)
	var c := SkyPlate.layout(99)
	eq(int(a["moon"]["x"]), int(b["moon"]["x"]), "same seed keeps the moon")
	eq((a["clouds_far"] as Array).size(), (b["clouds_far"] as Array).size(),
			"same seed keeps cloud count")
	ok((a["clouds_far"] as Array).size() >= SkyPlate.CLOUD_FAR_LO,
			"far clouds are scattered, not one plate")
	ok((a["clouds_low"] as Array).size() >= SkyPlate.CLOUD_LOW_LO,
			"low clouds are scattered, not one plate")
	ok((a["clouds_far"] as Array).size() > 8, "far field has more than the old 5-8 wisps")
	ok((a["clouds_low"] as Array).size() > 6, "low field has more than the old 4-6 wisps")
	ok((a["stars"] as Array).size() >= SkyPlate.STAR_MIN, "night sky plants a visible star field")
	ok((a["stars"] as Array).size() <= SkyPlate.STAR_MAX, "stars stay sparse, not a noise plate")
	eq((a["stars"] as Array).size(), (b["stars"] as Array).size(), "same seed keeps star count")
	var stars_a: Array = a["stars"]
	var wave := _star_peak_trough(stars_a[0])
	ok(absf(SkyPlate.star_brightness(stars_a[0], wave.x) - SkyPlate.star_brightness(stars_a[0], wave.y)) > 0.08,
			"a star pip steps between wave peak and trough")
	var pair := _field_phase_pair(stars_a)
	var luma0 := SkyPlate.star_field_luma(stars_a, pair.x)
	var luma1 := SkyPlate.star_field_luma(stars_a, pair.y)
	ok(absf(luma0 - luma1) > 0.08, "star field brightness breathes across ticks")
	ok(
			int(a["moon"]["x"]) != int(c["moon"]["x"])
			or int((a["clouds_far"] as Array)[0]["x"]) != int((c["clouds_far"] as Array)[0]["x"]),
			"a new seed rearranges the sky")
	ok(SkyPlate.CLOUD_FAR_FIELD != SkyPlate.CLOUD_LOW_FIELD, "cloud fields do not share a wrap")
	ok(SkyPlate.FOG_RIDGE_FIELD != SkyPlate.FOG_NEAR_FIELD, "fog fields do not share a wrap")


func test_runtime_sky_uses_units_not_wide_tile() -> void:
	var host := Node2D.new()
	add_child(host)
	var backdrop := ParallaxBackground.new()
	backdrop.name = "ParallaxBackdrop"
	host.add_child(backdrop)
	for spec in [
		["Far", Vector2(0.08, 0.04)],
		["CloudFar", Vector2(0.10, 0.03)],
		["CloudLow", Vector2(0.12, 0.04)],
	]:
		var layer := ParallaxLayer.new()
		layer.name = String(spec[0])
		layer.motion_scale = spec[1]
		layer.motion_mirroring = Vector2(704, 0)
		var spr := Sprite2D.new()
		spr.name = "Sprite"
		spr.centered = false
		layer.add_child(spr)
		backdrop.add_child(layer)
	var extras := Level01Parallax.new()
	add_child(extras)
	extras.build(host)
	var far := backdrop.get_node("Far") as ParallaxLayer
	var far_spr := backdrop.get_node("Far/Sprite") as Sprite2D
	var moon := backdrop.get_node_or_null("SkyMoon/Moon") as Sprite2D
	var cloud_far := backdrop.get_node("CloudFar") as ParallaxLayer
	var cloud_low := backdrop.get_node("CloudLow") as ParallaxLayer
	ok(far_spr.texture != null and far_spr.texture.get_height() >= 400,
			"play keeps an authored-height night wash")
	ok(far_spr.texture.get_width() <= 64, "Far wash is a sampled strip, not the 704 scene tile")
	almost(far.motion_mirroring.x, float(SkyPlate.SKY_COVER_W), 0.01,
			"Far mirrors a full-width coverage region")
	ok(far_spr.region_enabled, "sky sampling strip repeats over the complete view")
	ok(far_spr.region_rect.size.x >= 640.0, "sky region covers the world viewport")
	eq(far_spr.texture_repeat, CanvasItem.TEXTURE_REPEAT_ENABLED, "sky region repeats source pixels")
	ok(moon != null and moon.texture != null, "one moon sprite cut from the sky plate")
	eq(moon.texture.get_width(), 56, "moon uses its offline reduced native pixels")
	eq(backdrop.get_node("SkyMoon").get_child_count(), 1, "moon is instanced once")
	almost((backdrop.get_node("SkyMoon") as ParallaxLayer).motion_mirroring.x, 0.0, 0.01,
			"moon does not tile")
	var far_stamps := _stamp_count(cloud_far)
	var low_stamps := _stamp_count(cloud_low)
	ok(far_stamps >= SkyPlate.CLOUD_FAR_LO, "CloudFar is a stamp field")
	ok(low_stamps >= SkyPlate.CLOUD_LOW_LO, "CloudLow is a stamp field")
	ok(far_stamps > 8, "CloudFar scatters more than the old handful")
	ok(low_stamps > 6, "CloudLow scatters more than the old handful")
	var stars := backdrop.get_node_or_null("SkyStars") as ParallaxLayer
	var star_spr := backdrop.get_node_or_null("SkyStars/Stars") as Sprite2D
	ok(stars != null and star_spr != null, "SkyStars field is planted")
	ok(extras.star_count() >= SkyPlate.STAR_MIN, "star count has a visible floor")
	eq(stars.get_child_count(), 1, "stars share one field sprite, not a node each")
	ok(star_spr.texture != null, "star field has a texture")
	eq(star_spr.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST, "stars stay NEAREST")
	almost(stars.motion_mirroring.x, float(SkyPlate.STAR_FIELD_W), 0.01,
			"stars wrap on their own field")
	var pair := _field_phase_pair(SkyPlate.layout(extras.sky_seed)["stars"] as Array)
	var blink0 := extras.twinkle(pair.x)
	var blink1 := extras.twinkle(pair.y)
	ok(absf(blink0 - blink1) > 0.08, "twinkle() changes field brightness")
	ok(cloud_far.get_node("Sprite").visible == false, "old cloud strip is hidden")
	ok(cloud_far.motion_mirroring.x > 1000.0, "cloud wrap is a field, not 704")
	ok(cloud_far.motion_mirroring.x != cloud_low.motion_mirroring.x,
			"the two cloud fields do not share a seam")
	eq(far_spr.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST, "sky band stays NEAREST")
	ok(extras.sky_seed != 0, "level stores the sky seed")
	var fog := backdrop.get_node_or_null("FogNear") as ParallaxLayer
	if fog != null:
		ok(_stamp_count(fog) >= 3, "fog is blobs, not one mirrored strip")
		ok(fog.motion_mirroring.x != 704.0, "fog wrap is not the old sky tile")


func test_night_sky_has_twinkling_stars() -> void:
	var plan := SkyPlate.layout(7)
	var stars: Array = plan["stars"]
	ok(stars.size() >= SkyPlate.STAR_MIN, "layout plants enough stars to read as a night sky")
	ok(stars.size() <= SkyPlate.STAR_MAX, "stars are not a photo starfield / noise plate")
	var plus_n := 0
	for item in stars:
		var spec: Dictionary = item
		ok(int(spec["x"]) >= 0 and int(spec["x"]) < SkyPlate.STAR_FIELD_W, "star stays on the field")
		ok(int(spec["y"]) >= 0 and int(spec["y"]) < SkyPlate.STAR_FIELD_H, "star sits in the sky band")
		if int(spec.get("kind", 0)) == 1:
			plus_n += 1
	ok(plus_n >= 1, "at least one plus / cross pip among the dots")
	var wave := _star_peak_trough(stars[0])
	ok(absf(SkyPlate.star_brightness(stars[0], wave.x) - SkyPlate.star_brightness(stars[0], wave.y)) > 0.08,
			"star brightness steps between wave peak and trough")
	var pair := _field_phase_pair(stars)
	var frame0 := SkyPlate.star_field_image(stars, pair.x)
	var frame1 := SkyPlate.star_field_image(stars, pair.y)
	ok(_alpha_sum(frame0) > 0, "first star frame has pixels")
	ok(_alpha_sum(frame0) != _alpha_sum(frame1), "two ticks paint different star brightness")
	ok(absf(SkyPlate.star_field_luma(stars, pair.x) - SkyPlate.star_field_luma(stars, pair.y)) > 0.08,
			"twinkle interface changes field luma")


func test_runtime_extras_still_attach() -> void:
	var host := Node2D.new()
	add_child(host)
	var backdrop := ParallaxBackground.new()
	backdrop.name = "ParallaxBackdrop"
	host.add_child(backdrop)
	for name in ["Far", "Mid", "MidGrove", "Hills"]:
		var layer := ParallaxLayer.new()
		layer.name = name
		backdrop.add_child(layer)
		if name == "Far":
			var spr := Sprite2D.new()
			spr.name = "Sprite"
			layer.add_child(spr)
	var extras := Level01Parallax.new()
	add_child(extras)
	extras.build(host)
	ok(host.get_node_or_null("MoodTint") != null, "MoodTint still planted")
	ok(host.get_node_or_null("MoonFill") != null, "MoonFill still planted")
	ok(host.get_node_or_null("CineFx") != null, "CineFx still planted")
	ok(backdrop.get_node_or_null("NearSilhouette") != null, "NearSilhouette still planted")
	ok(backdrop.get_node_or_null("FogRidge") != null, "FogRidge at the mountain feet")
	ok(backdrop.get_node_or_null("FogFar") != null, "FogFar in the grove band")
	ok(backdrop.get_node_or_null("FogNear") != null, "FogNear on the graveyard strip")
	var ridge := backdrop.get_node_or_null("FogRidge") as ParallaxLayer
	var grove_fog := backdrop.get_node_or_null("FogFar") as ParallaxLayer
	var near := backdrop.get_node_or_null("FogNear") as ParallaxLayer
	var mid := backdrop.get_node("Mid")
	var grove := backdrop.get_node("MidGrove")
	var hills := backdrop.get_node("Hills")
	if ridge != null and mid != null:
		ok(ridge.get_index() == mid.get_index() + 1, "FogRidge sits just after Mid")
	if grove_fog != null and grove != null:
		ok(grove_fog.get_index() == grove.get_index() + 1, "FogFar sits just after MidGrove")
	if near != null and hills != null:
		ok(near.get_index() == hills.get_index() + 1, "FogNear sits just after Hills")


func _star_peak_trough(spec: Dictionary) -> Vector2:
	var period := maxf(0.55, float(spec.get("period", 2.6)))
	var phase := float(spec.get("phase", 0.0))
	return Vector2(
			fposmod((PI * 0.5 - phase) * period / TAU, period),
			fposmod((PI * 1.5 - phase) * period / TAU, period))


func _field_phase_pair(stars: Array) -> Vector2:
	## 0.7s is many 12Hz ticks, so two samples cannot share one 4-step bucket.
	var times: Array[float] = [0.0, 0.7, 1.4, 2.1, 2.8, 3.5, 4.2]
	var t_lo := times[0]
	var t_hi := times[0]
	var lo := SkyPlate.star_field_luma(stars, t_lo)
	var hi := lo
	for t in times:
		var luma := SkyPlate.star_field_luma(stars, t)
		if luma < lo:
			lo = luma
			t_lo = t
		if luma > hi:
			hi = luma
			t_hi = t
	return Vector2(t_lo, t_hi)


func _alpha_sum(img: Image) -> int:
	if img == null:
		return 0
	var s := 0
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			s += int(round(img.get_pixel(x, y).a * 255.0))
	return s


func _foot_frac(img: Image) -> float:
	var w := img.get_width()
	var h := img.get_height()
	if w <= 0 or h <= 0:
		return 0.0
	var y := maxi(0, h - 4)
	var n := 0
	for x in w:
		if img.get_pixel(x, y).a >= 0.5:
			n += 1
	return float(n) / float(w)


func _monument_blob_count(img: Image) -> int:
	var w := img.get_width()
	var h := img.get_height()
	var seen := PackedByteArray()
	seen.resize(w * h)
	var hard := 0
	for y in h:
		for x in w:
			var i := y * w + x
			if seen[i] != 0:
				continue
			if img.get_pixel(x, y).a < 0.5:
				seen[i] = 1
				continue
			var stack: Array[Vector2i] = [Vector2i(x, y)]
			seen[i] = 1
			var cells: Array[Vector2i] = []
			while not stack.is_empty():
				var p: Vector2i = stack.pop_back()
				cells.append(p)
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var n: Vector2i = p + d
					if n.x < 0 or n.y < 0 or n.x >= w or n.y >= h:
						continue
					var ni := n.y * w + n.x
					if seen[ni] != 0:
						continue
					if img.get_pixel(n.x, n.y).a < 0.5:
						seen[ni] = 1
						continue
					seen[ni] = 1
					stack.append(n)
			if cells.size() < 20:
				continue
			var x0 := w
			var x1 := 0
			var y0 := h
			var y1 := 0
			for p in cells:
				x0 = mini(x0, p.x)
				x1 = maxi(x1, p.x)
				y0 = mini(y0, p.y)
				y1 = maxi(y1, p.y)
			var bw := x1 - x0 + 1
			var bh := y1 - y0 + 1
			var fill := float(cells.size()) / float(maxi(1, bw * bh))
			var peri := 0
			var cellset: Dictionary = {}
			for p in cells:
				cellset[p] = true
			for p in cells:
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					if not cellset.has(p + d):
						peri += 1
			var jag := float(peri) / sqrt(float(cells.size()))
			if fill >= 0.78 and bh >= 18 and bw >= 14 and bw <= 28 and jag <= 7.2:
				hard += 1
	return hard


func _stamp_count(layer: ParallaxLayer) -> int:
	var n := 0
	if layer == null:
		return 0
	for child in layer.get_children():
		if child is Sprite2D and (
				String(child.name).begins_with("SkyStamp")
				or (String(child.name) != "Sprite" and child.visible)):
			n += 1
	return n


func _load_level() -> Node:
	var packed := load(LEVEL) as PackedScene
	ok(packed != null, "Level01_Static packs")
	var level: Node = packed.instantiate()
	return level
