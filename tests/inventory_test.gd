extends TestCase
## RustCoreInventory socket semantics + AbilityIds/Catalog data sanity.


func test_empty_pouch_insert_is_rejected_with_message() -> void:
	var inv := RustCoreInventory.new()
	add_child(inv)
	ok(not inv.insert_into_socket(0))
	ok(not inv.insert_first_available())


func test_insert_unlocks_ability_and_swap_returns_old_core_to_pouch() -> void:
	var inv := RustCoreInventory.new()
	add_child(inv)
	inv.add_to_pouch(AbilityCatalog.kiln_core())
	ok(inv.insert_into_socket(0))
	ok(inv.has_ability(AbilityIds.HEAT_FORGE))
	eq(inv.pouch.size(), 0)

	inv.add_to_pouch(AbilityCatalog.tether_core())
	ok(inv.insert_into_socket(0)) # swap: kiln back to pouch
	ok(inv.has_ability(AbilityIds.HOOKSHOT_TETHER))
	ok(not inv.has_ability(AbilityIds.HEAT_FORGE), "swapped-out core is unequipped")
	eq(inv.pouch.size(), 1)
	eq((inv.pouch[0] as RustCore).ability_id, AbilityIds.HEAT_FORGE)


func test_out_of_range_socket_is_safe() -> void:
	var inv := RustCoreInventory.new()
	add_child(inv)
	inv.add_to_pouch(AbilityCatalog.tether_core())
	ok(not inv.insert_into_socket(-1))
	ok(not inv.insert_into_socket(99))


func test_catalog_cores_carry_expected_ids() -> void:
	eq(AbilityCatalog.kiln_core().ability_id, AbilityIds.HEAT_FORGE)
	eq(AbilityCatalog.tether_core().ability_id, AbilityIds.HOOKSHOT_TETHER)
	eq(AbilityIds.display_name(AbilityIds.HEAT_FORGE), "Heat Forge")
	ok(String(AbilityIds.display_name(&"unknown_x")).length() > 0)
