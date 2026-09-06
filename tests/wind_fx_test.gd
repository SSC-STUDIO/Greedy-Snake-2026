extends TestCase
## Wind is visible: dust / leaf flecks enter from the upwind edge and cross the view.


func setup() -> void:
	WorldClock.reset()
	WorldClock.menu_hold = false
	WorldClock.set_zone(WorldClock.Zone.OUTDOORS)


func teardown() -> void:
	WorldClock.reset()


func test_motes_enter_upwind_and_cross_the_view() -> void:
	WorldClock.wind_heading = 1.0
	WorldClock._heading_target = 1.0
	WorldClock._snap_wind_speed()
	var fx := WindFx.new()
	add_child(fx)
	var rect := Rect2(Vector2(1000, 100), Vector2(640, 360))
	var mote := fx.spawn_mote(rect)
	ok(mote != null)
	if mote == null:
		return
	eq(WindFx.wind_heading(), 1.0)
	ok(mote.position.x < rect.position.x, "an east wind spawns motes just off the west edge")
	ok(mote.position.y > rect.position.y and mote.position.y < rect.end.y, "motes spawn inside the view height")
	eq(mote.position, mote.position.round(), "motes sit on the pixel grid")
	var x0 := mote.position.x
	mote._process(0.2)
	ok(mote.position.x > x0, "motes travel downwind")
	ok(mote.modulate.a > 0.0 and mote.modulate.a < 0.8, "motes fade in, never opaque")
	for i in 120:
		mote._process(0.1)
	ok(mote.is_queued_for_deletion(), "motes free themselves once past the far edge")
	WorldClock.wind_heading = -1.0
	WorldClock._heading_target = -1.0
	WorldClock._snap_wind_speed()
	var west := fx.spawn_mote(rect)
	ok(west.position.x > rect.end.x, "a west wind spawns motes off the east edge")
	west._process(0.2)
	ok(west.position.x < rect.end.x + WindFx.EDGE_PAD, "and they travel west")


func test_gale_moves_motes_faster_than_a_breeze() -> void:
	WorldClock.wind_heading = 1.0
	WorldClock._heading_target = 1.0
	WorldClock.set_weather(WorldClock.Weather.HAZE, true)
	WorldClock._snap_wind_speed()
	var fx := WindFx.new()
	add_child(fx)
	var rect := Rect2(Vector2.ZERO, Vector2(640, 360))
	var a := fx.spawn_mote(rect)
	a._speed_k = 1.0
	var ax := a.position.x
	a._process(0.5)
	var breeze := a.position.x - ax
	WorldClock.set_weather(WorldClock.Weather.EMBER_WIND, true)
	WorldClock._snap_wind_speed()
	var b := fx.spawn_mote(rect)
	b._speed_k = 1.0
	var bx := b.position.x
	b._process(0.5)
	ok(b.position.x - bx > breeze * 1.3, "ember wind carries dust noticeably faster")


func test_emitter_caps_count_and_respects_zone() -> void:
	var fx := WindFx.new()
	add_child(fx)
	var rect := Rect2(Vector2.ZERO, Vector2(640, 360))
	for i in WindFx.MAX_MOTES + 6:
		fx.spawn_mote(rect)
	ok(fx.mote_count() == WindFx.MAX_MOTES + 6, "spawn_mote itself is uncapped; the tick is")
	fx._headless = false
	WorldClock.set_zone(WorldClock.Zone.INDOORS)
	var before := fx.mote_count()
	fx._process(2.0)
	eq(fx.mote_count(), before, "indoors the emitter adds nothing")
	WorldClock.set_zone(WorldClock.Zone.OUTDOORS)
	WorldClock.set_weather(WorldClock.Weather.EMBER_WIND, true)
	WorldClock._snap_wind_speed()
	fx._process(2.0)
	eq(fx.mote_count(), before, "the tick never exceeds MAX_MOTES")
	for child in fx.get_children():
		child.free()
	fx._process(1.0)
	ok(fx.mote_count() > 0, "outdoors in a gale the tick does spawn")
	ok(fx.mote_count() <= WindFx.MAX_MOTES)
