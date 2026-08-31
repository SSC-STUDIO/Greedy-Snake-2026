# Rustgrave（锈墓）

2D 像素风 Metroidvania。你是废料堆里复燃的 **余烬骑士**，扛着过重的锯齿巨剑，在死去的机械文明地下陵墓里探索。

本仓库是 **Godot 4 + GDScript** 的可玩垂直切片 + 完整设计文档，对应五步创意包（视觉 / GDD / 美术规格 / 程序 / 音频）。角色为像素帧动画（Fantasy Knight / Gothicvania 系敌人），环境为 ansimuz Gothicvania 素材，音效为 Kenney CC0 音频。

## 打开项目

1. 安装 [Godot 4.7+](https://godotengine.org/download)。
2. Godot 启动器里 **Import**，选本目录中的 `project.godot`。
3. 主场景为 `scenes/ui/TitleScreen.tscn`（标题屏 → 关卡 壹「腐液回廊」），按 F5 运行。

命令行（若 `godot` 在 PATH 上）：

```bat
godot --path "C:\Users\Administrator\OneDrive\Documents\My-Program\Rustgrave"
```

## 操作

| 按键 | 动作 |
| --- | --- |
| A / D 或 ← / → | 移动（沉重惯性） |
| Space | 跳跃（镶余烬核后可二段跳） |
| Shift | 冲刺（带无敌帧） |
| J 或 鼠标左键 | 挥砍。判定帧内碰到敌弹 = **弹反** |
| K 或 鼠标右键 | 同样是挥砍（给想按“弹反键”的人） |
| E | 交互（废料堆、插座台、滤芯、净化祠、锈门） |
| 1 / 2 | 把背包里第一枚锈核插入剑的 1 / 2 号插座 |
| F | 钩锁（需已镶嵌 Hookshot Tether）：钩住锚点把自己拉过缺口 |

弹反 **不是** 单独的格挡动作：按设计，巨剑挥砍的 active 帧打中弹丸，就会把它打回去。

## 关卡里要做什么

左：平台、跳跃、冲刺。  
中：腐液坑（积毒素；附近有滤芯）。  
右上：喷吐者，练弹反（弹回去可以打它）；地面有巡逻冲锋的碎甲者与持盾的齿轮盾卫。  
右：压力板开门 → 废料堆拿到 **熔热锻核** → 插座台或按 1/2 镶嵌 → 融化锈门 → 战前净化祠（赌博）→ 刽子手 → 锻炉残芯（复燃 / 熄灭）。

喷吐者死亡后会掉 **钩锁核**。东侧高台有 **余烬核**（要钩上去）。两核同槽会点亮组合技。

## 已实现 / 仅文档

**已经能玩**

- 可变加速度移动、下落加重、余烬核门禁的二段跳、冲刺 i-frame
- 带前摇/判定/后摇的三段重斩，近战 hitbox
- 判定帧弹反投射物（判定统一在 `MeleeCombat`）；弹反减毒并点燃 2 秒共鸣
- 毒素即燃料：档位越高越锋利，满溢掉血；净化是卸武装
- 锈核共鸣：窑+系绳=熔钩，窑+余烬=爆燃斩，系绳+余烬=摆荡步
- 三种敌人 + 东端刽子手 Boss（半血二阶段）与复燃/熄灭双结局
- 过场：Director 淡变/字幕/镜头托管（苏醒、初毒、初核、初弹反、Boss、结局）
- 像素帧动画角色：玩家 Fantasy Knight，敌人 Hell Beast / Hell Hound / Undead Executioner（`CharFrames` + `FrameAnimSprite` 逐帧驱动）
- Gothicvania 环境：无缝视差背景、双皮肤平台、腐液毒池、剪影层与漂雾
- 墓园昼夜（约 20 分钟一轮）与薄雾 / 雨 / 锈雨 / 浓雾 / 余烬风；室内锁暖光；夜里点燃的余烬巢有被平台挡住的暖光
- 压力板、门、废料堆、滤芯、净化祠、锈门
- 毒素槽：满了掉血，同时驱动能力档位；滤芯/祠减毒
- 锈核背包与剑上插座（窑核 / 系绳核 / 余烬核），插入后解锁能力
- 熔热锻：镶上后可融化锈门；钩锁：钩住锚点的真实拉索运动
- 存档与余烬巢重生
- 平滑镜头 + 按移动方向的水平 look-ahead；打击停顿/震屏等打击感反馈
- 像素 UI：`assets/ui/theme_rust.tres` 统一字体/配色/9-slice 面板，字体为 Fusion Pixel（中英全覆盖）
- 标题屏菜单（开始/继续/操作说明/退出，键鼠导航 + 余烬粒子）、暂停菜单、操作说明面板、死亡覆盖层
- HUD：心槽血量、分段毒素槽、剑核/袋中、交互提示、播报横幅、低血量血雾
- Kenney CC0 音效集（挥砍/受击/弹反/拾取/UI，见 `scripts/autoload/sfx.gd`）

**只在文档里（尚未做成关卡/完整技能）**

- 五生态区地图（Scrapyard / Gutterworks / Kiln / Hollow Stack / Abyssal Forge + Furnace Hub）

## 文档

| 文件 | 内容 |
| --- | --- |
| `docs/architecture.md` | 代码结构速查（Autoload、Level01 拆分、玩家子节点） |
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
  scenes/            玩家、相机、敌人、交互、关卡、HUD、标题屏
  scripts/           分模块 GDScript（autoload / player / enemies / combat / ...）
  assets/characters/ 切好帧的角色像素动画（CharFrames 目录约定）
  assets/env/        环境贴图裁切件（Gothicvania）
  assets/fonts/      像素字体（Fusion Pixel / Jacquard 24，均 OFL）
  assets/ui/         程序化生成的像素 UI 套件 + theme_rust.tres（见 tools/gen_ui_kit.py）
  assets/external/   原始素材包与 CREDITS.md
  icon.png/.ico      游戏图标（见 tools/gen_icon.py）
  tests/             零依赖单测/集成测试
```

代码标识符为英文；GDD 与 README 为中文。

## 素材署名

完整来源与许可见 `assets/external/CREDITS.md`：

- **环境 / 敌人像素**：Luis Zuno (ansimuz) — Gothicvania Cemetery / Church / Patreon's Collection、Industrial Parallax（CC0 / 公有领域 / 免费使用）
- **玩家角色**：Nauris Amatnieks (aamatniekss) — Fantasy Knight（免费商用许可）
- **齿轮盾卫**：Kronovi (DarkPixel) — Undead Executioner（免费商用许可）
- **音效**：Kenney（CC0）；**特效帧**：CodeManu Free Pixel Effects Pack、tbbk sword slash（CC0）
- **字体**：Fusion Pixel Font（TakWolf，OFL 1.1，正文全字号）、Jacquard 24（Tyler Finck，OFL 1.1，仅离线烘 RUSTGRAVE 标题牌）
- **UI 套件**：本项目用 PIL 程序化绘制（`tools/gen_ui_kit.py`），不是 AI 生图
- **游戏图标**：同上程序化绘制（`tools/gen_icon.py`），16x16 栅格起稿后整数倍放大
- **标题屏 keyart**：本项目 AI 生成（唯一保留的 AI 图；游戏内角色/环境均为像素素材）

## 调色（基础色板）

占位/程序化元素沿用的 16 色基调（见 `scripts/data/palette.gd`）：

- `#3A3A3A` Shadow  
- `#8B4513` Rust Dark  
- `#CD5C5C` Rust Light  
- `#FF8C00` Toxic Glow  
- `#4A6B6B` Teal/Water  

窗口 1280×720，viewport 拉伸，全局纹理过滤 Nearest（像素锐利）。

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
