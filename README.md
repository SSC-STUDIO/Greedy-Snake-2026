# Greedy Snake 2026

Godot 4.6.2 migration of the 2025 C++/EasyX Greedy Snake project.

## Run

Open `project.godot` with Godot 4.6.2 stable, or run:

```bash
godot --path /home/chenrunsen/workspace/My-Project/Active/Games/Greedy-Snake-2026
```

If using the locally downloaded verifier from this implementation session:

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

Headless import:

```bash
/tmp/godot-4.6.2/Godot_v4.6.2-stable_linux.x86_64 --headless --editor --path . --quit
```

Smoke test:

```bash
/tmp/godot-4.6.2/Godot_v4.6.2-stable_linux.x86_64 --headless --path . --scene res://scenes/tests/SmokeRunner.tscn
```

Expected smoke-test output:

```text
SMOKE_TEST_OK
```
