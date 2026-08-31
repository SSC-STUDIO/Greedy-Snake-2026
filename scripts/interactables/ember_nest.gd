class_name EmberNest
extends Interactable
## Ember Nest: a weighted checkpoint. Interacting saves the game and sets this
## nest as the respawn point (the knight is fully restored here on death).

const SCENE_PATH := "res://scenes/levels/Level01_Static.tscn"
const BASE_PATH := "res://assets/env/rubble_c.png"
const GLOW_PATH := "res://assets/env/fireball_1.png"

var _lit: bool = false
var _glow: CanvasItem


func _ready() -> void:
	super._ready()
	add_to_group("persistent")
	prompt = "E 点燃余烬巢"
	# rubble_c 原生 27x33，等比 2/3 → 18x22，脚底贴地不再横向压扁。
	ensure_sprite(BASE_PATH, Vector2(18, 22), Vector2(-2, -2), Palette.RUST_DARK)


func _ensure_glow() -> void:
	if _glow != null or not ResourceLoader.exists(GLOW_PATH):
		return
	var tex := load(GLOW_PATH) as Texture2D
	var spr := Sprite2D.new()
	spr.name = "Glow"
	spr.texture = tex
	spr.centered = true
	spr.position = Vector2(9, 2)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.scale = Vector2(0.28, 0.28)
	spr.modulate = Color(1.0, 0.75, 0.4, 0.85)
	add_child(spr)
	_glow = spr
	_breathe()


func _breathe() -> void:
	if _glow == null:
		return
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
		_ensure_glow()
		SaveData.register_lit_nest(String(get_path()))
		GameEvents.announcement.emit("余烬重新点燃 —— 进度已刻入铁锈")
		SaveData.save_game(SCENE_PATH, p)
		Sfx.play(&"insert")


func get_persistent_state() -> Dictionary:
	return {"lit": _lit}


func apply_persistent_state(state: Dictionary) -> void:
	_lit = bool(state.get("lit", false))
	if _lit:
		_ensure_glow()
