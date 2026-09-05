class_name Level01Parallax
extends Node
## Level01 backdrop extras: drifting fog, near-silhouette strip, mood tint.
## Sky/cloud/fog stamps are cut from the authored Gothicvania plates, then
## seeded. Mountain / grove / graveyard strips stay. Near grass stays a strip.

## Pixel fog already has body; WorldClock haze alphas stay low, so lift locally.
const FOG_SEE := 1.35
## 近景剪影带（motion 0.65）：一段 512px 宽的图样平铺，只种暗紫软物，
## 填在远景 Hills(0.48) 与游玩层(1.0) 之间。石碑/雕像不进这层——
## 看起来能踩却够不着，叠在月亮/远山上会像「飞着的交互物」。
## feet 落在 Hills 墓园板与玩法地面重叠的山脚带（约 318–322），不是远空。
const SIL_PATTERN := [
	# 近景台阶：树 + 灌木留空，不种雕像。矮草条 NearGround 另铺一层。
	[Level01Env.DECOR_TREE_2, 64.0, 320.0, 0.44],
	[Level01Env.DECOR_BUSH_S, 150.0, 322.0, 0.70],
	[Level01Env.DECOR_BUSH_L, 250.0, 322.0, 0.50],
	[Level01Env.DECOR_TREE_3, 430.0, 320.0, 0.38],
	[Level01Env.DECOR_BUSH_L, 360.0, 322.0, 0.42],
]
const SIL_TINT := Color(0.10, 0.08, 0.14, 0.70)
const SIL_FEET_MIN := 300.0
const SIL_FEET_MAX := 340.0
const SIL_SPAN := 512.0
const TINT_FOLLOW := 2.8
const STAR_TICK := 1.0 / 12.0
## Keep the authored wide sky plate as the primary backdrop.  The generated
## wash + 56px moon made the whole scene read flatter and smaller than the
## original presentation; weather/fog layers remain available on top.
const USE_AUTHORED_SKY_PLATE := true

var _far_layer: ParallaxLayer
var _star_layer: ParallaxLayer
var _star_sprite: Sprite2D
var _star_tex: ImageTexture
var _star_img: Image
var _stars: Array = []
var _star_t: float = 0.0
var _star_acc: float = 0.0
var _cloud_far: ParallaxLayer
var _cloud_low: ParallaxLayer
var _fog_ridge: ParallaxLayer
var _fog_far: ParallaxLayer
var _fog_near: ParallaxLayer
var _fog_ridge_spr: Sprite2D
var _fog_far_spr: Sprite2D
var _fog_near_spr: Sprite2D
var _sil_layer: ParallaxLayer
var _near_ground: ParallaxLayer
var _foreground: ParallaxLayer
var _far_sprite: Sprite2D
var _moon_sprite: Sprite2D
var _mood_tint: CanvasModulate
var _moon_fill: DirectionalLight2D
var sky_seed: int = 0
var _plan: Dictionary = {}


