extends CanvasLayer
## Pixel-style debug HUD: hearts, toxin, sockets, prompt, announcements.

var _hp_bar: HBoxContainer
var _toxin_fill: ColorRect
var _toxin_label: Label
var _socket_label: Label
var _pouch_label: Label
var _prompt: Label
var _announce: Label
var _announce_time: float = 0.0
var _toxin_ratio: float = 0.0
var _low_hp: bool = false
var _vignette: Control
var _vignette_tween: Tween
var _time: float = 0.0
var _breath_time: float = 0.0


func _ready() -> void:
	layer = 10
	_build()
	GameEvents.player_health_changed.connect(_on_hp)
	GameEvents.toxin_changed.connect(_on_toxin)
	GameEvents.interact_prompt.connect(_on_prompt)
	GameEvents.announcement.connect(_on_announce)
	GameEvents.core_inserted.connect(func(_c, _i): _refresh_cores())
	GameEvents.core_acquired.connect(func(_c): _refresh_cores())
	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		_on_hp(player.health.current, player.health.max_hp)
		_on_toxin(player.toxin.toxin, player.toxin.max_toxin)
		_refresh_cores()


func _process(delta: float) -> void:
	_time += delta
	if _announce_time > 0.0:
		_announce_time -= delta
		if _announce_time <= 0.0:
			_announce.text = ""
	if _toxin_ratio >= TOXIN_ALARM_RATIO:
		var pulse := lerpf(TOXIN_PULSE_MIN, TOXIN_PULSE_MAX, 0.5 + 0.5 * sin(TAU * _time / TOXIN_PULSE_PERIOD))
		_toxin_fill.modulate = Color(pulse, pulse, pulse)
		_toxin_label.modulate = Color(pulse, pulse, pulse)
	if _low_hp and not _vignette_tween_active():
		_breath_time += delta
		_vignette.modulate.a = lerpf(VIGNETTE_BREATH_MIN, VIGNETTE_BREATH_MAX, 0.5 + 0.5 * sin(TAU * _breath_time / VIGNETTE_BREATH_PERIOD))
	_refresh_cores()


const HEART_FULL_PATH := "res://assets/kenney_clean/hud/heartFull.png"
const HEART_EMPTY_PATH := "res://assets/kenney_clean/hud/heartEmpty.png"
const HEART_HALF_PATH := "res://assets/kenney_clean/hud/heartHalf.png"
var _heart_full: Texture2D
var _heart_empty: Texture2D
var _heart_half: Texture2D
var _use_sprite_hearts: bool = false

# Danger feedback tuning: toxin alarm pulse + low-HP blood vignette.
const TOXIN_ALARM_RATIO := 0.8
const TOXIN_PULSE_PERIOD := 0.5
const TOXIN_PULSE_MIN := 1.0
const TOXIN_PULSE_MAX := 1.6
const VIGNETTE_EDGE := 24.0
const VIGNETTE_RED := Color(0.6, 0.05, 0.05)
const VIGNETTE_FADE_IN := 0.4
const VIGNETTE_FADE_OUT := 0.6
const VIGNETTE_ALPHA := 0.35
const VIGNETTE_BREATH_MIN := 0.25
const VIGNETTE_BREATH_MAX := 0.45
const VIGNETTE_BREATH_PERIOD := 3.0

