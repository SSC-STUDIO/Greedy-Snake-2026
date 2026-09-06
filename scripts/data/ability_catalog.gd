class_name AbilityCatalog
extends Object
## Factory for the cores used by the test arena and enemy drops.
## Names are player-facing (HUD pouch, pickup prompt, announcements) — Chinese only.


static func kiln_core() -> RustCore:
	var core := RustCore.new()
	core.id = &"kiln_core"
	core.display_name = "窑核"
	core.description = "热锻 — 剑刃带上窑火，能熔开锈死的门。"
	core.ability_id = AbilityIds.HEAT_FORGE
	core.tint = Palette.TOXIC
	return core


static func tether_core() -> RustCore:
	var core := RustCore.new()
	core.id = &"tether_core"
	core.display_name = "系核"
	core.description = "钩锁 — 甩索勾住锚点，荡过断口。"
	core.ability_id = AbilityIds.HOOKSHOT_TETHER
	core.tint = Palette.TEAL
	return core


static func ember_core() -> RustCore:
	var core := RustCore.new()
	core.id = &"ember_core"
	core.display_name = "余烬核"
	core.description = "余烬步 — 用一把炉灰换第二段跳。"
	core.ability_id = AbilityIds.EMBER_STEP
	core.tint = Palette.EMBER
	return core


## Rehydrate a core from its id (used by SaveData load). Returns null for
## ids this catalog doesn't know about so old/new saves degrade gracefully.
static func for_id(id: StringName) -> RustCore:
	match id:
		&"kiln_core":
			return kiln_core()
		&"tether_core":
			return tether_core()
		&"ember_core":
			return ember_core()
	return null
