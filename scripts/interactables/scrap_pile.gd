class_name ScrapPile
extends Interactable
## Lootable scrap. Yields a Kiln Core (Heat Forge) in the test arena.

var _looted: bool = false


func _ready() -> void:
	super._ready()
	prompt = "E 搜刮废料堆"
	ensure_rect(Vector2(22, 18), Palette.RUST_DARK)
	var cap := ColorRect.new()
	cap.size = Vector2(14, 10)
	cap.position = Vector2(4, -6)
	cap.color = Palette.RUST_LIGHT
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cap)


func can_interact(_actor: Node) -> bool:
	return not _looted


func interact(actor: Node) -> void:
	if _looted:
		return
	if actor is Player:
		_looted = true
		prompt = ""
		(actor as Player).collect_core(AbilityCatalog.kiln_core())
		modulate.a = 0.4
		GameEvents.announcement.emit("废料堆里摸到窑核")
