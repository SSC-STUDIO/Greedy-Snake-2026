extends Node
class_name UiAnimations

## UI 动画工具类 - 提供可复用的动画效果

## 按钮按下动画（缩放效果）
static func button_press_animation(button: Button) -> void:
	if not SettingsStore.animations_on:
		return
	var tween := button.create_tween()
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2(0.96, 0.96), 0.08)
	tween.tween_property(button, "scale", Vector2.ONE, 0.12).set_delay(0.08)

## 淡入效果
static func fade_in(control: Control, duration := 0.25) -> void:
	if not SettingsStore.animations_on:
		control.modulate.a = 1.0
		control.show()
		return
	control.modulate.a = 0.0
	control.show()
	var tween := control.create_tween()
	tween.tween_property(control, "modulate:a", 1.0, duration)

## 淡出效果
static func fade_out(control: Control, duration := 0.2) -> void:
	if not SettingsStore.animations_on:
		control.hide()
		return
	var tween := control.create_tween()
	tween.tween_property(control, "modulate:a", 0.0, duration)
	tween.tween_callback(control.hide)

## 缩放弹入效果
static func scale_in(control: Control, from := 0.85, duration := 0.3) -> void:
	if not SettingsStore.animations_on:
		control.scale = Vector2.ONE
		control.show()
		return
	control.scale = Vector2(from, from)
	control.show()
	var tween := control.create_tween()
	tween.set_parallel(true)
	tween.tween_property(control, "modulate:a", 1.0, duration)
	tween.tween_property(control, "scale", Vector2.ONE, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

## 淡入+缩放组合效果
static func fade_scale_in(control: Control, duration := 0.35) -> void:
	if not SettingsStore.animations_on:
		control.modulate.a = 1.0
		control.scale = Vector2.ONE
		control.show()
		return
	control.modulate.a = 0.0
	control.scale = Vector2(0.9, 0.9)
	control.show()
	var tween := control.create_tween()
	tween.set_parallel(true)
	tween.tween_property(control, "modulate:a", 1.0, duration)
	tween.tween_property(control, "scale", Vector2.ONE, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

## 数字滚动动画
static func number_rolling(label: Label, from: int, to: int, duration := 0.4) -> void:
	if not SettingsStore.animations_on or from == to:
		label.text = str(to)
		return
	var tween := label.create_tween()
	tween.tween_method(func(value: int) -> void: label.text = str(value), from, to, duration)

## 卡片依次入场动画
static func cards_staggered_entry(cards: Array, delay := 0.08) -> void:
	if not SettingsStore.animations_on:
		for card in cards:
			if is_instance_valid(card) and card is Control:
				card.modulate.a = 1.0
				card.scale = Vector2.ONE
				card.show()
		return
	for i in range(cards.size()):
		var card = cards[i]
		if not is_instance_valid(card) or not card is Control:
			continue
		card.modulate.a = 0.0
		card.scale = Vector2(0.85, 0.85)
		card.show()
		var tween := card.create_tween()
		tween.set_parallel(true)
		tween.tween_property(card, "modulate:a", 1.0, 0.3).set_delay(i * delay)
		tween.tween_property(card, "scale", Vector2.ONE, 0.3).set_delay(i * delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

## 脉冲放大效果（用于连击高亮等）
static func pulse_scale(control: Control, scale_to := 1.2, duration := 0.25) -> void:
	if not SettingsStore.animations_on:
		return
	var tween := control.create_tween()
	tween.tween_property(control, "scale", Vector2(scale_to, scale_to), duration * 0.4)
	tween.tween_property(control, "scale", Vector2.ONE, duration * 0.6)
