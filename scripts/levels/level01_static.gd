class_name Level01Static
extends Node2D
## Level01 — 静态手摆关卡。
## 锚点、拾取物、视差背景等全部固化在 .tscn 里，可直接在 Godot 编辑器中
## 可视化编辑；本脚本只负责生成玩家/相机/HUD 三件套并接线机关信号。

const PLAYER := preload("res://scenes/player/Player.tscn")
const CAMERA := preload("res://scenes/camera/GameCamera.tscn")
const HUD := preload("res://scenes/ui/HUD.tscn")
const PLATFORM := preload("res://scenes/world/Platform.tscn")

@onready var plate: PressurePlate = get_node_or_null("Props/PressurePlate")
@onready var door: ArenaDoor = get_node_or_null("Props/Door")

const DEFAULT_SPAWN := Vector2(96, 290)
## GroundLeft / GroundRight / east floor 顶。单跳约 37px（v=-268, g=980）。
const GROUND_TOP := 320.0
## 单跳顶点；踏步用 32px，留约 5px 余量，且不挡地面行人头顶（碰撞高 26px）。
const JUMP_REACH := 37.0
const STEP_RISE := 32.0
## 毒坑：水面 y=336（ToxinPool.surface_rect），坑底见 Level01EastWing.PIT_FLOOR_Y。
## 余烬巢右侧的第一级教学台：实心抵地，人从台上过而不是从台下钻。
## 高 48 而不是 32：底部 16px 埋进地面，用自己的土盖掉地面那行草——
## 否则是一块草皮方砖摆在草皮上（草下面还是草），读作土丘才自然。
const TEACH_TERRACE_POS := Vector2(228, 288)
const TEACH_TERRACE_SIZE := Vector2(40, 48)
## 路牌：1x 木牌 35×35（normalized/props），字写在牌面上而不是飘在牌子上方。
const SIGN_TEX := "res://assets/env/normalized/props/waymark_sign.png"
## 牌面在贴图里的矩形（贴图 y 3–22；柱脚在 (17,35)）；12px 像素字体两个字 24×12 正好落在牌面里。
const SIGN_PLANK := Rect2(0, 3, 35, 20)
const SIGN_FONT_SIZE := 12
## Plat_268 降到第二级（64px），从教学台再单跳 32px 上去。
const TEACH_MID_Y := 256.0
const WAYMARKS := [
	[Vector2(118, 320), "余烬"],
	[Vector2(344, 320), "腐液"],
	[Vector2(980, 320), "压板"],
	[Vector2(1624, 320), "东翼"],
]
## 硬物只在玩法层：scale=1，脚钉 GROUND_TOP，无 WindSway。近景视差条不画碑。
## 坟从余烬巢一路排到 x≈1580 就断了——石板路（EastFloor 1600 起）之后再无墓碑。
const PLAY_DECOR := [
	[Level01Env.DECOR_BUSH_L, Vector2(78, 320), 0.65],
	[Level01Env.DECOR_STONE_1, Vector2(210, 320), 1.0],
	[Level01Env.DECOR_TREE_2, Vector2(268, 320), 0.46],
	[Level01Env.DECOR_STONE_3, Vector2(360, 320), 1.0],
	[Level01Env.DECOR_STONE_4, Vector2(596, 320), 1.0],
	[Level01Env.DECOR_BUSH_S, Vector2(620, 320), 1.0],
	[Level01Env.DECOR_GRAVE_CROSS, Vector2(690, 320), 1.0],
	[Level01Env.DECOR_STATUE, Vector2(880, 320), 1.0],
	[Level01Env.DECOR_STONE_2, Vector2(1020, 320), 1.0],
	[Level01Env.DECOR_TREE_1, Vector2(1210, 320), 0.48],
	[Level01Env.DECOR_BUSH_L, Vector2(1440, 320), 0.62],
	[Level01Env.DECOR_STONE_1, Vector2(1496, 320), 1.0],
	[Level01Env.DECOR_STONE_4, Vector2(1580, 320), 1.0],
]

const EAST_LIMIT := Level01EastWing.EAST_LIMIT
const EAST_FLOOR_X := Level01EastWing.EAST_FLOOR_X

