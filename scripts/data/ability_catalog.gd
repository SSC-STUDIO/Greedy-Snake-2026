class_name AbilityCatalog
extends Object
## Factory for the cores used by the test arena and enemy drops.


static func kiln_core() -> RustCore:
	var core := RustCore.new()
	core.id = &"kiln_core"
	core.display_name = "Kiln Core"
	core.description = "Heat Forge — melt rusted gates with the blade's heat."
	core.ability_id = AbilityIds.HEAT_FORGE
	core.tint = Palette.TOXIC
	return core


static func tether_core() -> RustCore:
	var core := RustCore.new()
	core.id = &"tether_core"
	core.display_name = "Tether Core"
	core.description = "Hookshot Tether — grapple onto anchors and swing the gaps."
	core.ability_id = AbilityIds.HOOKSHOT_TETHER
	core.tint = Palette.TEAL
	return core


## Rehydrate a core from its id (used by SaveData load). Returns null for
## ids this catalog doesn't know about so old/new saves degrade gracefully.
static func for_id(id: StringName) -> RustCore:
	match id:
		&"kiln_core":
			return kiln_core()
		&"tether_core":
			return tether_core()
	return null

