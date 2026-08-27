class_name AbilityIds
extends Object
## Named abilities unlocked by inserting Rust-Cores into sword sockets.

const HOOKSHOT_TETHER := &"hookshot_tether"
const HEAT_FORGE := &"heat_forge"
const EMBER_STEP := &"ember_step"

static func display_name(ability_id: StringName) -> String:
	match ability_id:
		HOOKSHOT_TETHER:
			return "Hookshot Tether"
		HEAT_FORGE:
			return "Heat Forge"
		EMBER_STEP:
			return "Ember Step"
		_:
			return String(ability_id)
