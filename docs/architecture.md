# Rustgrave — Architecture Quick Map

Target: **Godot 4.7** · GDScript only · zero external deps.

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
| `WorldClock` | `scripts/autoload/world_clock.gd` | Simulation only: `time_of_day`、`phase`、`weather`、`zone`、`wind_heading` / `wind_speed` / `gust`。API：`wind_vector()` `sway_radians()` `mood_tint()`。不创建 Sprite。演出层是 `WindSway` / `CineFx` / `WeatherFx`。 |

## Level01 (`scenes/levels/Level01_Static.tscn`)

The `.tscn` stays the authored map (platforms, props, three parallax plates). `level01_static.gd` only spawns player / camera / HUD, wires plate→door, and plants grave sprites. Runtime children do the rest so `Platforms/`, `Props/ForgeHeart`, and `BossGate` paths do not move:

| Script | Role |
|---|---|
| `scripts/levels/level01_env.gd` | Shared `plant()` — foliage sits on a foot pivot with `WindSway`. |
| `scripts/levels/level01_parallax.gd` | Fog / silhouette / MoodTint / `WeatherFx` / `CineFx`. Drift follows `wind_vector()`. |
| `scripts/levels/level01_east_wing.gd` | Pit beams, east floor, ember ledge, Executioner, ForgeHeart, BossGate, ForgeShelter indoor zone. |
| `scripts/levels/level01_story_beats.gd` | One-shot Director scripts from `GameEvents` + east-wing signals. |

East wing is a helper node, not a PackedScene: instancing a sub-scene would reparent those nodes and break save / story lookups.

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

## Testing

Zero-dependency harness under `tests/`. See the Testing section in `README.md`.
