class_name Level01Env
extends Object
## Shared cemetery sprite planting for Level01 grave props and parallax silhouette.

const DECOR_TREE_1 := "res://assets/external/gothicvania_cemetery/PNG/Environment/sliced-objects/tree-1.png"
const DECOR_TREE_2 := "res://assets/external/gothicvania_cemetery/PNG/Environment/sliced-objects/tree-2.png"
const DECOR_TREE_3 := "res://assets/external/gothicvania_cemetery/PNG/Environment/sliced-objects/tree-3.png"
const DECOR_BUSH_L := "res://assets/external/gothicvania_cemetery/PNG/Environment/sliced-objects/bush-large.png"
const DECOR_BUSH_S := "res://assets/external/gothicvania_cemetery/PNG/Environment/sliced-objects/bush-small.png"
const DECOR_STONE_1 := "res://assets/external/gothicvania_cemetery/PNG/Environment/sliced-objects/stone-1.png"
const DECOR_STONE_2 := "res://assets/external/gothicvania_cemetery/PNG/Environment/sliced-objects/stone-2.png"
const DECOR_STONE_3 := "res://assets/external/gothicvania_cemetery/PNG/Environment/sliced-objects/stone-3.png"
const DECOR_STATUE := "res://assets/external/gothicvania_cemetery/PNG/Environment/sliced-objects/statue.png"


static func plant(parent: Node2D, path: String, feet: Vector2, scale: float, tint: Color = Color.WHITE) -> Sprite2D:
	if not ResourceLoader.exists(path):
		return null
	var tex := load(path) as Texture2D
	if tex == null:
		return null
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.centered = false
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.scale = Vector2(scale, scale)
	spr.position = Vector2(feet.x, feet.y - float(tex.get_height()) * scale)
	if tint != Color.WHITE:
		spr.modulate = tint
	parent.add_child(spr)
	return spr
