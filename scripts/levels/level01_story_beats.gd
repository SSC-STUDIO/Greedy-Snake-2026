class_name Level01StoryBeats
extends Node
## One-shot Level01 Director scripts. Listens to GameEvents + east-wing signals;
## flags live on SaveData so a reload does not replay the same caption.

var _host: Node
var _player: Player
var _boss: ExecutionerBoss
var _bound := false


func bind(host: Node, player: Player, boss: ExecutionerBoss) -> void:
	_host = host
	_player = player
	_boss = boss
	if _bound:
		return
	_bound = true
	GameEvents.toxin_changed.connect(_on_toxin_story)
	GameEvents.core_acquired.connect(_on_core_story)
	GameEvents.ability_unlocked.connect(_on_insert_story)
	GameEvents.parried.connect(_on_parry_story)


func set_boss(boss: ExecutionerBoss) -> void:
	_boss = boss


func _exit_tree() -> void:
	if not _bound:
		return
	_bound = false
	if GameEvents.toxin_changed.is_connected(_on_toxin_story):
		GameEvents.toxin_changed.disconnect(_on_toxin_story)
	if GameEvents.core_acquired.is_connected(_on_core_story):
		GameEvents.core_acquired.disconnect(_on_core_story)
	if GameEvents.ability_unlocked.is_connected(_on_insert_story):
		GameEvents.ability_unlocked.disconnect(_on_insert_story)
	if GameEvents.parried.is_connected(_on_parry_story):
		GameEvents.parried.disconnect(_on_parry_story)


func try_wake() -> void:
	if SaveData.entering_from_checkpoint or SaveData.has_pending_spawn() or SaveData.has_flag("wake"):
		if not Director.playing:
			GameEvents.announcement.emit("锈墓・壹 — 腐液回廊")
		return
	SaveData.mark_flag("wake")
	var nest: Node = null
	if _host != null:
		nest = _host.get_node_or_null("Props/EmberNest")
	Director.play([
		{"kind": "lock"},
		{"kind": "sfx", "id": "insert"},
		{"kind": "cam_focus", "target": nest, "duration": 0.2},
		{"kind": "wait", "seconds": 0.25},
		{"kind": "caption", "text": "炉灭之后，循环变成了锈。", "hold": 1.5},
		{"kind": "cam_focus", "target": _player, "duration": 0.55},
		{"kind": "wait", "seconds": 0.2},
		{"kind": "cam_release"},
		{"kind": "unlock"},
	])


func on_boss_gate(body: Node) -> void:
	if SaveData.has_flag("boss_intro") or SaveData.has_flag("boss_dead"):
		return
	if not body is Player or _boss == null or not is_instance_valid(_boss):
		return
	SaveData.mark_flag("boss_intro")
	Director.play([
		{"kind": "lock"},
		{"kind": "sfx", "id": "gate"},
		{"kind": "cam_focus", "target": _boss, "duration": 0.55},
		{"kind": "caption", "text": "炉约的刽子手还守着残芯。", "hold": 1.6},
		{"kind": "cam_release"},
		{"kind": "unlock"},
	])


func on_boss_slain() -> void:
	var heart: ForgeHeart = null
	if _host != null:
		heart = _host.get_node_or_null("Props/ForgeHeart") as ForgeHeart
	if heart:
		heart.unlock()
	if SaveData.has_flag("boss_dead"):
		return
	Level01EastWing.mark_executioner_slain()
	Director.play([
		{"kind": "lock"},
		{"kind": "sfx", "id": "insert"},
		{"kind": "cam_focus", "target": heart, "duration": 0.7},
		{"kind": "caption", "text": "残芯还在跳。你可以把剑送进去。", "hold": 1.7},
		{"kind": "cam_release"},
		{"kind": "unlock"},
	])


func _on_toxin_story(current: float, _maximum: float) -> void:
	if SaveData.has_flag("toxin") or current <= 0.0:
		return
	SaveData.mark_flag("toxin")
	var pool: Node = null
	if _host != null:
		pool = _host.get_node_or_null("Props/ToxinPool")
	Director.play([
		{"kind": "lock"},
		{"kind": "cam_focus", "target": pool, "duration": 0.4},
		{"kind": "caption", "text": "它吃肺，也吃记忆。也吃你的剑。", "hold": 1.6},
		{"kind": "cam_release"},
		{"kind": "unlock"},
	])


func _on_core_story(_core: Resource) -> void:
	if SaveData.has_flag("core"):
		return
	SaveData.mark_flag("core")
	Director.play([
		{"kind": "lock"},
		{"kind": "caption", "text": "前人的残响。嵌进剑里，它才肯说话。", "hold": 1.5},
		{"kind": "unlock"},
	])


func _on_insert_story(_ability_id: StringName) -> void:
	if SaveData.has_flag("insert"):
		return
	SaveData.mark_flag("insert")
	Director.play([
		{"kind": "lock"},
		{"kind": "caption", "text": "剑身热了一下。插座咬住了这枚核。", "hold": 1.4},
		{"kind": "unlock"},
	])


func _on_parry_story(_bolt: Node, _by: Node) -> void:
	if SaveData.has_flag("parry"):
		return
	SaveData.mark_flag("parry")
	Director.play([
		{"kind": "lock"},
		{"kind": "caption", "text": "打回去的不只是弹。锈也被你炼过了。", "hold": 1.6},
		{"kind": "unlock"},
	])
