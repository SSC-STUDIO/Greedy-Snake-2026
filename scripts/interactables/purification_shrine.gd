class_name PurificationShrine
extends Interactable
## Rare shrine. Full toxin cleanse (and a courtesy heal in the test arena).


const SHRINE_TEX_PATH := "res://assets/kenney_clean/interactables/gemYellow.png"

func _ready() -> void:
	super._ready()
	prompt = "E 祈请净化祠"
	ensure_rect(Vector2(18, 32), Palette.TEAL_DEEP)
	var cap := ColorRect.new()
	cap.name = "Cap"
	cap.size = Vector2(10, 6)
	cap.position = Vector2(4, -4)
	cap.color = Palette.FOG
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cap)
	if ResourceLoader.exists(SHRINE_TEX_PATH):
		var tex: Texture2D = load(SHRINE_TEX_PATH) as Texture2D
		if tex != null:
			var fill := get_node_or_null("Fill") as ColorRect
			if fill:
				fill.visible = false
			(get_node_or_null("Cap") as ColorRect).visible = false if get_node_or_null("Cap") else null
			var spr := Sprite2D.new()
			spr.name = "KenneyIcon"
			spr.texture = tex
			spr.centered = true
			spr.position = Vector2(9, 16)
			spr.modulate = Palette.FOG.lerp(Color.WHITE, 0.2)
			spr.scale = Vector2(0.28, 0.28)
			add_child(spr)


func interact(actor: Node) -> void:
	if actor is Player:
		var p := actor as Player
		p.toxin.purify(1.0)
		p.health.heal_full()
		GameEvents.player_health_changed.emit(p.health.current, p.health.max_hp)
		GameEvents.announcement.emit("净化祠洗去了锈尘")
