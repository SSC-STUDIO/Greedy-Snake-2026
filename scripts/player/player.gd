class_name Player
extends CharacterBody2D
## Ember-Knight root. Movement, combat, toxin, and cores live on child nodes.

@onready var controller: PlayerController = $PlayerController
@onready var health: Health = $Health
@onready var toxin: ToxinMeter = $ToxinMeter
@onready var inventory: RustCoreInventory = $RustCoreInventory
@onready var melee: MeleeCombat = $MeleeCombat
@onready var sensor: InteractionSensor = $InteractionSensor
@onready var visual: Node2D = $Visual
@onready var hookshot: HookshotTether = $HookshotTether


const P_STAND_PATH := "res://assets/kenney_clean/player/p1_stand.png"
const P_JUMP_PATH := "res://assets/kenney_clean/player/p1_jump.png"
const P_HURT_PATH := "res://assets/kenney_clean/player/p1_hurt.png"

## AI 生成的余烬骑士贴图（紧贴内容裁切，96px 高，脚底在图片底边）。
## 厚涂风：idle + jump + fall + hurt + 三段斩击（windup/active/parry/recovery）。
## 行走的逐帧轮换被砍掉，运行时复用 idle；视觉差异用一个简单的代码 bob 补回。
const AI_DIR := "res://assets/kenney_clean/player_ai/"
const AI_IDLE_PATH := AI_DIR + "knight_pose_idle.png"
const AI_JUMP_PATH := AI_DIR + "knight_pose_jump.png"
const AI_FALL_PATH := AI_DIR + "knight_pose_fall.png"
const AI_HURT_PATH := AI_DIR + "knight_pose_hurt.png"
const AI_SLASH_PATHS := [
	AI_DIR + "knight_pose_slash_a.png",  # windup
	AI_DIR + "knight_pose_slash_b.png",  # active (parry)
	AI_DIR + "knight_pose_slash_c.png",  # recovery
]
## AI 帧是紧裁切的：精灵中心在半高处（Kenney 图带留白，中心偏移不同）。
const AI_SPRITE_OFFSET := Vector2(0.0, -48.0)
const KENNEY_SPRITE_OFFSET := Vector2(0.0, -13.0)
## 巨剑在手部的挂点（AI 骑士 96 高，手约在 -52）。
const AI_SWORD_ANCHOR := Vector2(10.0, -52.0)
## 行走的代码 bob：在地面移动时给精灵一个 ~2px 的 Y 方向 sin 摆动。
const WALK_BOB_AMPLITUDE := 1.5
const WALK_BOB_FREQ := 7.0
## 判定帧前冲（世界单位/秒），克制到不破坏沉重移动手感。
const SLASH_LUNGE := 78.0
const AFTERIMAGE_LIFE := 0.16
## 受击红闪（纯表现）：染红后 tween 回白，~120ms。
const HIT_FLASH_COLOR := Color(1.9, 0.35, 0.35)
const HIT_FLASH_SECONDS := 0.12

var _sprites: Dictionary = {}
var _sprite_root: Sprite2D
var _slash_textures: Array[Texture2D] = []
var _hit_flash_tween: Tween
var _was_on_floor := true
var _melee_active_prev := false
var _bob_t: float = 0.0
var _moving_prev := false

func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	health.changed.connect(_on_health_changed)
	health.died.connect(_on_died)
	toxin.overflow_tick.connect(_on_toxin_overflow)
	GameEvents.player_health_changed.emit(health.current, health.max_hp)
	GameEvents.toxin_changed.emit(toxin.toxin, toxin.max_toxin)
	GameEvents.hit.connect(_on_game_hit)
	GameEvents.dash_performed.connect(_on_dash_performed)
	_setup_kenney_sprite()
	# 主题标识：余烬骑士周身漂浮的橙色余烬（Fx 内部自带 headless 守卫）。
	Fx.attach_ember(self)


func _physics_process(delta: float) -> void:
	if health.is_invincible() and health.current <= 0:
		return
	health.invincible = controller.is_invincible()
	var move_scale := 0.42 if melee.is_busy() else 1.0
	controller.physics_tick(self, delta, move_scale)
	if hookshot.is_active():
		# 钩索接管速度（在 controller 之后、move_and_slide 之前）。
		hookshot.apply_tether_velocity(self)
	var fall_speed := velocity.y
	move_and_slide()
	var face := float(controller.facing)
	visual.scale.x = face
	melee.scale.x = face
	# 落地扬尘：从明显下落转为触地时在脚边 puff 一团灰。
	if is_on_floor() and not _was_on_floor and fall_speed > 60.0:
		Fx.dust_puff(global_position + Vector2(0.0, -2.0))
	_was_on_floor = is_on_floor()
	_update_kenney_sprite(delta)
	_poll_slash_arc(face)
	_poll_interact()
	_poll_sockets()
	_poll_hookshot()


