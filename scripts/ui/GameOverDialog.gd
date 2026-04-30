extends Control

signal restart_requested
signal menu_requested

const NeonAssetsData := preload("res://scripts/ui/NeonAssets.gd")
const RunDataUtil := preload("res://scripts/data/RunData.gd")

var _score_label: Label
var _detail_label: Label
var _record_label: Label

func _ready() -> void:
	_build()
	hide()

func show_result(result) -> void:
	var summary := {}
	if result is Dictionary:
		summary = result
	else:
		summary = {"score": int(result)}
	var tags: Array = summary.get("build_tags", [])
	_score_label.text = "Score  %d" % int(summary.get("score", 0))
	_detail_label.text = "Time %s  Kills %d  Combo %d\nDeath  %s\nBuild  %s" % [
		RunDataUtil.format_duration(float(summary.get("duration", 0.0))),
		int(summary.get("kills", 0)),
		int(summary.get("max_combo", 0)),
		String(summary.get("death_reason", "Unknown")),
		", ".join(tags) if not tags.is_empty() else "none",
	]
	var record: Dictionary = summary.get("record", {})
	var record_text := "Best  %d" % int(record.get("best_score", RunRecords.get_best_score()))
	if bool(record.get("is_record", false)):
		record_text = "New record  %d" % int(record.get("best_score", 0))
	elif int(record.get("previous_best", 0)) > 0:
		var gap := int(record.get("previous_best", 0)) - int(summary.get("score", 0))
		if gap > 0:
			record_text = "Best  %d  Gap  %d" % [int(record.get("previous_best", 0)), gap]
	_record_label.text = "%s  Seed %d" % [record_text, int(summary.get("challenge_seed", RunRecords.daily_seed()))]
	show()

func _build() -> void:
	var background := TextureRect.new()
	background.texture = NeonAssetsData.atlas_texture(NeonAssetsData.MENU_BACKGROUNDS, NeonAssetsData.GAME_OVER_BG)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.48)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(430, 390)
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_bottom", 26)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "Game Over"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(1.0, 0.58, 0.46))
	layout.add_child(title)

	_score_label = Label.new()
	_score_label.text = "Score  0"
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.add_theme_font_size_override("font_size", 24)
	_score_label.add_theme_color_override("font_color", Color(0.88, 1.0, 0.92))
	layout.add_child(_score_label)

	_detail_label = Label.new()
	_detail_label.text = ""
	_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_label.add_theme_font_size_override("font_size", 16)
	_detail_label.add_theme_color_override("font_color", Color(0.74, 0.86, 0.82))
	layout.add_child(_detail_label)

	_record_label = Label.new()
	_record_label.text = ""
	_record_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_record_label.add_theme_font_size_override("font_size", 15)
	_record_label.add_theme_color_override("font_color", Color(0.94, 1.0, 0.66))
	layout.add_child(_record_label)

	layout.add_child(_make_button("Restart", Callable(self, "_emit_restart")))
	layout.add_child(_make_button("Menu", Callable(self, "_emit_menu")))

func _make_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(220, 44)
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(func() -> void:
		AudioBus.play_button()
		callback.call()
	)
	return button

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.04, 0.045, 0.98)
	style.border_color = Color(0.9, 0.38, 0.24, 0.72)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style

func _emit_restart() -> void:
	restart_requested.emit()

func _emit_menu() -> void:
	menu_requested.emit()
