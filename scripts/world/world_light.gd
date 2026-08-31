class_name WorldLight
extends PointLight2D
## Presentation point light. Hosts set `follow` / `lit`; WorldClock never owns this.

const TEX_SIZE := 64.0

@export var follow: StringName = &""
@export var flicker: bool = false
@export var lit: bool = false

var _flame_frame: int = 0
static var _radial: Texture2D


func _ready() -> void:
	shadow_enabled = true
	shadow_filter = Light2D.SHADOW_FILTER_NONE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	blend_mode = Light2D.BLEND_MODE_ADD
	if texture == null:
		texture = _radial_texture()
	apply(true)


func _process(_delta: float) -> void:
	apply(false)


func set_flame_frame(frame: int) -> void:
	_flame_frame = frame


func apply(snap: bool = false) -> void:
	var e := _target_energy()
	var r := _target_radius()
	if flicker and lit and not snap:
		e *= 0.92 + 0.16 * (float(_flame_frame % 8) / 7.0)
	if not lit:
		enabled = false
		energy = 0.0
		return
	enabled = e > 0.001
	energy = e
	texture_scale = (r * 2.0) / TEX_SIZE


func _target_energy() -> float:
	if not lit:
		return 0.0
	match follow:
		&"nest":
			return WorldClock.nest_light_energy()
		&"indoor":
			return WorldClock.indoor_fill_energy()
		&"heart":
			return WorldClock.heart_light_energy()
		_:
			return energy


func _target_radius() -> float:
	match follow:
		&"nest":
			return WorldClock.nest_light_radius()
		&"indoor":
			return WorldClock.indoor_fill_radius()
		&"heart":
			return WorldClock.heart_light_radius()
		_:
			return TEX_SIZE * texture_scale * 0.5


func _radial_texture() -> Texture2D:
	if _radial != null:
		return _radial
	var size := int(TEX_SIZE)
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size * 0.5, size * 0.5)
	var radius := size * 0.5
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(center) / radius
			var a := clampf(1.0 - d, 0.0, 1.0)
			a = a * a
			img.set_pixel(x, y, Color(1.0, 0.78, 0.42, a))
	_radial = ImageTexture.create_from_image(img)
	return _radial
