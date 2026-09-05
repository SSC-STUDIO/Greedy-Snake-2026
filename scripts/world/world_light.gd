class_name WorldLight
extends PointLight2D
## Presentation point light. Hosts set `follow` / `lit`; WorldClock never owns this.
## Clock numbers stay the source of truth; this node carves, clamps, and stops leak.

const TEX_SIZE := 64.0
## ForgeShelter is 256×160. A 220 clock radius floods the boss floor.
const INDOOR_RADIUS_MAX := 112.0
## Residual coal, not a second room fill on top of WarmPool.
const HEART_RADIUS_MAX := 46.0
## Graveyard view of the remnant: doorway glow, not an indoor flood.
const INDOOR_OUTDOOR_RADIUS := 72.0

@export var follow: StringName = &""
@export var flicker: bool = false
@export var lit: bool = false
## 0 = use the follow default cap. Hosts may tighten further.
@export var radius_cap: float = 0.0
@export var base_energy: float = 0.55
@export var base_radius: float = 64.0
@export var casts_shadow := true
var _bound_follow: StringName = &"__unbound"
var _atmosphere: WorldAtmosphere

var _flame_frame: int = 0
static var _radial_tight: Texture2D
static var _radial_soft: Texture2D


func _ready() -> void:
	shadow_enabled = casts_shadow
	shadow_filter = Light2D.SHADOW_FILTER_NONE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_atmosphere = WorldAtmosphere.for_node(self)
	_bind_presentation()
	apply(true)


func _process(_delta: float) -> void:
	apply(false)


func set_flame_frame(frame: int) -> void:
	_flame_frame = frame


func apply(snap: bool = false) -> void:
	_bind_presentation()
	var e := _present_energy()
	var r := _present_radius()
	if flicker and lit and not snap:
		e *= 0.92 + 0.16 * (float(_flame_frame % 8) / 7.0)
	if not lit:
		enabled = false
		energy = 0.0
		return
	enabled = e > 0.001
	energy = e
	texture_scale = (r * 2.0) / TEX_SIZE


func _bind_presentation() -> void:
	if _bound_follow == follow:
		return
	_bound_follow = follow
	# Keep the blend operation stable while crossing a zone boundary.
	blend_mode = Light2D.BLEND_MODE_ADD
	if follow == &"indoor":
		height = 0.32
		texture = _soft_texture()
	elif follow == &"heart":
		height = 0.22
		texture = _tight_texture()
	else:
		height = 0.40
		texture = _tight_texture()


func _indoor_weight() -> float:
	if not is_instance_valid(_atmosphere):
		_atmosphere = WorldAtmosphere.for_node(self)
	if _atmosphere != null:
		return _atmosphere.indoor_weight
	return 1.0 if WorldClock.zone == WorldClock.Zone.INDOORS else 0.0


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
		&"torch":
			return base_energy
		_:
			return energy


func _present_energy() -> float:
	if not lit:
		return 0.0
	var e := _target_energy()
	if follow == &"indoor":
		return e * lerpf(0.40, 0.82, _indoor_weight())
	if follow == &"nest":
		# Ambient now keeps enemies readable; the brightest source stays bounded.
		return minf(e * 0.82, 1.65)
	if follow == &"torch":
		var outdoor := 0.58 if WorldClock.phase == WorldClock.Phase.DAY else 0.82
		return e * lerpf(outdoor, 1.0, _indoor_weight())
	return e


func _target_radius() -> float:
	match follow:
		&"nest":
			return WorldClock.nest_light_radius()
		&"indoor":
			return WorldClock.indoor_fill_radius()
		&"heart":
			return WorldClock.heart_light_radius()
		&"torch":
			return base_radius
		_:
			return TEX_SIZE * texture_scale * 0.5


func _present_radius() -> float:
	var r := _target_radius()
	var cap := radius_cap
	if cap <= 0.0:
		match follow:
			&"indoor":
				cap = INDOOR_RADIUS_MAX
			&"heart":
				cap = HEART_RADIUS_MAX
	if cap > 0.0:
		r = minf(r, cap)
	if follow == &"indoor":
		r = lerpf(minf(r, INDOOR_OUTDOOR_RADIUS), r, _indoor_weight())
	return r


func _tight_texture() -> Texture2D:
	if _radial_tight != null:
		return _radial_tight
	_radial_tight = _make_radial(3.0)
	return _radial_tight


func _soft_texture() -> Texture2D:
	if _radial_soft != null:
		return _radial_soft
	_radial_soft = _make_radial(2.0)
	return _radial_soft


func _make_radial(power: float) -> Texture2D:
	var size := int(TEX_SIZE)
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size * 0.5, size * 0.5)
	var radius := size * 0.5
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(center) / radius
			var a := clampf(1.0 - d, 0.0, 1.0)
			a = pow(a, power)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	return ImageTexture.create_from_image(img)
