extends TestCase
## WorldClock: slow cemetery cycle, weather blends, freeze rules, save restore.


func setup() -> void:
	WorldClock.reset()
	WorldClock.menu_hold = false
	WorldClock.time_scale = 1.0
	Director.abort()
	Director.resume()
	Director.choice_hold = false
	if get_tree().paused:
		get_tree().paused = false
	SaveData.save_path = "user://rustgrave_test_clock_save.cfg"
	SaveData.delete_save()


func teardown() -> void:
	WorldClock.reset()
	WorldClock.menu_hold = false
	Director.abort()
	Director.resume()
	Director.choice_hold = false
	if get_tree().paused:
		get_tree().paused = false
	SaveData.delete_save()
	SaveData.save_path = "user://rustgrave_save.cfg"


func test_advance_changes_phase() -> void:
	WorldClock.set_time(0.48)
	eq(WorldClock.phase, WorldClock.Phase.DAY, "just before dusk")
	WorldClock.advance(CYCLE_CROSS)
	eq(WorldClock.phase, WorldClock.Phase.DUSK, "crossing 0.50 becomes dusk")
	WorldClock.set_time(0.61)
	WorldClock.advance(CYCLE_CROSS)
	eq(WorldClock.phase, WorldClock.Phase.NIGHT, "crossing 0.62 becomes night")


func test_pause_freezes_clock() -> void:
	WorldClock.set_time(0.30)
	var t0 := WorldClock.time_of_day
	get_tree().paused = true
	ok(WorldClock.is_frozen(), "paused tree freezes the clock")
	WorldClock._process(8.0)
	almost(WorldClock.time_of_day, t0, 0.0001, "paused clock does not advance")
	get_tree().paused = false
	ok(not WorldClock.is_frozen())


func test_cutscene_freezes_clock() -> void:
	WorldClock.set_time(0.30)
	var t0 := WorldClock.time_of_day
	Director.play([
		{"kind": "lock"},
		{"kind": "wait", "seconds": 30.0},
		{"kind": "unlock"},
	])
	ok(Director.playing)
	ok(WorldClock.is_frozen(), "Director.playing freezes the clock")
	WorldClock._process(8.0)
	almost(WorldClock.time_of_day, t0, 0.0001, "cutscene clock does not jump")
	Director.abort()
	ok(not WorldClock.is_frozen())


func test_choice_hold_freezes_clock() -> void:
	WorldClock.set_time(0.40)
	var t0 := WorldClock.time_of_day
	Director.choice_hold = true
	ok(WorldClock.is_frozen())
	WorldClock._process(5.0)
	almost(WorldClock.time_of_day, t0, 0.0001)
	Director.choice_hold = false


func test_menu_hold_freezes_clock() -> void:
	WorldClock.hold_for_menu()
	ok(WorldClock.is_frozen(), "title pins the clock")
	almost(WorldClock.time_of_day, WorldClock.TITLE_TIME, 0.0001)
	eq(WorldClock.phase, WorldClock.Phase.DUSK, "title stays at dusk")
	var t0 := WorldClock.time_of_day
	WorldClock._process(10.0)
	almost(WorldClock.time_of_day, t0, 0.0001, "menu does not roll the sky")
	WorldClock.release_menu()
	ok(not WorldClock.is_frozen())


func test_weather_blend_stays_legal() -> void:
	WorldClock.set_weather(WorldClock.Weather.HAZE, true)
	WorldClock.set_weather(WorldClock.Weather.RAIN, false)
	eq(WorldClock.weather, WorldClock.Weather.RAIN)
	eq(WorldClock.previous_weather, WorldClock.Weather.HAZE)
	ok(WorldClock.weather_blend >= 0.0 and WorldClock.weather_blend < 1.0, "blend starts open")
	WorldClock._process(1.0)
	ok(WorldClock.weather_blend > 0.0 and WorldClock.weather_blend <= 1.0)
	ok(WorldClock.weather >= WorldClock.Weather.HAZE)
	ok(WorldClock.weather <= WorldClock.Weather.EMBER_WIND)
	ok(WorldClock.rain_opacity() > 0.0, "rain opacity rises during blend-in")
	WorldClock.set_weather(WorldClock.Weather.FOG, true)
	almost(WorldClock.weather_blend, 1.0, 0.001)
	eq(WorldClock.weather, WorldClock.Weather.FOG)


func test_weather_does_not_swap_during_cutscene() -> void:
	WorldClock.set_weather(WorldClock.Weather.HAZE, true)
	WorldClock.set_weather_hold(0.01)
	Director.play([{"kind": "wait", "seconds": 20.0}])
	WorldClock._process(2.0)
	eq(WorldClock.weather, WorldClock.Weather.HAZE, "cutscene blocks a weather roll")
	Director.abort()


func test_save_roundtrip_time_and_weather() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	WorldClock.set_time(0.73)
	WorldClock.set_weather(WorldClock.Weather.FOG, true)
	ok(SaveData.save_game("res://scenes/levels/Level01_Static.tscn", player))
	WorldClock.reset()
	almost(WorldClock.time_of_day, WorldClock.DEFAULT_TIME, 0.0001)
	eq(WorldClock.weather, WorldClock.Weather.HAZE)
	ok(SaveData.load_game())
	almost(WorldClock.time_of_day, 0.73, 0.0001, "load restores the hour")
	eq(WorldClock.weather, WorldClock.Weather.FOG, "load restores fog")
	eq(WorldClock.phase, WorldClock.Phase.NIGHT)
	eq(String(SaveData.data["atmosphere"]["weather"]), "fog")


func test_night_tint_stays_playable() -> void:
	WorldClock.set_time(0.80)
	WorldClock.set_weather(WorldClock.Weather.FOG, true)
	var night := WorldClock.mood_tint()
	ok(night.r >= 0.50 and night.g >= 0.50 and night.b >= 0.50, "night is not a black frame")
	ok(WorldClock.mood_luminance() >= 0.50, "night luminance stays playable")
	ok(night != Color.BLACK)
	WorldClock.set_time(0.30)
	WorldClock.set_weather(WorldClock.Weather.HAZE, true)
	var day := WorldClock.mood_tint()
	ok(day.b >= day.r * 0.95, "day stays cool, not a sunny yellow")
	ok(WorldClock.mood_luminance() > WorldClock.NIGHT_TINT.r * 0.9)
	ok(WorldClock.nest_light_energy() < 0.25, "day nest glow stays a ember tongue")
	WorldClock.set_time(0.80)
	ok(WorldClock.nest_light_energy() > 0.90, "night nest glow is the bright setting")


func test_parallax_follows_clock_tint() -> void:
	WorldClock.set_time(0.80)
	WorldClock.set_weather(WorldClock.Weather.FOG, true)
	var host := Node2D.new()
	add_child(host)
	var backdrop := ParallaxBackground.new()
	backdrop.name = "ParallaxBackdrop"
	host.add_child(backdrop)
	var far := ParallaxLayer.new()
	far.name = "Far"
	backdrop.add_child(far)
	var extras := Level01Parallax.new()
	add_child(extras)
	extras.build(host)
	var tint := host.get_node_or_null("MoodTint") as CanvasModulate
	ok(tint != null)
	if tint != null:
		ok(tint.color.r >= 0.50 and tint.color.g >= 0.50 and tint.color.b >= 0.50,
				"MoodTint night stays in the playable band")
		ok(tint.color.a >= 0.99)
	ok(host.get_node_or_null("WeatherFx") != null, "rain layer is attached")


const CYCLE_CROSS := 30.0
