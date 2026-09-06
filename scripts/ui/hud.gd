extends CanvasLayer
## 游戏内 HUD（1280x720）：左上状态板、顶部播报横幅、底部交互提示、
## 低血量血雾，外挂一个暂停菜单层。
##
## 所有外观取自项目默认主题 assets/ui/theme_rust.tres 的变体，面板一律是
## 9-slice 贴图；这里只负责布局、数值与动效。华丽但克制：状态板收在左上角
## 一小块，播报在顶、交互提示贴底边，不切进玩家的视野中央。

const PAUSE_MENU := preload("res://scenes/ui/PauseMenu.tscn")

## 心：11x9 的 Gothicvania 像素心按 2 倍放进 26x22 的插槽里，和 24px 字号同栅格。
const HEART_FULL_PATH := "res://assets/env/hud_heart_full.png"
const HEART_EMPTY_PATH := "res://assets/env/hud_heart_empty.png"
const HEART_SIZE := Vector2(22, 18)
const HEART_SLOT_SIZE := Vector2(26, 22)
const HEART_FLASH := 0.22

const TOXIN_BAR_SIZE := Vector2(176, 24)
## 与 assets/ui/banner.png 的高度一致（21 设计像素 * 2）。
const BANNER_HEIGHT := 42.0
## 交互提示贴在视口底边，避开玩家所在的中下视野；字幕占用底边时整条让路。
const PROMPT_BOTTOM := 10.0

# 危险反馈：毒素报警脉动 + 低血量血雾呼吸。
const TOXIN_ALARM_RATIO := 0.8
const TOXIN_PULSE_PERIOD := 0.5
const TOXIN_PULSE_MIN := 1.0
const TOXIN_PULSE_MAX := 1.6
const VIGNETTE_FADE_IN := 0.4
const VIGNETTE_FADE_OUT := 0.6
const VIGNETTE_ALPHA := 0.55
const VIGNETTE_BREATH_MIN := 0.38
const VIGNETTE_BREATH_MAX := 0.68
const VIGNETTE_BREATH_PERIOD := 3.0

const ANNOUNCE_HOLD := 2.4
const ANNOUNCE_FADE := 0.35
const HINT_HOLD := 6.0

var _hearts_row: HBoxContainer
var _toxin_bar: ProgressBar
var _toxin_label: Label
var _socket_label: Label
var _pouch_label: Label
var _prompt_panel: PanelContainer
var _prompt_label: Label
var _banner: PanelContainer
var _announce_label: Label
var _hint: Label
var _vignette: TextureRect
var _death_overlay: Control
var _pause: PauseMenu

var _heart_full: Texture2D
var _heart_empty: Texture2D
var _hp_shown := -1
var _announce_time := 0.0
var _hint_time := HINT_HOLD
var _toxin_ratio := 0.0
var _low_hp := false
var _vignette_tween: Tween
var _time := 0.0
var _breath_time := 0.0
var _announce_queue: Array[String] = []
var _resonating := false
var _atmos_hint: Label
var _prompt_text := ""

var _boss_bar_panel: PanelContainer
var _boss_title_label: Label
var _boss_hp_bar: ProgressBar
var _boss_max_hp: int = 1


func _ready() -> void:
	layer = 10
	WorldClock.isolate_ui_layer(self)
	DisplayServer.window_set_title("Rustgrave")
	_heart_full = UiKit.tex(HEART_FULL_PATH)
	_heart_empty = UiKit.tex(HEART_EMPTY_PATH)
	_build()
	GameEvents.player_health_changed.connect(_on_hp)
	GameEvents.toxin_changed.connect(_on_toxin)
	GameEvents.interact_prompt.connect(_on_prompt)
	GameEvents.announcement.connect(_on_announce)
	GameEvents.player_died.connect(_on_player_died)
	GameEvents.core_inserted.connect(func(_c, _i): _refresh_cores())
	GameEvents.core_acquired.connect(func(_c): _refresh_cores())
	GameEvents.sockets_changed.connect(_refresh_cores)
	GameEvents.resonance_changed.connect(_on_resonance)
	GameEvents.boss_appeared.connect(_on_boss_appeared)
	GameEvents.boss_hp_changed.connect(_on_boss_hp_changed)
	GameEvents.boss_defeated.connect(_on_boss_defeated)
	WorldClock.phase_changed.connect(_on_atmosphere)
	WorldClock.weather_changed.connect(_on_atmosphere)
	WorldClock.zone_changed.connect(_on_atmosphere)
	_refresh_atmosphere()
	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		_on_hp(player.health.current, player.health.max_hp)
		_on_toxin(player.toxin.toxin, player.toxin.max_toxin)
		_refresh_cores()


