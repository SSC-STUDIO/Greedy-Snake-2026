extends TestCase
## GameCamera: 2.5K pixel snap, look-ahead, deadzone, land punch, letterbox.


func teardown() -> void:
	Director.set_letterbox(false, true)


func test_pixel_grid_matches_world_render_texel() -> void:
	almost(GameCamera.PIXEL_GRID, 1.0, 0.0001)
	almost(GameCamera.PIXEL_GRID * GameCamera.ZOOM, 1.0, 0.0001, "one texel before output enlargement")


func test_snap_to_world_pixels() -> void:
	var cam := GameCamera.new()
	add_child(cam)
	var p := cam.snap_to_pixel(Vector2(10.13, -3.37))
	almost(p.x, 10.0, 0.0001)
	almost(p.y, -3.0, 0.0001)
	var q := cam.snap_to_pixel(Vector2(2.5, 1.0))
	almost(q.x, 3.0, 0.0001)
	almost(q.y, 1.0, 0.0001)


func test_physics_snaps_position_without_player() -> void:
	var cam := GameCamera.new()
	add_child(cam)
	cam.global_position = Vector2(100.13, 200.19)
	cam._physics_process(1.0 / 60.0)
	var snapped := cam.snap_to_pixel(cam.global_position)
	almost(cam.global_position.x, snapped.x, 0.0001)
	almost(cam.global_position.y, snapped.y, 0.0001)


func test_idle_look_ahead_stays_inside_deadzone() -> void:
	var cam := GameCamera.new()
	add_child(cam)
	var idle := cam.desired_look_ahead(1, 0.0, 300.0)
	ok(absf(idle) < cam.deadzone.x, "idle look does not drag past deadzone")
	ok(absf(idle) < absf(cam.desired_look_ahead(1, 108.0, 300.0)), "run looks farther")


func test_look_ahead_ramps_with_speed() -> void:
	var cam := GameCamera.new()
	add_child(cam)
	var slow := cam.desired_look_ahead(1, 20.0, 300.0)
	var fast := cam.desired_look_ahead(1, 108.0, 300.0)
	ok(absf(fast) > absf(slow), "look ramps instead of snapping at 18px/s")
	almost(fast, cam.look_ahead, 0.01)


func test_climb_damps_look_ahead() -> void:
	var cam := GameCamera.new()
	add_child(cam)
	var low := cam.desired_look_ahead(1, 108.0, 300.0)
	var high := cam.desired_look_ahead(1, 108.0, 100.0)
	ok(absf(high) < absf(low) * 0.7, "shaft damps horizontal look")


func test_look_ahead_rate_boosts_on_reverse_and_dash() -> void:
	var cam := GameCamera.new()
	add_child(cam)
	var hold := cam.look_ahead_rate(40.0, 40.0, false)
	var flip := cam.look_ahead_rate(40.0, -40.0, false)
	ok(flip > hold * 1.5, "reverse look catches up")
	ok(cam.look_ahead_rate(0.0, 40.0, true) > hold, "dash speeds look")


func test_deadzone_holds_small_error() -> void:
	var cam := GameCamera.new()
	add_child(cam)
	var cur := Vector2(100, 200)
	eq(cam.deadzone_target(cur, cur + Vector2(8, 10)), cur, "inside deadzone camera holds")
	var far := cam.deadzone_target(cur, cur + Vector2(40, 0))
	almost(far.x, cur.x + 40.0 - cam.deadzone.x, 0.01, "follow the overflow edge")
	almost(far.y, cur.y, 0.01)


func test_keep_in_view_pulls_back_from_edge() -> void:
	var cam := GameCamera.new()
	add_child(cam)
	cam.zoom = Vector2(GameCamera.ZOOM, GameCamera.ZOOM)
	var player := Vector2(400, 240)
	var drifted := player + Vector2(400, 0)
	var fixed := cam.keep_in_view(drifted, player)
	ok(absf(player.x - fixed.x) < absf(player.x - drifted.x), "pulls back")
	var half := 640.0 / (2.0 * GameCamera.ZOOM)
	ok(absf(player.x - fixed.x) <= half - 40.0, "player stays inside margin")


func test_letterbox_insets_and_softens_punch() -> void:
	var cam := GameCamera.new()
	add_child(cam)
	cam.zoom = Vector2(GameCamera.ZOOM, GameCamera.ZOOM)
	Director.set_letterbox(false, true)
	almost(cam.letter_inset(), 0.0, 0.01)
	cam.notify_landed()
	var punch_open := cam.punch_offset().y
	Director.set_letterbox(true, true)
	ok(cam.letter_inset() > 10.0, "widescreen crops view")
	ok(absf(cam.punch_offset().y) < absf(punch_open) * 0.5, "letterbox damps land punch")
	Director.set_letterbox(false, true)


func test_land_punch_decays_without_player() -> void:
	var cam := GameCamera.new()
	add_child(cam)
	cam.notify_landed()
	almost(cam.land_punch(), 1.0, 0.01)
	cam._physics_process(0.12)
	ok(cam.land_punch() < 0.7, "landing settle fades")
	ok(cam.offset.y > 0.0, "settle lives on offset, not follow dest")