var _player: Player
var _boss: ExecutionerBoss
var _wing: Level01EastWing
var _beats: Level01StoryBeats


func _enter_tree() -> void:
	add_to_group("game_world")


func _ready() -> void:
	DisplayFit.apply()
	# 先读档再铺东翼：否则 boss_dead 还在磁盘上，刽子手会先进场。
	var restored := false
	if SaveData.has_save():
		restored = SaveData.load_game()
	_extend_east()
	_tune_play_layout()
	_spawn_decor()
	_spawn_waymarks()
	_spawn_steles_and_bastion_decor()
	_build_parallax_extras()
	_spawn_actors(restored)
	_wire_props()
	_bind_story()
	call_deferred("_try_wake")


func _wire_props() -> void:
	if plate != null and door != null and not plate.activated.is_connected(door.open_door):
		plate.activated.connect(door.open_door)
	var toxin := get_node_or_null("Props/ToxinPool") as ToxinPool
	if toxin != null:
		toxin.configure(Vector2(112, 32))


func _spawn_actors(restored: bool) -> void:
	_player = PLAYER.instantiate()
	_player.position = DEFAULT_SPAWN
	add_child(_player)

	var from_checkpoint := SaveData.entering_from_checkpoint
	if SaveData.has_pending_spawn():
		_player.position = SaveData.consume_pending_spawn()
	elif restored and SaveData.data.has("player") and (SaveData.data["player"] as Dictionary).has("pos"):
		_player.position = SaveData.data["player"]["pos"]
	if restored:
		SaveData.apply_player(_player)
		SaveData.apply_world(self)
		SaveData.apply_consumed(self)
	SaveData.apply_lit_nests(self)
	if from_checkpoint:
		_player.health.heal_full()
		_player.toxin.purify(1.0)
		GameEvents.player_health_changed.emit(_player.health.current, _player.health.max_hp)

	var cam: GameCamera = CAMERA.instantiate()
	add_child(cam)
	cam.limit_right = EAST_LIMIT
	cam.global_position = _player.global_position + Vector2(0, -18)

	var hud: CanvasLayer = HUD.instantiate()
	GameContext.ui_host(self).add_child(hud)


func _tune_play_layout() -> void:
	var platforms := get_node_or_null("Platforms") as Node2D
	if platforms == null:
		return
	place_teach_layout(platforms)


## 开局单跳链：地面 → 32px 实心教学台 → 再 32px 到 Plat_268。
func place_teach_layout(platforms: Node2D) -> void:
	if platforms == null:
		return
	if platforms.get_node_or_null("TeachTerrace") == null:
		var terrace: SolidPlatform = PLATFORM.instantiate()
		terrace.name = "TeachTerrace"
		terrace.skin = "ground"
		terrace.position = TEACH_TERRACE_POS
		terrace.size = TEACH_TERRACE_SIZE
		terrace.cap_left = true
		terrace.cap_right = true
		platforms.add_child(terrace)
	var mid := platforms.get_node_or_null("Plat_268_248") as SolidPlatform
	if mid != null:
		mid.position.y = TEACH_MID_Y


func _spawn_waymarks() -> void:
	if get_node_or_null("Waymarks") != null:
		return
	var layer := Node2D.new()
	layer.name = "Waymarks"
	layer.z_index = 2
	add_child(layer)
	for item in WAYMARKS:
		_waymark(layer, item[0] as Vector2, String(item[1]))


func _waymark(parent: Node2D, feet: Vector2, text: String) -> void:
	var root := Node2D.new()
	root.name = "Sign_%s" % text
	root.position = feet
	parent.add_child(root)
	var plank := SIGN_PLANK
	var origin := Vector2(-17.0, -35.0)
	if ResourceLoader.exists(SIGN_TEX):
		var spr := Sprite2D.new()
		spr.name = "Board"
		spr.texture = load(SIGN_TEX) as Texture2D
		spr.centered = false
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.position = origin
		root.add_child(spr)
	# 字写在牌面上：按 12px 像素字体的实际排版尺寸在牌面矩形里居中，坐标取整。
	var lab := Label.new()
	lab.name = "Text"
	lab.text = text
	lab.add_theme_font_size_override("font_size", SIGN_FONT_SIZE)
	lab.add_theme_color_override("font_color", Palette.PALE)
	lab.add_theme_color_override("font_outline_color", Palette.VOID)
	lab.add_theme_constant_override("outline_size", 1)
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	root.add_child(lab)
	# Size after entering the tree: the theme resolves the font on enter and
	# would otherwise grow the label to its pre-theme fallback minimum.
	lab.position = (origin + plank.position).round()
	lab.size = plank.size


