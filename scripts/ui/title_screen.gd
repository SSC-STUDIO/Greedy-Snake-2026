class_name TitleScreen
extends Control
## 标题画面：keyart + 标题 + 漂浮余烬 + 按任意键开始（正式游戏感的入口）。


const KEYART_PATH := "res://assets/kenney_clean/backgrounds/title_keyart.png"
const LEVEL_PATH := "res://scenes/levels/Level01_Static.tscn"
const EMBER_COUNT := 14

var _started := false
var _time := 0.0
var _press_label: Label
var _continue_label: Label
var _fade: ColorRect
var _embers: Array[ColorRect] = []
var _ember_meta: Array[Vector3] = []  # (speed, sway_phase, sway_amp)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	_spawn_embers()


func _build() -> void:
	# 背景 keyart（1280x720 → 640x360 正好 2:1 整数缩放）。
	var art := TextureRect.new()
	art.name = "Keyart"
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if ResourceLoader.exists(KEYART_PATH):
		art.texture = load(KEYART_PATH) as Texture2D
	else:
		art.color = Color(0.10, 0.07, 0.06, 1.0)
	add_child(art)

	# 整体压暗，让标题更可读。
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.22)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	# 主标题。
	var title := Label.new()
	title.name = "Title"
	title.text = "RUSTGRAVE"
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.position = Vector2(0, 42)
	title.custom_minimum_size = Vector2(640, 0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 58)
	title.add_theme_color_override("font_color", Color(0.98, 0.62, 0.35))
	title.add_theme_color_override("font_shadow_color", Color(0.05, 0.02, 0.0, 0.9))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	# 副标题。
	var subtitle := Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = "锈 墓 · 余 烬 骑 士"
	subtitle.set_anchors_preset(Control.PRESET_CENTER_TOP)
	subtitle.position = Vector2(0, 112)
	subtitle.custom_minimum_size = Vector2(640, 0)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(0.78, 0.70, 0.62))
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(subtitle)

	# 按键提示（脉冲）。
	_press_label = Label.new()
	_press_label.name = "PressStart"
	_press_label.text = "— 按任意键 点燃余烬 —"
	_press_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_press_label.position = Vector2(0, -64)
	_press_label.custom_minimum_size = Vector2(640, 0)
	_press_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_press_label.add_theme_font_size_override("font_size", 14)
	_press_label.add_theme_color_override("font_color", Color(0.95, 0.78, 0.55))
	_press_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_press_label)

	# 继续游戏提示（仅当存在存档）。
	_continue_label = Label.new()
	_continue_label.name = "ContinueHint"
	_continue_label.text = "有刻录的余烬之旅 — 按 1 继续"
	_continue_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_continue_label.position = Vector2(0, -40)
	_continue_label.custom_minimum_size = Vector2(640, 0)
	_continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_continue_label.add_theme_font_size_override("font_size", 12)
	_continue_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.45))
	_continue_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_continue_label.visible = SaveData.has_save()
	add_child(_continue_label)

	# 底部素材来源致谢。
	var credits := Label.new()
	credits.name = "Credits"
	credits.text = "美术：Kenney / ansimuz / CodeManu / tbbk (CC0) · AI 生成角色 · 音频：Kenney (CC0)"
	credits.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	credits.position = Vector2(8, -18)
	credits.add_theme_font_size_override("font_size", 9)
	credits.add_theme_color_override("font_color", Color(0.8, 0.75, 0.7, 0.55))
	credits.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(credits)

	# 转场用的黑幕。
	_fade = ColorRect.new()
	_fade.name = "Fade"
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)


func _spawn_embers() -> void:
	for i in EMBER_COUNT:
		var e := ColorRect.new()
		var s := 2.0 if i % 3 != 0 else 3.0
		e.size = Vector2(s, s)
		e.color = Palette.EMBER.lerp(Color(1.0, 0.9, 0.7), randf() * 0.5)
		e.color.a = randf_range(0.35, 0.85)
		e.position = Vector2(randf_range(0.0, 640.0), randf_range(0.0, 360.0))
		e.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(e)
		_embers.append(e)
		_ember_meta.append(Vector3(randf_range(9.0, 26.0), randf() * TAU, randf_range(4.0, 12.0)))


func _process(delta: float) -> void:
	_time += delta
	if _press_label != null:
		_press_label.modulate.a = 0.55 + 0.45 * sin(_time * 2.4)
	for i in _embers.size():
		var e := _embers[i]
		var m := _ember_meta[i]
		e.position.y -= m.x * delta
		e.position.x += sin(_time * 1.3 + m.y) * m.z * delta
		if e.position.y < -4.0:
			e.position.y = 364.0
			e.position.x = randf_range(0.0, 640.0)


func _unhandled_input(event: InputEvent) -> void:
	if _started:
		return
	if event is InputEventJoypadButton and event.pressed:
		_start(SaveData.has_save())
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1 and SaveData.has_save():
			_start(true)
		elif event.keycode not in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]:
			_start(false)
		return
	if event is InputEventMouseButton and event.pressed:
		_start(false)


func _start(continue_game: bool) -> void:
	_started = true
	if continue_game:
		SaveData.load_game()
	else:
		# A fresh run: wipe any previous progress.
		SaveData.delete_save()
	Sfx.play(&"gate")
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, 0.7)
	tween.tween_callback(func() -> void:
		get_tree().change_scene_to_file(LEVEL_PATH)
	)
