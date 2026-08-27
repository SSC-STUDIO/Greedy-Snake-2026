class_name SocketStation
extends Interactable
## Diegetic socket bench. Inserts the next pouch core into the first empty socket.


const SOCKET_TEX_PATH := "res://assets/kenney_clean/interactables/gemYellow.png"

func _ready() -> void:
	super._ready()
	prompt = "E 在插座台嵌核"
	ensure_rect(Vector2(20, 24), Palette.IRON)
	var gem := ColorRect.new()
	gem.name = "GemRect"
	gem.size = Vector2(8, 8)
	gem.position = Vector2(6, 4)
	gem.color = Palette.EMBER
	gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(gem)
	if ResourceLoader.exists(SOCKET_TEX_PATH):
		var tex: Texture2D = load(SOCKET_TEX_PATH) as Texture2D
		if tex != null:
			gem.visible = false
			var spr := Sprite2D.new()
			spr.name = "KenneyGem"
			spr.texture = tex
			spr.centered = true
			spr.position = Vector2(10, 8)
			spr.modulate = Palette.EMBER.lerp(Color.WHITE, 0.25)
			spr.scale = Vector2(0.18, 0.18)
			add_child(spr)


func interact(actor: Node) -> void:
	if actor is Player:
		(actor as Player).inventory.insert_first_available()
