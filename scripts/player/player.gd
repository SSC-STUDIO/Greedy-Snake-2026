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
@onready var resonance: Resonance = $Resonance

## Director sets this during a cutscene. Input is ignored; gravity still applies.
var cutscene_locked: bool = false

const P_STAND_PATH := "res://assets/kenney_clean/player/p1_stand.png"
const P_JUMP_PATH := "res://assets/kenney_clean/player/p1_jump.png"
const P_HURT_PATH := "res://assets/kenney_clean/player/p1_hurt.png"
const KENNEY_SPRITE_OFFSET := Vector2(0.0, -13.0)
## 行走的代码 bob（仅 Kenney 单帧回退路径）：地面移动时 ~2px 的 Y 向 sin 摆动。
const WALK_BOB_AMPLITUDE := 1.5
const WALK_BOB_FREQ := 7.0

## Fantasy Knight 像素帧动画（assets/characters/player_fantasy_knight/，朝右）。
## 画布统一 120x80、脚底贴画布底边；身体中心在画布 x≈54.5 → 补偿 +6px。
## centered=true 时 (6, -40) 让脚底落在节点原点、身体对准碰撞体中线。
const KNIGHT_CHAR := "player_fantasy_knight"
const KNIGHT_POS := Vector2(6.0, -40.0)
## 三段连击对应的动作名（fps 在 swing_started 时按挥砍总时长动态同步）。
const KNIGHT_ATTACK_ANIMS := ["attack1", "attack2", "attack_combo"]
## 受击帧短暂覆盖运动动画的时长。
const HURT_POSE_SECONDS := 0.18
## 判定帧前冲（世界单位/秒），克制到不破坏沉重移动手感。
const SLASH_LUNGE := 78.0
const AFTERIMAGE_LIFE := 0.16
## 受击红闪（纯表现）：染红后 tween 回白，~120ms。
const HIT_FLASH_COLOR := Color(1.9, 0.35, 0.35)
const HIT_FLASH_SECONDS := 0.12

var _sprites: Dictionary = {}
var _sprite_root: Sprite2D
var _anim: FrameAnimSprite
var _attack_anim: String = "attack1"
var _hurt_timer: float = 0.0
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
	GameEvents.swing_started.connect(_on_swing_started)
	if not _setup_knight_anim():
		_setup_kenney_sprite()
	# 主题标识：余烬骑士周身漂浮的橙色余烬（Fx 内部自带 headless 守卫）。
	Fx.attach_ember(self)


func _physics_process(delta: float) -> void:
	if health.is_invincible() and health.current <= 0:
		return
	controller.extra_jumps_unlocked = inventory.has_ability(AbilityIds.EMBER_STEP)
	if cutscene_locked:
		_tick_cutscene_idle(delta)
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
	_update_visual(delta)
	_poll_slash_arc(face)
	_poll_interact()
	_poll_sockets()
	_poll_hookshot()


func _on_dash_performed() -> void:
	Fx.dust_puff(global_position)


## Fantasy Knight 逐帧动画（主路径）。素材缺失（如未导入）返回 false，
## 交给 Kenney 单帧回退；两者都缺时保留场景内 ColorRect 占位。
func _setup_knight_anim() -> bool:
	if not CharFrames.available(KNIGHT_CHAR):
		return false
	_anim = FrameAnimSprite.new()
	_anim.name = "KnightSprite"
	# 动作表：帧目录 / fps / 是否循环（画布统一 → 基线相同）。
	var table := [
		["idle", 10.0, true], ["run", 12.0, true],
		["jump", 10.0, false], ["fall", 10.0, true],
		["dash", 14.0, true], ["hurt", 10.0, false],
		["death", 10.0, false], ["turn", 14.0, false],
		["attack1", 14.0, false], ["attack2", 14.0, false],
		["attack_combo", 14.0, false],
	]
	for row in table:
		_anim.register(row[0], CharFrames.anim(KNIGHT_CHAR, row[0]), row[1], row[2], KNIGHT_POS)
	_anim.play("idle")
	visual.add_child(_anim)
	_sprite_root = _anim  # 残像/白闪等表现直接复用同一 Sprite。
	# 骑士帧自带剑与盔甲：隐藏所有占位色块和程序化多边形剑。
	for c in visual.get_children():
		if c == _anim:
			continue
		if c is ColorRect or c is Polygon2D:
			c.visible = false
	return true


