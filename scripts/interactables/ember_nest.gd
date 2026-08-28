class_name EmberNest
extends Interactable
## Ember Nest: a weighted checkpoint. Interacting saves the game and sets this
## nest as the respawn point (the knight is fully restored here on death).
## Persistent: once lit, stays lit across reloads.

const SCENE_PATH := "res://scenes/levels/Level01_Static.tscn"

var _lit: bool = false
var _glow: ColorRect


func _ready() -> void:
	super._ready()
	add_to_group("persistent")
	prompt = "E 点燃余烬巢"
	ensure_rect(Vector2(18, 20), Palette.RUST_DARK)
	# Flames / ember core that brightens once lit.
	_glow = ColorRect.new()
	_glow.name = "Glow"
	_glow.size = Vector2(10, 14)
	_glow.position = Vector2(4, 3)
	_glow.color = Palette.EMBER
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_glow)
	_glow.modulate.a = 0.25
	_breathe()


func _breathe() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(_glow, "modulate:a", 0.25 if _lit else 0.15, 0.8)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_glow, "modulate:a", 0.9 if _lit else 0.4, 0.8)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func can_interact(_actor: Node) -> bool:
	return true


func get_prompt(_actor: Node) -> String:
	return "E 点燃余烬巢" if not _lit else "余烬巢已点燃"


func interact(actor: Node) -> void:
	if actor is Player:
		var p := actor as Player
		p.health.heal_full()
		p.toxin.purify(1.0)
		GameEvents.player_health_changed.emit(p.health.current, p.health.max_hp)
		_lit = true
		SaveData.register_lit_nest(String(get_path()))
		GameEvents.announcement.emit("余烬重新点燃 —— 进度已刻入铁锈")
		SaveData.save_game(SCENE_PATH, p)
		Sfx.play(&"insert")


## --- persistence ---------------------------------------------------------
func get_persistent_state() -> Dictionary:
	return {"lit": _lit}


func apply_persistent_state(state: Dictionary) -> void:
	_lit = bool(state.get("lit", false))
	if _glow:
		_glow.modulate.a = 0.9 if _lit else 0.25
	GameEvents.announcement.emit("余烬巢已点亮（存档恢复）")
