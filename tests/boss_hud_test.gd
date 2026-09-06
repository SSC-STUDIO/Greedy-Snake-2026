extends TestCase
## Boss HUD unit tests: boss bar appearance, HP tracking, and defeat fadeout.

const HUD_SCENE := preload("res://scenes/ui/HUD.tscn")


func test_boss_health_bar_tracks_events() -> void:
	var hud := HUD_SCENE.instantiate()
	add_child(hud)
	await flush(1)

	var boss_bar := hud.get_node_or_null("Root/BossBar") as PanelContainer
	ok(boss_bar != null, "BossBar node exists in HUD")
	ok(not boss_bar.visible, "BossBar hidden by default")

	# Boss appears
	GameEvents.boss_appeared.emit("炉约刽子手 · 铸渣残躯", 13, 13)
	await flush(1)
	ok(boss_bar.visible, "BossBar visible after boss_appeared")

	var bar := boss_bar.find_child("BossHpBar", true, false) as ProgressBar
	var label := boss_bar.find_child("BossTitle", true, false) as Label
	ok(bar != null, "ProgressBar found in boss bar")
	ok(label != null, "Title label found in boss bar")
	eq(int(bar.max_value), 13, "Max HP matches event")
	eq(int(bar.value), 13, "Current HP matches event")

	# Boss takes damage
	GameEvents.boss_hp_changed.emit(6, 13)
	await flush(2)
	ok(bar.value <= 13, "HP changes smoothly")

	# Boss defeated
	GameEvents.boss_defeated.emit()
	await flush(2)


## The bar used to pop up on the boss's first physics tick, i.e. while the
## knight was still grappling the ember ledge three screens away.
func test_executioner_announces_at_the_gate_not_at_spawn() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var boss := preload("res://scenes/enemies/ExecutionerBoss.tscn").instantiate() as ExecutionerBoss
	boss.position = Vector2(200, 0)
	arena.add_child(boss)
	var heard: Array = []
	var on_appear := func(name_: String, _cur: int, _max: int) -> void: heard.append(name_)
	GameEvents.boss_appeared.connect(on_appear)
	await flush(4)
	ok(not boss.is_announced(), "ticking in BLOCK does not announce")
	eq(heard.size(), 0, "no boss bar before the gate")
	boss.announce()
	boss.announce()
	eq(heard.size(), 1, "gate entry announces exactly once")
	ok(boss.is_announced())
	GameEvents.boss_appeared.disconnect(on_appear)


func test_hitting_the_executioner_first_also_announces_him() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var boss := preload("res://scenes/enemies/ExecutionerBoss.tscn").instantiate() as ExecutionerBoss
	boss.position = Vector2(200, 0)
	arena.add_child(boss)
	await flush(2)
	var heard: Array = []
	var on_appear := func(_n: String, cur: int, _max: int) -> void: heard.append(cur)
	GameEvents.boss_appeared.connect(on_appear)
	boss.health.current -= 1
	boss.health.changed.emit(boss.health.current, boss.health.max_hp)
	eq(heard.size(), 1, "damage before the gate still shows the bar")
	GameEvents.boss_appeared.disconnect(on_appear)
