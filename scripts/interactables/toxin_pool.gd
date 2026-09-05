class_name ToxinPool
extends Area2D
## Corrosive sludge pit. Murky teal liquid that darkens with depth, capped by
## a brighter scum film whose two frames slosh back and forth with a gentle
## bob, so it reads as "the ground broke open into acid", not a green slab.

@export var toxin_per_second: float = 36.0

var _bodies: Array = []
var _pool_size := Vector2(112, 32)

const BUBBLE_INTERVAL := 0.4
var _bubble_accum := 0.0

const SLUDGE_PATH := "res://assets/env/toxin_sludge.png"
const SCUM_PATH := "res://assets/env/toxin_scum.png"
const SCUM_B_PATH := "res://assets/env/toxin_scum_b.png"
const WORLD := 16.0
## Scum frame swap cadence and bob amplitude (px).
const SCUM_FRAME_TIME := 0.45
const SCUM_BOB := 1.0
const WADE_SPLASH_GAP := 0.22
const WADE_SPEED := 18.0

var _scum_sprites: Array[Sprite2D] = []
var _scum_frames: Array[Texture2D] = []
var _scum_time := 0.0
var _wade_cd := 0.0


func _ready() -> void:
	collision_layer = 128
	collision_mask = 2
	monitoring = true
	monitorable = true
	z_index = -1
	add_to_group("toxin_pools")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_rebuild_visual()


func configure(size: Vector2) -> void:
	_pool_size = size
	_rebuild_visual()


func _rebuild_visual() -> void:
	for child in get_children():
		if child is CollisionShape2D:
			continue
		remove_child(child)
		child.free()
	_scum_sprites.clear()
	_scum_frames.clear()
	# 夜色 CanvasModulate 会把 8,31,30 的淤泥吃成黑坑。先铺一层过亮的体积，
	# 再叠 tile，水坑才读得出是液体而不是一条绿线。
	var volume := ColorRect.new()
	volume.name = "Volume"
	volume.size = _pool_size
	volume.color = Color(0.38, 0.86, 0.68, 1.0)
	volume.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(volume)
	var sludge := _load_tex(SLUDGE_PATH)
	var scum := _load_tex(SCUM_PATH)
	var scum_b := _load_tex(SCUM_B_PATH)
	if sludge == null:
		sludge = scum
	if sludge != null:
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(Vector4(position.x, position.y, _pool_size.x, _pool_size.y))
		var cols := maxi(1, int(ceil(_pool_size.x / WORLD)))
		var rows := maxi(1, int(ceil(_pool_size.y / WORLD)))
		for r in rows:
			for c in cols:
				var spr := Sprite2D.new()
				spr.texture = sludge
				spr.centered = false
				spr.flip_h = rng.randf() < 0.5
				spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				spr.position = Vector2(c * WORLD, r * WORLD)
				var src := float(sludge.get_width())
				var s := WORLD / maxf(1.0, src)
				spr.scale = Vector2(s, s)
				var remain_x := _pool_size.x - c * WORLD
				var remain_y := _pool_size.y - r * WORLD
				if remain_x < WORLD - 0.01 or remain_y < WORLD - 0.01:
					spr.region_enabled = true
					spr.region_rect = Rect2(0, 0, minf(src, remain_x / s), minf(float(sludge.get_height()), remain_y / s))
				# Liquid darkens with depth; keep it above MoodTint's floor.
				var k := lerpf(1.20, 0.78, float(r) / maxf(1.0, float(rows - 1)))
				spr.modulate = Color(k * 1.15, k * 1.28, k * 1.10)
				add_child(spr)
		if scum != null:
			_scum_frames.append(scum)
			if scum_b != null:
				_scum_frames.append(scum_b)
			var scum_h := float(scum.get_height())
			for c in cols:
				var spr := Sprite2D.new()
				spr.texture = scum
				spr.centered = false
				spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				spr.position = Vector2(c * WORLD, 0)
				var remain_x := _pool_size.x - c * WORLD
				if remain_x < WORLD - 0.01:
					spr.region_enabled = true
					spr.region_rect = Rect2(0, 0, minf(float(scum.get_width()), remain_x), scum_h)
				spr.modulate = Color(1.62, 1.52, 1.28)
				add_child(spr)
				_scum_sprites.append(spr)
	else:
		var fill := ColorRect.new()
		fill.name = "Fill"
		fill.size = _pool_size
		fill.color = Color(0.18, 0.42, 0.34, 0.88)
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(fill)
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col == null:
		col = CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		col.shape = shape
		add_child(col)
	(col.shape as RectangleShape2D).size = _pool_size
	col.position = _pool_size * 0.5


func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _process(delta: float) -> void:
	if _scum_sprites.is_empty():
		return
	_scum_time += delta
	var frame := 0
	if _scum_frames.size() > 1:
		frame = int(_scum_time / SCUM_FRAME_TIME) % _scum_frames.size()
	for i in _scum_sprites.size():
		var spr := _scum_sprites[i]
		if not is_instance_valid(spr):
			continue
		if _scum_frames.size() > 1 and spr.texture != _scum_frames[frame]:
			spr.texture = _scum_frames[frame]
		spr.position.y = roundf(sin(_scum_time * 1.7 + float(i) * 0.9) * SCUM_BOB)


func _physics_process(delta: float) -> void:
	# 过场锁输入时人走不开，继续灌毒会在台词里把骑士灌满并触发满溢。
	if Director.is_input_locked():
		return
	_wade_cd = maxf(0.0, _wade_cd - delta)
	for body in _bodies:
		if body is Player:
			var knight := body as Player
			knight.toxin.expose(toxin_per_second * delta)
			if _wade_cd <= 0.0 and knight.velocity.length() > WADE_SPEED:
				_wade_cd = WADE_SPLASH_GAP
				Fx.pool_splash(splash_point(knight.global_position.x))
	_bubble_accum += delta
	if _bubble_accum >= BUBBLE_INTERVAL:
		_bubble_accum -= BUBBLE_INTERVAL
		Fx.toxin_bubbles(self, _bubble_rect())


func surface_rect() -> Rect2:
	return Rect2(global_position, Vector2(_pool_size.x, 8.0))


func volume_rect() -> Rect2:
	return Rect2(global_position, _pool_size)


func splash_point(x: float) -> Vector2:
	var surface := surface_rect()
	return Vector2(clampf(x, surface.position.x + 2.0, surface.end.x - 2.0), surface.position.y + 1.0)


func _on_body_entered(body: Node2D) -> void:
	_bodies.append(body)
	if body is Player:
		Fx.pool_splash(splash_point(body.global_position.x))


func _on_body_exited(body: Node2D) -> void:
	_bodies.erase(body)


func _bubble_rect() -> Rect2:
	return Rect2(
		Vector2(4.0, _pool_size.y * 0.15),
		Vector2(_pool_size.x - 8.0, _pool_size.y * 0.55)
	)
