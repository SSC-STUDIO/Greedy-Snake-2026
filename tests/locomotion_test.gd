extends TestCase
## Locomotion maths for PlayerController, verified WITHOUT input injection.
## Every physics step is followed by an awaited engine frame so contact and
## floor bookkeeping behave exactly like in-game; nothing runs in tight loops.

var ctrl: PlayerController
var body: CharacterBody2D


func setup() -> void:
	ctrl = PlayerController.new()
	add_child(ctrl)
	build_floor(self, 320.0)
	body = CharacterBody2D.new()
	body.position = Vector2(320, -6) # slight drop onto the y==0 surface
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
		await get_tree().physics_frame


func test_body_settles_grounded_on_the_fixture_floor() -> void:
	await _step(8)
	almost(body.global_position.y, 0.0, 2.0, "feet resting on y == 0")
	ok(body.is_on_floor(), "grounded after settle")


func test_ground_deceleration_is_gradual_not_instant() -> void:
	await _step(8)
	ok(body.is_on_floor(), "rig grounded before decel run")
	body.velocity.x = ctrl.max_speed
	var steps := 0
	while body.velocity.x > 0.5 and steps < 60:
		await _step()
		steps += 1
	ok(steps >= 10 and steps <= 40,
			"stopping takes deliberate frames (%d)" % steps)


func test_turning_rate_exceeds_stopping_rate() -> void:
	var stopping := ctrl.deceleration * (1.0 / 60.0)
	var turning := ctrl.acceleration * 1.55 * (1.0 / 60.0)
	ok(turning > stopping, "turning outpaces braking")


func test_fall_gravity_scale_heavier_than_rise() -> void:
	body.position = Vector2(320, -200)
	body.velocity.y = 20.0 # descending
	ctrl.physics_tick(body, 1.0 / 60.0, 1.0)
	var g_fall := body.velocity.y - 20.0

	body.velocity.y = -20.0 # ascending (jump held is irrelevant headless)
	ctrl.physics_tick(body, 1.0 / 60.0, 1.0)
	var g_up := absf(absf(body.velocity.y) - 20.0)

	ok(g_fall > g_up * 1.5, "falling gravity amplified (%.1f vs %.1f)" % [g_fall, g_up])


func test_dash_grants_iframes_and_cooldown_then_recovers() -> void:
	await _step(8)
	ok(body.is_on_floor(), "grounded before dashing")
	body.velocity = Vector2.ZERO
	ctrl.facing = 1
	ctrl.call("_try_dash", body) # bypass Input: dash semantics under test
	ok(ctrl.is_dashing())
	ok(ctrl.is_invincible(), "dash carries i-frames")

	await _step(1)
	almost(body.velocity.x, ctrl.dash_speed, 1.0, "dash locks horizontal speed")
	almost(body.velocity.y, 0.0, 0.01, "no vertical drift mid-dash")

	for i in int(ctrl.dash_duration * 60.0) + 1:
		ctrl.physics_tick(body, 1.0 / 60.0, 1.0)
	ok(not ctrl.is_dashing(), "dash timer expired")
	for i in int((ctrl.dash_cooldown - ctrl.dash_duration) * 60.0) + 1:
		ctrl.physics_tick(body, 1.0 / 60.0, 1.0)
	ok(not ctrl.is_dashing(), "cooldown window elapsed")


func test_extra_jump_requires_unlock() -> void:
	await _step(8)
	ok(body.is_on_floor())
	ctrl.extra_jumps_unlocked = false
	body.position.y = -80.0
	body.velocity.y = 20.0
	# Burn coyote time so this is a true air jump, not a grounded one.
	await _step(int(ctrl.coyote_time * 60.0) + 3)
	ok(not body.is_on_floor())
	eq(ctrl._jumps_left, 0, "no bonus charges while locked")
	ctrl._buffer = 1.0
	ctrl._try_jump(body)
	ok(body.velocity.y > -40.0, "locked extra jump does not fire")
	ctrl.grant_air_jump()
	ctrl._buffer = 1.0
	ctrl._try_jump(body)
	ok(body.velocity.y < -100.0, "grant_air_jump can still give one extra")


func test_camera_land_punch_decays() -> void:
	var cam := GameCamera.new()
	add_child(cam)
	cam.notify_landed()
	almost(cam.land_punch(), 1.0, 0.01)
	cam._physics_process(0.12)
	ok(cam.land_punch() < 0.7, "landing settle fades")
