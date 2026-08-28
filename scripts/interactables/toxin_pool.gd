class_name ToxinPool
extends Area2D
## Orange sludge. Standing in it fills the knight's toxin meter.

@export var toxin_per_second: float = 36.0

var _bodies: Array = []

## Ambient bubble cadence; Fx no-ops under headless, so this stays test-safe.
const BUBBLE_INTERVAL := 0.4
var _bubble_accum := 0.0

const TOXIN_TEX_PATH := "res://assets/kenney_clean/enemies/slimeWalk1.png"

func _ready() -> void:
	collision_layer = 128
	collision_mask = 2
	monitoring = true
	monitorable = true
	body_entered.connect(func(b: Node2D) -> void: _bodies.append(b))
	body_exited.connect(func(b: Node2D) -> void: _bodies.erase(b))
	if get_node_or_null("Fill") == null:
		if ResourceLoader.exists(TOXIN_TEX_PATH):
			var tex: Texture2D = load(TOXIN_TEX_PATH) as Texture2D
			var spr := Sprite2D.new()
			spr.name = "Fill"
			spr.texture = tex
			spr.centered = false
			spr.position = Vector2(0, 0)
			spr.modulate = Palette.TOXIC
			spr.modulate.a = 0.9
			# Stretch to default pool size via scale.
			spr.scale = Vector2(112.0 / tex.get_width(), 48.0 / tex.get_height())
			add_child(spr)
			# Keep a subtle ColorRect underneath for rust tint.
			var under := ColorRect.new()
			under.name = "UnderTint"
			under.size = Vector2(112, 48)
			under.color = Palette.TOXIC
			under.color.a = 0.25
			under.mouse_filter = Control.MOUSE_FILTER_IGNORE
			under.z_index = -1
			add_child(under)
		else:
			var fill := ColorRect.new()
			fill.name = "Fill"
			fill.size = Vector2(112, 48)
			fill.color = Color(Palette.TOXIC.r, Palette.TOXIC.g, Palette.TOXIC.b, 0.78)
			fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(fill)
	if get_node_or_null("CollisionShape2D") == null:
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(112, 48)
		col.shape = shape
		col.position = Vector2(56, 24)
		add_child(col)


func configure(size: Vector2) -> void:
	var fill := get_node_or_null("Fill") as ColorRect
	if fill:
		fill.size = size
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col and col.shape is RectangleShape2D:
		(col.shape as RectangleShape2D).size = size
		col.position = size * 0.5


func _physics_process(delta: float) -> void:
	for body in _bodies:
		if body is Player:
			(body as Player).toxin.expose(toxin_per_second * delta)
	_bubble_accum += delta
	if _bubble_accum >= BUBBLE_INTERVAL:
		_bubble_accum -= BUBBLE_INTERVAL
		Fx.toxin_bubbles(self, _bubble_rect())


## Local-space sludge region bubbles rise out of; reads the live collision
## shape so `configure()` sizes stay in sync. Biased low so bubbles visibly
## rise through the fill.
func _bubble_rect() -> Rect2:
	var pool_size := Vector2(112, 48)
	var origin := Vector2.ZERO
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col != null and col.shape is RectangleShape2D:
		var shape_size := (col.shape as RectangleShape2D).size
		if shape_size.x > 1.0 and shape_size.y > 1.0:
			pool_size = shape_size
			origin = col.position - pool_size * 0.5
	return Rect2(
		origin + Vector2(4.0, pool_size.y * 0.35),
		Vector2(pool_size.x - 8.0, pool_size.y * 0.6)
	)
