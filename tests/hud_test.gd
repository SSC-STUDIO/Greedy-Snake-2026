extends TestCase
## HUD core labels refresh on inventory signals, not every _process frame.


const HUD_SCENE := preload("res://scenes/ui/HUD.tscn")


func _find_label(root: Node, prefix: String) -> Label:
	if root is Label and String((root as Label).text).begins_with(prefix):
		return root as Label
	for child in root.get_children():
		var found := _find_label(child, prefix)
		if found != null:
			return found
	return null


func test_hud_cores_refresh_on_signal_not_process() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	var hud := HUD_SCENE.instantiate()
	add_child(hud)
	await flush(2)
	var pouch := _find_label(hud, "袋中")
	ok(pouch != null, "pouch label exists")
	eq(pouch.text, "袋中 0")
	player.inventory.pouch.append(AbilityCatalog.kiln_core())
	await flush(4)
	eq(pouch.text, "袋中 0", "silent pouch write does not refresh")
	GameEvents.sockets_changed.emit()
	await flush(1)
	eq(pouch.text, "袋中 1", "signal refreshes core labels")
