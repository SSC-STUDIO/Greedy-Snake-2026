# Rustgrave — Architecture Quick Map

Target: **Godot 4.7** · GDScript only · zero external deps.

显示边界：世界始终在 **640×360 SubViewport** 中以原生像素渲染，`GameCamera.zoom=1`；`GamePresentation` 将世界图像和 1280×720 设计单位的 UI 一起放入最大整数倍率内容矩形。`PresentationMetrics` 是内容矩形、倍率和坐标转换的唯一来源，非 16:9 窗口只增加黑边。

## Autoloads

Do not give autoload scripts a `class_name` — the autoload name is the API.

| Autoload | Script | Role |
|---|---|---|
| `GameEvents` | `scripts/autoload/game_events.gd` | Signal bus (`hit`, `parried`, `announcement`, `toxin_changed`, `core_acquired`, `ability_unlocked`, `ending_chosen`, …). Cross-cutting traffic goes through it; systems do not couple directly. |
| `Juice` | `scripts/autoload/juice.gd` | Hit-stop / camera punch. |
| `Sfx` | `scripts/autoload/sfx.gd` | One-shot library + looping rain / rust-rain / cemetery drone. `Sfx` / `Ambience` buses. |
| `Fx` | `scripts/autoload/fx.gd` | Particles, ember attach, death puffs. |
| `SaveData` | `scripts/autoload/save_data.gd` | `user://` save: player, inventory, persistent world, consumed paths, story `flags`, ending. |
| `Director` | `scripts/autoload/director.gd` | Fade, sequenced cutscenes, cinematic letterbox. Never touches `Engine.time_scale`. |
| `WorldClock` | `scripts/autoload/world_clock.gd` | Simulation only: `time_of_day`、`phase`、`weather`、`zone`、`wind_*`。API：`wind_vector()` `sway_radians()` `mood_tint()` `outdoor_tint()` `indoor_tint()` `nest_light_*()` `outdoor_moon_energy()` `indoor_fill_energy()`。不创建 Sprite / Light。演出层是 `WorldAtmosphere` / `WindSway` / `CineFx` / `WeatherFx` / `WorldLight`。 |

## Level01 (`scenes/levels/Level01_Static.tscn`)

The `.tscn` stays the authored map (platforms, props, three parallax plates). `level01_static.gd` only spawns player / camera / HUD, wires plate→door, and plants grave sprites. Runtime children do the rest so `Platforms/`, `Props/ForgeHeart`, and `BossGate` paths do not move:

| Script | Role |
|---|---|
| `scripts/levels/level01_env.gd` | Shared `plant()` — foliage sits on a foot pivot with `WindSway`; play-layer trees also get a sibling `LeafShed`. |
| `scripts/levels/level01_parallax.gd` | Fog / silhouette / MoodTint / `WeatherFx` / `CineFx` / `MoonFill`. Drift follows `wind_vector()`. |
| `scripts/levels/level01_east_wing.gd` | Pit beams, `EastFloor` (`skin = "stone"` — the nave is paved, the graveyard is grass), ember ledge, Executioner, ForgeHeart, BossGate, ForgeShelter indoor zone. |
| `scripts/levels/level01_story_beats.gd` | One-shot Director scripts from `GameEvents` + east-wing signals. |

East wing is a helper node, not a PackedScene: instancing a sub-scene would reparent those nodes and break save / story lookups.

Set dressing that is not in the `.tscn`:

| Script | Role |
|---|---|
| `scripts/world/solid_platform.gd` | Skins: `ground` (grass + cemetery earth), `floating` (church slabs), `stone` (two flagstone rows cut from `slab_a/b/c` over the same earth). Collision never changes with the skin. |
| `scripts/world/ruin_plate.gd` | Slices a rectangular wall plate into 8px columns with a deterministic broken crown. Used by `TorchLight` and the altar / gargoyle backdrops; arch plates keep their authored tops. |
| `scripts/world/leaf_shed.gd` | Dead leaves from play-layer trees: 2px, wind-drifted, pixel-snapped, dissolve on the foot line. |
| `ToxinPool.Wisp` | Additive green vapor cells rising off the sludge film; rain halves the rate. |

