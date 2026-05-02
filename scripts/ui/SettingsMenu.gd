extends Control

signal menu_requested
signal about_requested

const GameConfigData := preload("res://scripts/data/GameConfig.gd")
const UiMotion := preload("res://scripts/ui/UiAnimations.gd")
const SETTINGS_BACKGROUND_TEXTURE := preload("res://assets/generated/obsidian_ui/settings_background.png")
const Responsive := preload("res://scripts/ui/ResponsiveLayout.gd")
const UiThemeData := preload("res://scripts/ui/UiTheme.gd")

var _difficulty_buttons: Array[Button] = []
var _speed_buttons: Array[Button] = []
var _effects_buttons: Array[Button] = []
var _minimap_buttons: Array[Button] = []
var _language_buttons: Array[Button] = []

func _ready() -> void:
	Responsive.update_scale()
	_build()
	_play_intro()

func _build() -> void:
	_add_background()

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 64)
	margin.add_theme_constant_override("margin_right", 64)
	margin.add_theme_constant_override("margin_top", 46)
	margin.add_theme_constant_override("margin_bottom", 42)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	margin.add_child(layout)

	var title := Label.new()
	title.text = LocaleText.t("settings.title")
	UiThemeData.apply_font(title)
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.9, 1.0, 0.82))
	layout.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)

	var settings := VBoxContainer.new()
	settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings.add_theme_constant_override("separation", 12)
	scroll.add_child(settings)

	settings.add_child(_section_label(LocaleText.t("settings.language")))
	settings.add_child(_segmented_row(LocaleText.t("settings.language"), LocaleText.language_labels(), LocaleText.language_index(SettingsStore.language), Callable(self, "_set_language"), _language_buttons))

	settings.add_child(_section_label(LocaleText.t("settings.gameplay")))
	settings.add_child(_segmented_row(LocaleText.t("menu.difficulty"), LocaleText.difficulty_labels(), SettingsStore.difficulty, Callable(self, "_set_difficulty"), _difficulty_buttons))
	settings.add_child(_segmented_row(LocaleText.t("settings.snake_speed"), LocaleText.speed_labels(), SettingsStore.snake_speed, Callable(self, "_set_speed"), _speed_buttons))

	settings.add_child(_section_label(LocaleText.t("settings.display")))
	settings.add_child(_segmented_row(LocaleText.t("settings.effects"), LocaleText.effects_labels(), SettingsStore.effects_quality, Callable(self, "_set_effects_quality"), _effects_buttons))
	settings.add_child(_toggle_row(LocaleText.t("settings.animations"), SettingsStore.animations_on, Callable(SettingsStore, "set_animations_on")))
	settings.add_child(_toggle_row(LocaleText.t("settings.screen_shake"), SettingsStore.screen_shake_on, Callable(SettingsStore, "set_screen_shake_on")))
	settings.add_child(_toggle_row(LocaleText.t("settings.minimap"), SettingsStore.minimap_on, Callable(SettingsStore, "set_minimap_on")))
	settings.add_child(_segmented_row(LocaleText.t("settings.map_size"), LocaleText.minimap_size_labels(), SettingsStore.minimap_size, Callable(self, "_set_minimap_size"), _minimap_buttons))
	settings.add_child(_toggle_row(LocaleText.t("settings.antialiasing"), SettingsStore.anti_aliasing_on, Callable(SettingsStore, "set_anti_aliasing_on")))
	settings.add_child(_toggle_row(LocaleText.t("settings.fullscreen"), SettingsStore.fullscreen_on, Callable(SettingsStore, "set_fullscreen_on")))

	settings.add_child(_section_label(LocaleText.t("settings.audio")))
	settings.add_child(_volume_row(LocaleText.t("settings.master"), SettingsStore.volume, Callable(SettingsStore, "set_volume")))
	settings.add_child(_volume_row(LocaleText.t("settings.bgm"), SettingsStore.bgm_volume, Callable(SettingsStore, "set_bgm_volume")))
	settings.add_child(_volume_row(LocaleText.t("settings.sfx"), SettingsStore.sfx_volume, Callable(SettingsStore, "set_sfx_volume")))
	settings.add_child(_toggle_row(LocaleText.t("settings.sound"), SettingsStore.sound_on, Callable(SettingsStore, "set_sound_on")))

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_END
	bottom.add_theme_constant_override("separation", 12)
	layout.add_child(bottom)

	var reset := Button.new()
	UiThemeData.apply_button_font(reset)
	reset.text = LocaleText.t("settings.reset")
	reset.custom_minimum_size = Vector2(124, 46)
	reset.add_theme_font_size_override("font_size", 18)
	_apply_button_style(reset, Color(0.45, 0.2, 0.12))
	reset.pressed.connect(func() -> void:
		AudioBus.play_button()
		SettingsStore.reset_to_defaults()
		_rebuild()
	)
	bottom.add_child(reset)

	var about := Button.new()
	UiThemeData.apply_button_font(about)
	about.text = LocaleText.t("menu.about")
	about.custom_minimum_size = Vector2(124, 46)
	about.add_theme_font_size_override("font_size", 18)
	_apply_button_style(about, Color(0.16, 0.32, 0.14))
	about.pressed.connect(func() -> void:
		AudioBus.play_button()
		about_requested.emit()
	)
	bottom.add_child(about)

	var back := Button.new()
	UiThemeData.apply_button_font(back)
	back.text = LocaleText.t("settings.back")
	back.custom_minimum_size = Vector2(148, 46)
	back.add_theme_font_size_override("font_size", 18)
	_apply_button_style(back, Color(0.28, 0.56, 0.22))
	back.pressed.connect(func() -> void:
		AudioBus.play_button()
		menu_requested.emit()
	)
	bottom.add_child(back)