func _build() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_build_stat_panel(root)
	_build_banner(root)
	_build_boss_bar(root)
	_build_prompt(root)
	_build_hint(root)
	_build_vignette(root)
	_build_death_overlay(root)

	_pause = PAUSE_MENU.instantiate()
	add_child(_pause)
	WorldClock.isolate_ui_layer(_pause)


func _build_stat_panel(root: Control) -> void:
	var plate := UiKit.panel(&"HudPanel")
	plate.name = "StatPanel"
	plate.offset_left = 16.0
	plate.offset_top = 12.0
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(plate)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	plate.add_child(column)

	_hearts_row = HBoxContainer.new()
	_hearts_row.add_theme_constant_override("separation", 4)
	column.add_child(_hearts_row)

	var toxin_row := HBoxContainer.new()
	toxin_row.add_theme_constant_override("separation", 8)
	toxin_row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(toxin_row)
	_toxin_bar = ProgressBar.new()
	_toxin_bar.custom_minimum_size = TOXIN_BAR_SIZE
	_toxin_bar.show_percentage = false
	_toxin_bar.min_value = 0.0
	_toxin_bar.max_value = 100.0
	_toxin_bar.value = 0.0
	toxin_row.add_child(_toxin_bar)
	_toxin_label = UiKit.label("毒素 冷 0%", &"HudToxinLabel")
	_toxin_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toxin_row.add_child(_toxin_label)

	_socket_label = UiKit.label("剑核  - · -", &"HudStrongLabel")
	column.add_child(_socket_label)
	_pouch_label = UiKit.label("袋中 0", &"HudLabel")
	column.add_child(_pouch_label)
	_atmos_hint = UiKit.label("", &"HudLabel")
	_atmos_hint.name = "AtmosphereHint"
	column.add_child(_atmos_hint)


func _build_banner(root: Control) -> void:
	_banner = UiKit.panel(&"BannerPanel")
	_banner.name = "Banner"
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.offset_top = 14.0
	# 高度钉在贴图原高：横幅一被纵向拉伸，两端的尖角就会出现半像素毛边。
	_banner.custom_minimum_size = Vector2(0.0, BANNER_HEIGHT)
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.modulate.a = 0.0
	root.add_child(_banner)
	_announce_label = UiKit.label("", &"AnnounceLabel", HORIZONTAL_ALIGNMENT_CENTER)
	_announce_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.add_child(_announce_label)


func _build_boss_bar(root: Control) -> void:
	_boss_bar_panel = UiKit.panel(&"HudPanel")
	_boss_bar_panel.name = "BossBar"
	_boss_bar_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_boss_bar_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_boss_bar_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_boss_bar_panel.offset_top = -68.0
	_boss_bar_panel.offset_bottom = -22.0
	_boss_bar_panel.custom_minimum_size = Vector2(460.0, 40.0)
	_boss_bar_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_bar_panel.visible = false
	root.add_child(_boss_bar_panel)

	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 2)
	_boss_bar_panel.add_child(col)

	_boss_title_label = UiKit.label("炉 约 刽 子 手 · 铸 渣 残 躯", &"HudStrongLabel", HORIZONTAL_ALIGNMENT_CENTER)
	_boss_title_label.name = "BossTitle"
	_boss_title_label.add_theme_color_override("font_color", Palette.EMBER)
	col.add_child(_boss_title_label)

	_boss_hp_bar = ProgressBar.new()
	_boss_hp_bar.name = "BossHpBar"
	_boss_hp_bar.custom_minimum_size = Vector2(420.0, 10.0)
	_boss_hp_bar.show_percentage = false
	_boss_hp_bar.min_value = 0.0
	_boss_hp_bar.max_value = 13.0
	_boss_hp_bar.value = 13.0
	col.add_child(_boss_hp_bar)


func _build_prompt(root: Control) -> void:
	_prompt_panel = UiKit.panel(&"HudPanel")
	_prompt_panel.name = "Prompt"
	_prompt_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_prompt_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_prompt_panel.offset_top = -PROMPT_BOTTOM
	_prompt_panel.offset_bottom = -PROMPT_BOTTOM
	_prompt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt_panel.visible = false
	root.add_child(_prompt_panel)
	_prompt_label = UiKit.label("", &"PromptLabel", HORIZONTAL_ALIGNMENT_CENTER)
	_prompt_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_prompt_panel.add_child(_prompt_label)


func _build_hint(root: Control) -> void:
	_hint = UiKit.label("Esc 暂停 · 完整键位见暂停菜单里的操作说明", &"FootnoteLabel",
			HORIZONTAL_ALIGNMENT_RIGHT)
	_hint.anchor_left = 1.0
	_hint.anchor_right = 1.0
	_hint.offset_left = -440.0
	_hint.offset_right = -18.0
	_hint.offset_top = 16.0
	_hint.offset_bottom = 34.0
	root.add_child(_hint)


