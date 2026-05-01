extends Control

signal resume_requested
signal restart_requested
signal menu_requested

const NeonAssetsData := preload("res://scripts/ui/NeonAssets.gd")

var _build_label: Label
var _stats_label: Label

func _ready() -> void:
	_build()

func set_build_snapshot(snapshot: Dictionary) -> void:
	if _build_label == null:
		return
	var tags: Array = snapshot.get("build_tags", [])
	var upgrades: Array = snapshot.get("upgrade_names", [])
	_build_label.text = "Build  %s" % (", ".join(tags) if not tags.is_empty() else "none")
	_stats_label.text = "Wave %d  Combo %d  Upgrades %d\n%s" % [
		int(snapshot.get("wave", 1)),
		int(snapshot.get("max_combo", 0)),
		upgrades.size(),
		", ".join(upgrades.slice(maxi(0, upgrades.size() - 4), upgrades.size())) if not upgrades.is_empty() else "No upgrades yet",
	]

	# 入场动画：淡入+缩放
	if SettingsStore.animations_on and not visible:
		modulate.a = 0.0
		scale = Vector2(0.92, 0.92)
		show()
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "modulate:a", 1.0, 0.3)
		tween.tween_property(self, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	else:
		show()

func _build() -> void:
	var background := TextureRect.new()
	background.texture = NeonAssetsData.atlas_texture(NeonAssetsData.MENU_BACKGROUNDS, NeonAssetsData.PAUSE_BG)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.44)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 330)
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.88, 1.0, 0.92))
	layout.add_child(title)

	_build_label = Label.new()
	_build_label.text = "Build  none"
	_build_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_build_label.add_theme_font_size_override("font_size", 16)
	_build_label.add_theme_color_override("font_color", Color(0.68, 1.0, 0.78))
	layout.add_child(_build_label)

	_stats_label = Label.new()
	_stats_label.text = "Wave 1  Combo 0  Upgrades 0"
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stats_label.add_theme_font_size_override("font_size", 14)
	_stats_label.add_theme_color_override("font_color", Color(0.72, 0.84, 0.8))
	layout.add_child(_stats_label)

	layout.add_child(_make_button("Resume", Callable(self, "_emit_resume")))
	layout.add_child(_make_button("Restart", Callable(self, "_emit_restart")))
	layout.add_child(_make_button("Menu", Callable(self, "_emit_menu")))

func _make_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(210, 44)
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(func() -> void:
		AudioBus.play_button()
		callback.call()
	)
	return button

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.055, 0.06, 0.96)
	style.border_color = Color(0.28, 0.72, 0.55, 0.72)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style

func _emit_resume() -> void:
	resume_requested.emit()

func _emit_restart() -> void:
	restart_requested.emit()

func _emit_menu() -> void:
	menu_requested.emit()