func build(host: Node2D) -> void:
	var backdrop := host.get_node_or_null("ParallaxBackdrop") as ParallaxBackground
	if backdrop == null:
		return
	_far_layer = backdrop.get_node_or_null("Far") as ParallaxLayer
	if _far_layer != null:
		_far_sprite = _far_layer.get_node_or_null("Sprite") as Sprite2D
	_cloud_far = backdrop.get_node_or_null("CloudFar") as ParallaxLayer
	_cloud_low = backdrop.get_node_or_null("CloudLow") as ParallaxLayer
	_apply_stamp_sky(backdrop)
	_fog_ridge = _add_fog_field(
			backdrop, "FogRidge", Vector2(0.28, 0.07), 198.0, 0.18,
			_plan.get("fog_ridge", []), SkyPlate.FOG_RIDGE_FIELD, "Mid")
	_fog_far = _add_fog_field(
			backdrop, "FogFar", Vector2(0.42, 0.09), 222.0, 0.20,
			_plan.get("fog_far", []), SkyPlate.FOG_FAR_FIELD, "MidGrove")
	_fog_near = _add_fog_field(
			backdrop, "FogNear", Vector2(0.56, 0.11), 248.0, 0.24,
			_plan.get("fog_near", []), SkyPlate.FOG_NEAR_FIELD, "Hills")
	if _fog_ridge != null:
		_fog_ridge_spr = _first_stamp(_fog_ridge)
	if _fog_far != null:
		_fog_far_spr = _first_stamp(_fog_far)
	if _fog_near != null:
		_fog_near_spr = _first_stamp(_fog_near)
	_sil_layer = _add_silhouette_layer(backdrop)
	_near_ground = backdrop.get_node_or_null("NearGround") as ParallaxLayer
	if _near_ground != null:
		# 近景条只留草/灌。墓石碎石在 GraveDecor（scale=1，无风，钉地）。
		# 比剪影更近，画在 Sil 前面，仍在玩法层后面。
		if _sil_layer != null:
			backdrop.move_child(_near_ground, _sil_layer.get_index() + 1)
		elif backdrop.get_node_or_null("FogNear") != null:
			var fog_n := backdrop.get_node("FogNear")
			backdrop.move_child(_near_ground, fog_n.get_index() + 1)
	var front := host.get_node_or_null("ParallaxForeground") as ParallaxBackground
	if front != null:
		# motion>1 只给幕前草。碑/石/土唇不进这张条，否则人一走坟自己在滑。
		_foreground = front.get_node_or_null("Foreground") as ParallaxLayer
	# 全局微紫色调：把厚涂角色与紫色墓地轻轻拉到同一冷色轴上。
	# CanvasModulate 与余烬巢 PointLight2D 叠在同一视口：夜里压暗，点光打出暖圈。
	var tint := host.get_node_or_null("MoodTint") as CanvasModulate
	if tint == null:
		tint = CanvasModulate.new()
		tint.name = "MoodTint"
		host.add_child(tint)
	_mood_tint = tint
	_mood_tint.color = WorldClock.mood_tint()
	var moon := host.get_node_or_null("MoonFill") as DirectionalLight2D
	if moon == null:
		moon = DirectionalLight2D.new()
		moon.name = "MoonFill"
		moon.color = Color(0.72, 0.78, 1.0)
		moon.shadow_enabled = true
		moon.height = 0.65
		moon.rotation = deg_to_rad(-18.0)
		host.add_child(moon)
	_moon_fill = moon
	_snap_atmosphere()
	if host.get_node_or_null("WeatherFx") == null:
		var wx := WeatherFx.new()
		wx.name = "WeatherFx"
		host.add_child(wx)
	if host.get_node_or_null("CineFx") == null:
		var cine := CineFx.new()
		cine.name = "CineFx"
		host.add_child(cine)


func _apply_stamp_sky(backdrop: ParallaxBackground) -> void:
	sky_seed = WorldClock.roll_sky_seed()
	_plan = SkyPlate.layout(sky_seed)
	if _far_sprite != null:
		_far_sprite.texture = SkyPlate.sky_wash()
		_far_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_far_sprite.scale = Vector2(1, 1)
		_far_sprite.region_enabled = true
		_far_sprite.region_rect = Rect2(0.0, 0.0, 640.0, float(SkyPlate.SKY_H))
		_far_sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		_far_sprite.set_meta("source_path", SkyPlate.SKY_SRC)
		if _far_layer != null:
			_far_layer.motion_mirroring = Vector2(float(SkyPlate.SKY_COVER_W), 0)
		if USE_AUTHORED_SKY_PLATE:
			var authored := Sprite2D.new()
			authored.name = "AuthoredSkyPlate"
			authored.texture = load(SkyPlate.SKY_SRC) as Texture2D
			authored.centered = false
			authored.position = _far_sprite.position
			authored.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			authored.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			authored.region_enabled = true
			authored.region_rect = Rect2(0.0, 0.0, SkyPlate.SKY_COVER_W, float(SkyPlate.SKY_H))
			authored.set_meta("source_path", SkyPlate.SKY_SRC)
			_far_layer.add_child(authored)
	_add_moon(backdrop, _plan["moon"])
	if USE_AUTHORED_SKY_PLATE:
		# The authored plate already contains its large moon, clouds and stars.
		# Keep generated nodes for tooling compatibility but prevent double images.
		var moon := backdrop.get_node_or_null("SkyMoon") as CanvasItem
		if moon != null:
			moon.visible = false
		var stars := backdrop.get_node_or_null("SkyStars") as CanvasItem
		if stars != null:
			stars.visible = false
		if _cloud_far != null:
			_cloud_far.visible = false
		if _cloud_low != null:
			_cloud_low.visible = false
	_add_stars(backdrop, _plan.get("stars", []))
	_scatter_field(_cloud_far, _plan.get("clouds_far", []), SkyPlate.cloud_units(),
			SkyPlate.CLOUD_FAR_FIELD, 8.0)
	_scatter_field(_cloud_low, _plan.get("clouds_low", []), SkyPlate.cloud_units(),
			SkyPlate.CLOUD_LOW_FIELD, 68.0)
	if _cloud_far != null:
		_cloud_far.modulate = Color(1.0, 0.90, 1.0, 0.78)
	if _cloud_low != null:
		_cloud_low.modulate = Color(0.94, 0.86, 1.0, 0.58)


