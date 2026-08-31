# Rustgrave 角色像素美术替换计划

> 生成时间：2026-08-31。本文档只做素材选型与接线规划，**未改动任何现有 .gd / .tscn / project.godot / CREDITS.md**。
> 所有新素材已通过 `godot --headless --import` 验证，导入无报错。

---

## 1. 选型总览

| 游戏角色 | 选定素材 | 来源包 | 动作覆盖 | 原图朝向 |
|---|---|---|---|---|
| **玩家** | Fantasy Knight（暗色版 Colour1 / NoOutline） | aamatniekss `FreeKnight_v1` | idle/run/jump/fall/attack1/attack2/combo/roll/dash/hurt/death/turn | **右** |
| 玩家备选 B | Gothic Hero | ansimuz Gothicvania Patreon 合集 | idle/run/jump/attack/crouch/crouch_slash/hurt/jump_attack/climb（**无死亡**） | 右 |
| 玩家备选 C | Cemetery Hero | ansimuz Gothicvania Cemetery 完整包 | idle/run/jump/attack/crouch/hurt（**无死亡**） | 右 |
| **Spitter（吐毒怪）** | Hell Beast（重新主题化为"喷吐炉渣的守墓兽"） | ansimuz Patreon 合集 | idle/attack(吐息)/death(烈焰焚毁)/projectile(火球3帧) | **左** |
| **Scrapper（冲击怪）** | Hell Hound | ansimuz Patreon 合集 | idle/walk/run/jump（死亡用通用 enemy-death 特效） | **左** |
| **GearShield（持盾重甲怪）** | Undead Executioner（重新主题化为"锈甲刽子手"） | DarkPixel-Kronovi | idle/idle2/attack(13帧双段挥砍)/skill/summon/death(18帧) + 召唤幽灵3动作 | **左** |
| Boss 备选 | 同上 Executioner（本身就是 boss 级），或 Nightmare 梦魇马 | Kronovi / ansimuz | Nightmare: idle/gallop | 左 |
| 飞行怪备选 | Flying Demon / Fire Skull / Ghost | ansimuz Patreon 合集 | demon: idle/attack；skull: fly；ghost: appear/idle/attack/vanish | 左 |

**玩家候选对比图（idle + 攻击帧，3 倍放大）：`docs/player_candidates_comparison.png`**

选 Fantasy Knight 的理由：三个候选中唯一有**死亡（10帧）+ 翻滚（12帧）+ dash（2帧）+ 两套独立挥砍 + 完整连击**的，与游戏现有 dash/两段攻击机制一一对应；暗色哑光配色与 Gothicvania 紫暗环境同代感强；角色实际高约 37px ≈ 2.3 格（16px tile），正好在需求的 32~48px 区间。Gothic Hero 风格上最"ansimuz 正统"，但缺死亡动画，列为备选。

---

## 2. 已下载包与许可证据

### 2.1 ansimuz — Gothicvania Patreon's Collection（Gothic Hero / Hell Beast / Hell Hound / Demon / Fire Skull / Ghost / Nightmare）
- 存放：`assets/external/gothicvania_patreon/`
- 来源：https://opengameart.org/content/gothicvania-patreons-collection （zip 直链下载成功）
- 许可原文（OGA 页面 Copyright/Attribution Notice）：**"by ansimuz (Not required but appreciated it)"** —— 免费使用，署名非必需。我们仍建议署名。

### 2.2 ansimuz — GothicVania Cemetery Pack 完整版（Cemetery Hero / skeleton / ghost / hell-gato / enemy-death）
- 存放：`assets/external/gothicvania_cemetery/Sprites/`（环境部分此前已在用，本次补齐角色 Sprites）
- 来源：https://opengameart.org/content/gothicvania-cemetery-pack
- 许可原文：**"Artwork created by Luis Zuno @ansimuz. License for Everyone. Public domain and free to use on whatever you want, personal or commercial. Credit is not required but appreciated."** —— 公有领域。

### 2.3 ansimuz — Hell Hound（独立包，与 Patreon 合集内容相同）
- 来源：https://opengameart.org/content/hell-hound-character （已下载至 `_downloads/hell_hound/`，未入库——直接用 Patreon 合集里的同图即可）
- 注意：该独立页许可为 **"Credit to ansimuz.com is required"**（itch 页标 CC-BY 4.0）。我们采用的是 Patreon 合集版本（署名非必需），但建议统一署名 ansimuz，两边都覆盖。

