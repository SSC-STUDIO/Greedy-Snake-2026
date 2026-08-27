extends Node
## Autoload signal bus. Keep gameplay modules decoupled.
## Do not give this script a class_name — the autoload name is GameEvents.

signal hit(attacker: Node, target: Node, amount: int)
signal parried(projectile: Node, by_actor: Node)
signal toxin_changed(current: float, maximum: float)
signal core_acquired(core: Resource)
signal core_inserted(core: Resource, socket_index: int)
signal ability_unlocked(ability_id: StringName)
signal interact_prompt(text: String)
signal player_health_changed(current: int, maximum: int)
signal announcement(text: String)
signal player_died
signal rusty_gate_melted
signal swing_started(combo_index: int)
signal dash_performed
signal jumped(is_extra: bool)
