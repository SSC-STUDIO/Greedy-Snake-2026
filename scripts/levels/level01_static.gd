extends Node2D
## Level01 — 静态手摆关卡。
## 锚点、拾取物、视差背景等全部固化在 .tscn 里，可直接在 Godot 编辑器中
## 可视化编辑；本脚本只负责生成玩家/相机/HUD 三件套并接线机关信号。

const PLAYER := preload("res://scenes/player/Player.tscn")
const CAMERA := preload("res://scenes/camera/GameCamera.tscn")
const HUD := preload("res://scenes/ui/HUD.tscn")

const DECOR_TREE_1 := "res://assets/external/gothicvania_cemetery/PNG/Environment/sliced-objects/tree-1.png"
const DECOR_TREE_2 := "res://assets/external/gothicvania_cemetery/PNG/Environment/sliced-objects/tree-2.png"
const DECOR_TREE_3 := "res://assets/external/gothicvania_cemetery/PNG/Environment/sliced-objects/tree-3.png"
const DECOR_BUSH_L := "res://assets/external/gothicvania_cemetery/PNG/Environment/sliced-objects/bush-large.png"
const DECOR_BUSH_S := "res://assets/external/gothicvania_cemetery/PNG/Environment/sliced-objects/bush-small.png"
const DECOR_STONE_1 := "res://assets/external/gothicvania_cemetery/PNG/Environment/sliced-objects/stone-1.png"
const DECOR_STONE_2 := "res://assets/external/gothicvania_cemetery/PNG/Environment/sliced-objects/stone-2.png"
const DECOR_STONE_3 := "res://assets/external/gothicvania_cemetery/PNG/Environment/sliced-objects/stone-3.png"
const DECOR_STATUE := "res://assets/external/gothicvania_cemetery/PNG/Environment/sliced-objects/statue.png"

@onready var plate: PressurePlate = $Props/PressurePlate
@onready var door: ArenaDoor = $Props/Door

const DEFAULT_SPAWN := Vector2(96, 290)

const FOG_PATH := "res://assets/env/fog_band.png"
## 近景剪影带（motion 0.65）：一段 512px 宽的图样平铺，枯树/石碑压成暗紫剪影，
## 填在远景 Hills(0.48) 与游玩层(1.0) 之间，背景不再是三张图硬叠。
const SIL_PATTERN := [
	# [path, x, feet_y, scale]。树不要缩太狠：密集枝干缩到一半以下会糊成实心色板。
	[DECOR_STONE_2, 14.0, 300.0, 1.0],
	[DECOR_TREE_2, 46.0, 300.0, 0.72],
	[DECOR_STONE_1, 224.0, 303.0, 1.0],
	[DECOR_STATUE, 282.0, 300.0, 0.85],
	[DECOR_TREE_1, 342.0, 302.0, 0.62],
	[DECOR_STONE_3, 476.0, 300.0, 1.0],
]
const SIL_TINT := Color(0.17, 0.14, 0.24, 0.95)
const SIL_SPAN := 512.0

var _far_layer: ParallaxLayer
var _fog_far: ParallaxLayer
var _fog_near: ParallaxLayer


func _ready() -> void:
	_spawn_decor()
	_build_parallax_extras()
	_spawn_actors()
	_wire_props()
	GameEvents.announcement.emit("锈墓・壹 — 腐液回廊")


func _process(delta: float) -> void:
	# 极缓的天空/雾漂移：月亮云层向左蹭，两层雾对向流动，画面不再死板。
	if _far_layer != null:
		_far_layer.motion_offset.x -= 1.1 * delta
	if _fog_far != null:
		_fog_far.motion_offset.x += 2.6 * delta
	if _fog_near != null:
		_fog_near.motion_offset.x -= 4.0 * delta


func _wire_props() -> void:
	if plate != null and door != null and not plate.activated.is_connected(door.open_door):
		plate.activated.connect(door.open_door)
	var toxin := get_node_or_null("Props/ToxinPool") as ToxinPool
	if toxin != null:
		toxin.configure(Vector2(112, 32))


