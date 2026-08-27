extends TestCase
## ToxinMeter logic driven 100% manually — the meter is never added to the
## tree, so no engine _process() interleaves with the hand-fed timeline.
## This makes cadence assertions exact regardless of headless frame rate.


var t: ToxinMeter


func setup() -> void:
	t = ToxinMeter.new() # deliberately NOT add_child()'d


func teardown() -> void:
	t.free()


func test_expose_accumulates_and_clamps_at_max() -> void:
	t.expose(40.0)
	almost(t.toxin, 40.0, 0.01)
	t.expose(9999.0)
	almost(t.toxin, t.max_toxin, 0.01)
	ok(t.is_full())


func test_drains_only_when_not_exposing() -> void:
	t.expose(60.0) # latches exposure
	t._process(1.0 / 60.0) # exposure frame: no drain, resets latch
	almost(t.toxin, 60.0, 0.01, "exposure frame does not drain")
	t._process(1.0) # a full second outside sludge
	almost(t.toxin, 60.0 - t.drain_per_second, 0.05)
	t.expose(10.0) # re-enter sludge for one frame
	t._process(1.0 / 60.0)
	t._process(1.0)
	almost(t.toxin, 70.0 - t.drain_per_second * 2.0, 0.2,
			"drain resumes after leaving")


func test_purify_clears_and_overflow_never_fires_when_not_full() -> void:
	var ticks := [0]
	t.overflow_tick.connect(func(): ticks[0] += 1)
	t.purify(1.0)
	for i in 8:
		t._process(0.25)
	eq(ticks[0], 0)
	almost(t.toxin, 0.0, 0.01)


func test_overflow_tick_cadence_while_continuously_exposed() -> void:
	var ticks := [0]
	t.overflow_tick.connect(func(): ticks[0] += 1)
	t.expose(t.max_toxin)
	for i in 3: # 3 × 0.25 s spans the 0.55 s interval exactly once
		t.expose(0.0) # pools keep the latch closed each frame
		t._process(0.25)
	eq(ticks[0], 1, "overflow fired once after one interval")
	almost(t.toxin, t.max_toxin, 0.01, "no drain while exposed")

	var capped: int = ticks[0]
	for i in 2: # 0.5 s more — below threshold for a second tick
		t.expose(0.0)
		t._process(0.25)
	eq(ticks[0], capped, "still only one tick")
	almost(t.toxin, t.max_toxin, 0.01)

	t.purify(1.0) # leave the pool: drains to zero, no further ticks
	for i in 4:
		t._process(0.25)
	eq(ticks[0], capped, "overflow stops once below full")
	almost(t.toxin, 0.0, 0.01)