## 按挥砍段位同步攻击动画：一次挥砍（前摇+判定+后摇）≈ 播完整段帧。
func _on_swing_started(combo_index: int) -> void:
	if _anim == null:
		return
	var idx := clampi(combo_index, 0, KNIGHT_ATTACK_ANIMS.size() - 1)
	_attack_anim = KNIGHT_ATTACK_ANIMS[idx]
	var duration: float = MeleeCombat.COMBO_WINDUP[idx] \
			+ MeleeCombat.COMBO_ACTIVE[idx] + MeleeCombat.COMBO_RECOVERY[idx]
	var frames := CharFrames.anim(KNIGHT_CHAR, _attack_anim)
	if not frames.is_empty():
		_anim.set_fps(_attack_anim, float(frames.size()) / maxf(duration, 0.05))
	_anim.play(_attack_anim, true)


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
	_sprite_root.texture = _sprites["stand"]
	_sprite_root.modulate = Color(1, 1, 1, 1)


func _update_visual(delta: float) -> void:
	if _hurt_timer > 0.0:
		_hurt_timer = maxf(0.0, _hurt_timer - delta)
	if _anim != null:
		_update_knight_anim()
		return
	_update_kenney_sprite(delta)


## 状态优先级：死亡 > 挥砍 > dash > 受击帧 > 空中(升/降) > 跑动 > 待机。
func _update_knight_anim() -> void:
	if health.current <= 0:
		_anim.play("death")
		return
	if melee.is_busy():
		_anim.play(_attack_anim)
		return
	if controller.is_dashing():
		_anim.play("dash")
		return
	if _hurt_timer > 0.0:
		_anim.play("hurt")
		return
	if not is_on_floor():
		_anim.play("jump" if velocity.y < 0.0 else "fall")
		return
	_anim.play("run" if absf(velocity.x) > 12.0 else "idle")


func _update_kenney_sprite(delta: float) -> void:
	if _sprite_root == null:
		return
	var tex: Texture2D = _sprites.get("stand") as Texture2D
	var is_slashing := melee.phase_name() != "idle"
	if health.current <= 0:
		tex = _sprites.get("hurt", tex) as Texture2D
	elif controller.is_dashing() or not is_on_floor():
		tex = _sprites.get("jump", tex) as Texture2D
	if tex != null and _sprite_root.texture != tex:
		_sprite_root.texture = tex
	# 行走 bob：地面移动时给精灵 Y 方向 sin 摆动，恢复到 stand 时直接归零。
	var moving := is_on_floor() and not is_slashing and absf(velocity.x) > 12.0
	if moving:
		_bob_t += delta
		var base_y := KENNEY_SPRITE_OFFSET.y
		_sprite_root.position.y = base_y + sin(_bob_t * WALK_BOB_FREQ * TAU) * WALK_BOB_AMPLITUDE
		_moving_prev = true
	elif _moving_prev:
		_sprite_root.position.y = KENNEY_SPRITE_OFFSET.y
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
			if _anim != null:
				# 骑士帧自带剑痕：弧光降级为辅助拖影（缩小压暗），避免双重剑光；
				# 弹反炸亮由 SlashArc._on_parried 覆盖 modulate/scale，反馈保留。
				arc.scale = Vector2(0.6, 0.6)
				arc.modulate = Color(1.0, 0.92, 0.78, 0.5)
				arc.position = Vector2(20.0 * face, -18.0)
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
	# 存活且不在挥砍锁定时，短暂切到受击帧。
	if health.current > 0 and not melee.is_busy():
		_hurt_timer = HURT_POSE_SECONDS
	if _hit_flash_tween != null and _hit_flash_tween.is_valid():
		_hit_flash_tween.kill()
	_sprite_root.modulate = HIT_FLASH_COLOR
	_hit_flash_tween = create_tween()
	_hit_flash_tween.tween_property(_sprite_root, "modulate", Color.WHITE, HIT_FLASH_SECONDS)


func is_invincible() -> bool:
	return controller.is_invincible() or health.is_invincible()


func collect_core(core: RustCore) -> void:
	inventory.add_to_pouch(core)


func _tick_cutscene_idle(delta: float) -> void:
	if not is_on_floor():
		velocity.y += float(ProjectSettings.get_setting("physics/2d/default_gravity")) * delta
	velocity.x = move_toward(velocity.x, 0.0, 420.0 * delta)
	move_and_slide()
	visual.scale.x = float(controller.facing)
	_update_visual(delta)


func on_melee_active(combo_index: int) -> void:
	var pot := toxin.potency()
	if pot >= 0.85 and inventory.has_ability(AbilityIds.HEAT_FORGE):
		_spawn_fire_trail()
	# 双槽冲击波只在共鸣窗口点亮，避免嵌核后每段三连都白嫖。
	if combo_index >= 2 and resonance.is_active() \
			and inventory.has_pair(AbilityIds.HEAT_FORGE, AbilityIds.EMBER_STEP):
		_spawn_blast()


