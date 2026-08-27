# Rustgrave — Architecture Quick Map

Target: **Godot 4.3+** · GDScript only · zero external deps.

## Autoloads
- `scripts/autoload/game_events.gd` — global signal bus (`hit_taken`, `parried`, `announcement`, `toxin_changed`, …). Everything cross-cutting routes through it; never couple systems directly.

## Player (`scenes/player/Player.tscn`)
| Child node | Script | Role |
|---|---|---|
| root `CharacterBody2D` | `player/player.gd` | orchestrates children each frame |
| `PlayerController` | `player/player_controller.gd` | heavy-momentum locomotion maths, dash/jump gating. Drives any body via `physics_tick(body, delta, move_scale)` |
| `Health` | `player/health.gd` | HP pool with i-frames & death latch |
| `ToxinMeter` | `player/toxin_meter.gd` | sludge exposure → overflow ticks |
| `RustCoreInventory` | `player/rust_core_inventory.gd` | pouch/socket ability cores |
| `MeleeCombat` (`Node2D`) | `combat/melee_combat.gd` | slash state machine: windup → active (== parry window) → recovery. Public `tick()/start_swing()/phase_name()` keep the input layer swappable |

## Combat
- `melee_combat.gd` — on ACTIVE frames a per-idle-frame sweep feeds overlapping projectiles into `Projectile.deflect()` (bounces them home at their source).
- `hitbox.gd` / `hurtbox.gd` — thin tagged volumes (layers: world 1, player 2, enemy 4, player_hitbox 8, projectile 16, hurtbox 32, interact 64).

## Data
- `data/ability_ids.gd`, `data/ability_catalog.gd`, `data/rust_core.gd` — immutable core definitions (kiln ⇒ Heat Forge, tether ⇒ Hookshot Tether).

## Testing
Zero-dependency harness under `tests/`. See "Testing" section in README.
