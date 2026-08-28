class_name RustyGate
extends Interactable
## Heat Forge gate. Melt it once the kiln core is socketed.

var _melted: bool = false


const GATE_TEX_PATH := "res://assets/kenney_clean/tiles/castleCenter.png"

func _ready() -> void:
	super._ready()
	prompt = "需要熔热锻"
	ensure_rect(Vector2(16, 64), Palette.RUST_LIGHT)
	if get_node_or_null("Solid") == null:
		var solid := StaticBody2D.new()
		solid.name = "Solid"
		solid.collision_layer = 1
		solid.collision_mask = 0
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(16, 64)
		col.shape = shape
		col.position = Vector2(8, 32)
		solid.add_child(col)
		add_child(solid)
	_try_gate_sprite()


func _try_gate_sprite() -> void:
	if not ResourceLoader.exists(GATE_TEX_PATH):
		return
	var fill := get_node_or_null("Fill") as ColorRect
	if fill == null:
		return
	var tex: Texture2D = load(GATE_TEX_PATH) as Texture2D
	if tex == null:
		return
	fill.visible = false
	var spr := Sprite2D.new()
	spr.name = "KenneyGate"
	spr.texture = tex
	spr.centered = false
	spr.position = Vector2(0, 0)
	spr.modulate = Palette.RUST_LIGHT.lerp(Color.WHITE, 0.2)
	# Tile vertically: 64px gate from 70px tile, scale slightly.
	spr.scale = Vector2(16.0 / tex.get_width(), 64.0 / tex.get_height())
	add_child(spr)


func can_interact(actor: Node) -> bool:
	if _melted:
		return false
	if actor is Player:
		return (actor as Player).inventory.has_ability(AbilityIds.HEAT_FORGE)
	return false


func get_prompt(actor: Node) -> String:
	if actor is Player and (actor as Player).inventory.has_ability(AbilityIds.HEAT_FORGE):
		return "E 融化锈门"
	return "锈门封死 — 需要熔热锻"


func interact(actor: Node) -> void:
	if not can_interact(actor):
		GameEvents.announcement.emit("锈门太厚。把窑核嵌进剑里。")
		return
	_melted = true
	SaveData.mark_consumed(String(get_path()))
	var solid := get_node_or_null("Solid") as StaticBody2D
	if solid:
		solid.collision_layer = 0
	visible = false
	GameEvents.rusty_gate_melted.emit()
	GameEvents.announcement.emit("熔热锻咬开了锈门")
	queue_free()
