extends Control
class_name UpgradePicker

signal upgrade_selected(upgrade: Dictionary)

const UpgradeCatalogData := preload("res://scripts/data/UpgradeCatalog.gd")
const UiMotion := preload("res://scripts/ui/UiAnimations.gd")
const UiThemeData := preload("res://scripts/ui/UiTheme.gd")
const UPGRADE_ICONS := preload("res://assets/generated/neon_ecology/upgrade_icons_atlas.png")
const ICON_CELL_SIZE := Vector2i(256, 256)
const ICON_COLUMNS := 6

var _choice_buttons: Array[Button] = []
var _tag_label: Label
var _current_choices: Array = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	_build()
	hide()

func show_choices(choices: Array, build_tags: Array) -> void:
	_current_choices = choices.duplicate(true)
	_tag_label.text = LocaleText.format("upgrade.build", [LocaleText.join_tags(build_tags, "common.new_run")])
	for i in range(_choice_buttons.size()):
		var button := _choice_buttons[i]
		if i >= choices.size():
			button.hide()
			continue
		var upgrade: Dictionary = choices[i].duplicate(true)
		var rarity := String(upgrade.get("rarity", "common"))
		var color := UpgradeCatalogData.rarity_color(rarity)
		button.show()
		button.text = "%d  %s\n%s\n%s" % [
			i + 1,
			LocaleText.translate_upgrade_name(upgrade),
			LocaleText.translate_upgrade_description(upgrade),
			" / ".join(LocaleText.translate_tags(upgrade.get("tags", []))),
		]
		button.icon = _icon_for(upgrade)
		button.add_theme_stylebox_override("normal", _card_style(color.darkened(0.5), color, 0.28))
		button.add_theme_stylebox_override("hover", _card_style(color.darkened(0.38), color, 0.56))
		button.add_theme_stylebox_override("pressed", _card_style(color.darkened(0.6), color, 0.72))

		# 卡片入场动画
		if SettingsStore.animations_on:
			button.modulate.a = 0.0
			button.scale = Vector2(0.85, 0.85)
			var tween := button.create_tween()
			tween.set_parallel(true)
			tween.tween_property(button, "modulate:a", 1.0, 0.3).set_delay(i * 0.08)
			tween.tween_property(button, "scale", Vector2.ONE, 0.3).set_delay(i * 0.08).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		else:
			button.modulate.a = 1.0
			button.scale = Vector2.ONE

	show()
	for button in _choice_buttons:
		if button.visible:
			button.grab_focus()
			return
	grab_focus()

func choose_index(index: int) -> void:
	if not visible:
		return
	if index >= 0 and index < _choice_buttons.size() and _choice_buttons[index].visible:
		_choice_buttons[index].emit_signal("pressed")

func _build() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.64)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(930, 360)
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	margin.add_child(layout)

	var title := Label.new()
	title.text = LocaleText.t("upgrade.title")
	UiThemeData.apply_font(title)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.9, 1.0, 0.94))
	layout.add_child(title)

	_tag_label = Label.new()
	UiThemeData.apply_font(_tag_label)
	_tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tag_label.add_theme_font_size_override("font_size", 15)
	_tag_label.add_theme_color_override("font_color", Color(0.64, 0.82, 0.76))
	layout.add_child(_tag_label)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	layout.add_child(row)

	for i in range(3):
		var button := Button.new()
		UiThemeData.apply_button_font(button)
		var index := i
		button.custom_minimum_size = Vector2(286, 198)
		button.focus_mode = Control.FOCUS_ALL
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.expand_icon = false
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 17)
		button.add_theme_constant_override("icon_max_width", 76)
		button.pressed.connect(func() -> void: _pick(index))
		UiMotion.bind_button_motion(button, Vector2(1.018, 1.025), Vector2(0.97, 0.95))
		row.add_child(button)
		_choice_buttons.append(button)

func _pick(index: int) -> void:
	if index < 0 or index >= _current_choices.size():
		return
	AudioBus.play_button()
	upgrade_selected.emit(_current_choices[index].duplicate(true))

func _icon_for(upgrade: Dictionary) -> Texture2D:
	var texture := AtlasTexture.new()
	texture.atlas = UPGRADE_ICONS
	var upgrade_id := String(upgrade.get("id", ""))
	var index := 0
	for i in range(UpgradeCatalogData.UPGRADES.size()):
		if String(UpgradeCatalogData.UPGRADES[i].get("id", "")) == upgrade_id:
			index = i
			break
	var row := floori(float(index) / float(ICON_COLUMNS))
	var column := index % ICON_COLUMNS
	texture.region = Rect2i(column * ICON_CELL_SIZE.x, row * ICON_CELL_SIZE.y, ICON_CELL_SIZE.x, ICON_CELL_SIZE.y)
	return texture

func _panel_style() -> StyleBoxTexture:
	return UiThemeData.textured_panel_style(Color(0.02, 0.04, 0.045, 0.96), Color(0.48, 1.0, 0.72, 0.68), 12)

func _card_style(fill: Color, border: Color, alpha: float) -> StyleBoxTexture:
	var style := UiThemeData.textured_button_style(Color(fill.r, fill.g, fill.b, 0.88), Color(border.r, border.g, border.b, alpha), 10)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style