func _add_background() -> void:
	var background := TextureRect.new()
	background.texture = SETTINGS_BACKGROUND_TEXTURE
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.014, 0.006, 0.82)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var beam := ColorRect.new()
	beam.color = Color(0.76, 1.0, 0.36, 0.055)
	beam.set_anchors_preset(Control.PRESET_TOP_WIDE)
	beam.offset_top = 102
	beam.offset_bottom = 106
	add_child(beam)

func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_difficulty_buttons.clear()
	_speed_buttons.clear()
	_effects_buttons.clear()
	_minimap_buttons.clear()
	_language_buttons.clear()
	_build()

func _section_label(text: String) -> Label:
	var label := Label.new()
	UiThemeData.apply_font(label)
	label.text = text
	label.custom_minimum_size = Vector2(1, 28)
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.74, 1.0, 0.44))
	return label

func _segmented_row(label_text: String, labels: Array, active_index: int, callback: Callable, store: Array[Button]) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(1, 56)
	row.add_theme_constant_override("separation", 14)

	var label := _row_label(label_text)
	row.add_child(label)

	var group := ButtonGroup.new()
	for i in range(labels.size()):
		var button := Button.new()
		UiThemeData.apply_button_font(button)
		var index := i
		button.text = String(labels[i])
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = i == active_index
		button.custom_minimum_size = Vector2(118, 42)
		button.add_theme_font_size_override("font_size", 17)
		_apply_button_style(button, Color(0.08, 0.32, 0.34), i == active_index)
		button.pressed.connect(func() -> void:
			AudioBus.play_button()
			callback.call(index)
		)
		store.append(button)
		row.add_child(button)

	return row

