# Rustgrave — 程序脚手架 Prompt（第四步原文）

此文件保存用户喂给编程 AI 的原始需求。当前仓库已按 **Godot 4 + GDScript** 落地（空仓库、2D 像素 Metroidvania，不使用 Unity）。

## Programming System Prompt（原文，请原样复制）

```
I am building a 2D Metroidvania game called "Rustgrave" using Unity (C#) / Godot (GDScript).
Please create the core code structure for the player controller.
Requirements:

PlayerController: Ground movement with variable acceleration (heavy momentum), multi-jump with gravity scaling, a dash with invincibility frames.

Combat System: A melee attack that creates a hitbox, with a cooldown. Additionally, implement a "Parry/Deflect" mechanic where swinging the sword at the exact moment a projectile hits will redirect it back to the enemy.

Interactable System: An interface (IInteractable) for pressure plates, doors, and lootable scrap piles.

Camera Follow: Smooth camera with slight horizontal look-ahead based on movement direction.
Please provide the code in clean, commented modules.
```

## 本仓库的对应实现

| 需求 | 实现 |
| --- | --- |
| PlayerController | `scripts/player/player_controller.gd` |
| 近战 + 弹反 | `scripts/combat/melee_combat.gd`，弹反窗口 = 挥砍 active 帧 |
| IInteractable | `scripts/interactables/interactable.gd` 基类 + `interact()` |
| Camera look-ahead | `scripts/camera/game_camera.gd` |
| 主场景 | `scenes/levels/TestArena.tscn` |
