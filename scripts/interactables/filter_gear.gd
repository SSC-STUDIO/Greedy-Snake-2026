class_name FilterGear
extends Interactable
## Consumable Filter-Gear. Knocks a chunk off the toxin meter.


const FILTER_TEX_PATH := "res://assets/kenney_clean/interactables/boxCoin.png"

func _ready() -> void:
	super._ready()
	prompt = "E 使用滤芯齿轮"
	ensure_rect(Vector2(12, 12), Palette.TEAL)
	_try_replace_fill_with_sprite(FILTER_TEX_PATH, Palette.TEAL)


func _try_replace_fill_with_sprite(path: String, tint: Color) -> void:
	if not ResourceLoader.exists(path):
		return
	var fill := get_node_or_null("Fill") as ColorRect
	if fill == null:
		return
	var tex: Texture2D = load(path) as Texture2D
	if tex == null:
		return
	fill.visible = false
	var spr := Sprite2D.new()
	spr.name = "KenneyIcon"
	spr.texture = tex
	spr.centered = true
	spr.position = fill.position + fill.size * 0.5
	spr.modulate = tint.lerp(Color.WHITE, 0.35)
	# Scale 70px icon down to ~12px rect.
	spr.scale = Vector2(0.22, 0.22)
	add_child(spr)


func interact(actor: Node) -> void:
	if actor is Player:
		(actor as Player).toxin.purify(0.45)
		GameEvents.announcement.emit("滤芯咬合，毒素下降")
		queue_free()
