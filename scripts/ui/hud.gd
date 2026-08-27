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
	if _announce_time > 0.0:
		_announce_time -= delta
		if _announce_time <= 0.0:
			_announce.text = ""
	_refresh_cores()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_hp_bar = HBoxContainer.new()
	_hp_bar.position = Vector2(8, 8)
	_hp_bar.add_theme_constant_override("separation", 3)
	root.add_child(_hp_bar)
	for i in 5:
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


func _on_hp(current: int, maximum: int) -> void:
	for i in _hp_bar.get_child_count():
		var pip := _hp_bar.get_child(i) as ColorRect
		pip.color = Palette.RUST_LIGHT if i < current else Palette.SHADOW
	if maximum > _hp_bar.get_child_count():
		pass


func _on_toxin(current: float, maximum: float) -> void:
	var t := 0.0 if maximum <= 0.0 else current / maximum
	_toxin_fill.size.x = 80.0 * t
	_toxin_label.text = "TOXIN %d%%" % int(t * 100.0)


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
