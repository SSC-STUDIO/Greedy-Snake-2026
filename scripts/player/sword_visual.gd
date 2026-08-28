class_name SwordVisual
extends Polygon2D
## 程序化锯齿巨剑（纯表现层）。
## 锈色剑身（RUST_DARK）+ RUST_LIGHT 高光上刃 + 下刃锯齿 + 渐窄尖端，
## 全长约 54px、宽约 10px，与角色不成比例的巨剑感。
## 握柄（旋转 pivot）即本节点原点；三阶段摆动旋转由 MeleeCombat._tween_sword
## 驱动（待机/前摇/判定/后摇），朝向翻转继承父节点 Visual 的 scale.x。
## 本脚本只负责绘制，不做任何旋转或朝向逻辑。

const GRIP_LEN := 6.0          # 握柄长度（原点后方）
const GRIP_HALF_W := 1.6       # 握柄半宽
const GUARD_X := 2.0           # 护手厚度
const GUARD_HALF_W := 6.2      # 护手半宽（略宽于剑身）
const BLADE_TOP_Y := -5.0      # 上刃（高光边）
const BLADE_BOT_Y := 4.2       # 下刃谷底
const TOOTH_Y := 6.3           # 锯齿齿尖
const TIP_X := 54.0            # 剑尖（顶端渐窄汇聚点）
const TOOTH_SPAN := 5.0        # 锯齿间距


func _ready() -> void:
	color = Palette.RUST_DARK
	polygon = _build_blade_points()
	_build_highlight()


## 剑身轮廓：握柄 → 护手 → 平直上刃 → 渐窄尖端 → 锯齿下刃折返 → 握柄。
func _build_blade_points() -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.append(Vector2(-GRIP_LEN, -GRIP_HALF_W))
	pts.append(Vector2(0.0, -GRIP_HALF_W))
	pts.append(Vector2(0.0, -GUARD_HALF_W))
	pts.append(Vector2(GUARD_X, -GUARD_HALF_W))
	pts.append(Vector2(GUARD_X, BLADE_TOP_Y))
	pts.append(Vector2(TIP_X - 8.0, BLADE_TOP_Y))
	pts.append(Vector2(TIP_X, 0.0))
	pts.append(Vector2(TIP_X - 6.0, BLADE_BOT_Y))
	# 下刃锯齿：自尖端向护手折返，齿尖朝外（+y，挥砍的引导刃）。
	var x := TIP_X - 10.0
	while x > GUARD_X + TOOTH_SPAN:
		pts.append(Vector2(x - TOOTH_SPAN * 0.35, BLADE_BOT_Y))
		pts.append(Vector2(x - TOOTH_SPAN * 0.7, TOOTH_Y))
		x -= TOOTH_SPAN
	pts.append(Vector2(GUARD_X, GUARD_HALF_W))
	pts.append(Vector2(0.0, GUARD_HALF_W))
	pts.append(Vector2(0.0, GRIP_HALF_W))
	pts.append(Vector2(-GRIP_LEN, GRIP_HALF_W))
	return pts


## RUST_LIGHT 高光：沿上刃与尖端的窄条，叠在剑身填充之上。
func _build_highlight() -> void:
	var highlight := Polygon2D.new()
	highlight.name = "Highlight"
	highlight.color = Palette.RUST_LIGHT
	highlight.polygon = PackedVector2Array([
		Vector2(GUARD_X, BLADE_TOP_Y),
		Vector2(TIP_X - 8.0, BLADE_TOP_Y),
		Vector2(TIP_X, 0.0),
		Vector2(TIP_X - 2.5, 1.2),
		Vector2(TIP_X - 8.0, BLADE_TOP_Y + 1.4),
		Vector2(GUARD_X, BLADE_TOP_Y + 1.4)
	])
	add_child(highlight)
