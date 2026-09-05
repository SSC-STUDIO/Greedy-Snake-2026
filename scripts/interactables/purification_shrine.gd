class_name PurificationShrine
extends Interactable
## Rare shrine. Full toxin cleanse (and a courtesy heal in the test arena).

const SHRINE_TEX_PATH := "res://assets/env/statue_keeper.png"


func _ready() -> void:
	super._ready()
	prompt = "E 祈请净化祠"
	ensure_sprite(SHRINE_TEX_PATH, Vector2(32, 38), Vector2(-7, -6), Palette.TEAL_DEEP)


func get_prompt(actor: Node) -> String:
	if actor is Player and _already_clean(actor as Player):
		return "净化祠已洁净"
	return "E 祈请净化祠"


func interact(actor: Node) -> void:
	if actor is Player:
		var p := actor as Player
		var dirty := not _already_clean(p)
		p.toxin.purify(1.0)
		p.health.heal_full()
		GameEvents.player_health_changed.emit(p.health.current, p.health.max_hp)
		Sfx.play(&"insert")
		if dirty:
			GameEvents.announcement.emit("净化祠洗去了锈尘")
		else:
			GameEvents.announcement.emit("祠里已经没有锈可洗")


func _already_clean(p: Player) -> bool:
	return p.toxin.toxin <= 0.01 and p.health.current >= p.health.max_hp
