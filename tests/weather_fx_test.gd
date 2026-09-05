extends TestCase
## Rain streaks collide in world space: ground, toxin water, Ember Nest.


func setup() -> void:
	WorldClock.reset()
	WorldClock.menu_hold = false
	Director.abort()
	Director.choice_hold = false


func teardown() -> void:
	WorldClock.reset()
	WorldClock.menu_hold = false
	Director.abort()
	Director.choice_hold = false


func test_canvas_to_world_is_identity_without_camera() -> void:
	var fx := WeatherFx.new()
	add_child(fx)
	await flush(1)
	eq(fx.canvas_to_world(Vector2(40, 80)), Vector2(40, 80))
	eq(fx.world_to_canvas(Vector2(40, 80)), Vector2(40, 80))


func test_drop_hits_ground_platform() -> void:
	var arena := Node2D.new()
	add_child(arena)
	var plat := SolidPlatform.new()
	plat.size = Vector2(80, 16)
	plat.position = Vector2(100, 200)
	arena.add_child(plat)
	var fx := WeatherFx.new()
	arena.add_child(fx)
	await flush(2)
	var hit: Dictionary = fx.probe_segment(Vector2(140, 188), Vector2(140, 210))
	eq(hit["kind"], &"ground", "rain stops on the grass, not the viewport floor")
	ok((hit["point"] as Vector2).y <= 201.0, "contact is the platform top")
	eq(fx.probe_segment(Vector2(140, 40), Vector2(140, 52))["kind"], &"", "open air is a miss")


func test_drop_hits_pool_water_before_pit_floor() -> void:
	var arena := Node2D.new()
	add_child(arena)
	var floor := SolidPlatform.new()
	floor.size = Vector2(112, 48)
	floor.position = Vector2(400, 352)
	arena.add_child(floor)
	var pool := ToxinPool.new()
	pool.position = Vector2(400, 336)
	arena.add_child(pool)
	pool.configure(Vector2(112, 32))
	var fx := WeatherFx.new()
	arena.add_child(fx)
	await flush(2)
	ok(pool.is_in_group("toxin_pools"))
	var surface: Dictionary = fx.probe_segment(Vector2(450, 328), Vector2(450, 342))
	eq(surface["kind"], &"toxin", "rain kisses the scum, not the pit floor")
	almost((surface["point"] as Vector2).y, 337.0, 1.5, "splash sits on the waterline")
	eq(pool.splash_point(450.0), surface["point"])
	var submerged: Dictionary = fx.probe_segment(Vector2(450, 350), Vector2(450, 358))
	eq(submerged["kind"], &"toxin", "a drop already in the volume still counts as water")


func test_drop_hits_pit_lip_as_ground() -> void:
	var arena := Node2D.new()
	add_child(arena)
	var lip := SolidPlatform.new()
	lip.size = Vector2(32, 16)
	lip.position = Vector2(400, 336)
	arena.add_child(lip)
	var floor := SolidPlatform.new()
	floor.size = Vector2(112, 48)
	floor.position = Vector2(400, 352)
	arena.add_child(floor)
	var pool := ToxinPool.new()
	pool.position = Vector2(400, 336)
	arena.add_child(pool)
	pool.configure(Vector2(112, 32))
	var fx := WeatherFx.new()
	arena.add_child(fx)
	await flush(2)
	var lip_hit: Dictionary = fx.probe_segment(Vector2(416, 328), Vector2(416, 342))
	eq(lip_hit["kind"], &"ground", "rain on the pit step is turf, not a green kiss")
	var water: Dictionary = fx.probe_segment(Vector2(456, 328), Vector2(456, 342))
	eq(water["kind"], &"toxin", "open water between the lips still kisses")


func test_pool_volume_reads_and_scum_snaps() -> void:
	var pool := ToxinPool.new()
	add_child(pool)
	pool.configure(Vector2(112, 32))
	await flush(1)
	eq(pool.z_index, -1, "water sits under pit lips")
	var volume := pool.get_node_or_null("Volume") as ColorRect
	ok(volume != null, "pool has a liquid body, not only a 5px film")
	if volume != null:
		eq(volume.size, Vector2(112, 32))
		ok(volume.color.g > volume.color.r, "volume stays teal")
	ok(not pool._scum_sprites.is_empty(), "scum film still tiles the surface")
	pool._process(0.35)
	for spr in pool._scum_sprites:
		eq(spr.position.y, roundf(spr.position.y), "scum stays on the pixel grid")
		ok(spr.modulate.g > 1.0, "scum is pre-boosted against MoodTint")


