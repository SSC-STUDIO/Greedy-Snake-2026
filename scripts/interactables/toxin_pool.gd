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

var _scum_sprites: Array[Sprite2D] = []
var _scum_frames: Array[Texture2D] = []
var _scum_time := 0.0
var _hinted := false


func _ready() -> void:
	# Sensor only — never a solid lid. Player mask is layer 1; this stays on 128.
	collision_layer = 128
	collision_mask = 2
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_rebuild_visual()


func configure(size: Vector2) -> void:
	_pool_size = size
	_rebuild_visual()


## World-space water film. Rain / splash FX use the top edge as the hit plane,
## not the pit floor. Do not shrink this to a collision inset — weather_fx
## samples `y = rect.position.y` as the scum surface.
func surface_rect() -> Rect2:
	return Rect2(global_position, _pool_size)


func _on_body_entered(body: Node2D) -> void:
	if not _bodies.has(body):
		_bodies.append(body)
	if body is Player:
		Sfx.play(&"splash", 0.08, -8.0)


func _on_body_exited(body: Node2D) -> void:
	_bodies.erase(body)
	if body is Player:
		_hinted = false


func _rebuild_visual() -> void:
	for child in get_children():
		if child is CollisionShape2D:
			continue
		child.queue_free()
	_scum_sprites.clear()
	_scum_frames.clear()
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
				# Liquid darkens with depth; texture already fades, rows push further.
				var k := lerpf(0.9, 0.45, float(r) / maxf(1.0, float(rows - 1)))
				spr.modulate = Color(k, k, k)
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
		spr.position.y = sin(_scum_time * 1.7 + float(i) * 0.9) * SCUM_BOB - 0.5


func _physics_process(delta: float) -> void:
	# 过场锁输入时人走不开，继续灌毒会在台词里把骑士灌满并触发满溢。
	# 池不改 velocity：人在腐液里仍能左右走、跳，爬岸靠关卡矮唇。
	if Director.is_input_locked():
		return
	_prune_bodies()
	for body in _bodies:
		if body is Player:
			(body as Player).toxin.expose(toxin_per_second * delta)
			_maybe_hint()
	_bubble_accum += delta
	if _bubble_accum >= BUBBLE_INTERVAL:
		_bubble_accum -= BUBBLE_INTERVAL
		Fx.toxin_bubbles(self, _bubble_rect())


func _prune_bodies() -> void:
	var i := _bodies.size() - 1
	while i >= 0:
		if not is_instance_valid(_bodies[i]):
			_bodies.remove_at(i)
		i -= 1


func _maybe_hint() -> void:
	if _hinted:
		return
	# 初次入池由剧情字幕请客；过场中也先记一笔，避免解锁后再叠一句。
	if Director.is_input_locked() or Director.playing:
		_hinted = true
		return
	_hinted = true
	GameEvents.announcement.emit("腐液咬着靴底")


func _bubble_rect() -> Rect2:
	return Rect2(
		Vector2(4.0, _pool_size.y * 0.15),
		Vector2(_pool_size.x - 8.0, _pool_size.y * 0.55)
	)
