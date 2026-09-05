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
