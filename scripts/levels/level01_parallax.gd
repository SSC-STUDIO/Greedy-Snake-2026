class_name Level01Parallax
extends Node
## Level01 backdrop extras: drifting fog, near-silhouette strip, mood tint.
## Attaches into the host's existing ParallaxBackdrop; does not replace authored layers.
## Mood / fog / sky follow WorldClock — existing plates stay, only their modulate moves.

const FOG_PATH := "res://assets/env/fog_band.png"
## 近景剪影带（motion 0.65）：一段 512px 宽的图样平铺，枯树/石碑压成暗紫剪影，
## 填在远景 Hills(0.48) 与游玩层(1.0) 之间，背景不再是三张图硬叠。
const SIL_PATTERN := [
	# [path, x, feet_y, scale]。树不要缩太狠：密集枝干缩到一半以下会糊成实心色板。
	[Level01Env.DECOR_STONE_2, 14.0, 300.0, 1.0],
	[Level01Env.DECOR_TREE_2, 46.0, 300.0, 0.72],
	[Level01Env.DECOR_STONE_1, 224.0, 303.0, 1.0],
	[Level01Env.DECOR_STATUE, 282.0, 300.0, 0.85],
	[Level01Env.DECOR_TREE_1, 342.0, 302.0, 0.62],
	[Level01Env.DECOR_STONE_3, 476.0, 300.0, 1.0],
]
const SIL_TINT := Color(0.17, 0.14, 0.24, 0.95)
const SIL_SPAN := 512.0
const TINT_FOLLOW := 2.8

var _far_layer: ParallaxLayer
var _fog_far: ParallaxLayer
var _fog_near: ParallaxLayer
var _fog_far_spr: Sprite2D
var _fog_near_spr: Sprite2D
var _sil_layer: ParallaxLayer
var _far_sprite: Sprite2D
var _mood_tint: CanvasModulate


func build(host: Node2D) -> void:
	var backdrop := host.get_node_or_null("ParallaxBackdrop") as ParallaxBackground
	if backdrop == null:
		return
	_far_layer = backdrop.get_node_or_null("Far") as ParallaxLayer
	if _far_layer != null:
		_far_sprite = _far_layer.get_node_or_null("Sprite") as Sprite2D
	var fog_tex: Texture2D = null
	if ResourceLoader.exists(FOG_PATH):
		fog_tex = load(FOG_PATH) as Texture2D
	if fog_tex != null:
		_fog_far = _add_fog_layer(backdrop, "FogFar", Vector2(0.5, 0.1), 234.0, 0.13, fog_tex)
		_fog_far_spr = _fog_far.get_child(0) as Sprite2D
	_sil_layer = _add_silhouette_layer(backdrop)
	if fog_tex != null:
		_fog_near = _add_fog_layer(backdrop, "FogNear", Vector2(0.75, 0.14), 276.0, 0.2, fog_tex)
		_fog_near_spr = _fog_near.get_child(0) as Sprite2D
	# 全局微紫色调：把厚涂角色与紫色墓地轻轻拉到同一冷色轴上。
	# CanvasModulate 与余烬巢 PointLight2D 叠在同一视口：夜里压暗，点光打出暖圈。
	var tint := host.get_node_or_null("MoodTint") as CanvasModulate
	if tint == null:
		tint = CanvasModulate.new()
		tint.name = "MoodTint"
		host.add_child(tint)
	_mood_tint = tint
	_mood_tint.color = WorldClock.mood_tint()
	_snap_atmosphere()
	if host.get_node_or_null("WeatherFx") == null:
		var wx := WeatherFx.new()
		wx.name = "WeatherFx"
		host.add_child(wx)


func _process(delta: float) -> void:
	# 极缓的天空/雾漂移：月亮云层向左蹭，两层雾对向流动，画面不再死板。
	if _far_layer != null:
		_far_layer.motion_offset.x -= 1.1 * delta
	if _fog_far != null:
		_fog_far.motion_offset.x += 2.6 * delta
	if _fog_near != null:
		_fog_near.motion_offset.x -= 4.0 * delta
	_follow_atmosphere(delta)


func _snap_atmosphere() -> void:
	_follow_atmosphere(999.0)


func _follow_atmosphere(delta: float) -> void:
	var k := 1.0 if delta > 10.0 else (1.0 - exp(-TINT_FOLLOW * delta))
	if _mood_tint != null:
		_mood_tint.color = _mood_tint.color.lerp(WorldClock.mood_tint(), k)
	if _fog_far_spr != null:
		var fa := WorldClock.fog_far_alpha()
		_fog_far_spr.modulate = _fog_far_spr.modulate.lerp(Color(1, 1, 1, fa), k)
	if _fog_near_spr != null:
		var na := WorldClock.fog_near_alpha()
		_fog_near_spr.modulate = _fog_near_spr.modulate.lerp(Color(1, 1, 1, na), k)
	if _sil_layer != null:
		_sil_layer.modulate = _sil_layer.modulate.lerp(WorldClock.silhouette_modulate(), k)
	if _far_sprite != null:
		_far_sprite.modulate = _far_sprite.modulate.lerp(WorldClock.sky_modulate(), k)


func _add_fog_layer(backdrop: ParallaxBackground, layer_name: String, motion: Vector2, y: float, alpha: float, tex: Texture2D) -> ParallaxLayer:
	var layer := ParallaxLayer.new()
	layer.name = layer_name
	layer.motion_scale = motion
	layer.motion_mirroring = Vector2(SIL_SPAN, 0)
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.centered = false
	spr.position = Vector2(0, y)
	spr.scale = Vector2(SIL_SPAN / float(tex.get_width()), 1.0)
	spr.modulate = Color(1, 1, 1, alpha)
	layer.add_child(spr)
	backdrop.add_child(layer)
	return layer


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