func test_drop_hits_ember_nest_bowl() -> void:
	var arena := Node2D.new()
	add_child(arena)
	var plat := SolidPlatform.new()
	plat.size = Vector2(200, 32)
	plat.position = Vector2(80, 320)
	arena.add_child(plat)
	var nest := EmberNest.new()
	nest.position = Vector2(150, 306)
	arena.add_child(nest)
	var fx := WeatherFx.new()
	arena.add_child(fx)
	await flush(2)
	ok(nest.is_in_group("ember_nests"))
	var hit: Dictionary = fx.probe_segment(Vector2(150, 278), Vector2(150, 298))
	eq(hit["kind"], &"nest", "rain hits the iron bowl before the turf")
	nest.apply_persistent_state({"lit": true})
	var lit: Dictionary = fx.probe_segment(Vector2(150, 278), Vector2(150, 298))
	eq(lit["kind"], &"nest_lit", "lit nest steams instead of a cold iron kiss")


func test_resolve_fall_recycles_to_the_sky() -> void:
	var arena := Node2D.new()
	add_child(arena)
	var plat := SolidPlatform.new()
	plat.size = Vector2(80, 16)
	plat.position = Vector2(0, 100)
	arena.add_child(plat)
	var fx := WeatherFx.new()
	arena.add_child(fx)
	await flush(2)
	var resolved: Dictionary = fx.resolve_fall(Vector2(40, 90), Vector2(40, 120), Vector2(640, 360))
	eq(resolved["kind"], &"ground")
	ok(resolved["recycled"])
	ok((resolved["world"] as Vector2).y < 0.0, "streak restarts above the view")
	var wrap: Dictionary = fx.resolve_fall(Vector2(20, 350), Vector2(20, 372), Vector2(640, 360))
	ok(wrap["recycled"], "empty sky still wraps at the viewport")
	eq(wrap["kind"], &"")


func test_canvas_to_world_follows_the_level_camera() -> void:
	var vp := SubViewport.new()
	vp.size = PresentationMetrics.WORLD_SIZE
	vp.world_2d = World2D.new()
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var world := Node2D.new()
	vp.add_child(world)
	var cam := Camera2D.new()
	cam.position = Vector2(320, 200)
	world.add_child(cam)
	cam.make_current()
	var plat := SolidPlatform.new()
	plat.size = Vector2(640, 32)
	plat.position = Vector2(0, 280)
	world.add_child(plat)
	var fx := WeatherFx.new()
	world.add_child(fx)
	await flush(3)
	var mid := Vector2(PresentationMetrics.WORLD_SIZE) * 0.5
	var mapped := fx.canvas_to_world(mid)
	ok(absf(mapped.x - cam.get_screen_center_position().x) < 2.0, "view center maps to camera")
	ok(absf(mapped.y - cam.get_screen_center_position().y) < 2.0)
	# Grass at world y=280 sits near canvas y=260 when the camera is at y=200.
	var from_w := fx.canvas_to_world(Vector2(320, 248))
	var to_w := fx.canvas_to_world(Vector2(320, 268))
	var hit: Dictionary = fx.probe_segment(from_w, to_w)
	eq(hit["kind"], &"ground", "mapped rain still finds the platform under the camera")
	var world_pt := Vector2(400, 280)
	var back: Vector2 = fx.canvas_to_world(fx.world_to_canvas(world_pt))
	almost(back.x, world_pt.x, 0.51, "world→canvas→world roundtrips")
	almost(back.y, world_pt.y, 0.51)
	var view := Rect2(cam.get_screen_center_position() - Vector2(PresentationMetrics.WORLD_SIZE) * 0.5, Vector2(PresentationMetrics.WORLD_SIZE))
	var resolved: Dictionary = fx.resolve_fall(Vector2(320, 268), Vector2(320, 292), view)
	eq(resolved["kind"], &"ground", "a world-space drop stops on the turf")
	ok((resolved["world"] as Vector2).y < view.position.y + 1.0, "recycle is above the lens, not inside the dirt")
