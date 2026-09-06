class_name SolidPlatform
extends StaticBody2D
## Two texture families so terrain reads correctly at a glance:
## - "ground": grass top + cemetery dirt that fades to near-black — for
##   terrain rooted in the earth (bottoms may run off-screen unfinished).
## - "floating": church hovering-slab stones — finished top face, closed
##   left/right ends, ragged hanging underside that shows sky through the
##   gaps. For airborne steps, which must never show a raw dirt
##   cross-section nor a boxy filled bottom.
## - "stone": cathedral paving — two rows of cracked flagstone cut from the
##   48px church slabs, then the same cemetery earth underneath. Marks the
##   Executioner's nave apart from the graveyard grass without new art.
## Missing art falls back to a ColorRect (headless/tests).

@export var size: Vector2 = Vector2(64, 16)
@export var fill: Color = Color("#2a1e32")
@export var cap_surface: bool = true
## Grass caps overhanging the open left/right ends of the surface row.
## Disable the side that butts against a wall / level boundary.
@export var cap_left: bool = true
@export var cap_right: bool = true
## Multiplied onto every tile; pits/interiors can sit darker than open ground.
@export var tone: Color = Color.WHITE
## "auto": thin, wide platforms count as floating; everything else is ground.
@export_enum("auto", "ground", "floating", "stone") var skin: String = "auto"

const TOP_A := "res://assets/env/tile_top_a.png"
const TOP_B := "res://assets/env/tile_top_b.png"
const TOP_LEFT := "res://assets/env/tile_top_left.png"
const TOP_RIGHT := "res://assets/env/tile_top_right.png"
const FILL_PLAIN := "res://assets/env/tile_fill_plain.png"
const FILL_PLAIN_B := "res://assets/env/tile_fill_plain_b.png"
const FILL_SKULL := "res://assets/env/tile_fill_skull.png"
const FILL_EDGE_L := "res://assets/env/tile_fill_edge_l.png"
const FILL_EDGE_R := "res://assets/env/tile_fill_edge_r.png"
const FILL_FADE_A := "res://assets/env/tile_fill_fade_a.png"
const FILL_FADE_B := "res://assets/env/tile_fill_fade_b.png"
const FILL_DEEP := "res://assets/env/tile_fill_deep.png"
const FLOAT_LEFT := "res://assets/env/float_left.png"
const FLOAT_RIGHT := "res://assets/env/float_right.png"
## 四种中段：同一石板的不同切段（含镜像），垂挂轮廓各不相同。
const FLOAT_MIDS: Array[String] = [
	"res://assets/env/float_mid_a.png",
	"res://assets/env/float_mid_b.png",
	"res://assets/env/float_mid_c.png",
	"res://assets/env/float_mid_d.png",
]
## 悬浮石台整体略偏冷灰，和草顶暖土在同一色板里拉开对比。
const FLOAT_TONE := Color(0.82, 0.8, 0.95)
## 48×48 教堂石板：上 16px 带亮沿的板面，16–32px 是裂纹石身，下面是残缺底。
const STONE_SLABS: Array[String] = [
	"res://assets/env/slab_a.png",
	"res://assets/env/slab_b.png",
	"res://assets/env/slab_c.png",
]
## 石板行数：板面 + 石身；再往下回到墓园深土，铺路只是压在坟土上。
const STONE_ROWS := 2
## 铺路略偏冷紫，和柱子/拱门同一族，草地暖土留给墓园。
const STONE_TONE := Color(0.88, 0.84, 0.98)
const WORLD := 16.0
## Row brightness: surface row full, then darken toward DEPTH_FLOOR by row 4.
const DEPTH_FLOOR := 0.4
## Chance for a skull accent in the dirt band (row 1). Rare on purpose.
const SKULL_CHANCE := 0.12


func setup(pos: Vector2, sz: Vector2, col: Color) -> void:
	position = pos
	size = sz
	fill = col


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_build_visual()
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	col.position = size * 0.5
	add_child(col)
	_add_light_occluder()


