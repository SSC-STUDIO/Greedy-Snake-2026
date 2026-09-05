extends TestCase
## PlayerController feel: coyote, jump buffer through dash, landing extra-jump
## steal, jump-cut delay, apex hang, terminal fall, wall unstick. No InputMap.

var ctrl: PlayerController
var body: CharacterBody2D


func setup() -> void:
	ctrl = PlayerController.new()
	add_child(ctrl)
	build_floor(self, 320.0)
	body = CharacterBody2D.new()
	body.position = Vector2(320, -6)
	body.floor_snap_length = 4.0
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(14, 26)
	col.shape = shape
	col.position = Vector2(0, -13)
	body.add_child(col)
	add_child(body)


func _step(n: int = 1) -> void:
	for i in n:
		ctrl.physics_tick(body, 1.0 / 60.0, 1.0)
		body.move_and_slide()
		ctrl.settle_after_slide(body)
		await get_tree().physics_frame


func _airborne_above_floor(height: float) -> void:
	body.position = Vector2(320, -height)
	body.velocity = Vector2.ZERO
	body.floor_snap_length = 0.0


func _sync_airborne() -> void:
	body.move_and_slide()
	await get_tree().physics_frame
	body.move_and_slide()
	await get_tree().physics_frame


func test_coyote_outlasts_a_short_walkoff() -> void:
	await _step(8)
	ok(body.is_on_floor(), "settled")
	almost(ctrl._coyote, ctrl.coyote_time, 0.001, "coyote refreshed on floor")
	body.position.y = -80.0
	body.velocity.y = 10.0
	await _step(1)
	ok(not body.is_on_floor(), "walked off")
	ok(ctrl._coyote > 0.05, "coyote still live one frame later (%.3f)" % ctrl._coyote)
	var frames := 0
	while ctrl._coyote > 0.0 and frames < 20:
		await _step()
		frames += 1
	ok(frames >= 5 and frames <= 12, "coyote is ~7 frames at 60Hz (%d)" % frames)


func test_jump_buffer_survives_full_dash() -> void:
	await _step(8)
	ok(body.is_on_floor())
	ctrl.facing = 1
	ctrl.call("_try_dash", body)
	ctrl._buffer = ctrl.jump_buffer_time
	var dash_frames := int(ctrl.dash_duration * 60.0) + 1
	for i in dash_frames:
		ctrl.physics_tick(body, 1.0 / 60.0, 1.0)
	ok(ctrl._buffer > 0.0, "buffer frozen during dash (%.3f)" % ctrl._buffer)
	ok(not ctrl.is_dashing(), "dash ended")
	ctrl.physics_tick(body, 1.0 / 60.0, 1.0)
	ok(body.velocity.y < -100.0, "buffered jump fires the tick dash ends")


func test_falling_near_floor_keeps_extra_jump_for_landing() -> void:
	await _step(8)
	_airborne_above_floor(10.0)
	body.velocity.y = 90.0
	await _sync_airborne()
	ok(not body.is_on_floor(), "hovering just above the floor")
	ctrl._coyote = 0.0
	ctrl._jumps_left = 1
	ctrl.extra_jumps_unlocked = true
	ctrl._buffer = 1.0
	ctrl.call("_try_jump", body)
	eq(ctrl._jumps_left, 1, "near-floor extra jump is not stolen")
	ok(body.velocity.y > 0.0, "still falling; buffer waits for land")
	ok(ctrl._buffer > 0.0, "land buffer kept")


func test_high_air_extra_jump_still_fires() -> void:
	await _step(8)
	_airborne_above_floor(120.0)
	body.velocity.y = 40.0
	await _sync_airborne()
	ok(not body.is_on_floor(), "high in the air")
	ctrl._coyote = 0.0
	ctrl._jumps_left = 1
	ctrl.extra_jumps_unlocked = true
	ctrl._buffer = 1.0
	ctrl.call("_try_jump", body)
	eq(ctrl._jumps_left, 0, "high air extra jump consumes a charge")
	ok(body.velocity.y < -100.0, "extra jump launched")


func test_jump_cut_waits_min_hold() -> void:
	_airborne_above_floor(80.0)
	ctrl.call("_do_jump", body, false)
	var before := body.velocity.y
	ctrl._apply_gravity(body, 1.0 / 60.0)
	var applied := body.velocity.y - before
	var rise := float(ProjectSettings.get_setting("physics/2d/default_gravity")) / 60.0
	almost(applied, rise, 1.0, "first airborne tick is rise gravity, not cut")


func test_apex_hang_is_lighter_than_fall() -> void:
	_airborne_above_floor(80.0)
	body.velocity.y = 8.0
	ctrl._apply_gravity(body, 1.0 / 60.0)
	var g_apex := body.velocity.y - 8.0
	body.velocity.y = 40.0
	ctrl._apply_gravity(body, 1.0 / 60.0)
	var g_fall := body.velocity.y - 40.0
	ok(g_apex < g_fall * 0.55, "apex hang (%.1f) lighter than fall (%.1f)" % [g_apex, g_fall])


func test_fall_speed_is_capped() -> void:
	_airborne_above_floor(80.0)
	body.velocity.y = 800.0
	ctrl._apply_gravity(body, 1.0 / 60.0)
	almost(body.velocity.y, ctrl.max_fall_speed, 0.01, "terminal fall")


func test_wall_unstick_cancels_into_wall_speed() -> void:
	var wall := StaticBody2D.new()
	wall.collision_layer = 1
	wall.collision_mask = 0
	wall.position = Vector2(360, -40)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20, 160)
	col.shape = shape
	wall.add_child(col)
	add_child(wall)
	await flush(2)

	body.position = Vector2(344, -70)
	body.velocity = Vector2(120.0, 40.0)
	for i in 8:
		body.move_and_slide()
		ctrl.settle_after_slide(body)
		await get_tree().physics_frame
	ok(body.is_on_wall() or body.velocity.x <= 1.0, "contacted or released the wall")
	ok(body.velocity.x <= 1.0, "no residual into-wall vx (%.1f)" % body.velocity.x)


func test_ground_accel_still_weighted() -> void:
	var time_to_max := ctrl.max_speed / ctrl.acceleration
	ok(time_to_max >= 0.20 and time_to_max <= 0.35,
			"startup stays heavy (%.2fs)" % time_to_max)
	ok(ctrl.acceleration * 1.55 > ctrl.deceleration, "turn still beats brake")
	ok(ctrl.air_acceleration > 220.0, "air steer covers ZOOM=2 ledges")


func test_held_jump_height_stays_level_tuned() -> void:
	# Levels are authored around v=-268 / g=980 → ~37px. Don't silently retune.
	var g := float(ProjectSettings.get_setting("physics/2d/default_gravity"))
	var height := (ctrl.jump_velocity * ctrl.jump_velocity) / (2.0 * g)
	ok(height >= 34.0 and height <= 40.0, "single jump ~37px (%.1f)" % height)
	almost(ctrl.jump_velocity, -268.0, 0.01)