func _volume_row(label_text: String, value: float, callback: Callable) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(1, 56)
	row.add_theme_constant_override("separation", 14)
	row.add_child(_row_label(label_text))

	var slider := HSlider.new()
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = value
	slider.custom_minimum_size = Vector2(260, 42)
	slider.add_theme_stylebox_override("slider", _slider_style(Color(0.32, 0.5, 0.16), 0.3))
	slider.add_theme_stylebox_override("grabber_area", _slider_style(Color(0.72, 1.0, 0.38), 0.46))
	row.add_child(slider)

	var value_label := Label.new()
	UiThemeData.apply_font(value_label)
	value_label.custom_minimum_size = Vector2(54, 1)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_font_size_override("font_size", 16)
	value_label.add_theme_color_override("font_color", Color(0.78, 0.88, 0.68))
	value_label.text = "%d%%" % roundi(value * 100.0)
	row.add_child(value_label)

	slider.value_changed.connect(func(next_value: float) -> void:
		callback.call(next_value)
		value_label.text = "%d%%" % roundi(next_value * 100.0)
	)
	return row

func _toggle_row(label_text: String, active: bool, callback: Callable) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(1, 50)
	row.add_theme_constant_override("separation", 14)
	row.add_child(_row_label(label_text))

	var checkbox := CheckBox.new()
	UiThemeData.apply_button_font(checkbox)
	checkbox.button_pressed = active
	checkbox.text = LocaleText.t("common.on") if active else LocaleText.t("common.off")
	checkbox.custom_minimum_size = Vector2(96, 42)
	checkbox.add_theme_font_size_override("font_size", 17)
	_apply_button_style(checkbox, Color(0.18, 0.34, 0.13), active)
	checkbox.toggled.connect(func(enabled: bool) -> void:
		AudioBus.play_button()
		checkbox.text = LocaleText.t("common.on") if enabled else LocaleText.t("common.off")
		callback.call(enabled)
	)
	row.add_child(checkbox)

	return row

func _row_label(text: String) -> Label:
	var label := Label.new()
	UiThemeData.apply_font(label)
	label.text = text
	label.custom_minimum_size = Vector2(150, 1)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.82, 0.9, 0.72))
	return label

func _set_difficulty(index: int) -> void:
	SettingsStore.set_difficulty(index)

func _set_speed(index: int) -> void:
	SettingsStore.set_snake_speed(index)

func _set_effects_quality(index: int) -> void:
	SettingsStore.set_effects_quality(index)

func _set_minimap_size(index: int) -> void:
	SettingsStore.set_minimap_size(index)

func _set_language(index: int) -> void:
	SettingsStore.set_language(String(LocaleText.LANGUAGES[clampi(index, 0, LocaleText.LANGUAGES.size() - 1)]))
	_rebuild()

func _apply_button_style(button: Button, color: Color, active := false) -> void:
	UiThemeData.apply_button_font(button)
	button.add_theme_color_override("font_color", Color(0.94, 1.0, 0.84))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _button_style(color.lightened(0.04) if active else color.darkened(0.12), Color(0.78, 1.0, 0.46, 0.42 if active else 0.22)))
	button.add_theme_stylebox_override("hover", _button_style(color.lightened(0.1), Color(0.9, 1.0, 0.58, 0.55)))
	button.add_theme_stylebox_override("pressed", _button_style(color.darkened(0.22), Color(1.0, 0.78, 0.36, 0.72)))
	button.add_theme_stylebox_override("focus", _button_style(color.lightened(0.08), Color(0.92, 1.0, 0.64, 0.72)))
	UiMotion.bind_button_motion(button, Vector2(1.018, 1.025), Vector2(0.97, 0.95))

func _button_style(fill: Color, border: Color) -> StyleBoxTexture:
	var style := UiThemeData.textured_button_style(fill, border, 12)
	style.content_margin_left = 14
	style.content_margin_right = 14
	return style

func _slider_style(color: Color, alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, alpha)
	style.border_color = Color(0.84, 1.0, 0.5, alpha * 0.65)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style

func _play_intro() -> void:
	if not SettingsStore.animations_on:
		return
	modulate.a = 0.0
	position.y -= 12.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", position.y + 12.0, 0.42).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
