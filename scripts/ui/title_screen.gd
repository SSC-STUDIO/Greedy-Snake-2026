class_name TitleScreen
extends Control
## Title: 1280x720 keyart, centered type, watermark bar, drifting embers.


const KEYART_PATH := "res://assets/kenney_clean/backgrounds/title_keyart.png"
const LEVEL_PATH := "res://scenes/levels/Level01_Static.tscn"
const EMBER_COUNT := 18

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
	DisplayServer.window_set_title("Rustgrave")
	_build()
	_spawn_embers()


func _build() -> void:
	var art := TextureRect.new()
	art.name = "Keyart"
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if ResourceLoader.exists(KEYART_PATH):
		art.texture = load(KEYART_PATH) as Texture2D
	add_child(art)

	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.18)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	# Full-width bottom gradient band: anchors the start/credits text and
	# swallows the keyart's baked bottom-right badge in one sweep.
	var band := TextureRect.new()
	band.name = "BottomBand"
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	grad.colors = PackedColorArray([
		Color(0.0, 0.0, 0.0, 0.0),
		Color(0.02, 0.01, 0.03, 0.52),
		Color(0.02, 0.01, 0.03, 0.85),
	])
	var grad_tex := GradientTexture2D.new()
	grad_tex.gradient = grad
	grad_tex.width = 8
	grad_tex.height = 128
	grad_tex.fill_from = Vector2(0.0, 0.0)
	grad_tex.fill_to = Vector2(0.0, 1.0)
	band.texture = grad_tex
	band.stretch_mode = TextureRect.STRETCH_SCALE
	band.anchor_left = 0.0
	band.anchor_right = 1.0
	band.anchor_top = 1.0
	band.anchor_bottom = 1.0
	band.offset_top = -136.0
	band.offset_bottom = 0.0
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(band)

	var title := Label.new()
	title.name = "Title"
	title.text = "RUSTGRAVE"
	title.anchor_left = 0.0
	title.anchor_right = 1.0
	title.offset_top = 56.0
	title.offset_bottom = 132.0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.98, 0.62, 0.35))
	title.add_theme_color_override("font_shadow_color", Color(0.05, 0.02, 0.0, 0.9))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	var subtitle := Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = "锈 墓 · 余 烬 骑 士"
	subtitle.anchor_left = 0.0
	subtitle.anchor_right = 1.0
	subtitle.offset_top = 128.0
	subtitle.offset_bottom = 160.0
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.78, 0.70, 0.62))
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(subtitle)

	_press_label = Label.new()
	_press_label.name = "PressStart"
	_press_label.text = "— 按任意键 点燃余烬 —"
	_press_label.anchor_left = 0.0
	_press_label.anchor_right = 1.0
	_press_label.anchor_top = 1.0
	_press_label.anchor_bottom = 1.0
	_press_label.offset_top = -92.0
	_press_label.offset_bottom = -56.0
	_press_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_press_label.add_theme_font_size_override("font_size", 18)
	_press_label.add_theme_color_override("font_color", Color(0.95, 0.78, 0.55))
	_press_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_press_label)

	_continue_label = Label.new()
	_continue_label.name = "ContinueHint"
	_continue_label.text = "有刻录的余烬之旅 — 按 1 继续"
	_continue_label.anchor_left = 0.0
	_continue_label.anchor_right = 1.0
	_continue_label.anchor_top = 1.0
	_continue_label.anchor_bottom = 1.0
	_continue_label.offset_top = -56.0
	_continue_label.offset_bottom = -32.0
	_continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_continue_label.add_theme_font_size_override("font_size", 14)
	_continue_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.45))
	_continue_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_continue_label.visible = SaveData.has_save()
	add_child(_continue_label)

	var credits := Label.new()
	credits.name = "Credits"
	credits.text = "美术 ansimuz · aamatniekss · Kronovi · CodeManu · Kenney — 音频 Kenney"
	credits.anchor_left = 0.0
	credits.anchor_top = 1.0
	credits.anchor_right = 0.0
	credits.anchor_bottom = 1.0
	credits.offset_left = 16.0
	credits.offset_top = -28.0
	credits.offset_right = 420.0
	credits.offset_bottom = -8.0
	credits.add_theme_font_size_override("font_size", 11)
	credits.add_theme_color_override("font_color", Color(0.8, 0.75, 0.7, 0.55))
	credits.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(credits)

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
		e.position = Vector2(randf_range(0.0, 1280.0), randf_range(0.0, 720.0))
		e.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(e)
		_embers.append(e)
		_ember_meta.append(Vector3(randf_range(14.0, 38.0), randf() * TAU, randf_range(6.0, 18.0)))


func _process(delta: float) -> void:
	_time += delta
	DisplayServer.window_set_title("Rustgrave")
	if _press_label != null:
		_press_label.modulate.a = 0.55 + 0.45 * sin(_time * 2.4)
	for i in _embers.size():
		var e := _embers[i]
		var m := _ember_meta[i]
		e.position.y -= m.x * delta
		e.position.x += sin(_time * 1.3 + m.y) * m.z * delta
		if e.position.y < -4.0:
			e.position.y = 724.0
			e.position.x = randf_range(0.0, 1280.0)


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
		SaveData.delete_save()
	Sfx.play(&"gate")
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, 0.7)
	tween.tween_callback(func() -> void:
		get_tree().change_scene_to_file(LEVEL_PATH)
	)
