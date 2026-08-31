class_name FilterGear
extends Interactable
## Consumable Filter-Gear. Knocks a chunk off the toxin meter.

const FILTER_TEX_PATH := "res://assets/env/rust_core.png"


func _ready() -> void:
	super._ready()
	prompt = "E 使用滤芯齿轮"
	# 齿轮核贴图（原生 12x12）等比放大，染青绿区分于拾取用的橙色核。
	ensure_sprite(FILTER_TEX_PATH, Vector2(14, 14), Vector2(-1, -2), Palette.TEAL)
	var spr := get_node_or_null("Fill") as CanvasItem
	if spr != null and spr is Sprite2D:
		spr.modulate = Color(0.6, 1.05, 0.9)


func interact(actor: Node) -> void:
	if actor is Player:
		(actor as Player).toxin.purify(0.45)
		GameEvents.announcement.emit("滤芯咬合，毒素下降")
		SaveData.mark_consumed(String(get_path()))
		queue_free()