func _add_moon(backdrop: ParallaxBackground, spec: Dictionary) -> void:
	var old := backdrop.get_node_or_null("SkyMoon")
	if old != null:
		old.free()
	var layer := ParallaxLayer.new()
	layer.name = "SkyMoon"
	layer.motion_scale = Vector2(0.06, 0.03)
	layer.motion_mirroring = Vector2.ZERO
	var spr := Sprite2D.new()
	spr.name = "Moon"
	spr.texture = SkyPlate.moon_tex()
	spr.centered = true
	spr.position = Vector2(float(spec["x"]), float(spec["y"]))
	var sc := maxi(1, int(spec.get("scale", 1)))
	spr.scale = Vector2(sc, sc)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var moon_material := CanvasItemMaterial.new()
	moon_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	spr.material = moon_material
	var halo := Sprite2D.new()
	halo.name = "MoonHalo"
	halo.texture = _moon_halo_texture()
	halo.position = spr.position
	halo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var halo_material := CanvasItemMaterial.new()
	halo_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	halo_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	halo.material = halo_material
	layer.add_child(halo)
	layer.add_child(spr)
	backdrop.add_child(layer)
	if _far_layer != null:
		backdrop.move_child(layer, _far_layer.get_index() + 1)
	_moon_sprite = spr


func _moon_halo_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color(0.38, 0.48, 0.90, 0.0),
		Color(0.34, 0.44, 0.88, 0.16),
		Color(0.28, 0.36, 0.72, 0.0),
	])
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.width = 128
	tex.height = 128
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	return tex


func _add_stars(backdrop: ParallaxBackground, items: Array) -> void:
	var old := backdrop.get_node_or_null("SkyStars")
	if old != null:
		old.free()
	_stars = items
	_star_t = 0.0
	_star_acc = 0.0
	_star_img = SkyPlate.star_field_image(_stars, 0.0)
	_star_tex = ImageTexture.create_from_image(_star_img)
	var layer := ParallaxLayer.new()
	layer.name = "SkyStars"
	layer.motion_scale = Vector2(0.075, 0.03)
	layer.motion_mirroring = Vector2(float(SkyPlate.STAR_FIELD_W), 0)
	layer.set_meta("star_count", _stars.size())
	var spr := Sprite2D.new()
	spr.name = "Stars"
	spr.texture = _star_tex
	spr.centered = false
	spr.position = Vector2(0, -16)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	layer.add_child(spr)
	backdrop.add_child(layer)
	if _far_layer != null:
		backdrop.move_child(layer, _far_layer.get_index() + 1)
	_star_layer = layer
	_star_sprite = spr
	_star_layer.modulate.a = _star_visibility()


func star_count() -> int:
	return _stars.size()


func twinkle(time_sec: float) -> float:
	_star_t = maxf(0.0, time_sec)
	_paint_stars()
	return SkyPlate.star_field_luma(_stars, _star_t)


func _paint_stars() -> void:
	if _star_img == null or _star_tex == null:
		return
	SkyPlate.paint_stars(_star_img, _stars, _star_t)
	_star_tex.update(_star_img)


func _star_visibility() -> float:
	match WorldClock.phase:
		WorldClock.Phase.NIGHT:
			return 1.0
		WorldClock.Phase.DUSK:
			return 0.72
		WorldClock.Phase.DAWN:
			return 0.28
		_:
			return 0.0


func _scatter_field(
		layer: ParallaxLayer,
		items: Array,
		units: Array[Texture2D],
		field: float,
		y_base: float) -> void:
	if layer == null or items.is_empty() or units.is_empty():
		return
	var authored := layer.get_node_or_null("Sprite") as Sprite2D
	if authored != null:
		authored.visible = false
	_clear_stamps(layer)
	var i := 0
	for item in items:
		var spec: Dictionary = item
		var spr := Sprite2D.new()
		spr.name = "SkyStamp_%d" % i
		i += 1
		spr.texture = units[int(spec["unit"]) % units.size()]
		spr.centered = false
		spr.position = Vector2(float(spec["x"]), y_base + float(spec["y"]))
		var sc := maxi(1, int(spec.get("scale", 1)))
		spr.scale = Vector2(sc, sc)
		spr.flip_h = bool(spec.get("flip", false))
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		layer.add_child(spr)
	layer.motion_mirroring = Vector2(field, 0)


