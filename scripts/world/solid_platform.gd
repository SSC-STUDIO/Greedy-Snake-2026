class_name SolidPlatform
extends StaticBody2D
## Two texture families so terrain reads correctly at a glance:
## - "ground": grass top + cemetery dirt that fades to near-black — for
##   terrain rooted in the earth (bottoms may run off-screen unfinished).
## - "floating": church hovering-slab stones — finished top face, closed
##   left/right ends, ragged hanging underside. For airborne steps, which
##   must never show a raw dirt cross-section.
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
@export_enum("auto", "ground", "floating") var skin: String = "auto"

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
const FLOAT_MID_A := "res://assets/env/float_mid_a.png"
const FLOAT_MID_B := "res://assets/env/float_mid_b.png"
const FLOAT_RIGHT := "res://assets/env/float_right.png"
## 悬浮石台整体略偏冷灰，和草顶暖土在同一色板里拉开对比。
const FLOAT_TONE := Color(0.82, 0.8, 0.95)
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


func _build_visual() -> void:
	var floating := skin == "floating" \
			or (skin == "auto" and size.y <= WORLD + 0.5 and size.x > WORLD + 0.5)
	if floating and _build_floating():
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


## 悬浮石台：左右端头 + 交替中段，顶面与碰撞体顶对齐，垂挂岩底自然收边。
## 端头永远画完整 16px（非整数宽度时右端头向左回收对齐 size.x，盖在中段上）。
func _build_floating() -> bool:
	var lcap := _load_tex(FLOAT_LEFT)
	var rcap := _load_tex(FLOAT_RIGHT)
	var mids: Array[Texture2D] = []
	for path in [FLOAT_MID_A, FLOAT_MID_B]:
		var t := _load_tex(path)
		if t != null:
			mids.append(t)
	if lcap == null or rcap == null or mids.is_empty():
		return false
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector4(position.x, position.y, size.x, size.y))
	var mid_flip := rng.randi_range(0, 1)
	# 中段先铺（16..size.x-16），端头最后画压在上面，保证两端永远是完整收边。
	var x := WORLD
	var i := 0
	while x < size.x - WORLD - 0.01:
		_add_float_piece(mids[(i + mid_flip) % mids.size()], x, minf(WORLD, size.x - WORLD - x))
		x += WORLD
		i += 1
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


func _fallback_rect() -> void:
	var rect := ColorRect.new()
	rect.name = "VisualRect"
	rect.size = size
	rect.color = fill
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
