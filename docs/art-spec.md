# Rustgrave — 像素美术规格（第三步）

给像素画师或 Aseprite / 像素 AI 使用。下面英文块为原始 Prompt，请原样复制。

## Art Asset Specification Prompt（原文，请原样复制）

```
Generate a 2D pixel art asset sheet for an action game.

Resolution: 64x64 pixels for the protagonist (Idle, Run, Slash, Deflect).

Tileset Size: 16x16 pixel tiles, arranged in a 256x256 grid.

Palette Restriction (GB-style + Rust): Maximum of 16 colors. Dominant colors: #3A3A3A (Shadow), #8B4513 (Rust Dark), #CD5C5C (Rust Light), #FF8C00 (Toxic Glow), #4A6B6B (Teal/Water).

Style Guide: No anti-aliasing, use sharp jagged edges (chunky pixels) to emphasize the "rusty" and "broken" theme. The protagonist should have a long tattered cloak to emphasize movement during combat.
```

## 硬性规格

| 资源 | 尺寸 | 备注 |
| --- | --- | --- |
| 主角精灵 | 64×64 | 动作至少：Idle / Run / Slash / Deflect（弹反即挥砍判定帧） |
| 建议额外帧 | 64×64 | Jump, Fall, Dash, Hurt, Land, Interact |
| 地砖 | 16×16 | 禁止半像素 |
| 图块集画布 | 256×256 | 16×16 网格 = 16×16 个 tile |
| 敌人 | 32×32 或 48×32 | 与 16 网格对齐 |
| 投射物 | 8×8 或 16×8 | 锯齿金属碎片 / 熔渣弹 |
| UI | 以 16 为基数 | 视口 640×360，整数倍放大 |

## 技术约束

- **禁止抗锯齿**、禁止半透明混合描边、禁止高斯模糊。
- 边缘用硬锯齿（chunky pixels）表现锈蚀与断裂。
- 主角必须有 **长破披风**，跑、斩、冲时披风是读动作的主要剪影。
- 引擎导入：Filter = **Nearest**，Mipmaps 关，不要压缩成失真格式。
- 角色脚底锚点放在 64×64 画布底部中心，预留 1–2 像素给落地尘。

## 16 色调色板（GB-style + Rust）

前 5 个为需求指定的主色；其余 11 个为项目补全色，用于阴影、高光、混凝土与雾，仍计入 16 色上限。

| # | Hex | 名称 | 用途 |
| --- | --- | --- | --- |
| 0 | `#1A1412` | Void | 最深洞穴、轮廓 |
| 1 | `#3A3A3A` | **Shadow** | 指定。钢梁暗部、盔甲 |
| 2 | `#5E5A56` | Iron | 中性金属 |
| 3 | `#8A8680` | Concrete | 混凝土、尘 |
| 4 | `#C8C2B8` | Pale Metal | 边缘高光（极少使用） |
| 5 | `#4A2A18` | Rust Shadow | 锈的最暗层 |
| 6 | `#8B4513` | **Rust Dark** | 指定。主体锈层 |
| 7 | `#A0522D` | Rust Mid | 过渡 |
| 8 | `#CD5C5C` | **Rust Light** | 指定。新断面、披风衬里 |
| 9 | `#E8B090` | Ember Ash | 余烬、皮肤高光 |
| 10 | `#7A3A00` | Toxic Dark | 泥浆深处 |
| 11 | `#FF8C00` | **Toxic Glow** | 指定。毒素、应急灯 |
| 12 | `#FFC14A` | Ember | 炉心、斩击闪光 |
| 13 | `#2A4040` | Teal Deep | 积水暗部 |
| 14 | `#4A6B6B` | **Teal/Water** | 指定。积水、滤芯、UI 安全色 |
| 15 | `#7FA8A0` | Fog Teal | 雾、远景、净化光 |

当前脚手架用 ColorRect / Polygon2D 占位，只使用指定主色 + Void，待正式像素替换。

## 主角剪影要点

- 头小、剑极大（剑长约身长 1.3–1.6 倍），强调 Weight & Momentum。
- 披风尾端撕成 2–3 片破布，Idle 时轻微下垂，Slash 时甩向反方向。
- 不要把角色画“帅而干净”；表面应有锈斑与补丁。

## 图块集分区建议（256×256）

```
[0,0]    地面 / 锈铁地板
[4,0]    混凝土墙与裂隙
[8,0]    齿轮、管道、铆钉装饰
[12,0]   危险：栅栏、熔渣、毒素边缘
[0,8]    背景钢梁（可作装饰 tile）
[8,8]    门、压力板、废料堆、插座台
```

脚手架里的测试关使用 16px 几何占位，等待此规格的正式 tile 替换。