### 2.4 aamatniekss — Fantasy Knight (FreeKnight_v1)
- 存放：`assets/external/free_knight/FreeKnight_v1/`（含 Colour1/Colour2 × Outline/NoOutline 四套）
- 来源页：https://aamatniekss.itch.io/fantasy-knight-free-pixelart-animated-character （文件经公开镜像仓库 github.com/SenZmaKi/gyattsouls 获取，与官方 FreeKnight_v1.zip 同构）
- 许可原文（itch 页面）：**"LICENCE: This asset pack can be used in both free and commercial projects. You can modify it to suit your own needs. Credit is not necessary, but highly appreciated. You may not redistribute or resell the assets on their own… The assets can't be used in AI creations."** —— 允许免费/商业游戏使用，可修改；不得单独转售/再分发素材本体。
- 官方帧数说明：角色实际约 38×20px，画布 120×80（部分动作出画布所以画布大）。

### 2.5 DarkPixel-Kronovi — Boss: Undead Executioner
- 存放：`assets/external/undead_executioner/`（9 张 spritesheet）
- 来源页：https://darkpixel-kronovi.itch.io/undead-executioner （文件经公开镜像仓库 github.com/adithya-gv/MythBusters 获取）
- 许可原文（itch 页面）：**"You are free to edit the sprite once you downloaded it and you can use it for commercial and non-commercial use, credits are not required but always deeply appreciated."**

### 2.6 本地已有（此前已下载、本次盘点确认可用）
`assets/external/gothicvania_church/SPRITES/`（Gothicvania Church 包，ansimuz）：
- `player/`：拳脚系主角（idle4/walk6/jump2/fall2/hurt2/crouch2/kick5/punch6/crouch-kick5/flying-kick2）——**无剑、无死亡**，不适合本作骑士玩家，保留备用。
- `wizard/`：idle5 + fire10 —— 可做备选施法系 Spitter。
- `angel/`：idle8 + attack3 —— 备选远程/飞行怪。
- `burning-ghoul/`：8 帧行走（两个配色）—— 备选杂兵。
- `fx/`：fireball 3 帧、enemy-death 9 帧 —— 通用弹体/死亡特效。

---

## 3. 切帧成果（assets/characters/）

命名规范：`assets/characters/<角色>/<动作>/<动作>_<序号>.png`，同一动作内画布统一、脚底基线一致。
`pad_bottom` = 帧内容距画布底边的透明像素行数（对齐脚底用）；`content_h` = 角色实际像素高。

### player_fantasy_knight（画布全部 120×80，pad_bottom=0~1，朝右）
| 动作 | 帧数 | content_h | 建议 fps | 循环 |
|---|---|---|---|---|
| idle | 10 | 37 | 10 | 是 |
| run | 10 | 36 | 12 | 是 |
| jump | 3 | 37 | 10 | 否 |
| jump_fall | 2 | 36 | 10 | 否（跳-落过渡） |
| fall | 3 | 37 | 10 | 是 |
| attack1 | 4 | 42 | 14 | 否 |
| attack2 | 6 | 40 | 14 | 否 |
| attack_combo | 10 | 42 | 14 | 否（两段连击整段） |
| roll | 12 | 36 | 18 | 否 |
| dash | 2 | 33 | 14 | 否 |
| hurt | 1 | 38 | — | 否 |
| death | 10 | 38 | 10 | 否 |
| turn | 3 | 35 | 14 | 否 |

### player_gothic_hero（朝右，无死亡）
idle 4帧 38×48 / run 12帧 66×48 / jump 5帧 61×77 / attack 6帧 96×48 / crouch 3帧 48×48 / crouch_slash 4帧 80×32 / hurt 3帧 48×48 / jump_attack 6帧 84×80 / climb 7帧 112×96，content_h≈39~42。

### player_cemetery_hero（朝右，无死亡；画布统一 100×59）
idle 4 / run 6 / jump 4 / attack 5 / crouch 1 / hurt 1，content_h≈41~50。

### spitter_hell_beast（朝左）
| 动作 | 帧数 | 画布 | content_h | 建议 fps |
|---|---|---|---|---|
| idle | 5 | 66×67 | 54 | 8（循环） |
| attack | 4 | 64×64 | 62 | 10（吐息前摇→喷吐） |
| death | 6 | 74×160 | 159 | 12（烈焰焚毁，火柱较高） |
| projectile | 3 | 19×16 | 9 | 12（循环，火球） |

