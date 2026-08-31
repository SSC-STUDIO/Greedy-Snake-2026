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


static func is_foliage(path: String) -> bool:
	var name := path.get_file()
	return name.begins_with("tree-") or name.begins_with("bush-")


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
	if tint != Color.WHITE:
		spr.modulate = tint
	var w := float(tex.get_width()) * scale
	var h := float(tex.get_height()) * scale
	if is_foliage(path):
		var pivot := Node2D.new()
		pivot.name = "Sway_%s" % path.get_file().get_basename()
		pivot.position = Vector2(feet.x + w * 0.5, feet.y)
		parent.add_child(pivot)
		spr.position = Vector2(-w * 0.5, -h)
		pivot.add_child(spr)
		var sway := WindSway.new()
		sway.amplitude = 1.35 if path.get_file().begins_with("bush-") else 1.0
		sway.freq = 1.45 if path.get_file().begins_with("bush-") else 0.82
		pivot.add_child(sway)
		return spr
	spr.position = Vector2(feet.x, feet.y - h)
	parent.add_child(spr)
	return spr
