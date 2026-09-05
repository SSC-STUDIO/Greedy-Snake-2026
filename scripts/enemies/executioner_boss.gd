class_name ExecutionerBoss
extends GearShieldEnemy
## 锻炉残室的刽子手。保留正面盾规则；半血后射弹加密并挥斧。

signal slain

var _enraged := false
var _slash_next := false
var _slash_cd := 0.0
var _intro_announced := false


func is_enraged() -> bool:
	return _enraged


func _enemy_ready() -> void:
	super._enemy_ready()
	health.max_hp = 13
	health.heal_full()
	health.changed.connect(_on_hp_changed)
	shoot_interval = 2.0
	aggro_range = 360.0
	if _anim != null:
		if CharFrames.available(EXEC_CHAR, "attack"):
			_anim.register("slash", CharFrames.anim(EXEC_CHAR, "attack"), 12.0, false, EXEC_POS)
		if CharFrames.available(EXEC_CHAR, "skill"):
			_anim.register("skill", CharFrames.anim(EXEC_CHAR, "skill"), 10.0, false, EXEC_POS)


func _on_hp_changed(current: int, maximum: int) -> void:
	GameEvents.boss_hp_changed.emit(current, maximum)
	if _enraged or maximum <= 0:
		return
	if current <= maximum / 2:
		_enraged = true
		shoot_interval = 1.15
		Juice.shake(4.0, 300)
		Juice.slow_mo(200, 0.2)
		Fx.hit_sparks(global_position)
		GameEvents.announcement.emit("炉渣在他的斧上重新沸腾")


func _tick_block(delta: float) -> void:
	if not _intro_announced:
		_intro_announced = true
		GameEvents.boss_appeared.emit("炉 约 刽 子 手 · 铸 渣 残 躯", health.current, health.max_hp)
	_slash_cd = maxf(0.0, _slash_cd - delta)
	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null and _slash_cd <= 0.0 \
			and global_position.distance_to(player.global_position) < 78.0:
		_begin_slash()
		return
	super._tick_block(delta)


func _begin_slash() -> void:
	_slash_next = true
	_state = State.CHARGE
	_timer = 0.52
	_set_blocking(true)
	_flicker_slash()
	if _anim != null and _anim.has_anim("slash"):
		_anim.play("slash", true)


func _update_anim() -> void:
	if _slash_next and _anim != null and _anim.has_anim("slash"):
		_anim.play("slash")
		return
	super._update_anim()


func _tick_charge(delta: float) -> void:
	if _dead:
		return
	if not _slash_next:
		super._tick_charge(delta)
		return
	velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
	_timer -= delta
	if _timer <= 0.0:
		_do_slash()
		_slash_next = false
		_slash_cd = 1.6 if _enraged else 2.1
		_state = State.BLOCK
		_shoot_timer = shoot_interval
		_refresh_indicator()


## 挥斧前摇：余烬脉冲，和射弹蓄力的毒橙闪区分开，0.52s 窗更可读。
func _flicker_slash() -> void:
	if _indicator == null:
		return
	_kill_flicker()
	_flicker_tween = create_tween()
	_flicker_tween.tween_property(_indicator, "modulate", Palette.EMBER, 0.16)
	_flicker_tween.tween_property(_indicator, "modulate", Color(1.45, 0.72, 0.38), 0.36)


func _do_slash() -> void:
	if _dead:
		return
	var box := Hitbox.new()
	box.damage = 2
	box.team = &"enemy"
	box.knockback = Vector2(float(_shield_facing) * 110.0, -28.0)
	box.monitoring = true
	box.collision_layer = 8
	box.collision_mask = 32
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(36, 28)
	shape.shape = rect
	box.add_child(shape)
	get_parent().add_child(box)
	box.global_position = global_position + Vector2(float(_shield_facing) * 22.0, -18.0)
	box.arm(Vector2(float(_shield_facing) * 110.0, -28.0))
	Sfx.play(&"swing")
	get_tree().create_timer(0.16).timeout.connect(func() -> void:
		if is_instance_valid(box):
			box.queue_free()
	)


func _fire() -> void:
	super._fire()
	if not _enraged:
		return
	if _anim != null and _anim.has_anim("skill"):
		_anim.play("skill", true)
	var player := get_tree().get_first_node_in_group("player") as Player
	var proj := PROJECTILE_SCENE.instantiate() as Projectile
	get_tree().current_scene.add_child(proj)
	var origin := global_position + Vector2(_shield_facing * 16.0, -38.0)
	var aim := Vector2(_shield_facing * 40.0, -18.0)
	if player:
		aim = player.global_position + Vector2(0, -28) - origin
	proj.setup(origin, aim, projectile_speed * 0.92, &"enemy", self)


func _on_died() -> void:
	slain.emit()
	_death_burst(CharFrames.anim(EXEC_CHAR, "death"), 14.0,
			_shield_facing == 1, EXEC_DEATH_BASELINE, "刽子手跪进炉灰里")
