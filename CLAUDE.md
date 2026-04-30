# Greedy Snake 2026 — Claude Context

## Project Overview

Godot 4.6.2 migration of the 2025 C++/EasyX Greedy Snake project. A roguelike arena survival game with upgrade system, AI opponents, and terrain mechanics.

## Architecture

### Single-File Arena Pattern
All game logic is concentrated in `scripts/game/Arena.gd` (~1771 lines), containing:
- 5 internal classes: `FoodDot`, `SnakeAgent`, `VfxParticle`, `Shockwave`, `FoodSpatialGrid`
- ~60 functions for game loop, rendering, collision, AI, upgrades

### Directory Structure
```
scripts/
  data/      # Static data definitions (Dictionary constants + static query functions)
  game/      # Core game logic (Arena.gd only)
  systems/   # Global Autoload singletons
  ui/        # UI components (code-built, no .tscn UI scenes)
  tests/     # Smoke test runner
scenes/
  Main.tscn, Arena.tscn, SettingsMenu.tscn, AboutMenu.tscn
```

### Autoload Singletons
- `SettingsStore` — User settings persistence (ConfigFile)
- `AudioBus` — Audio playback pooling and caching
- `SceneRouter` — Scene transition management
- `RunRecords` — Leaderboard and achievement persistence

## Key Conventions

### Data Carrier
- Uses `Dictionary` instead of custom `Resource` for all game data
- State dictionaries returned by `RunData.new_modifier_state()`, `RunData.new_wave_state()`

### Signal Naming
- Pattern: `xxx_requested` / `xxx_selected`
- Examples: `start_game_requested`, `upgrade_selected(upgrade)`

### Settings Fields (14 total)
| Field | Type | Range | Default |
|-------|------|-------|---------|
| volume | float | 0.0-1.0 | DEFAULT_VOLUME |
| bgm_volume | float | 0.0-1.0 | 0.78 |
| sfx_volume | float | 0.0-1.0 | 0.9 |
| difficulty | int | 0-2 | 1 |
| snake_speed | int | 0-2 | 1 |
| animations_on | bool | - | true |
| anti_aliasing_on | bool | - | true |
| fullscreen_on | bool | - | false |
| effects_quality | int | 0-2 | 2 |
| screen_shake_on | bool | - | true |
| minimap_on | bool | - | true |
| minimap_size | int | 0-2 | 1 |

## Game Mechanics

### Snake Movement
- Keyboard: Arrow keys for direction change
- Mouse: Cursor tracking with smooth interpolation
- Speed affected by terrain, boost, upgrades

### Food System (6 types)
- Normal: +1 score, +1 length
- Shield: Temporary invulnerability
- Magnet: Attracts nearby food
- Explosion: Area blast damage
- Combo: Score multiplier
- Golden: High score value

### Upgrade System
- Triggered after eating threshold count
- 3 random choices from `UpgradeCatalog`
- 20 upgrade definitions with rarity tiers

### Terrain System (4 regions)
- Neon Ecology (green): Normal speed
- Cyber Desert (orange): +20% speed
- Ice Plains (cyan): -30% speed
- Magma Fields (red): Lava boundary danger

### AI System
- Elite prefixes: Fast, Tank, Ghost, Splitter, etc.
- Boss waves with special abilities
- Wall avoidance AI behavior

## Testing

### Smoke Test
- Location: `scenes/tests/SmokeRunner.tscn`
- Run: `godot --headless --path . --scene res://scenes/tests/SmokeRunner.tscn`
- Success output: `SMOKE_TEST_OK`

### Coverage
- Current: ~3% overall
- Covered: UpgradeCatalog, RunData, TerrainCatalog, SettingsStore, scene loading
- Missing: Arena.gd core logic (collision, AI, upgrades, combat)

## Development Commands

```bash
# Run game
godot --path .

# Run smoke test
godot --headless --path . --scene res://scenes/tests/SmokeRunner.tscn

# Import validation
godot --headless --editor --path . --quit
```

## Completed Improvements (2026-05-01)

1. ✅ Git repository initialized and pushed to GitHub
2. ✅ GitHub Actions CI workflow (import check, smoke test, build)
3. ✅ GitHub Actions Release workflow (Linux, Windows, Web)
4. ✅ Fixed player body collision bug - now correctly damages player
5. ✅ Fixed magnet duration bug - added `magnet_duration_bonus` modifier
6. ✅ Implemented VfxParticle/Shockwave object pools (300+22 preallocated)
7. ✅ Decoupled SettingsStore ↔ AudioBus circular dependency with signals

## Remaining Improvements

1. **Performance**: `_foods.pop_front()` is O(n) operation - consider ring buffer
2. **Documentation**: Add function docstrings to Arena.gd (~60 functions)
3. **Testing**: Add unit tests for collision logic (GUT or GdUnit)
4. **Architecture**: Consider splitting Arena.gd into smaller modules