### scrapper_hell_hound（朝左，无专用死亡→用 fx_enemy_death）
idle 6帧 64×32 / walk 12帧 64×32 / run 5帧 67×32 / jump 5帧 78×48，content_h 24~41。建议 idle 8fps、walk 10fps、run 14fps、jump 12fps。

### gear_shield_executioner（朝左；画布 100×100，pad_bottom≈16~17）
| 动作 | 帧数 | 建议 fps | 映射 |
|---|---|---|---|
| idle | 4 | 8 | PATROL/待机 |
| idle2 | 8 | 8 | 备用待机（举斧姿态，可当 BLOCK 格挡读条） |
| attack | 13 | 14 | CHARGE 后的两段挥砍 |
| skill | 12 | 12 | 精英技能/砸地（可作 Boss 阶段） |
| summon | 5 | 10 | 召唤（可作 Boss 阶段） |
| death | 18 | 12 | 死亡（化作黑球消散） |
| spirit_appear/idle/death | 3/4/3 | 10 | 召唤物幽灵（可选） |

### 加分素材
- `flying_demon/`：idle 6帧 160×144、attack 11帧 240×192（吐蓝焰）——大型飞行怪/小 Boss。
- `fire_skull/`：fly 8帧 96×112 —— 飞行杂兵。
- `ghost/`：appear 6 / idle 7 / attack(尖啸) 4 / vanish 7 —— 幽魂投射者备选。
- `boss_nightmare/`：idle 4帧 128×96、gallop 4帧 144×96 —— 冲撞型 Boss 坐骑（无攻击帧，只适合冲撞玩法）。
- `skeleton/`：walk 8 + rise(破土) 6（44×52）—— 杂兵/复活演出。
- `fx_enemy_death/`：5帧 44×52 通用敌人死亡烟雾（cemetery 包）。

---

## 4. 缩放与对齐建议（环境 16px tile）

- **全部保持 scale = 1，禁止非整数缩放**（像素图缩放会糊/抖）。相机 zoom 保持现状即可。
- 玩家（骑士 content_h 37px ≈ 2.3 格）：Player.tscn 碰撞体 14×26，脚底在 y=0。AnimatedSprite2D `centered=true` 时设 `offset.y = -40`（=帧高80/2），使 120×80 画布底边贴 y=0；帧内容 pad_bottom=0，脚正好落地。
- Gothic/Cemetery hero 若启用：同理 `offset.y = -画布高/2`（各动作画布不同，建议每动作单独帧库或统一挪到底对齐画布——切帧已保证同动作内基线一致）。
- Hell Beast（54px ≈ 3.4 格）：作为重型喷吐怪合理；death 帧高 160，注意 SpriteFrames 里该动画 offset 需单独设置（火柱向上长，底边仍对齐）。
- Hell Hound（24~29px ≈ 1.7 格）：低矮快速怪，贴地感好。
- Executioner（62~73px ≈ 4 格 + pad_bottom 16）：`offset.y = -(50 - 16) = -34` 使脚底贴 y=0。体型是玩家近两倍——符合"重甲精英/小 Boss"定位；若嫌大，宁可当 Boss 用也不要非整数缩放。
- 朝向：玩家素材朝右、所有敌人素材朝左。现有代码若用 `facing`（+1 右），敌人 `flip_h = facing > 0`，玩家 `flip_h = facing < 0`。

---

## 5. 游戏状态 → 动画映射

### 玩家（scripts/player/player.gd + player_controller.gd + melee_combat.gd）
| 游戏状态 | 动画 | 说明 |
|---|---|---|
| 地面站立 | idle | |
| 地面移动 | run | |
| 上升 | jump | 一次性，末帧保持 |
| 升→降过渡 | jump_fall | 2 帧过渡 |
| 下降 | fall | 循环 |
| dash（有 i-frame） | dash（快速位移感）或 roll（更贴"翻滚闪避"手感，12帧@18fps≈0.67s，比 dash_duration 0.13s 长，建议 dash 用 `dash`，将来做闪避技能再用 roll） | |
| 攻击第 1 段 | attack1 | 4帧@14fps≈0.29s |
| 攻击第 2 段 | attack2 | 6帧@14fps≈0.43s |
| 受击 | hurt | 单帧 + 闪白 |
| 死亡 | death | 播完停在末帧 |

### Spitter（scripts/enemies/spitter_enemy.gd）
idle→常驻循环；蓄力(CHARGE_TIME)→attack 前 2 帧慢放；发射瞬间→attack 后 2 帧 + 从 Muzzle 出 `projectile` 火球（替换现有弹体贴图）；死亡→death（烈焰焚毁）。