func _build_visual() -> void:
	var floating := skin == "floating" \
			or (skin == "auto" and size.y <= WORLD + 0.5 and size.x > WORLD + 0.5)
	if floating and _build_floating():
		return
	if skin == "stone" and _build_stone():
		return
	var tops: Array[Texture2D] = []
	for path in [TOP_A, TOP_B]:
		var t := _load_tex(path)
		if t != null:
			tops.append(t)
	var fills: Array[Texture2D] = []
	for path in [FILL_PLAIN, FILL_PLAIN_B]:
		var t := _load_tex(path)
		if t != null:
			fills.append(t)
	if tops.is_empty() and fills.is_empty():
		_fallback_rect()
		return
	if fills.is_empty():
		fills = tops
	if tops.is_empty():
		tops = fills
	var cap_l := _load_tex(TOP_LEFT)
	var cap_r := _load_tex(TOP_RIGHT)
	var skull := _load_tex(FILL_SKULL)
	var edge_l := _load_tex(FILL_EDGE_L)
	var edge_r := _load_tex(FILL_EDGE_R)
	var fades: Array[Texture2D] = []
	for path in [FILL_FADE_A, FILL_FADE_B]:
		var t := _load_tex(path)
		if t != null:
			fades.append(t)
	var deep := _load_tex(FILL_DEEP)

	# Deterministic per-platform variation (stable across reloads).
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector4(position.x, position.y, size.x, size.y))

	var cols := maxi(1, int(ceil(size.x / WORLD)))
	var rows := maxi(1, int(ceil(size.y / WORLD)))
	var thin := size.y <= WORLD + 0.5
	var wall := size.x <= WORLD + 0.5 and size.y > WORLD * 2.0
	var use_surface := cap_surface and not wall
	for r in rows:
		for c in cols:
			var tex: Texture2D
			var flip := false
			var is_left := c == 0
			var is_right := c == cols - 1
			if use_surface and (thin or r == 0):
				if cap_left and is_left and cap_l != null and cols > 1:
					tex = cap_l
				elif cap_right and is_right and cap_r != null and cols > 1:
					tex = cap_r
				else:
					tex = tops[rng.randi_range(0, tops.size() - 1)]
					flip = rng.randf() < 0.5
			elif use_surface and r == 1:
				# Dirt band right under the grass; edge shading on open ends.
				if cap_left and is_left and edge_l != null and cols > 1:
					tex = edge_l
				elif cap_right and is_right and edge_r != null and cols > 1:
					tex = edge_r
				elif skull != null and rng.randf() < SKULL_CHANCE:
					tex = skull
					flip = rng.randf() < 0.5
				else:
					tex = fills[rng.randi_range(0, fills.size() - 1)]
					flip = rng.randf() < 0.5
			elif use_surface and r == 2:
				# 过渡行：以安静的暗土为主，偶尔一块骸骨渐隐 tile 作点缀，
				# 连排骷髅会变成一条"骷髅带"。
				if not fades.is_empty() and rng.randf() < 0.22:
					tex = fades[rng.randi_range(0, fades.size() - 1)]
				else:
					tex = fills[rng.randi_range(0, fills.size() - 1)]
				flip = rng.randf() < 0.5
			elif use_surface and r >= 3 and deep != null:
				tex = deep if rng.randf() < 0.72 else fills[rng.randi_range(0, fills.size() - 1)]
				flip = rng.randf() < 0.5
			else:
				tex = fills[rng.randi_range(0, fills.size() - 1)]
				flip = rng.randf() < 0.5
			var spr := Sprite2D.new()
			spr.texture = tex
			spr.centered = false
			spr.flip_h = flip
			spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			var src := float(tex.get_width())
			var s := WORLD / maxf(1.0, src)
			spr.scale = Vector2(s, s)
			spr.position = Vector2(c * WORLD, r * WORLD)
			var remain_x := size.x - c * WORLD
			var remain_y := size.y - r * WORLD
			if remain_x < WORLD - 0.01 or remain_y < WORLD - 0.01:
				spr.region_enabled = true
				var rw := minf(src, remain_x / s)
				var rh := minf(float(tex.get_height()), remain_y / s)
				# Right-end partials keep the outer edge of the art (caps and
				# edge shading live on the right side of those tiles).
				var rx := src - rw if is_right and rw < src else 0.0
				spr.region_rect = Rect2(rx, 0, rw, rh)
			spr.z_index = -1
			spr.modulate = _row_tint(r, rows, use_surface)
			add_child(spr)


## 悬浮石台：左右端头 + 随机中段，顶面与碰撞体顶对齐，薄石板 + 短垂岩（透明）。
## 端头永远画完整 16px（非整数宽度时右端头向左回收对齐 size.x，盖在中段上）。
func _build_floating() -> bool:
	var lcap := _load_tex(FLOAT_LEFT)
	var rcap := _load_tex(FLOAT_RIGHT)
	var mids: Array[Texture2D] = []
	for path in FLOAT_MIDS:
		var t := _load_tex(path)
		if t != null:
			mids.append(t)
	if lcap == null or rcap == null or mids.is_empty():
		return false
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector4(position.x, position.y, size.x, size.y))
	# 中段先铺（16..size.x-16），端头最后画压在上面，保证两端永远是完整收边。
	# 每格随机取一种中段且不与前一格重复，长台的垂挂轮廓才不会按 16px 打拍子。
	var x := WORLD
	var prev := -1
	while x < size.x - WORLD - 0.01:
		var i := rng.randi_range(0, mids.size() - 1)
		if i == prev and mids.size() > 1:
			i = (i + 1 + rng.randi_range(0, mids.size() - 2)) % mids.size()
		prev = i
		_add_float_piece(mids[i], x, minf(WORLD, size.x - WORLD - x))
		x += WORLD
	_add_float_piece(lcap, 0.0, WORLD)
	_add_float_piece(rcap, size.x - WORLD, WORLD)
	return true


