class_name ScrapPile
extends Interactable
## Lootable scrap. Yields a Kiln Core (Heat Forge) in the test arena.

var _looted: bool = false


const SCRAP_TEX_PATH := "res://assets/kenney_clean/interactables/boxItem.png"

func _ready() -> void:
	super._ready()
	add_to_group("persistent")
	prompt = "E 搜刮废料堆"
	ensure_rect(Vector2(22, 18), Palette.RUST_DARK)
	var cap := ColorRect.new()
	cap.name = "Cap"
	cap.size = Vector2(14, 10)
	cap.position = Vector2(4, -6)
	cap.color = Palette.RUST_LIGHT
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cap)
	_try_sprite_overlay()


func _try_sprite_overlay() -> void:
	if not ResourceLoader.exists(SCRAP_TEX_PATH):
		return
	var fill := get_node_or_null("Fill") as ColorRect
	if fill == null:
		return
	var tex: Texture2D = load(SCRAP_TEX_PATH) as Texture2D
	if tex == null:
		return
	fill.visible = false
	var spr := Sprite2D.new()
	spr.name = "KenneyIcon"
	spr.texture = tex
	spr.centered = true
	spr.position = fill.position + fill.size * 0.5
	spr.modulate = Palette.RUST_DARK.lerp(Color.WHITE, 0.3)
	spr.scale = Vector2(0.32, 0.32)
	add_child(spr)
	var cap := get_node_or_null("Cap") as ColorRect
	if cap:
		cap.visible = false


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


## --- persistence ---------------------------------------------------------
func get_persistent_state() -> Dictionary:
	return {"looted": _looted}


func apply_persistent_state(state: Dictionary) -> void:
	if bool(state.get("looted", false)):
		_looted = true
		prompt = ""
		modulate.a = 0.4
