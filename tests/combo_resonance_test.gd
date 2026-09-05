extends TestCase
## 双槽冲击波必须在共鸣窗口里点亮；仅 has_pair 不够。


func _equip_pair(player: Player) -> void:
	player.inventory.add_to_pouch(AbilityCatalog.kiln_core())
	player.inventory.add_to_pouch(AbilityCatalog.ember_core())
	player.inventory.insert_into_socket(0)
	player.inventory.insert_into_socket(1)


func _count_hitboxes(host: Node) -> int:
	var n := 0
	if host == null:
		return 0
	for child in host.get_children():
		if child is Hitbox:
			n += 1
	return n


func test_blast_requires_resonance_window() -> void:
	var arena := Node2D.new()
	add_child(arena)
	build_floor(arena)
	var player := await spawn_player(arena)
	_equip_pair(player)
	ok(player.inventory.has_pair(AbilityIds.HEAT_FORGE, AbilityIds.EMBER_STEP))
	ok(not player.resonance.is_active())
	var effects := GameContext.world_effects(player)
	var before := _count_hitboxes(effects)
	player.on_melee_active(2)
	eq(_count_hitboxes(effects), before, "no blast without resonance")
	player.resonance.pulse()
	ok(player.resonance.is_active())
	player.on_melee_active(2)
	ok(_count_hitboxes(effects) > before, "pair + resonance fires the blast")
