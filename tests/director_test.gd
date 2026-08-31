extends TestCase
## Director: step order, skip, and a hard rule — never touch Engine.time_scale.


func setup() -> void:
	Director.abort()
	Director.resume()
	Director.choice_hold = false
	Engine.time_scale = 1.0


func teardown() -> void:
	Director.abort()
	Director.resume()
	Engine.time_scale = 1.0


func test_empty_play_finishes_immediately() -> void:
	Director.play([])
	await flush(2)
	ok(not Director.playing, "empty script finishes")
	ok(not Director.is_input_locked())


func test_wait_then_unlock_releases_lock() -> void:
	Director.play([
		{"kind": "lock"},
		{"kind": "wait", "seconds": 0.05},
		{"kind": "unlock"},
	])
	ok(Director.playing)
	ok(Director.is_input_locked())
	var done := await wait_until(func() -> bool: return not Director.playing, 90)
	ok(done, "wait step elapsed")
	ok(not Director.is_input_locked())


func test_skip_advances_long_wait() -> void:
	Director.play([
		{"kind": "wait", "seconds": 8.0},
		{"kind": "unlock"},
	])
	await flush(2)
	Director.skip_step()
	var done := await wait_until(func() -> bool: return not Director.playing, 40)
	ok(done, "skip ended the long wait")


func test_play_does_not_touch_time_scale() -> void:
	Engine.time_scale = 1.0
	Director.play([
		{"kind": "wait", "seconds": 0.02},
		{"kind": "caption", "text": "test", "hold": 0.02},
		{"kind": "unlock"},
	])
	eq(Engine.time_scale, 1.0, "play start leaves time_scale")
	await wait_until(func() -> bool: return not Director.playing, 90)
	eq(Engine.time_scale, 1.0, "play finish leaves time_scale")


func test_play_queues_second_script() -> void:
	var kinds: Array[String] = []
	var on_step := func(_i: int, step: Dictionary) -> void:
		kinds.append(String(step.get("kind", "")))
	Director.step_started.connect(on_step)
	Director.play([{"kind": "wait", "seconds": 8.0}])
	Director.play([{"kind": "lock"}, {"kind": "unlock"}])
	ok(Director.playing, "first script still playing")
	ok(kinds.has("wait"), "first script started")
	Director.skip_step()
	var done := await wait_until(func() -> bool: return not Director.playing, 60)
	ok(done, "both queued scripts finished")
	ok(kinds.has("lock"), "second script ran after the first")
	Director.step_started.disconnect(on_step)


func test_fade_to_queues_latest_target() -> void:
	Director.last_fade_target = ""
	Director.fade_to("res://scenes/ui/TitleScreen.tscn")
	Director.fade_to("res://scenes/levels/TestArena.tscn")
	var done := await wait_until(func() -> bool: return not Director.is_fading(), 120)
	ok(done, "fade finished")
	eq(Director.last_fade_target, "res://scenes/levels/TestArena.tscn", "second fade_to wins")


func test_play_runs_two_queued_scripts_in_order() -> void:
	var kinds: Array[String] = []
	var on_step := func(_i: int, step: Dictionary) -> void:
		kinds.append(String(step.get("kind", "")))
	Director.step_started.connect(on_step)
	Director.play([{"kind": "wait", "seconds": 8.0}])
	Director.play([{"kind": "lock"}])
	Director.play([{"kind": "sfx", "id": "ui_select"}])
	Director.skip_step()
	var done := await wait_until(func() -> bool: return not Director.playing, 80)
	ok(done, "queued scripts finished")
	ok(kinds.has("wait") and kinds.has("lock") and kinds.has("sfx"), "all three scripts ran")
	var wait_i := kinds.find("wait")
	var lock_i := kinds.find("lock")
	var sfx_i := kinds.find("sfx")
	ok(wait_i >= 0 and lock_i > wait_i and sfx_i > lock_i, "queue order preserved")
	Director.step_started.disconnect(on_step)
