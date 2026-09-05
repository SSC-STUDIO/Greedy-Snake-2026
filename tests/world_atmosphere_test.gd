extends TestCase


func setup() -> void:
	WorldClock.reset()
	WorldClock.menu_hold = false
	WorldClock.set_time(0.80)
	WorldClock.set_weather(WorldClock.Weather.HAZE, true)


func teardown() -> void:
	WorldClock.reset()


func test_zone_transition_shares_weight_without_changing_blend_mode() -> void:
	var host := Node2D.new()
	add_child(host)
	var backdrop := ParallaxBackground.new()
	host.add_child(backdrop)
	var atmosphere := WorldAtmosphere.new()
	host.add_child(atmosphere)
	atmosphere.build(host, backdrop)
	var light := WorldLight.new()
	light.follow = &"indoor"
	light.lit = true
	host.add_child(light)
	light.apply(true)
	var outside_radius := light.texture_scale
	var outside_energy := light.energy
	var mode := light.blend_mode
	WorldClock.set_zone(WorldClock.Zone.INDOORS)
	atmosphere.advance(0.10)
	light.apply()
	ok(atmosphere.indoor_weight > 0.0 and atmosphere.indoor_weight < 1.0, "zone transition is gradual")
	ok(light.texture_scale > outside_radius, "doorway radius follows the shared transition")
	ok(light.energy > outside_energy, "room energy follows the same transition")
	eq(light.blend_mode, mode, "zone crossing never swaps canvas blend operations")
	var tint := host.get_node("MoodTint") as CanvasModulate
	var distant := backdrop.get_node("BackdropTint") as CanvasModulate
	ok(distant.color.v < tint.color.v, "backdrop remains subordinate to the play canvas")
	atmosphere.advance(5.0)
	ok(atmosphere.indoor_weight > 0.99, "room transition settles")


func test_decorative_torch_uses_shared_local_light() -> void:
	var torch := TorchLight.new()
	add_child(torch)
	var light := torch.get_node("FlameGlow") as WorldLight
	ok(light != null, "torch uses the same local-light presentation")
	eq(light.follow, &"torch")
	ok(not light.shadow_enabled, "decorative torches do not add full shadow passes")
