class_name HookAnchor
extends Area2D
## 钩锁锚点：钩索（HookshotTether）的挂接目标。
## 视觉（TEAL 呼吸环 + EMBER 内芯）固化在 HookAnchor.tscn，可在编辑器里直接调。


func _ready() -> void:
	add_to_group("hook_anchor")
	monitoring = false


func _process(_delta: float) -> void:
	# 轻微呼吸：环缓慢胀缩，提示"可以钩"。
	var t := Time.get_ticks_msec() / 1000.0
	var s := 1.0 + 0.12 * sin(t * 2.2)
	($Ring as Polygon2D).scale = Vector2(s, s)
