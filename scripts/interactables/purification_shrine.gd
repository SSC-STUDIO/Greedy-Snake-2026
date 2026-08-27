class_name PurificationShrine
extends Interactable
## Rare shrine. Full toxin cleanse (and a courtesy heal in the test arena).


func _ready() -> void:
	super._ready()
	prompt = "E 祈请净化祠"
	ensure_rect(Vector2(18, 32), Palette.TEAL_DEEP)
	var cap := ColorRect.new()
	cap.size = Vector2(10, 6)
	cap.position = Vector2(4, -4)
	cap.color = Palette.FOG
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cap)


func interact(actor: Node) -> void:
	if actor is Player:
		var p := actor as Player
		p.toxin.purify(1.0)
		p.health.heal_full()
		GameEvents.player_health_changed.emit(p.health.current, p.health.max_hp)
		GameEvents.announcement.emit("净化祠洗去了锈尘")