func _spawn_fire_trail() -> void:
	var face := float(controller.facing)
	var origin := global_position + Vector2(face * 28.0, -4.0)
	Fx.dust_puff(global_position + Vector2(face * 18.0, -2.0), face)
	var box := Hitbox.new()
	box.damage = 1
	box.team = &"player"
	box.monitoring = true
	box.collision_layer = 8
	box.collision_mask = 32
	var box_shape := CollisionShape2D.new()
	var box_rect := RectangleShape2D.new()
	box_rect.size = Vector2(42, 10)
	box_shape.shape = box_rect
	box.add_child(box_shape)
	var host: Node = get_tree().current_scene
	if host == null:
		host = get_parent()
	host.add_child(box)
	box.global_position = origin
	box.monitoring = true
	get_tree().create_timer(1.2).timeout.connect(func() -> void:
		if is_instance_valid(box):
			box.queue_free()
	)


func _spawn_blast() -> void:
	var face := float(controller.facing)
	var origin := global_position + Vector2(face * 22.0, -8.0)
	Fx.dust_puff(origin, face)
	Fx.hit_sparks(origin)
	var box := Hitbox.new()
	box.damage = 1
	box.team = &"player"
	box.knockback = Vector2(face * 80.0, -30.0)
	box.monitoring = true
	box.collision_layer = 8
	box.collision_mask = 32
	var box_shape := CollisionShape2D.new()
	var box_rect := RectangleShape2D.new()
	box_rect.size = Vector2(48, 20)
	box_shape.shape = box_rect
	box.add_child(box_shape)
	get_parent().add_child(box)
	box.global_position = origin
	box.monitoring = true
	for node in get_tree().get_nodes_in_group("pressure_plate"):
		if node is PressurePlate and (node as Node2D).global_position.distance_to(origin) < 56.0:
			(node as PressurePlate).slam()
	get_tree().create_timer(0.18).timeout.connect(func() -> void:
		if is_instance_valid(box):
			box.queue_free()
	)


func _poll_interact() -> void:
	if cutscene_locked:
		return
	var focus := sensor.get_focus()
	if focus:
		GameEvents.interact_prompt.emit(focus.get_prompt(self))
	else:
		GameEvents.interact_prompt.emit("")
	if focus and Input.is_action_just_pressed("interact"):
		focus.interact(self)


func _poll_sockets() -> void:
	if cutscene_locked:
		return
	if Input.is_action_just_pressed("socket_1"):
		inventory.insert_into_socket(0)
	elif Input.is_action_just_pressed("socket_2"):
		inventory.insert_into_socket(1)


func _poll_hookshot() -> void:
	if cutscene_locked:
		return
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
	# 过场锁死时不能走开：满溢伤害会把人钉死在毒池/台词里。
	if cutscene_locked:
		return
	health.take_damage(1, self)


func _on_died() -> void:
	if Director.playing:
		Director.abort()
	if _anim != null:
		_anim.play("death")  # 物理停摆后由 _process 继续播完倒地
	set_physics_process(false)
	GameEvents.player_died.emit()
	GameEvents.announcement.emit("余烬熄灭…")
	var wait := Timer.new()
	wait.one_shot = true
	wait.wait_time = 1.15
	add_child(wait)
	wait.start()
	await wait.timeout
	if not is_instance_valid(self) or get_tree() == null or get_tree().current_scene == null:
		return
	var nest := _resolve_lit_nest()
	if nest != null:
		GameEvents.player_respawned.emit()
		SaveData.respawn(get_tree().current_scene.scene_file_path, nest.global_position)
	else:
		Director.fade_to(get_tree().current_scene.scene_file_path)


## 存档里的巢路径是绝对 NodePath；换场景根名或测试宿主时可能对不上，再试叶子名。
func _resolve_lit_nest() -> Node2D:
	var nest_path := SaveData.last_lit_nest()
	if nest_path == "" or get_tree() == null:
		return null
	var scene := get_tree().current_scene
	if scene == null:
		return null
	var nest := scene.get_node_or_null(nest_path)
	if nest == null:
		nest = get_tree().root.get_node_or_null(nest_path)
	if nest == null:
		var leaf := nest_path.get_file()
		if leaf != "":
			nest = scene.find_child(leaf, true, false)
	if nest is Node2D and is_instance_valid(nest):
		return nest as Node2D
	return null