func _spawn_actors() -> void:
	var player: Player = PLAYER.instantiate()
	player.position = DEFAULT_SPAWN
	add_child(player)

	if SaveData.has_save():
		SaveData.load_game()
		if SaveData.pending_spawn != Vector2.INF:
			player.position = SaveData.consume_pending_spawn()
		elif SaveData.data.has("player") and (SaveData.data["player"] as Dictionary).has("pos"):
			player.position = SaveData.data["player"]["pos"]
		SaveData.apply_player(player)
		SaveData.apply_world(self)
		SaveData.apply_consumed(self)

	var cam: GameCamera = CAMERA.instantiate()
	add_child(cam)
	cam.global_position = player.global_position + Vector2(0, -18)

	var hud: CanvasLayer = HUD.instantiate()
	add_child(hud)


func _spawn_decor() -> void:
	var layer := Node2D.new()
	layer.name = "GraveDecor"
	layer.z_index = -2
	add_child(layer)
	# Feet planted on the y=320 ground; skip the toxin pit (x 400–512).
	_plant(layer, DECOR_TREE_1, Vector2(8, 320), 0.50)
	_plant(layer, DECOR_BUSH_L, Vector2(78, 320), 0.65)
	_plant(layer, DECOR_STONE_1, Vector2(210, 320), 1.0)
	_plant(layer, DECOR_TREE_2, Vector2(268, 320), 0.46)
	_plant(layer, DECOR_STONE_3, Vector2(360, 320), 1.0)
	_plant(layer, DECOR_TREE_3, Vector2(540, 320), 0.40)
	_plant(layer, DECOR_BUSH_S, Vector2(620, 320), 1.0)
	_plant(layer, DECOR_STATUE, Vector2(880, 320), 0.82)
	_plant(layer, DECOR_STONE_2, Vector2(1020, 320), 1.0)
	_plant(layer, DECOR_TREE_1, Vector2(1210, 320), 0.48)
	_plant(layer, DECOR_BUSH_L, Vector2(1440, 320), 0.62)
	_plant(layer, DECOR_STONE_1, Vector2(1540, 320), 1.0)


func _plant(parent: Node2D, path: String, feet: Vector2, scale: float) -> void:
	if not ResourceLoader.exists(path):
		return
	var tex := load(path) as Texture2D
	if tex == null:
		return
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.centered = false
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.scale = Vector2(scale, scale)
	spr.position = Vector2(feet.x, feet.y - float(tex.get_height()) * scale)
	parent.add_child(spr)


## --- 背景层次：剪影带 + 雾 + 全局色调 -------------------------------------
func _build_parallax_extras() -> void:
	var backdrop := get_node_or_null("ParallaxBackdrop") as ParallaxBackground
	if backdrop == null:
		return
	_far_layer = backdrop.get_node_or_null("Far") as ParallaxLayer
	var fog_tex: Texture2D = null
	if ResourceLoader.exists(FOG_PATH):
		fog_tex = load(FOG_PATH) as Texture2D
	if fog_tex != null:
		_fog_far = _add_fog_layer(backdrop, "FogFar", Vector2(0.5, 0.1), 234.0, 0.13, fog_tex)
	_add_silhouette_layer(backdrop)
	if fog_tex != null:
		_fog_near = _add_fog_layer(backdrop, "FogNear", Vector2(0.75, 0.14), 276.0, 0.2, fog_tex)
	# 全局微紫色调：把厚涂角色与紫色墓地轻轻拉到同一冷色轴上。
	var tint := CanvasModulate.new()
	tint.name = "MoodTint"
	tint.color = Color(0.955, 0.92, 1.0)
	add_child(tint)


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


func _add_silhouette_layer(backdrop: ParallaxBackground) -> void:
	var layer := ParallaxLayer.new()
	layer.name = "NearSilhouette"
	layer.motion_scale = Vector2(0.65, 0.12)
	layer.motion_mirroring = Vector2(SIL_SPAN, 0)
	var any := false
	for item in SIL_PATTERN:
		var path := item[0] as String
		if not ResourceLoader.exists(path):
			continue
		var tex := load(path) as Texture2D
		if tex == null:
			continue
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.centered = false
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var s := float(item[3])
		spr.scale = Vector2(s, s)
		spr.position = Vector2(float(item[1]), float(item[2]) - float(tex.get_height()) * s)
		spr.modulate = SIL_TINT
		layer.add_child(spr)
		any = true
	if any:
		backdrop.add_child(layer)
	else:
		layer.free()
