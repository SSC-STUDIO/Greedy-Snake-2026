# Greedy Snake 2026

Godot 4.6.2 migration of the 2025 C++/EasyX Greedy Snake project.

## Run

Open `project.godot` with Godot 4.6.2 stable, or from the repository root (with `godot` on your `PATH`):

```bash
godot --path .
```

Absolute-path example:

```bash
godot --path /home/chenrunsen/workspace/My-Project/Active/Games/Greedy-Snake-2026
```

If Godot is only installed as a standalone binary (example):

```bash
/tmp/godot-4.6.2/Godot_v4.6.2-stable_linux.x86_64 --path /home/chenrunsen/workspace/My-Project/Active/Games/Greedy-Snake-2026
```

## Controls

- Arrow keys or WASD: steer by keyboard.
- Mouse movement: switch to mouse steering.
- Left mouse button: boost.
- Esc or P: pause.
- R: restart from the game-over screen.

## Verification

From the repo root, with `godot` on `PATH`:

```bash
godot --headless --editor --path . --quit
godot --headless --path . --scene res://scenes/tests/SmokeRunner.tscn
```

Or with a full binary path (same as in **Run**):

```bash
/tmp/godot-4.6.2/Godot_v4.6.2-stable_linux.x86_64 --headless --editor --path . --quit
/tmp/godot-4.6.2/Godot_v4.6.2-stable_linux.x86_64 --headless --path . --scene res://scenes/tests/SmokeRunner.tscn
```

Expected smoke-test output:

```text
SMOKE_TEST_OK
```

UI language (English / 简体中文) is configured in Settings and stored with other options (`SettingsStore.language`).
