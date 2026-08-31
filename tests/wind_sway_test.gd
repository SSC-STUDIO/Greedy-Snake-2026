extends TestCase
## WindSway follows WorldClock heading; stones do not get a pivot.


func setup() -> void:
	WorldClock.reset()
	WorldClock.menu_hold = false
	WorldClock.set_zone(WorldClock.Zone.OUTDOORS)
	WorldClock.set_weather(WorldClock.Weather.HAZE, true)
	WorldClock._snap_wind_speed()


func teardown() -> void:
	WorldClock.reset()


func test_sway_flips_with_heading() -> void:
	WorldClock.wind_heading = 1.0
	WorldClock._heading_target = 1.0
	WorldClock._snap_wind_speed()
	var host := Node2D.new()
	add_child(host)
	var sway := WindSway.new()
	sway.amplitude = 1.0
	sway.phase = 0.0
	host.add_child(sway)
	sway._apply()
	ok(host.rotation > 0.0, "right wind leans positive")
	WorldClock.wind_heading = -1.0
	WorldClock._heading_target = -1.0
	sway._apply()
	ok(host.rotation < 0.0, "left wind leans negative")
	ok(absf(WorldClock.sway_radians()) >= 0.08, "outdoor sway is at least ~4.5 degrees")
	WorldClock.set_zone(WorldClock.Zone.INDOORS)
	WorldClock._snap_wind_speed()
	almost(WorldClock.sway_radians(), 0.0, 0.01, "indoor trees do not lean")


func test_plant_sways_trees_not_stones() -> void:
	var layer := Node2D.new()
	add_child(layer)
	var tree := Level01Env.plant(layer, Level01Env.DECOR_TREE_1, Vector2(0, 80), 0.5)
	var stone := Level01Env.plant(layer, Level01Env.DECOR_STONE_1, Vector2(80, 80), 1.0)
	if tree == null or stone == null:
		ok(true, "gothic assets missing in this checkout — skip plant assert")
		return
	ok(tree.get_parent() != layer, "foliage sits on a foot pivot")
	var found := false
	for child in tree.get_parent().get_children():
		if child is WindSway:
			found = true
	ok(found, "tree pivot has WindSway")
	ok(stone.get_parent() == layer, "stone stays a raw sprite")
	for child in stone.get_children():
		ok(not (child is WindSway), "stone has no sway child")
