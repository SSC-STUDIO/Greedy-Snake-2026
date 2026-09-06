class_name AbilityIds
extends Object
## Named abilities unlocked by inserting Rust-Cores into sword sockets.

const HOOKSHOT_TETHER := &"hookshot_tether"
const HEAT_FORGE := &"heat_forge"
const EMBER_STEP := &"ember_step"

## 玩家可见的能力名（HUD 剑核栏、嵌核公告）。界面全中文，这里也不混英文。
static func display_name(ability_id: StringName) -> String:
	match ability_id:
		HOOKSHOT_TETHER:
			return "钩锁"
		HEAT_FORGE:
			return "热锻"
		EMBER_STEP:
			return "余烬步"
		_:
			return String(ability_id)
