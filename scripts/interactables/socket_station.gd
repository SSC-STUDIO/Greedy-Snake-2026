class_name SocketStation
extends Interactable
## Diegetic socket bench. Inserts the next pouch core into the first empty socket.

const SOCKET_TEX_PATH := "res://assets/env/socket_altar.png"


func _ready() -> void:
	super._ready()
	prompt = "E 在嵌核台放入剑核"
	ensure_sprite(SOCKET_TEX_PATH, Vector2(32, 48), Vector2(-8, -16), Palette.IRON)


func interact(actor: Node) -> void:
	if actor is Player:
		(actor as Player).inventory.insert_first_available()
