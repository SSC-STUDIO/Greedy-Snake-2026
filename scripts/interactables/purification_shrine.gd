class_name PurificationShrine
extends Interactable
## Rare shrine. Full toxin cleanse (and a courtesy heal in the test arena).

const SHRINE_TEX_PATH := "res://assets/env/statue_keeper.png"


func _ready() -> void:
	super._ready()
	prompt = "E 祈请净化祠"
	ensure_sprite(SHRINE_TEX_PATH, Vector2(32, 38), Vector2(-7, -6), Palette.TEAL_DEEP)


func interact(actor: Node) -> void:
	if actor is Player:
		var p := actor as Player
		p.toxin.purify(1.0)
		p.health.heal_full()
		GameEvents.player_health_changed.emit(p.health.current, p.health.max_hp)
		GameEvents.announcement.emit("净化祠洗去了锈尘")