func _add_fog_field(
		backdrop: ParallaxBackground,
		layer_name: String,
		motion: Vector2,
		y: float,
		alpha: float,
		items: Array,
		field: float,
		after: String) -> ParallaxLayer:
	var units := SkyPlate.fog_units()
	if units.is_empty():
		return null
	var layer := ParallaxLayer.new()
	layer.name = layer_name
	layer.motion_scale = motion
	layer.modulate = Color(1, 1, 1, alpha)
	_scatter_field(layer, items, units, field, y)
	if layer.get_child_count() == 0:
		layer.free()
		return null
	backdrop.add_child(layer)
	var sib := backdrop.get_node_or_null(after)
	if sib != null:
		backdrop.move_child(layer, sib.get_index() + 1)
	return layer


func _clear_stamps(layer: ParallaxLayer) -> void:
	var dead: Array[Node] = []
	for child in layer.get_children():
		if child is Sprite2D and String(child.name).begins_with("SkyStamp"):
			dead.append(child)
	for child in dead:
		child.free()


func _first_stamp(layer: ParallaxLayer) -> Sprite2D:
	for child in layer.get_children():
		if child is Sprite2D and child.visible:
			return child
	return layer.get_child(0) as Sprite2D if layer.get_child_count() > 0 else null


func _process(delta: float) -> void:
	var drift := WorldClock.wind_vector().x
	if _far_layer != null:
		_far_layer.motion_offset.x += drift * 8.0 * delta
	if _star_layer != null:
		_star_layer.motion_offset.x += drift * 3.0 * delta
		_star_t += delta
		_star_acc += delta
		if _star_acc >= STAR_TICK:
			_star_acc -= STAR_TICK
			_paint_stars()
	if _cloud_far != null:
		_cloud_far.motion_offset.x += drift * 5.0 * delta
	if _cloud_low != null:
		_cloud_low.motion_offset.x += drift * 9.0 * delta
	if _fog_ridge != null:
		_fog_ridge.motion_offset.x += drift * 14.0 * delta
	if _fog_far != null:
		_fog_far.motion_offset.x += drift * 22.0 * delta
	if _fog_near != null:
		_fog_near.motion_offset.x += drift * 34.0 * delta
	if _near_ground != null:
		_near_ground.motion_offset.x += drift * 40.0 * delta
	if _foreground != null:
		_foreground.motion_offset.x += drift * 56.0 * delta
	_follow_atmosphere(delta)


func _snap_atmosphere() -> void:
	_follow_atmosphere(999.0)


func _follow_atmosphere(delta: float) -> void:
	var k := 1.0 if delta > 10.0 else (1.0 - exp(-TINT_FOLLOW * delta))
	if _mood_tint != null:
		_mood_tint.color = _mood_tint.color.lerp(WorldClock.mood_tint(), k)
	if _fog_ridge != null:
		var ra := clampf(WorldClock.fog_far_alpha() * FOG_SEE, 0.10, 0.48)
		_fog_ridge.modulate = _fog_ridge.modulate.lerp(Color(1, 1, 1, ra), k)
	if _fog_far != null:
		var mid := lerpf(WorldClock.fog_far_alpha(), WorldClock.fog_near_alpha(), 0.45)
		var fa := clampf(mid * FOG_SEE, 0.12, 0.50)
		_fog_far.modulate = _fog_far.modulate.lerp(Color(1, 1, 1, fa), k)
	if _fog_near != null:
		var na := clampf(WorldClock.fog_near_alpha() * FOG_SEE, 0.14, 0.52)
		_fog_near.modulate = _fog_near.modulate.lerp(Color(1, 1, 1, na), k)
	if _sil_layer != null:
		_sil_layer.modulate = _sil_layer.modulate.lerp(WorldClock.silhouette_modulate(), k)
	if _far_sprite != null:
		_far_sprite.modulate = _far_sprite.modulate.lerp(WorldClock.sky_modulate(), k)
	if _star_layer != null:
		var star_col := Color(1, 1, 1, _star_visibility())
		_star_layer.modulate = _star_layer.modulate.lerp(star_col, k)
	if _moon_fill != null:
		var e := WorldClock.moon_fill_energy()
		_moon_fill.energy = e
		_moon_fill.enabled = e > 0.001


func _add_silhouette_layer(backdrop: ParallaxBackground) -> ParallaxLayer:
	var layer := ParallaxLayer.new()
	layer.name = "NearSilhouette"
	layer.motion_scale = Vector2(0.65, 0.12)
	layer.motion_mirroring = Vector2(SIL_SPAN, 0)
	var any := false
	for item in SIL_PATTERN:
		var path := item[0] as String
		var spr := Level01Env.plant(
				layer,
				path,
				Vector2(float(item[1]), float(item[2])),
				float(item[3]),
				SIL_TINT)
		if spr != null:
			any = true
	if any:
		backdrop.add_child(layer)
		return layer
	layer.free()
	return null