func _spawn_decor() -> void:
	var layer := Node2D.new()
	layer.name = "GraveDecor"
	layer.z_index = -2
	add_child(layer)
	for item in PLAY_DECOR:
		Level01Env.plant(layer, String(item[0]), item[1] as Vector2, float(item[2]), Color.WHITE, true)


const STELE_SCENE := preload("res://scenes/interactables/LoreStele.tscn")
const TORCH_SCENE := preload("res://scenes/world/TorchLight.tscn")
const BALUSTRADE_TEX := "res://assets/env/balustrade.png"


func _spawn_steles_and_bastion_decor() -> void:
	var props := get_node_or_null("Props") as Node2D
	if props != null:
		_add_stele(props, Vector2(56, 144), "炉约纪事 · 熔熄", "炉火熄灭之时，整座地下之城沉入岩层，用锈铁为自身造就棺椁。")
		_add_stele(props, Vector2(320, 320), "工坊遗训 · 冷却液", "橙色的腐液本是冷却剂。它吃肺、吃记忆，却也使淬火之刃锋锐百倍。")

	var decor_layer := Node2D.new()
	decor_layer.name = "BastionDecor"
	decor_layer.z_index = -2
	add_child(decor_layer)
	_add_balustrade(decor_layer, Vector2(1090, 242))
	_add_balustrade(decor_layer, Vector2(1330, 242))
	_add_torch(decor_layer, Vector2(1144, 180))
	_add_torch(decor_layer, Vector2(1296, 230))
	_add_torch(decor_layer, Vector2(1488, 220))


func _add_stele(parent: Node2D, pos: Vector2, title: String, text: String) -> void:
	if STELE_SCENE == null:
		return
	var stele: Node2D = STELE_SCENE.instantiate()
	stele.position = pos
	stele.set("lore_title", title)
	stele.set("lore_text", text)
	parent.add_child(stele)


func _add_balustrade(parent: Node2D, pos: Vector2) -> void:
	if not ResourceLoader.exists(BALUSTRADE_TEX):
		return
	var spr := Sprite2D.new()
	spr.texture = load(BALUSTRADE_TEX) as Texture2D
	spr.centered = false
	spr.position = pos
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.modulate = Color(0.75, 0.7, 0.8, 0.85)
	parent.add_child(spr)


func _add_torch(parent: Node2D, pos: Vector2) -> void:
	if TORCH_SCENE == null:
		return
	var torch: Node2D = TORCH_SCENE.instantiate()
	torch.position = pos
	parent.add_child(torch)


func _build_parallax_extras() -> void:
	var extras := Level01Parallax.new()
	extras.name = "ParallaxExtras"
	add_child(extras)
	extras.build(self)


func _extend_east() -> void:
	_wing = Level01EastWing.new()
	_wing.name = "EastWing"
	add_child(_wing)
	_boss = _wing.build(self)


func _bind_story() -> void:
	_beats = Level01StoryBeats.new()
	_beats.name = "StoryBeats"
	add_child(_beats)
	_beats.bind(self, _player, _boss)
	if _wing != null:
		if not _wing.boss_gate_entered.is_connected(_beats.on_boss_gate):
			_wing.boss_gate_entered.connect(_beats.on_boss_gate)
		if not _wing.boss_slain.is_connected(_beats.on_boss_slain):
			_wing.boss_slain.connect(_beats.on_boss_slain)


func _try_wake() -> void:
	if _beats != null:
		_beats.try_wake()
	SaveData.entering_from_checkpoint = false


static func should_spawn_executioner() -> bool:
	return Level01EastWing.should_spawn_executioner()


static func should_unlock_forge() -> bool:
	return Level01EastWing.should_unlock_forge()


static func east_floor_rect() -> Rect2:
	return Level01EastWing.east_floor_rect()


static func mark_executioner_slain() -> void:
	Level01EastWing.mark_executioner_slain()
