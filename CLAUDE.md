# Greedy Snake 2026 — Claude Context

## Project Overview

Godot 4.6.2 migration of the 2025 C++/EasyX Greedy Snake project. A roguelike arena survival game with upgrade system, AI opponents, terrain mechanics, wave definitions, and localized UI (English / Simplified Chinese).

## Architecture

### Single-File Arena Pattern
Most game logic lives in `scripts/game/Arena.gd` (~3000 lines), containing:
- 5 internal classes: `FoodDot`, `SnakeAgent`, `VfxParticle`, `Shockwave`, `FoodSpatialGrid`
- Game loop, rendering, collision, AI, upgrades, hazards

Supporting game code: `TerrainHazardRenderer.gd` (terrain hazard drawing / helpers used by the arena).

### Directory Structure
```
scripts/
  data/      # Static data: UpgradeCatalog, TerrainCatalog, RunData, WaveCatalog, GameConfig
  game/      # Arena.gd + TerrainHazardRenderer.gd
  systems/   # Global Autoload singletons
  ui/        # Code-built UI; theme helpers (NeonAssets, ForestAssets, ObsidianUiAssets, UiTheme, ResponsiveLayout, …)
  tests/     # Smoke test runner
scenes/
  Main.tscn, game/Arena.tscn, menus/MainMenu.tscn, SettingsMenu.tscn, AboutMenu.tscn, tests/SmokeRunner.tscn
tools/
  build_forest_25d_assets.py   # Optional pipeline for forest 2.5D slice assets
assets/
  generated/   # Game textures (neon_ecology, forest_25d, obsidian_ui, …)
  fonts/       # NotoSansCJK for zh UI (large file; consider Git LFS if repo size matters)
```

### Autoload Singletons
Order matches `project.godot`:
- `SettingsStore` — User settings persistence (`ConfigFile` at `user://greedy_snake_2026_settings.cfg`)
- `LocaleText` — UI string lookup by `SettingsStore.language` (`en` / `zh`)
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

### Settings Fields (`SettingsStore`)
Persisted keys mirror `get_snapshot()` / `save_settings()`.

| Field | Type | Range / values | Default |
|-------|------|------------------|---------|
| volume | float | 0.0–1.0 | `GameConfig.DEFAULT_VOLUME` (0.85) |
| bgm_volume | float | 0.0–1.0 | 0.78 |
| sfx_volume | float | 0.0–1.0 | 0.9 |
| sound_on | bool | — | true |
| difficulty | int | 0–2 | 1 |
| snake_speed | int | 0–2 | 1 |
| animations_on | bool | — | true |
| anti_aliasing_on | bool | — | true |
| fullscreen_on | bool | — | true |
| effects_quality | int | 0–2 | 2 |
| screen_shake_on | bool | — | true |
| minimap_on | bool | — | true |
| minimap_size | int | 0–2 | 1 |
| language | String | `en`, `zh` | `en` |

## Game Mechanics

### Snake Movement
- Keyboard: Arrow keys or WASD for direction change
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

### Waves
- Wave definitions and queries live in `WaveCatalog.gd` (used by `Arena.gd` / run state).

### AI System
- Elite prefixes: Fast, Tank, Ghost, Splitter, etc.
- Boss waves with special abilities
- Wall avoidance AI behavior

## Testing

### Smoke Test
- Location: `scenes/tests/SmokeRunner.tscn`
- Run: `godot --headless --path . --scene res://scenes/tests/SmokeRunner.tscn`
- Success output: `SMOKE_TEST_OK`
- Covers: `UpgradeCatalog`, `RunData`, `TerrainCatalog`, `WaveCatalog`, `TerrainHazardRenderer` preload, required texture/font paths, main menu / settings / about / arena scene load, follower-damage smoke path

### Coverage
- Overall coverage remains low; smoke focuses on data + scene wiring + selected arena behaviors
- Missing: deep unit tests for `Arena.gd` collision, AI, and combat edge cases

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

## Completed Improvements (2026-05-02)

1. ✅ `WaveCatalog` data module and arena integration
2. ✅ `TerrainHazardRenderer` for terrain hazard presentation
3. ✅ `LocaleText` + `language` setting; CJK font asset for Chinese UI
4. ✅ Forest 2.5D + Obsidian UI generated assets and smoke-required path checks
5. ✅ `.gitignore` excludes Python `__pycache__` for `tools/` scripts

## Remaining Improvements

1. **Performance**: `_foods.pop_front()` is O(n) operation - consider ring buffer
2. **Documentation**: Add function docstrings to Arena.gd (large surface area)
3. **Testing**: Add unit tests for collision logic (GUT or GdUnit)
4. **Architecture**: Consider splitting Arena.gd into smaller modules
5. **Repository size**: Optional Git LFS for `NotoSansCJK-Regular.ttc` and large generated PNGs if clone size becomes an issue
