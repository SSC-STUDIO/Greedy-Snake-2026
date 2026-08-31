class_name EmberNest
extends Interactable
## Ember Nest: a weighted checkpoint. Interacting saves the game and sets this
## nest as the respawn point (the knight is fully restored here on death).

const SCENE_PATH := "res://scenes/levels/Level01_Static.tscn"
const BASE_PATH := "res://assets/env/rubble_c.png"
const FLAME_PATH := "res://assets/fx/shrine_flame.png"
const SPARK_PATH := "res://assets/ui/ember_motes.png"
const FLAME_FRAMES := 8
const SPARK_FRAMES := 8
const LIT_FPS := 12.0
const LIT_MOD := Color(1.0, 0.92, 0.62, 1.0)
const LIGHT_TEX := 64.0
const LIGHT_COLOR := Color(1.0, 0.70, 0.36)

var _lit: bool = false
var _flame: Sprite2D
var _sparks: Node2D
var _light: PointLight2D
var _beam: Sprite2D
var _frame_t := 0.0
var _spark_t := 0.35
var _headless := false
static var _light_tex: Texture2D


func _ready() -> void:
	super._ready()
	add_to_group("persistent")
	prompt = "E 点燃余烬巢"
	# rubble_c 原生 27x33，等比 2/3 → 18x22，脚底贴地不再横向压扁。
	ensure_sprite(BASE_PATH, Vector2(18, 22), Vector2(-2, -2), Palette.RUST_DARK)
	_headless = DisplayServer.get_name() == "headless"
	_ensure_flame()
	_ensure_light()
	_ensure_beam()
	_apply_flame_state()
	if not WorldClock.phase_changed.is_connected(_on_atmosphere):
		WorldClock.phase_changed.connect(_on_atmosphere)


func _ensure_flame() -> void:
	if _flame != null or not ResourceLoader.exists(FLAME_PATH):
		return
	var tex := load(FLAME_PATH) as Texture2D
	if tex == null:
		return
	var spr := Sprite2D.new()
	spr.name = "Flame"
	spr.texture = tex
	spr.hframes = FLAME_FRAMES
	spr.vframes = 1
	spr.centered = true
	# 18x22 石碑顶心约 (7, 0)；16x24 焰（8x12 设计格 2x）底坐碑帽，不盖碑身。
	spr.position = Vector2(7, -8)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.z_index = 1
	add_child(spr)
	_flame = spr
	var sparks := Node2D.new()
	sparks.name = "Sparks"
	sparks.position = spr.position
	sparks.z_index = 2
	add_child(sparks)
	_sparks = sparks


func _exit_tree() -> void:
	if WorldClock.phase_changed.is_connected(_on_atmosphere):
		WorldClock.phase_changed.disconnect(_on_atmosphere)


func _on_atmosphere(_phase: int) -> void:
	_sync_light(999.0)


func _process(delta: float) -> void:
	if _lit:
		_sync_light(delta)
		_lean_flame()
	if _flame == null or not _lit:
		return
	_frame_t += delta
	var step := 1.0 / LIT_FPS
	while _frame_t >= step:
		_frame_t -= step
		_flame.frame = (_flame.frame + 1) % FLAME_FRAMES
	if _headless or _sparks == null:
		return
	_spark_t += delta
	if _spark_t >= 0.40:
		_spark_t = 0.0
		_spawn_spark()


func _spawn_spark() -> void:
	if not _lit or not ResourceLoader.exists(SPARK_PATH):
		return
	if _sparks.get_child_count() >= 3:
		return
	var sheet := load(SPARK_PATH) as Texture2D
	if sheet == null:
		return
	_sparks.add_child(NestSpark.new(sheet))


func _ensure_light() -> void:
	if _light != null:
		return
	var light := PointLight2D.new()
	light.name = "NestLight"
	light.position = Vector2(7, -8)
	light.color = LIGHT_COLOR
	light.energy = 0.0
	light.enabled = false
	light.shadow_enabled = true
	light.shadow_filter = Light2D.SHADOW_FILTER_NONE
	light.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	light.texture = _nest_light_texture()
	light.texture_scale = (WorldClock.nest_light_radius() * 2.0) / LIGHT_TEX
	add_child(light)
	_light = light