func _on_dash_performed() -> void:
	Fx.dust_puff(global_position)


func _setup_kenney_sprite() -> void:
	if not ResourceLoader.exists(P_STAND_PATH):
		return
	# Hide placeholder ColorRects but keep them for headless fallback.
	for c in visual.get_children():
		if c is SwordVisual:
			continue  # 锯齿巨剑与 Kenney 素材同屏，不随占位符隐藏
		if c is ColorRect or c is Polygon2D:
			c.visible = false
	_sprite_root = Sprite2D.new()
	_sprite_root.name = "KenneySprite"
	_sprite_root.centered = true
	_sprite_root.position = KENNEY_SPRITE_OFFSET
	_sprite_root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.add_child(_sprite_root)
	_sprites["stand"] = load(P_STAND_PATH) as Texture2D
	if ResourceLoader.exists(P_JUMP_PATH):
		_sprites["jump"] = load(P_JUMP_PATH) as Texture2D
	if ResourceLoader.exists(P_HURT_PATH):
		_sprites["hurt"] = load(P_HURT_PATH) as Texture2D
	# AI 厚涂帧优先（覆盖 Kenney）；缺哪张就 fall-back 到 stand。
	if ResourceLoader.exists(AI_IDLE_PATH):
		_sprite_root.position = AI_SPRITE_OFFSET
		_sprites["stand"] = load(AI_IDLE_PATH) as Texture2D
		if ResourceLoader.exists(AI_JUMP_PATH):
			_sprites["jump"] = load(AI_JUMP_PATH) as Texture2D
		if ResourceLoader.exists(AI_FALL_PATH):
			_sprites["fall"] = load(AI_FALL_PATH) as Texture2D
		if ResourceLoader.exists(AI_HURT_PATH):
			_sprites["hurt"] = load(AI_HURT_PATH) as Texture2D
		_slash_textures.clear()
		for p in AI_SLASH_PATHS:
			if ResourceLoader.exists(p):
				_slash_textures.append(load(p) as Texture2D)
		# 巨剑挂点移到 AI 骑士的手部高度。
		var sword := visual.get_node_or_null("Sword") as Node2D
		if sword != null:
			sword.position = AI_SWORD_ANCHOR
	# FILTER：厚涂的 192px 渲染尺寸在 mipmap 关闭时会闪烁；切到 LINEAR_MIPMAP。
	_sprite_root.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_sprite_root.texture = _sprites["stand"]
	_sprite_root.modulate = Color(1, 1, 1, 1)


func _update_kenney_sprite(delta: float) -> void:
	if _sprite_root == null:
		return
	var tex: Texture2D = _sprites.get("stand") as Texture2D
	var phase := melee.phase_name()
	var is_slashing := phase != "idle"
	var slash_idx := 0
	match phase:
		"windup": slash_idx = 0
		"active": slash_idx = 1
		"recovery": slash_idx = 2
	if health.current <= 0:
		tex = _sprites.get("hurt", tex) as Texture2D
	elif is_slashing and slash_idx < _slash_textures.size():
		tex = _slash_textures[slash_idx]
	elif controller.is_dashing() or not is_on_floor():
		var key := "fall" if velocity.y > 30.0 and not is_on_floor() else "jump"
		tex = _sprites.get(key, _sprites.get("jump", tex)) as Texture2D
	var sword := visual.get_node_or_null("Sword") as Node2D
	if sword:
		# AI slash poses already paint the blade; hide the polygon sword.
		sword.visible = _slash_textures.is_empty()
	# else: on floor, not slashing, not dashing — show idle (with walk-bob below).
	if tex != null and _sprite_root.texture != tex:
		_sprite_root.texture = tex
	# 行走 bob：地面移动时给精灵 Y 方向 sin 摆动，恢复到 stand 时直接归零。
	var moving := is_on_floor() and not is_slashing and absf(velocity.x) > 12.0
	if moving:
		_bob_t += delta
		var base_y := AI_SPRITE_OFFSET.y
		_sprite_root.position.y = base_y + sin(_bob_t * WALK_BOB_FREQ * TAU) * WALK_BOB_AMPLITUDE
		_moving_prev = true
	elif _moving_prev:
		_sprite_root.position.y = AI_SPRITE_OFFSET.y
		_moving_prev = false


