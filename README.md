# Rustgrave（锈墓）

2D 像素风 Metroidvania。你是废料堆里复燃的 **余烬骑士**，扛着过重的锯齿巨剑，在死去的机械文明地下陵墓里探索。

本仓库是 **Godot 4 + GDScript** 的可玩脚手架 + 完整设计文档，对应五步创意包（视觉 / GDD / 美术规格 / 程序 / 音频）。

## 打开项目

1. 安装 [Godot 4.3+](https://godotengine.org/download)（4.2 通常也能开，推荐 4.3 或 4.4）。
2. Godot 启动器里 **Import**，选本目录中的 `project.godot`。
3. 主场景已设为 `scenes/levels/TestArena.tscn`，按 F5 运行。

命令行（若 `godot` 在 PATH 上）：

```bat
godot --path "C:\Users\Administrator\OneDrive\Documents\My-Program\Rustgrave"
```

脚手架生成时本机 **PATH 上没有 Godot**。请自行安装 4.3+ 后用编辑器 Import 本目录。不要用 Unity。

## 操作

| 按键 | 动作 |
| --- | --- |
| A / D 或 ← / → | 移动（沉重惯性） |
| Space | 跳跃（落地后可再跳一次） |
| Shift | 冲刺（带无敌帧） |
| J 或 鼠标左键 | 挥砍。判定帧内碰到敌弹 = **弹反** |
| K 或 鼠标右键 | 同样是挥砍（给想按“弹反键”的人） |
| E | 交互（废料堆、插座台、滤芯、净化祠、锈门） |
| 1 / 2 | 把背包里第一枚锈核插入剑的 1 / 2 号插座 |
| F | 尝试钩锁（需已镶嵌 Hookshot Tether；当前仅提示未锻成） |

弹反 **不是** 单独的格挡动作：按设计，巨剑挥砍的 active 帧打中弹丸，就会把它打回去。

## 测试关要做什么

左：平台、跳跃、冲刺。  
中：橙色腐液坑（积毒素；附近有滤芯）。  
右上：喷吐者，练弹反（弹回去可以打它）。  
右：压力板开门 → 废料堆拿到 **熔热锻核** → 插座台或按 1/2 镶嵌 → 融化锈门 → 净化祠。

喷吐者死亡后会掉 **钩锁核**，镶上后 HUD 会显示能力，F 键目前只播提示。

## 已实现 / 仅文档

**已经能玩**

- 可变加速度移动、下落加重、二段跳、冲刺 i-frame
- 带前摇/判定/后摇的重斩，近战 hitbox
- 判定帧弹反投射物
- 压力板、门、废料堆、滤芯、净化祠、锈门
- 毒素槽：满了掉血；滤芯/祠减毒
- 锈核背包与剑上插座，插入后解锁能力 id
- 熔热锻：镶上后可融化测试关锈门
- 平滑镜头 + 按移动方向的水平 look-ahead
- HUD：生命、毒素、插座、提示

**只在文档里（尚未做成关卡/完整技能）**

- 五生态区地图（Scrapyard / Gutterworks / Kiln / Hollow Stack / Abyssal Forge + Furnace Hub）
- Hookshot 的真实钩索运动
- 正式 64×64 像素角色与 16×16 tileset（现为色块占位）
- 音频（见 `docs/audio-mood.md`）
- 存档、Boss、双结局

## 文档

| 文件 | 内容 |
| --- | --- |
| `docs/GDD.md` | 完整中文设计文档 |
| `docs/gdd-prompt.md` | 第二步 GDD 英文 Prompt 原文 |
| `docs/visual-prompt.md` | 第一步视觉 Prompt（可喂 Midjourney/SD） |
| `docs/art-spec.md` | 第三步像素规格与 16 色 |
| `docs/programming-prompt.md` | 第四步程序 Prompt 原文 |
| `docs/audio-mood.md` | 第五步音频 Prompt |

## 目录

```
Rustgrave/
  project.godot
  README.md
  docs/
  scenes/          玩家、相机、敌人、交互、测试关、HUD
  scripts/         分模块 GDScript
  assets/placeholder/
```

代码标识符为英文；GDD 与 README 为中文。

## 调色（占位美术）

- `#3A3A3A` Shadow  
- `#8B4513` Rust Dark  
- `#CD5C5C` Rust Light  
- `#FF8C00` Toxic Glow  
- `#4A6B6B` Teal/Water  

视口 640×360，窗口 1280×720，viewport 拉伸 + 整数倍缩放，纹理过滤 Nearest。

## Testing

Zero-dependency unit/integration suite lives in `tests/`. No GUT/plugin install required.

```powershell
# import once after pulling
& "C:\Program Files\Godot\Godot_v4.7.1-stable_win64_console.exe" --headless --path . --import

# run the full suite (exit code 0 = green)
& "C:\Program Files\Godot\Godot_v4.7.1-stable_win64_console.exe" --headless --path . res://tests/run_tests.tscn
```

- Discovery is automatic: drop a file named `tests/*_test.gd`, extend `TestCase` (`tests/test_case.gd`), write methods starting with `test_`.
- Assertions: `ok(cond)`, `eq(got, expected)`, `almost(f)`. Counters inside signal lambdas must be captured as arrays (`var n := [0]`) because lambdas capture ints by value.
- Fixture helpers live on `TestCase`: `build_floor()`, `spawn_player()`, `flush(frames)`, `wait_until(pred)`.
- Heads-up: drive physics manually through public seams (`PlayerController.physics_tick`, `MeleeCombat.start_swing/tick`) instead of simulating Input; and never mix hand-fed `_process` calls with tree-resident nodes — engine idle frames interleave unpredictably in headless runs.
