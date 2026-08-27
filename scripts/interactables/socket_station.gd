class_name SocketStation
extends Interactable
## Diegetic socket bench. Inserts the next pouch core into the first empty socket.


func _ready() -> void:
	super._ready()
	prompt = "E 在插座台嵌核"
	ensure_rect(Vector2(20, 24), Palette.IRON)
	var gem := ColorRect.new()
	gem.size = Vector2(8, 8)
	gem.position = Vector2(6, 4)
	gem.color = Palette.EMBER
	gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(gem)


func interact(actor: Node) -> void:
	if actor is Player:
		(actor as Player).inventory.insert_first_available()