## 检测 MeleeCombat 进入 ACTIVE 的上升沿，生成一次性挥砍弧光（纯视觉）。
func _poll_slash_arc(face: float) -> void:
	var active_now := melee.phase_name() == "active"
	if active_now and not _melee_active_prev:
		velocity.x += face * SLASH_LUNGE
		_spawn_afterimages(face)
		if SlashArc.sheet_available():
			var arc := SlashArc.new()
			arc.flip_h = face < 0.0
			arc.position = Vector2(24.0 * face, -22.0)
			add_child(arc)
	_melee_active_prev = active_now


func _spawn_afterimages(_face: float) -> void:
	if _sprite_root == null or _sprite_root.texture == null:
		return
	for i in 2:
		var ghost := Sprite2D.new()
		ghost.texture = _sprite_root.texture
		ghost.centered = true
		ghost.texture_filter = _sprite_root.texture_filter
		ghost.global_position = _sprite_root.global_position + Vector2(-8.0 * float(i + 1) * visual.scale.x, 0)
		ghost.scale = _sprite_root.scale * visual.scale
		ghost.modulate = Color(1.0, 0.75, 0.45, 0.42 - 0.12 * float(i))
		ghost.z_index = visual.z_index - 1
		get_parent().add_child(ghost)
		var tw := ghost.create_tween()
		tw.tween_property(ghost, "modulate:a", 0.0, AFTERIMAGE_LIFE)
		tw.tween_callback(ghost.queue_free)


## 受击红闪：target 为本玩家时把精灵短暂染红后 tween 回白。
func _on_game_hit(_attacker: Node, target: Node, _amount: int) -> void:
	if target != self or _sprite_root == null:
		return
	if _hit_flash_tween != null and _hit_flash_tween.is_valid():
		_hit_flash_tween.kill()
	_sprite_root.modulate = HIT_FLASH_COLOR
	_hit_flash_tween = create_tween()
	_hit_flash_tween.tween_property(_sprite_root, "modulate", Color.WHITE, HIT_FLASH_SECONDS)


func is_invincible() -> bool:
	return controller.is_invincible() or health.is_invincible()


func collect_core(core: RustCore) -> void:
	inventory.add_to_pouch(core)


func _poll_interact() -> void:
	var focus := sensor.get_focus()
	if focus:
		GameEvents.interact_prompt.emit(focus.get_prompt(self))
	else:
		GameEvents.interact_prompt.emit("")
	if focus and Input.is_action_just_pressed("interact"):
		focus.interact(self)


func _poll_sockets() -> void:
	if Input.is_action_just_pressed("socket_1"):
		inventory.insert_into_socket(0)
	elif Input.is_action_just_pressed("socket_2"):
		inventory.insert_into_socket(1)


func _poll_hookshot() -> void:
	if not Input.is_action_just_pressed("hookshot"):
		return
	if not inventory.has_ability(AbilityIds.HOOKSHOT_TETHER):
		GameEvents.announcement.emit("需要钩锁核（Hookshot Tether）— 击败喷吐者可得")
		return
	if hookshot.is_active():
		return
	if not hookshot.try_fire(self):
		GameEvents.announcement.emit("范围内没有可钩住的锚点")


func _on_health_changed(current: int, maximum: int) -> void:
	GameEvents.player_health_changed.emit(current, maximum)


func _on_toxin_overflow() -> void:
	health.take_damage(1, self)


func _on_died() -> void:
	set_physics_process(false)
	GameEvents.player_died.emit()
	GameEvents.announcement.emit("余烬熄灭…")
	await get_tree().create_timer(1.15).timeout
	var nest_path := SaveData.last_lit_nest()
	if nest_path != "" and get_tree().current_scene != null:
		var nest := get_tree().current_scene.get_node_or_null(nest_path)
		var spawn: Vector2 = nest.global_position if nest != null and is_instance_valid(nest) else global_position
		GameEvents.player_respawned.emit()
		# Rebuild the level with the player dropped back at the last lit Ember Nest.
		SaveData.respawn(get_tree().current_scene.scene_file_path, spawn)
	else:
		get_tree().reload_current_scene()
