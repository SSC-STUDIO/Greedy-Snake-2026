class_name HookshotTether
extends Node2D
## 钩锁（Hookshot Tether）：按 F 朝面朝方向斜上方寻找锚点，
## 命中后把玩家匀速拉向锚点，接近时自动脱钩并向上弹起。
## 纯移动能力 —— 不改伤害/判定数值。


@export var max_range: float = 260.0
@export var pull_speed: float = 430.0
@export var release_radius: float = 26.0
@export var cooldown: float = 0.45
@export var release_pop: float = -170.0
## 出索方向允许的偏差（与面朝向+略朝上的向量做点积阈值）。
const AIM_DOT_MIN := 0.25
const ROPE_ORIGIN := Vector2(0.0, -48.0)

var _anchor: Node2D = null
var _cooldown_left: float = 0.0
var _rope: Line2D


func _ready() -> void:
	_rope = Line2D.new()
	_rope.name = "Rope"
	_rope.width = 2.5
	_rope.default_color = Palette.TEAL
	_rope.visible = false
	_rope.z_index = 5
	add_child(_rope)
	GameEvents.hit.connect(_on_game_hit)


func is_active() -> bool:
	return _anchor != null and is_instance_valid(_anchor)


func _process(delta: float) -> void:
	_cooldown_left = maxf(0.0, _cooldown_left - delta)
	if not is_active():
		return
	# 绳索：从手部到锚点，中点略微下垂。
	var from := ROPE_ORIGIN
	var to := to_local(_anchor.global_position)
	var mid := (from + to) * 0.5 + Vector2(0.0, clampf(from.distance_to(to) * 0.05, 0.0, 9.0))
	_rope.points = PackedVector2Array([from, mid, to])


func try_fire(player: Player) -> bool:
	if is_active() or _cooldown_left > 0.0:
		return false
	if player.inventory.has_pair(AbilityIds.HEAT_FORGE, AbilityIds.HOOKSHOT_TETHER):
		if _try_melt_hook(player):
			return true
	var anchor := _pick_anchor(player)
	if anchor == null:
		return false
	_anchor = anchor
	_rope.visible = true
	Sfx.play(&"gate")
	Fx.hit_sparks(anchor.global_position)
	return true


func _try_melt_hook(player: Player) -> bool:
	var origin := player.global_position + ROPE_ORIGIN
	var reach := max_range * (1.2 if player.toxin.potency() >= 0.5 else 1.0)
	for node in get_tree().get_nodes_in_group("rusty_gate"):
		var gate := node as RustyGate
		if gate == null or not is_instance_valid(gate):
			continue
		if origin.distance_to(gate.global_position) > reach:
			continue
		gate.melt(player)
		Fx.hit_sparks(gate.global_position)
		return true
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is GearShieldEnemy and origin.distance_to((node as Node2D).global_position) <= reach:
			var guard := node as GearShieldEnemy
			if guard.has_method("_enter_stagger"):
				guard._enter_stagger()
				Fx.hit_sparks(guard.global_position)
				return true
	return false


## 每物理帧由 Player 在 controller 之后调用：直接接管速度。
func apply_tether_velocity(player: CharacterBody2D) -> void:
	if not is_active():
		_release()
		return
	var to_anchor := _anchor.global_position - player.global_position
	var dist := to_anchor.length()
	# 跳跃键提前脱钩 / 撞墙强制脱钩。
	if Input.is_action_just_pressed("jump") or player.is_on_wall():
		_pop_off(player, to_anchor)
		return
	if dist <= release_radius:
		_pop_off(player, to_anchor)
		return
	player.velocity = to_anchor / dist * pull_speed


func _pop_off(player: CharacterBody2D, to_anchor: Vector2) -> void:
	var dir_x := signf(to_anchor.x) if absf(to_anchor.x) > 4.0 else 0.0
	player.velocity.x = player.velocity.x * 0.5 + dir_x * 130.0
	player.velocity.y = release_pop
	Fx.dust_puff(player.global_position + Vector2(0.0, -40.0))
	Sfx.play(&"jump")
	if player is Player:
		var knight := player as Player
		if knight.inventory.has_pair(AbilityIds.HOOKSHOT_TETHER, AbilityIds.EMBER_STEP):
			knight.controller.grant_air_jump()
			player.velocity.y = knight.controller.jump_velocity * knight.controller.extra_jump_scale
	_release()


func _release() -> void:
	_anchor = null
	_rope.visible = false
	var cd := cooldown
	var host := get_parent()
	if host is Player and (host as Player).resonance.is_active():
		cd *= 0.5
	_cooldown_left = cd


func _pick_anchor(player: Player) -> Node2D:
	var origin := player.global_position + ROPE_ORIGIN
	var aim := Vector2(signf(player.visual.scale.x), -0.35).normalized()
	var best: Node2D = null
	var best_score := -1.0
	for node in get_tree().get_nodes_in_group("hook_anchor"):
		var anchor := node as Node2D
		if anchor == null:
			continue
		var to := anchor.global_position - origin
		var dist := to.length()
		var reach := max_range
		if player.toxin.potency() >= 0.5:
			reach *= 1.2
		if dist > reach or dist < 8.0:
			continue
		var dir := to / dist
		var score := dir.dot(aim)
		if score < AIM_DOT_MIN:
			continue
		if not _has_line_of_sight(origin, anchor.global_position):
			continue
		if score > best_score:
			best_score = score
			best = anchor
	return best


func _has_line_of_sight(from: Vector2, to: Vector2) -> bool:
	# 只查世界层（mask=1），玩家/敌人/锚点都不会挡道。
	var query := PhysicsRayQueryParameters2D.create(from, to, 1)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return hit.is_empty()


func _on_game_hit(_attacker: Node, target: Node, _amount: int) -> void:
	# 受击打断钩索（表现层接管，不影响伤害结算）。
	if target == owner and is_active():
		_release()
