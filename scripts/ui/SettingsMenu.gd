extends Control

signal menu_requested
signal about_requested

const GameConfigData := preload("res://scripts/data/GameConfig.gd")
const NeonAssetsData := preload("res://scripts/ui/NeonAssets.gd")

var _difficulty_buttons: Array[Button] = []
var _speed_buttons: Array[Button] = []
var _effects_buttons: Array[Button] = []
var _minimap_buttons: Array[Button] = []

func _ready() -> void:
	_build()

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
	title.text = "Settings"
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.86, 1.0, 0.92))
	layout.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)

	var settings := VBoxContainer.new()
	settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings.add_theme_constant_override("separation", 12)
	scroll.add_child(settings)

	settings.add_child(_section_label("Gameplay"))
	settings.add_child(_segmented_row("Difficulty", GameConfigData.DIFFICULTY_LABELS, SettingsStore.difficulty, Callable(self, "_set_difficulty"), _difficulty_buttons))
	settings.add_child(_segmented_row("Snake speed", GameConfigData.SPEED_LABELS, SettingsStore.snake_speed, Callable(self, "_set_speed"), _speed_buttons))

	settings.add_child(_section_label("Display"))
	settings.add_child(_segmented_row("Effects", GameConfigData.EFFECT_QUALITY_LABELS, SettingsStore.effects_quality, Callable(self, "_set_effects_quality"), _effects_buttons))
	settings.add_child(_toggle_row("Animations", SettingsStore.animations_on, Callable(SettingsStore, "set_animations_on")))
	settings.add_child(_toggle_row("Screen shake", SettingsStore.screen_shake_on, Callable(SettingsStore, "set_screen_shake_on")))
	settings.add_child(_toggle_row("Mini-map", SettingsStore.minimap_on, Callable(SettingsStore, "set_minimap_on")))
	settings.add_child(_segmented_row("Map size", GameConfigData.MINIMAP_SIZE_LABELS, SettingsStore.minimap_size, Callable(self, "_set_minimap_size"), _minimap_buttons))
	settings.add_child(_toggle_row("Anti-aliasing", SettingsStore.anti_aliasing_on, Callable(SettingsStore, "set_anti_aliasing_on")))
	settings.add_child(_toggle_row("Fullscreen", SettingsStore.fullscreen_on, Callable(SettingsStore, "set_fullscreen_on")))

	settings.add_child(_section_label("Audio"))
	settings.add_child(_volume_row("Master", SettingsStore.volume, Callable(SettingsStore, "set_volume")))
	settings.add_child(_volume_row("BGM", SettingsStore.bgm_volume, Callable(SettingsStore, "set_bgm_volume")))
	settings.add_child(_volume_row("SFX", SettingsStore.sfx_volume, Callable(SettingsStore, "set_sfx_volume")))
	settings.add_child(_toggle_row("Sound", SettingsStore.sound_on, Callable(SettingsStore, "set_sound_on")))

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_END
	bottom.add_theme_constant_override("separation", 12)
	layout.add_child(bottom)

	var reset := Button.new()
	reset.text = "Reset"
	reset.custom_minimum_size = Vector2(124, 46)
	reset.add_theme_font_size_override("font_size", 18)
	reset.pressed.connect(func() -> void:
		AudioBus.play_button()
		SettingsStore.reset_to_defaults()
		_rebuild()
	)
	bottom.add_child(reset)

	var about := Button.new()
	about.text = "About"
	about.custom_minimum_size = Vector2(124, 46)
	about.add_theme_font_size_override("font_size", 18)
	about.pressed.connect(func() -> void:
		AudioBus.play_button()
		about_requested.emit()
	)
	bottom.add_child(about)

	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(148, 46)
	back.add_theme_font_size_override("font_size", 18)
	back.pressed.connect(func() -> void:
		AudioBus.play_button()
		menu_requested.emit()
	)
	bottom.add_child(back)

func _add_background() -> void:
	var background := TextureRect.new()
	background.texture = NeonAssetsData.atlas_texture(NeonAssetsData.MENU_BACKGROUNDS, NeonAssetsData.SETTINGS_BG)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.032, 0.88)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_difficulty_buttons.clear()
	_speed_buttons.clear()
	_effects_buttons.clear()
	_minimap_buttons.clear()
	_build()

func _section_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(1, 28)
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.48, 1.0, 0.7))
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
		var index := i
		button.text = String(labels[i])
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = i == active_index
		button.custom_minimum_size = Vector2(118, 42)
		button.add_theme_font_size_override("font_size", 17)
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
	row.add_child(slider)

	var value_label := Label.new()
	value_label.custom_minimum_size = Vector2(54, 1)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_font_size_override("font_size", 16)
	value_label.add_theme_color_override("font_color", Color(0.78, 0.86, 0.83))
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
	checkbox.button_pressed = active
	checkbox.text = "On" if active else "Off"
	checkbox.custom_minimum_size = Vector2(96, 42)
	checkbox.add_theme_font_size_override("font_size", 17)
	checkbox.toggled.connect(func(enabled: bool) -> void:
		AudioBus.play_button()
		checkbox.text = "On" if enabled else "Off"
		callback.call(enabled)
	)
	row.add_child(checkbox)

	return row

func _row_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(150, 1)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.8, 0.9, 0.86))
	return label

func _set_difficulty(index: int) -> void:
	SettingsStore.set_difficulty(index)

func _set_speed(index: int) -> void:
	SettingsStore.set_snake_speed(index)

func _set_effects_quality(index: int) -> void:
	SettingsStore.set_effects_quality(index)

func _set_minimap_size(index: int) -> void:
	SettingsStore.set_minimap_size(index)