Ambient effects are presentation only: they read `WorldClock` and never write physics, save data, or `Engine.time_scale`. One-shot `Fx` particles parent under the level's `WorldEffects` (via `GameContext.world_effects()`) so they render inside the 640×360 world viewport.

## Lighting

Night is a cold corridor (`mood_tint` ≈ 30–40% luminance). Lights carve warm pools; HUD / pause / Director stay on isolated canvases.

| Node | Script | Role |
|---|---|---|
| `WorldLight` | `scripts/world/world_light.gd` | Additive PointLight2D. `follow` is `nest` / `indoor` / `heart`. Shadows on. |
| `EmberNest/NestLight` + `Halo` | planted by the nest | Lit fire only: warm pool + additive glow sprite. Unlit = energy 0. |
| `DisplayFit` | `scripts/ui/display_fit.gd` | Keeps the pixel-safe integer presentation and saved window dimensions. Not an Autoload. |
| `MoonFill` | `Level01Parallax` | Weak cool `DirectionalLight2D`. Off indoors and on the title. |
| `ForgeShelter/WarmPool` | `Level01EastWing.place_forge_shelter` | Large dim indoor fill. |
| `ForgeHeart/HeartLight` | `forge_heart.gd` | Residual heat after `unlock()`. |

`SolidPlatform` / `GearPlatform` already carry `LightOccluder2D`. Purification shrine does not emit. No eighth Autoload.

`WorldAtmosphere` owns smooth outdoor/indoor tint and background hierarchy. `WorldLight` changes energy/radius during a doorway transition while keeping one blend mode, so lighting never pops between additive and mixed compositing. `WeatherFx` caches ground and water spans and maps hits through the world viewport transform.

## Player (`scenes/player/Player.tscn`)

| Child node | Script | Role |
|---|---|---|
| root `CharacterBody2D` | `player/player.gd` | Orchestrates children each frame |
| `PlayerController` | `player/player_controller.gd` | Heavy-momentum locomotion, dash/jump gating. Drives any body via `physics_tick(body, delta, move_scale)` |
| `Health` | `player/health.gd` | HP pool with i-frames & death latch |
| `ToxinMeter` | `player/toxin_meter.gd` | Sludge exposure → overflow ticks |
| `RustCoreInventory` | `player/rust_core_inventory.gd` | Pouch/socket ability cores |
| `MeleeCombat` (`Node2D`) | `combat/melee_combat.gd` | Slash state machine: windup → active (== parry window) → recovery |
| `HookshotTether` | `player/hookshot_tether.gd` | Grapple + heat-forge melt hook |
| `Resonance` | `player/resonance.gd` | Dual-core combo window after a parry |

## Combat

- `melee_combat.gd` — on ACTIVE frames a per-idle-frame sweep feeds overlapping projectiles into `Projectile.deflect()` (bounces them home at their source). Parry is not a separate action.
- `hitbox.gd` / `hurtbox.gd` — thin tagged volumes (layers: world 1, player 2, enemy 4, player_hitbox 8, projectile 16, hurtbox 32, interact 64).

## Data

- `data/ability_ids.gd`, `data/ability_catalog.gd`, `data/rust_core.gd` — immutable core definitions (kiln ⇒ Heat Forge, tether ⇒ Hookshot Tether, ember ⇒ Ember Step).

## Progress snapshots and testing

`SaveData.persist_progress()` writes player state, pouch/sockets, consumed paths, switches, Boss flags, checkpoints, weather and ending state as one atomic snapshot. The saved identifier remains `scenes/levels/Level01_Static.tscn` even though the presentation wrapper owns display. Legacy absolute node paths are resolved, and uncertain old pickup records are made obtainable again after a `.before_progress_repair.bak` backup.

Zero-dependency harness under `tests/`. See the Testing section in `README.md`.