func _build() -> void:
	_heart_full = _load_tex(HEART_FULL_PATH)
	_heart_empty = _load_tex(HEART_EMPTY_PATH)
	_heart_half = _load_tex(HEART_HALF_PATH)
	_use_sprite_hearts = _heart_full != null and _heart_empty != null

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_hp_bar = HBoxContainer.new()
	_hp_bar.position = Vector2(8, 8)
	_hp_bar.add_theme_constant_override("separation", 2)
	root.add_child(_hp_bar)
	for i in 5:
		if _use_sprite_hearts:
			var tr := TextureRect.new()
			tr.texture = _heart_full
			tr.expand_mode = TextureRect.EXPAND_KEEP_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.custom_minimum_size = Vector2(14, 12)
			# Tiny Kenney hearts are bright red; tint slightly toward rust palette.
			tr.modulate = Color(1, 1, 1, 1)
			tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			_hp_bar.add_child(tr)
		else:
			var pip := ColorRect.new()
			pip.custom_minimum_size = Vector2(10, 8)
			pip.color = Palette.RUST_LIGHT
			_hp_bar.add_child(pip)

	var toxin_back := ColorRect.new()
	toxin_back.position = Vector2(8, 20)
	toxin_back.size = Vector2(80, 6)
	toxin_back.color = Palette.SHADOW
	root.add_child(toxin_back)
	_toxin_fill = ColorRect.new()
	_toxin_fill.size = Vector2(0, 6)
	_toxin_fill.color = Palette.TOXIC
	toxin_back.add_child(_toxin_fill)
	_toxin_label = Label.new()
	_toxin_label.position = Vector2(92, 16)
	_toxin_label.add_theme_font_size_override("font_size", 8)
	_toxin_label.add_theme_color_override("font_color", Palette.TOXIC)
	_toxin_label.text = "TOXIN"
	root.add_child(_toxin_label)

	_socket_label = Label.new()
	_socket_label.position = Vector2(8, 30)
	_socket_label.add_theme_font_size_override("font_size", 8)
	_socket_label.add_theme_color_override("font_color", Palette.PALE)
	root.add_child(_socket_label)

	_pouch_label = Label.new()
	_pouch_label.position = Vector2(8, 40)
	_pouch_label.add_theme_font_size_override("font_size", 8)
	_pouch_label.add_theme_color_override("font_color", Palette.CONCRETE)
	root.add_child(_pouch_label)

	_prompt = Label.new()
	_prompt.position = Vector2(220, 300)
	_prompt.add_theme_font_size_override("font_size", 8)
	_prompt.add_theme_color_override("font_color", Palette.EMBER)
	root.add_child(_prompt)

	_announce = Label.new()
	_announce.position = Vector2(180, 48)
	_announce.add_theme_font_size_override("font_size", 10)
	_announce.add_theme_color_override("font_color", Palette.EMBER_ASH)
	root.add_child(_announce)

	var hint := Label.new()
	hint.position = Vector2(8, 338)
	hint.add_theme_font_size_override("font_size", 8)
	hint.add_theme_color_override("font_color", Palette.IRON)
	hint.text = "AD 移动  Space 跳  Shift 冲  J斩/弹反  E交互  1/2嵌核  F钩锁"
	root.add_child(hint)

	# Low-HP blood vignette: 4 red edge bands (hollow center), topmost layer.
	_vignette = Control.new()
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.modulate = Color(1, 1, 1, 0.0)
	_vignette.visible = false
	root.add_child(_vignette)
	_add_edge_rect(Vector4(0.0, 0.0, 1.0, 0.0), Vector4(0.0, 0.0, 0.0, VIGNETTE_EDGE))
	_add_edge_rect(Vector4(0.0, 1.0, 1.0, 1.0), Vector4(0.0, -VIGNETTE_EDGE, 0.0, 0.0))
	_add_edge_rect(Vector4(0.0, 0.0, 0.0, 1.0), Vector4(0.0, VIGNETTE_EDGE, VIGNETTE_EDGE, -VIGNETTE_EDGE))
	_add_edge_rect(Vector4(1.0, 0.0, 1.0, 1.0), Vector4(-VIGNETTE_EDGE, VIGNETTE_EDGE, 0.0, -VIGNETTE_EDGE))


