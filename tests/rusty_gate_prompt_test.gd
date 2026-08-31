extends TestCase
## 锈门在未融化时始终可聚焦，没窑核也能读到「需要熔热锻」。


const GATE_SCENE := preload("res://scenes/interactables/RustyGate.tscn")


func test_gate_is_focusable_without_heat_forge() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	var gate := GATE_SCENE.instantiate() as RustyGate
	gate.position = player.global_position
	arena.add_child(gate)
	await flush(3)
	ok(not player.inventory.has_ability(AbilityIds.HEAT_FORGE))
	ok(gate.can_interact(player), "visible gate stays focusable")
	eq(gate.get_prompt(player), "锈门封死 — 需要熔热锻")
	player.sensor._on_area_entered(gate)
	eq(player.sensor.get_focus(), gate, "sensor can target a locked-ability gate")
	var heard := [""]
	GameEvents.announcement.connect(func(t: String) -> void: heard[0] = t, CONNECT_ONE_SHOT)
	gate.interact(player)
	ok(heard[0].contains("窑核"), "E without kiln announces instead of melting")
	ok(is_instance_valid(gate) and not gate.is_queued_for_deletion())
