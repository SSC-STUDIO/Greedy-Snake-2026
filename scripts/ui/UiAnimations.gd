extends Node
class_name UiAnimations

## UI 动画工具类 - 提供可复用的动画效果

## 按钮按下动画（缩放效果）
static func button_press_animation(button: Button) -> void:
	if not SettingsStore.animations_on:
		return
	var tween: Tween = button.create_tween()
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2(0.96, 0.96), 0.08)
	tween.tween_property(button, "scale", Vector2.ONE, 0.12).set_delay(0.08)

## 给按钮绑定统一的悬停/按下动效。按钮缩放以中心为轴，避免抖动。
static func bind_button_motion(button: Button, hover_scale: Vector2 = Vector2(1.025, 1.025), press_scale: Vector2 = Vector2(0.965, 0.94)) -> void:
	_center_pivot(button)
	button.resized.connect(func() -> void:
		_center_pivot(button)
	)
	button.mouse_entered.connect(func() -> void:
		if not SettingsStore.animations_on:
			return
		_tween_control_scale(button, hover_scale, 0.12, Tween.TRANS_QUAD, Tween.EASE_OUT)
	)
	button.mouse_exited.connect(func() -> void:
		if not SettingsStore.animations_on:
			return
		_tween_control_scale(button, Vector2.ONE, 0.16, Tween.TRANS_QUART, Tween.EASE_OUT)
	)
	button.button_down.connect(func() -> void:
		if not SettingsStore.animations_on:
			return
		_tween_control_scale(button, press_scale, 0.07, Tween.TRANS_QUAD, Tween.EASE_OUT)
	)
	button.button_up.connect(func() -> void:
		if not SettingsStore.animations_on:
			return
		var target: Vector2 = hover_scale if button.is_hovered() else Vector2.ONE
		_tween_control_scale(button, target, 0.16, Tween.TRANS_BACK, Tween.EASE_OUT)
	)

static func _center_pivot(control: Control) -> void:
	var basis: Vector2 = control.size if control.size.length_squared() > 1.0 else control.custom_minimum_size
	control.pivot_offset = basis * 0.5

static func _tween_control_scale(control: Control, target: Vector2, duration: float, trans_type: Tween.TransitionType, ease_type: Tween.EaseType) -> void:
	var tween: Tween = control.create_tween()
	tween.tween_property(control, "scale", target, duration).set_trans(trans_type).set_ease(ease_type)

## 淡入效果
static func fade_in(control: Control, duration: float = 0.25) -> void:
	if not SettingsStore.animations_on:
		control.modulate.a = 1.0
		control.show()
		return
	control.modulate.a = 0.0
	control.show()
	var tween: Tween = control.create_tween()
	tween.tween_property(control, "modulate:a", 1.0, duration)

## 淡出效果
static func fade_out(control: Control, duration: float = 0.2) -> void:
	if not SettingsStore.animations_on:
		control.hide()
		return
	var tween: Tween = control.create_tween()
	tween.tween_property(control, "modulate:a", 0.0, duration)
	tween.tween_callback(control.hide)

## 缩放弹入效果
static func scale_in(control: Control, from: float = 0.85, duration: float = 0.3) -> void:
	if not SettingsStore.animations_on:
		control.scale = Vector2.ONE
		control.show()
		return
	control.scale = Vector2(from, from)
	control.show()
	var tween: Tween = control.create_tween()
	tween.set_parallel(true)
	tween.tween_property(control, "modulate:a", 1.0, duration)
	tween.tween_property(control, "scale", Vector2.ONE, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

## 淡入+缩放组合效果
static func fade_scale_in(control: Control, duration: float = 0.35) -> void:
	if not SettingsStore.animations_on:
		control.modulate.a = 1.0
		control.scale = Vector2.ONE
		control.show()
		return
	control.modulate.a = 0.0
	control.scale = Vector2(0.9, 0.9)
	control.show()
	var tween: Tween = control.create_tween()
	tween.set_parallel(true)
	tween.tween_property(control, "modulate:a", 1.0, duration)
	tween.tween_property(control, "scale", Vector2.ONE, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

## 数字滚动动画
static func number_rolling(label: Label, from: int, to: int, duration: float = 0.4) -> void:
	if not SettingsStore.animations_on or from == to:
		label.text = str(to)
		return
	var tween: Tween = label.create_tween()
	tween.tween_method(func(value: int) -> void: label.text = str(value), from, to, duration)

## 卡片依次入场动画
static func cards_staggered_entry(cards: Array, delay: float = 0.08) -> void:
	if not SettingsStore.animations_on:
		for raw_card in cards:
			if is_instance_valid(raw_card) and raw_card is Control:
				var card: Control = raw_card as Control
				card.modulate.a = 1.0
				card.scale = Vector2.ONE
				card.show()
		return
	for i in range(cards.size()):
		var raw_card = cards[i]
		if not is_instance_valid(raw_card) or not raw_card is Control:
			continue
		var card: Control = raw_card as Control
		card.modulate.a = 0.0
		card.scale = Vector2(0.85, 0.85)
		card.show()
		var tween: Tween = card.create_tween()
		tween.set_parallel(true)
		tween.tween_property(card, "modulate:a", 1.0, 0.3).set_delay(i * delay)
		tween.tween_property(card, "scale", Vector2.ONE, 0.3).set_delay(i * delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

## 脉冲放大效果（用于连击高亮等）
static func pulse_scale(control: Control, scale_to: float = 1.2, duration: float = 0.25) -> void:
	if not SettingsStore.animations_on:
		return
	var tween: Tween = control.create_tween()
	tween.tween_property(control, "scale", Vector2(scale_to, scale_to), duration * 0.4)
	tween.tween_property(control, "scale", Vector2.ONE, duration * 0.6)
