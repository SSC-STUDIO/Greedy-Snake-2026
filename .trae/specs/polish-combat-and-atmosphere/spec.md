# 精细化改造：战斗表现与陵墓氛围（Polish Combat & Atmosphere）Spec

## Why

游戏机制（重量移动、弹反、锈核、毒素）已经可玩，但主题承诺的「余烬骑士扛锯齿巨剑在工业陵墓里探索」在视听上几乎不可见：玩家没有行走动画、巨剑从不出现、挥砍没有弧光、没有粒子与屏幕震动、敌人受击无反馈、背景是空白。本次改造把这些主题核心的「感觉」补上。

## What Changes

- **网络素材选型与接入（首要环节）**：上网检索并下载匹配主题的免费可商用（CC0/免版税）素材包，替换/补充现有 Kenney 基础包，统一落入 `assets/external/` 与 `assets/kenney_clean/`，并记录来源与许可。已初步锁定的候选：
  - **VISTA — 10 Free Parallax Backgrounds**（najjar320, itch.io, CC0）：含 `flue` 工业烟囱/煤气罐场景，4 层无缝视差、384×216、附带 Godot ParallaxLayer 用法与滚动系数 JSON —— 直接充当陵墓远景
  - **Pixel art sword slash effect**（tbbk, OpenGameArt, CC0）：64×47 挥砍特效精灵表 —— 弧光素材
  - **PVFX Foundry**（nerijs, itch.io, CC0）：22 个 96×96/20fps 战斗+环境 VFX —— 火花/尘土/烟雾
  - **Alenia 10 Atmospheric VFX Pack**（CC0）：320×180 环境氛围特效（余烬/碎屑/光尘）
  - **8 Directional Greatsword Knight**（Hormelz, itch.io, CC0）：Idle/Walk/Slash 免费动画 —— 巨剑骑士参考或直接用作玩家视觉
  - **Pixel Factory Interior Props Pack**（Syntaxes of Play, itch.io, CC0）：工业道具 —— 关卡装饰
  - 备选：Free Industrial Zone Tileset（free-game-assets）、CC0 Sword Icons（OpenGameArt）
  - 检索仍将继续：若发现更贴合「锈/废土/地下陵墓」的免费包，优先替换；每接入一个包需写明来源 URL 与许可证
- **锯齿巨剑可视化**：玩家身后常驻一把锯齿巨剑（优先采用下载素材，回退为程序化多边形），随朝向翻转，挥砍时跟随 MeleeCombat 的前摇/判定/后摇阶段摆动。
- **挥砍弧光**：判定帧出现一次性的弧形拖尾（优先采用下载的挥砍特效精灵表，回退程序化渐隐），弹反成功时弧光变为亮白并加强。
- **玩家动画**：接入行走帧（walk1/walk2）形成行走循环；起跳/落地姿态区分；受击闪红。
- **粒子系统**（headless 下自动禁用）：
  - 落地/冲刺扬尘
  - 余烬骑士周身漂浮的橙色余烬粒子（主题标识）
  - 腐液坑冒泡
  - 受击火花、敌人死亡时锈屑迸溅
- **屏幕震动**：Juice autoload 增加 camera shake（命中轻震、弹反中震、玩家死亡重震），与既有 hit-stop/slow-mo 并行。
- **敌人反馈**：受击白闪（shader modulate）、Spitter 蓄力时的吐息预告（张口/变色）。
- **视差背景**：Level01 增加两层剪影视差（远处齿轮/铁梁剪影 + 应急橙灯光晕），贴合「死去的机械文明陵墓」。
- **HUD 危险反馈**：毒素 ≥80% 时毒素条与标签脉冲；生命 ≤1 时屏幕边缘红色暗角渐入。

非目标（明确不做）：Hookshot 真实钩索、新关卡/Boss、正式 64×64 原创美术、存档系统。

## Impact

- Affected code:
  - `scripts/player/player.gd`（行走动画、剑节点、受击反馈）
  - `scripts/combat/melee_combat.gd`（暴露挥砍阶段给视觉层；弧光挂载点）
  - `scripts/autoload/juice.gd`（新增 shake API + GameEvents 接线）
  - `scripts/autoload/game_events.gd`（如需新增信号）
  - `scripts/enemies/spitter_enemy.gd`、`scrapper_enemy.gd`（受击闪白、蓄力预告）
  - `scripts/interactables/toxin_pool.gd`（冒泡粒子）
  - `scripts/ui/hud.gd`（毒素脉冲、低血暗角）
  - `scenes/levels/Level01_Static.tscn` / `scripts/levels/level01_static.gd`（视差背景挂载）
- 兼容性约束：所有新增视觉代码必须以 `DisplayServer.get_name() == "headless"` 守卫或纯视觉不改逻辑，保证 `tests/` 全绿（现有 7 个测试文件不回归）。
- 不修改任何游戏数值与机制判定。