### Scrapper（scripts/enemies/scrapper_enemy.gd）
巡逻→walk；发现玩家冲刺→run；冲撞/扑击→jump；受击死亡→fx_enemy_death 通用烟雾（无专用死亡帧）。

### GearShield（scripts/enemies/gear_shield_enemy.gd，enum State { PATROL, BLOCK, CHARGE, STAGGER }）
PATROL→idle（慢速位移）；BLOCK→idle2（举斧格挡姿态，配合现有 `_shield_block_check`）；CHARGE→attack 前段慢放当读条（替代现有 modulate 闪烁指示）；攻击释放→attack 后段全速；STAGGER→idle 首帧 + 抖动；死亡→death。

---

## 6. 接线时需要改的文件（本次未改，供下一步实施）

| 文件 | 要点 |
|---|---|
| `scenes/player/Player.tscn` | 删 Visual 下 Cloak/Body/Head/Visor 色块，加 AnimatedSprite2D（SpriteFrames 指向 `assets/characters/player_fantasy_knight/*`，offset.y=-40）；Sword/slash_arc 视觉可保留叠加或退役 |
| `scripts/player/player.gd`（或新建 animator 脚本挂 Visual） | 按第 5 节映射驱动动画；死亡/受击接 Health 信号 |
| `scenes/enemies/SpitterEnemy.tscn` | 加 AnimatedSprite2D（hell_beast），Muzzle 位置对准嘴部（约 (-24,-40)，需在编辑器微调） |
| `scenes/enemies/ScrapperEnemy.tscn` | 加 AnimatedSprite2D（hell_hound） |
| `scenes/enemies/GearShieldEnemy.tscn` | 加 AnimatedSprite2D（executioner，offset.y=-34）；碰撞体按 4 格身高调大 |
| `scripts/enemies/{spitter,scrapper,gear_shield}_enemy.gd` | 状态切换处播对应动画；替换 modulate 闪烁读条 |
| `scenes/combat/Projectile.tscn` / `scripts/combat/projectile.gd` | 弹体贴图换 `spitter_hell_beast/projectile`（朝左原图，速度向右时 flip） |
| `scripts/autoload/fx.gd` | 敌人死亡统一播 `fx_enemy_death/death` 5 帧烟雾 |
| `CREDITS.md` | 追加署名（文本见第 7 节） |

---

## 7. 建议追加到 CREDITS.md 的署名文本

```
## Character Art
- "Gothicvania Patreon's Collection", "Gothicvania Cemetery Pack", "Hell Hound" — pixel art by Luis Zuno (@ansimuz), ansimuz.com. Licensed free for commercial use (Cemetery pack: public domain; collection: credit appreciated; standalone Hell Hound: CC-BY 4.0, credit ansimuz.com).
  https://opengameart.org/content/gothicvania-patreons-collection
  https://opengameart.org/content/gothicvania-cemetery-pack
- "Fantasy Knight" free character by Nauris Amatnieks (aamatniekss). Free for commercial projects, modification allowed; do not redistribute standalone.
  https://aamatniekss.itch.io/fantasy-knight-free-pixelart-animated-character
- "Boss: Undead Executioner" by Kronovi (DarkPixel-Kronovi). Free for commercial and non-commercial use.
  https://darkpixel-kronovi.itch.io/undead-executioner
```

---

## 8. 缺口与建议

1. **Hell Hound 无专用死亡/受击帧** —— 用 `fx_enemy_death` 烟雾 + 尸体淡出即可，Gothicvania 原作演示也是这么做的。
2. **Hell Beast 无受击帧** —— 建议受击时 idle 首帧 + 闪白（现有 juice.gd 应有类似工具）。
3. **Executioner 无移动帧** —— GearShield 是守卫型，PATROL 速度调慢配 idle 播放可接受；若必须要走路动画，后续可购买 Kronovi 完整包或改为原地守卫。
4. **Fantasy Knight 与 ansimuz 系色板略有差异**（更灰哑）——如果想 100% 统一，接线后可给玩家 sprite 加一层轻微紫色 modulate（如 #E6DCF0），或改用备选 B Gothic Hero 并另配死亡动画（可用 fx 白闪+倒地单帧代替）。
5. 下载暂存目录 `_downloads/`（含原始 zip、切帧脚本、QA 拼图）已加 `.gdignore`，Godot 不会导入；确认无用后可整目录删除。
6. Gothicvania Church 包的 wizard/angel/burning-ghoul 仍可作后续新怪素材，无需再下载。