func _add_edge_rect(anchors: Vector4, offsets: Vector4) -> void:
	# One screen-edge band; anchors/offsets packed as (left, top, right, bottom).
	var rect := ColorRect.new()
	rect.color = VIGNETTE_RED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.anchor_left = anchors.x
	rect.anchor_top = anchors.y
	rect.anchor_right = anchors.z
	rect.anchor_bottom = anchors.w
	rect.offset_left = offsets.x
	rect.offset_top = offsets.y
	rect.offset_right = offsets.z
	rect.offset_bottom = offsets.w
	_vignette.add_child(rect)


func _load_tex(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _on_hp(current: int, maximum: int) -> void:
	# Ensure bar size matches max (supports 3-8 hearts).
	while _hp_bar.get_child_count() < maximum:
		if _use_sprite_hearts:
			var tr := TextureRect.new()
			tr.texture = _heart_full
			tr.expand_mode = TextureRect.EXPAND_KEEP_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.custom_minimum_size = Vector2(14, 12)
			tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			_hp_bar.add_child(tr)
		else:
			var pip := ColorRect.new()
			pip.custom_minimum_size = Vector2(10, 8)
			pip.color = Palette.RUST_LIGHT
			_hp_bar.add_child(pip)
	while _hp_bar.get_child_count() > maximum:
		_hp_bar.get_child(_hp_bar.get_child_count() - 1).queue_free()
	for i in _hp_bar.get_child_count():
		var child := _hp_bar.get_child(i)
		if _use_sprite_hearts and child is TextureRect:
			var tr := child as TextureRect
			if i < current:
				tr.texture = _heart_full
				tr.modulate = Color(1, 1, 1, 1)
			else:
				tr.texture = _heart_empty
				tr.modulate = Color(1, 1, 1, 0.55)
		elif child is ColorRect:
			var pip := child as ColorRect
			pip.color = Palette.RUST_LIGHT if i < current else Palette.SHADOW
	if current <= 1 and not _low_hp:
		_low_hp = true
		_show_vignette()
	elif current > 1 and _low_hp:
		_low_hp = false
		_hide_vignette()


func _show_vignette() -> void:
	_vignette.visible = true
	if _vignette_tween != null and _vignette_tween.is_valid():
		_vignette_tween.kill()
	_vignette_tween = create_tween()
	_vignette_tween.tween_property(_vignette, "modulate:a", VIGNETTE_ALPHA, VIGNETTE_FADE_IN)
	_vignette_tween.finished.connect(func() -> void: _breath_time = 0.0)


func _hide_vignette() -> void:
	if _vignette_tween != null and _vignette_tween.is_valid():
		_vignette_tween.kill()
	_vignette_tween = create_tween()
	_vignette_tween.tween_property(_vignette, "modulate:a", 0.0, VIGNETTE_FADE_OUT)
	_vignette_tween.tween_callback(func() -> void: _vignette.visible = false)


func _vignette_tween_active() -> bool:
	return _vignette_tween != null and _vignette_tween.is_valid() and _vignette_tween.is_running()


func _on_toxin(current: float, maximum: float) -> void:
	var t := 0.0 if maximum <= 0.0 else current / maximum
	_toxin_ratio = t
	_toxin_fill.size.x = 80.0 * t
	_toxin_label.text = "TOXIN %d%%" % int(t * 100.0)
	if t < TOXIN_ALARM_RATIO:
		_toxin_fill.modulate = Color.WHITE
		_toxin_label.modulate = Color.WHITE


func _on_prompt(text: String) -> void:
	_prompt.text = text


func _on_announce(text: String) -> void:
	_announce.text = text
	_announce_time = 2.4


func _refresh_cores() -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	var inv := player.inventory
	var s0 := inv.socket_core(0)
	var s1 := inv.socket_core(1)
	var n0 := "-" if s0 == null else AbilityIds.display_name(s0.ability_id)
	var n1 := "-" if s1 == null else AbilityIds.display_name(s1.ability_id)
	_socket_label.text = "SOCKET 1:%s  2:%s" % [n0, n1]
	_pouch_label.text = "POUCH %d" % inv.pouch.size()