## ADDED Requirements

### Requirement: 锯齿巨剑可视化
系统 SHALL 在玩家节点上常驻渲染一把与角色不成比例的锯齿巨剑，随朝向翻转；挥砍时剑身按前摇(抬起)→判定(劈下)→后摇(回落)三阶段旋转摆动。

#### Scenario: 待机时可见
- **WHEN** 玩家站在地面未攻击
- **THEN** 巨剑以背负/持握姿态可见于角色侧后，朝向与 facing 一致

#### Scenario: 挥砍摆动
- **WHEN** 玩家按 J 触发 start_swing
- **THEN** 剑在前摇阶段抬起、判定帧劈下至水平、后摇缓落，全程不产生新的碰撞体

### Requirement: 挥砍弧光
系统 SHALL 在近战判定帧生成一个随挥砍方向展开的弧形渐隐拖尾；弹反成功时该弧光 SHALL 提亮为近白色并延长存在时间。

#### Scenario: 普通挥砍
- **WHEN** 判定帧开始
- **THEN** 弧光出现并在约 0.12s 内淡出

#### Scenario: 弹反强化
- **WHEN** 判定帧内弹反投射物成功（GameEvents.parried）
- **THEN** 同屏弧光变亮/加宽，持续约 0.2s

### Requirement: 玩家行走动画
系统 SHALL 在玩家水平速度超过阈值且在地面时，以 2 帧循环（walk1/walk2，约 8 fps）播放行走动画；空中使用 jump 帧；死亡使用 hurt 帧。

#### Scenario: 移动循环
- **WHEN** 玩家在地面以 |velocity.x| > 12 移动
- **THEN** 贴图在 walk1/walk2 间循环切换

### Requirement: 主题粒子
系统 SHALL 提供粒子效果：玩家周身持续飘散的橙色余烬（≤6 粒同时存在）、落地扬尘、冲刺残尘、腐液坑气泡、受击火花、敌人死亡锈屑。全部效果在 headless 模式下 SHALL 不创建任何节点。

#### Scenario: headless 安全
- **WHEN** 以 --headless 运行测试套件
- **THEN** 不实例化 GPUParticles2D/CPUParticles2D，测试全绿

### Requirement: 屏幕震动
Juice SHALL 提供 camera shake（衰减随机偏移），命中敌人轻震、玩家受击中震、弹反中震、死亡重震；震动 SHALL 通过 GameEvents 信号触发且不影响逻辑坐标。

#### Scenario: 弹反震动
- **WHEN** GameEvents.parried 发射
- **THEN** 活动相机在 ~150ms 内做衰减抖动后回到平滑跟随位置

### Requirement: 敌人受击反馈
敌人被命中时 SHALL 白闪 ~80ms；Spitter 在蓄力阶段 SHALL 有可读的变色/张口预告。

#### Scenario: 受击白闪
- **WHEN** 敌人 hurtbox 收到命中
- **THEN** 其 sprite modulate 短暂变白后恢复

### Requirement: 视差背景
Level01_Static SHALL 拥有至少两层（目标 4 层，采用下载的 VISTA `flue` 工业场景）视差背景，随相机以不同速率滚动，不参与碰撞；整体色调 SHALL 与锈墓调色板协调（必要时 modulate 压暗/偏锈红）。

#### Scenario: 视差滚动
- **WHEN** 相机水平移动
- **THEN** 背景各层以不同滚动系数位移，营造纵深

### Requirement: HUD 危险反馈
毒素 ≥80% 时毒素条与标签 SHALL 脉冲（透明度/亮度正弦波动）；生命 ≤1 时 SHALL 出现屏幕红色暗角，生命恢复后消失。

#### Scenario: 毒素告警
- **WHEN** toxin/max_toxin ≥ 0.8
- **THEN** 毒素条呈周期性脉冲且不改变槽宽

### Requirement: 外部素材合规
所有从网络下载的素材 SHALL 为 CC0 或同等免版税许可；每接入一个素材包，其来源 URL 与许可证 SHALL 记录在 `assets/external/CREDITS.md`。

#### Scenario: 素材落位
- **WHEN** 一个新素材包被采用
- **THEN** 原始文件位于 `assets/external/`，裁剪/重制版本位于 `assets/kenney_clean/`，CREDITS.md 同步更新

## MODIFIED Requirements

### Requirement: 视觉表现（原"Kenney 静态贴图接入"）
在原有 stand/jump/hurt 静态帧基础上，补充 walk 循环帧与运行时动画状态机（idle/walk/air/hurt），并叠加巨剑与弧光渲染层；headless 无资源时回退色块不变。

## REMOVED Requirements

无删除项。本次为纯表现层增量。