func _add_float_piece(tex: Texture2D, x: float, width: float) -> void:
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.centered = false
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.position = Vector2(x, 0)
	if width < float(tex.get_width()) - 0.01:
		spr.region_enabled = true
		spr.region_rect = Rect2(0, 0, width, float(tex.get_height()))
	spr.z_index = -1
	spr.modulate = Color(
		tone.r * FLOAT_TONE.r, tone.g * FLOAT_TONE.g, tone.b * FLOAT_TONE.b, tone.a
	)
	add_child(spr)


## 教堂铺路：前两行从三块 48px 石板上随机切 16px 段（列位、板号、镜像都随机，
## 长地板才不会按 48px 打拍子），第三行起沿用墓园深土与行深压暗。
func _build_stone() -> bool:
	var slabs: Array[Texture2D] = []
	for path in STONE_SLABS:
		var t := _load_tex(path)
		if t != null:
			slabs.append(t)
	if slabs.is_empty():
		return false
	var fills: Array[Texture2D] = []
	for path in [FILL_PLAIN, FILL_PLAIN_B]:
		var t := _load_tex(path)
		if t != null:
			fills.append(t)
	var deep := _load_tex(FILL_DEEP)
	if fills.is_empty() and deep == null:
		fills = slabs
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector4(position.x, position.y, size.x, size.y)) ^ 0x5710
	var cols := maxi(1, int(ceil(size.x / WORLD)))
	var rows := maxi(1, int(ceil(size.y / WORLD)))
	var slab_cols := int(float(slabs[0].get_width()) / WORLD)
	for r in rows:
		for c in cols:
			var remain_x := size.x - c * WORLD
			var remain_y := size.y - r * WORLD
			var w := minf(WORLD, remain_x)
			var h := minf(WORLD, remain_y)
			var spr := Sprite2D.new()
			spr.centered = false
			spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			spr.position = Vector2(c * WORLD, r * WORLD)
			spr.z_index = -1
			if r < STONE_ROWS:
				spr.texture = slabs[rng.randi_range(0, slabs.size() - 1)]
				spr.region_enabled = true
				var sx := float(rng.randi_range(0, maxi(0, slab_cols - 1))) * WORLD
				spr.region_rect = Rect2(sx, r * WORLD, w, h)
				spr.flip_h = rng.randf() < 0.5
				var k := _row_tint(r, rows, true)
				spr.modulate = Color(k.r * STONE_TONE.r, k.g * STONE_TONE.g, k.b * STONE_TONE.b, k.a)
			else:
				var tex: Texture2D
				if deep != null and (fills.is_empty() or rng.randf() < 0.72):
					tex = deep
				else:
					tex = fills[rng.randi_range(0, fills.size() - 1)]
				spr.texture = tex
				spr.flip_h = rng.randf() < 0.5
				var src := float(tex.get_width())
				var s := WORLD / maxf(1.0, src)
				spr.scale = Vector2(s, s)
				if w < WORLD - 0.01 or h < WORLD - 0.01:
					spr.region_enabled = true
					spr.region_rect = Rect2(0, 0, minf(src, w / s), minf(float(tex.get_height()), h / s))
				spr.modulate = _row_tint(r, rows, true)
			add_child(spr)
	return true


## Surface stays bright; each row below sinks toward DEPTH_FLOOR by row 4.
func _row_tint(r: int, rows: int, use_surface: bool) -> Color:
	var depth := 0.0
	if use_surface:
		depth = clampf(float(r - 1) / 3.0, 0.0, 1.0) if r >= 1 else 0.0
	else:
		depth = clampf(float(r) / maxf(1.0, float(rows - 1)) * 0.7, 0.0, 1.0)
	var k := lerpf(1.0, DEPTH_FLOOR, depth)
	return Color(tone.r * k, tone.g * k, tone.b * k, tone.a)


func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


## Occluder matches the collision rectangle only — never the hanging float skin.
func _add_light_occluder() -> void:
	if get_node_or_null("LightOccluder") != null:
		return
	var occ := LightOccluder2D.new()
	occ.name = "LightOccluder"
	var poly := OccluderPolygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(size.x, 0.0),
		Vector2(size.x, size.y),
		Vector2(0.0, size.y),
	])
	occ.occluder = poly
	add_child(occ)


func _fallback_rect() -> void:
	var rect := ColorRect.new()
	rect.name = "VisualRect"
	rect.size = size
	rect.color = fill
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
