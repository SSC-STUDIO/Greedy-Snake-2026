class_name FilterGear
extends Interactable
## Consumable Filter-Gear. Knocks a chunk off the toxin meter.


func _ready() -> void:
	super._ready()
	prompt = "E 使用滤芯齿轮"
	ensure_rect(Vector2(12, 12), Palette.TEAL)


func interact(actor: Node) -> void:
	if actor is Player:
		(actor as Player).toxin.purify(0.45)
		GameEvents.announcement.emit("滤芯咬合，毒素下降")
		queue_free()