func _build_vignette(root: Control) -> void:
	_vignette = UiKit.sprite_rect(UiKit.TEX_VIGNETTE)
	_vignette.name = "BloodVignette"
	_vignette.stretch_mode = TextureRect.STRETCH_SCALE
	_vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.modulate = Color(1, 1, 1, 0.0)
	_vignette.visible = false
	root.add_child(_vignette)


func _build_death_overlay(root: Control) -> void:
	_death_overlay = Control.new()
	_death_overlay.name = "DeathOverlay"
	_death_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_death_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_death_overlay.modulate.a = 0.0
	_death_overlay.visible = false
	root.add_child(_death_overlay)
	_death_overlay.add_child(UiKit.scrim(0.86, 0.86, 0.86))

	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_CENTER)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	_death_overlay.add_child(column)
	column.add_child(UiKit.label("余 烬 熄 灭", &"HeadLabel", HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(UiKit.divider())
	column.add_child(UiKit.label("在最后点亮的余烬巢重燃…", &"DimLabel",
			HORIZONTAL_ALIGNMENT_CENTER))


func _process(delta: float) -> void:
	_time += delta
	if _announce_time > 0.0:
		_announce_time -= delta
		if _announce_time <= 0.0:
			if not _announce_queue.is_empty():
				_show_announce(_announce_queue.pop_front())
			else:
				_hide_banner()
	if _hint_time > 0.0:
		_hint_time -= delta
		var banner_up := _banner != null and _banner.modulate.a > 0.2
		_hint.visible = not banner_up
		_hint.modulate.a = clampf(_hint_time / 1.6, 0.0, 0.7)
		if _hint_time <= 0.0:
			_hint.visible = false
	_sync_prompt()
	if _resonating:
		var glow := 0.55 + 0.45 * sin(TAU * _time / 0.35)
		_toxin_bar.modulate = Color(1.35, 0.82 + glow * 0.15, 0.38)
		_toxin_label.modulate = Color(1.25, 0.88, 0.5)
	elif _toxin_ratio >= TOXIN_ALARM_RATIO:
		var pulse := lerpf(TOXIN_PULSE_MIN, TOXIN_PULSE_MAX,
				0.5 + 0.5 * sin(TAU * _time / TOXIN_PULSE_PERIOD))
		_toxin_bar.modulate = Color(pulse, pulse, pulse)
		_toxin_label.modulate = Color(pulse, pulse, pulse)
	if _low_hp and not _vignette_tween_active():
		_breath_time += delta
		_vignette.modulate.a = lerpf(VIGNETTE_BREATH_MIN, VIGNETTE_BREATH_MAX,
				0.5 + 0.5 * sin(TAU * _breath_time / VIGNETTE_BREATH_PERIOD))


## 一颗心 = 深色插槽 + 2 倍放大的像素心。插槽让血量在明亮场景里也读得出来。
func _make_heart() -> Control:
	var wrap := Control.new()
	wrap.custom_minimum_size = HEART_SLOT_SIZE
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var slot := UiKit.sprite_rect(UiKit.TEX_HEART_SLOT)
	slot.name = "Slot"
	wrap.add_child(slot)
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.texture = _heart_full
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.position = (HEART_SLOT_SIZE - HEART_SIZE) * 0.5
	icon.size = HEART_SIZE
	wrap.add_child(icon)
	return wrap


func _on_hp(current: int, maximum: int) -> void:
	while _hearts_row.get_child_count() < maximum:
		_hearts_row.add_child(_make_heart())
	while _hearts_row.get_child_count() > maximum:
		_hearts_row.get_child(_hearts_row.get_child_count() - 1).queue_free()
	var lost := _hp_shown > current
	for i in _hearts_row.get_child_count():
		var icon := _hearts_row.get_child(i).get_node_or_null("Icon") as TextureRect
		if icon == null:
			continue
		var alive := i < current
		icon.texture = _heart_full if alive else _heart_empty
		icon.modulate = Color(1, 1, 1, 1.0 if alive else 0.5)
		# 刚刚熄灭的那颗心闪一下白，把掉血读成一次事件而不是静默变化。
		if lost and not alive and i < _hp_shown:
			_flash(icon)
	_hp_shown = current
	if current <= 1 and not _low_hp:
		_low_hp = true
		_show_vignette()
	elif current > 1 and _low_hp:
		_low_hp = false
		_hide_vignette()


func _flash(icon: TextureRect) -> void:
	icon.modulate = Color(2.4, 2.0, 1.8, 1.0)
	var tween := create_tween()
	tween.tween_property(icon, "modulate", Color(1, 1, 1, 0.5), HEART_FLASH)


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
	_toxin_bar.value = t * 100.0
	var band := ToxinMeter.band_for(current, maximum)
	_toxin_label.text = "毒素 %s %d%%" % [ToxinMeter.band_label_for(band), int(t * 100.0)]
	if band == &"hot":
		_toxin_label.modulate = Color(1.35, 0.75, 0.35)
	elif band == &"warm":
		_toxin_label.modulate = Color(1.15, 0.95, 0.65)
	elif t < TOXIN_ALARM_RATIO:
		_toxin_bar.modulate = Color.WHITE
		_toxin_label.modulate = Color.WHITE


func _on_boss_appeared(boss_name: String, current_hp: int, max_hp: int) -> void:
	if _boss_bar_panel == null:
		return
	_boss_max_hp = maxi(1, max_hp)
	_boss_title_label.text = boss_name
	_boss_hp_bar.max_value = float(_boss_max_hp)
	_boss_hp_bar.value = float(current_hp)
	_boss_bar_panel.modulate.a = 0.0
	_boss_bar_panel.visible = true
	var tw := create_tween()
	tw.tween_property(_boss_bar_panel, "modulate:a", 1.0, 0.6)


func _on_boss_hp_changed(current_hp: int, max_hp: int) -> void:
	if _boss_hp_bar == null:
		return
	if max_hp > 0:
		_boss_max_hp = max_hp
		_boss_hp_bar.max_value = float(max_hp)
	var tw := create_tween()
	tw.tween_property(_boss_hp_bar, "value", float(current_hp), 0.15)


func _on_boss_defeated() -> void:
	if _boss_bar_panel == null or not _boss_bar_panel.visible:
		return
	var tw := create_tween()
	tw.tween_property(_boss_bar_panel, "modulate:a", 0.0, 0.8)
	tw.tween_callback(func() -> void: _boss_bar_panel.visible = false)



func _on_prompt(text: String) -> void:
	_prompt_text = text
	if _prompt_label != null:
		_prompt_label.text = text
	_sync_prompt()


func _sync_prompt() -> void:
	if _prompt_panel == null:
		return
	var cap := Director.caption()
	var cap_busy := cap != null and cap.is_busy()
	var dead := _death_overlay != null and _death_overlay.visible
	_prompt_panel.visible = _prompt_text != "" and not cap_busy and not dead


func _on_announce(text: String) -> void:
	if text == "":
		return
	if _announce_time > 0.0 and _announce_label.text != "":
		if _announce_queue.size() < 2:
			_announce_queue.append(text)
		return
	_show_announce(text)


func _show_announce(text: String) -> void:
	_announce_label.text = text
	_announce_time = ANNOUNCE_HOLD
	var tween := create_tween()
	tween.tween_property(_banner, "modulate:a", 1.0, ANNOUNCE_FADE)


func _on_resonance(active: bool) -> void:
	_resonating = active
	if not active and _toxin_ratio < TOXIN_ALARM_RATIO:
		_toxin_bar.modulate = Color.WHITE
		_toxin_label.modulate = Color.WHITE


func _hide_banner() -> void:
	var tween := create_tween()
	tween.tween_property(_banner, "modulate:a", 0.0, ANNOUNCE_FADE)
	tween.tween_callback(func() -> void: _announce_label.text = "")


func _on_player_died() -> void:
	if _pause != null and _pause.is_open():
		_pause.close()
	_death_overlay.visible = true
	_sync_prompt()
	var tween := create_tween()
	tween.tween_property(_death_overlay, "modulate:a", 1.0, 0.45)


func _exit_tree() -> void:
	if WorldClock.phase_changed.is_connected(_on_atmosphere):
		WorldClock.phase_changed.disconnect(_on_atmosphere)
	if WorldClock.weather_changed.is_connected(_on_atmosphere):
		WorldClock.weather_changed.disconnect(_on_atmosphere)
	if WorldClock.zone_changed.is_connected(_on_atmosphere):
		WorldClock.zone_changed.disconnect(_on_atmosphere)


func _on_atmosphere(_value: int = 0) -> void:
	_refresh_atmosphere()


func _refresh_atmosphere() -> void:
	if _atmos_hint == null:
		return
	_atmos_hint.text = WorldClock.hud_line()


func _refresh_cores() -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	var inv := player.inventory
	var s0 := inv.socket_core(0)
	var s1 := inv.socket_core(1)
	var n0 := "-" if s0 == null else AbilityIds.display_name(s0.ability_id)
	var n1 := "-" if s1 == null else AbilityIds.display_name(s1.ability_id)
	_socket_label.text = "剑核  %s · %s" % [n0, n1]
	_pouch_label.text = "袋中 %d" % inv.pouch.size()