func _nest_light_texture() -> Texture2D:
	if _light_tex != null:
		return _light_tex
	var size := int(LIGHT_TEX)
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size * 0.5, size * 0.5)
	var radius := size * 0.5
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(center) / radius
			var a := clampf(1.0 - d, 0.0, 1.0)
			a = a * a
			img.set_pixel(x, y, Color(1.0, 0.78, 0.42, a))
	_light_tex = ImageTexture.create_from_image(img)
	return _light_tex


func _sync_light(delta: float) -> void:
	if _light == null:
		return
	if not _lit:
		_light.enabled = false
		_light.energy = 0.0
		return
	_light.enabled = true
	var target_e := WorldClock.nest_light_energy()
	var target_s := (WorldClock.nest_light_radius() * 2.0) / LIGHT_TEX
	var k := 1.0 if delta > 10.0 else (1.0 - exp(-8.0 * delta))
	_light.energy = lerpf(_light.energy, target_e, k)
	_light.texture_scale = lerpf(_light.texture_scale, target_s, k)


func _ensure_beam() -> void:
	if _beam != null:
		return
	var beam := Sprite2D.new()
	beam.name = "WarmShaft"
	beam.centered = true
	beam.position = Vector2(7, -48)
	beam.texture = _shaft_tex()
	beam.modulate = Color(1.0, 0.72, 0.38, 0.0)
	beam.visible = false
	beam.z_index = 0
	add_child(beam)
	_beam = beam


func _shaft_tex() -> Texture2D:
	var img := Image.create(10, 72, false, Image.FORMAT_RGBA8)
	for y in 72:
		for x in 10:
			var cx := absf(float(x) - 4.5) / 5.0
			var along := 1.0 - float(y) / 72.0
			var a := clampf((1.0 - cx) * (1.0 - cx) * along * 0.7, 0.0, 0.7)
			img.set_pixel(x, y, Color(1.0, 0.72, 0.36, a))
	return ImageTexture.create_from_image(img)


func _lean_flame() -> void:
	var lean := WorldClock.sway_radians() * 0.55 if _lit else 0.0
	if _flame != null:
		_flame.rotation = lean
	if _beam != null:
		_beam.rotation = lean * 0.35
		_beam.visible = _lit
		_beam.modulate.a = 0.28 if _lit else 0.0


func _apply_flame_state() -> void:
	if _flame != null:
		_flame.visible = _lit
		_flame.modulate = LIT_MOD
		if not _lit:
			_flame.rotation = 0.0
	if _sparks != null:
		_sparks.visible = _lit
		if not _lit:
			for child in _sparks.get_children():
				child.queue_free()
	_sync_light(999.0)
	_lean_flame()


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
		_apply_flame_state()
		SaveData.register_lit_nest(String(get_path()))
		GameEvents.announcement.emit("余烬重新点燃 —— 进度已刻入铁锈")
		SaveData.save_game(SCENE_PATH, p)
		Sfx.play(&"insert")


func get_persistent_state() -> Dictionary:
	return {"lit": _lit}


func apply_persistent_state(state: Dictionary) -> void:
	_lit = bool(state.get("lit", false))
	_apply_flame_state()


## 1x 余烬残片，从焰尖上飘；坐标取整以免 NEAREST 发糊。
class NestSpark extends Sprite2D:
	var _age := 0.0
	var _life := 0.7
	var _rise := 12.0
	var _phase := 0.0
	var _x0 := 0.0

	func _init(sheet: Texture2D) -> void:
		texture = sheet
		hframes = EmberNest.SPARK_FRAMES
		vframes = 1
		centered = true
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		scale = Vector2.ONE
		frame = randi_range(0, EmberNest.SPARK_FRAMES - 1)
		_x0 = float(randi_range(-2, 2))
		position = Vector2(_x0, float(randi_range(-8, -4)))
		_rise = randf_range(11.0, 18.0)
		_life = randf_range(0.40, 0.80)
		_phase = randf() * TAU
		modulate = Color(1.0, 0.78, 0.42, 0.80)

	func _process(delta: float) -> void:
		_age += delta
		if _age >= _life:
			queue_free()
			return
		var sway := sin(_age * 7.0 + _phase) * 1.4
		position = Vector2(roundf(_x0 + sway), roundf(position.y - _rise * delta))
		frame = int(_age / 0.10) % EmberNest.SPARK_FRAMES
		var k := _age / _life
		modulate.a = minf(k * 8.0, 1.0) * (1.0 - k)
