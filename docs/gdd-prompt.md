# Rustgrave — GDD 生成 Prompt（第二步原文）

此文件保存用户喂给文本 AI 的原始 System Prompt，便于日后重新生成或对照。完整设计文档见 `docs/GDD.md`。

## System Prompt for GDD Generation（原文，请原样复制）

```
You are now a senior game designer. Please write a complete Game Design Document (GDD) based on the following core concept.

Game Title: Rustgrave
Genre: 2D Pixel Art Metroidvania (Action-Exploration).
Setting: The world is a colossal, subterranean mausoleum of a dead mechanical civilization. Everything is built of heavy iron and stone, now decaying into red rust. The air is thick with carcinogenic dust and the echoes of broken engines.

Core Player Fantasy: The player is an "Ember-Knight," a tiny entity reanimated from a pile of scrap. They must explore the nonlinear map, using their massive sword not just to kill, but to deflect projectiles and trigger heavy pressure plates to open pathways.

Key Mechanics (The "Gimmick"):

Rust-Core System: Defeated enemies drop "Rust-Cores." Instead of just leveling up, the player inserts these cores into different "Sockets" on their sword to unlock new abilities (e.g., Hookshot Tether for grappling across gaps, or Heat Forge to melt rusty gates).

Weight & Momentum: The character has a heavy feel. Jumping and swinging the sword have deliberate wind-up and recovery frames, emphasizing tactical combat over button-mashing.

Toxin Meter: Exposure to the orange sludge builds up a "Toxin" meter. If full, the player takes damage. They must find "Purification Shrines" (rare) or use consumable "Filter-Gears" to survive.

Map Structure: 5 main interconnected biomes, all connected by the central "Furnace Hub." Biomes include: The Gutterworks (sewers), The Kiln (extreme heat/fire), The Hollow Stack (vertical climbing), The Abyssal Forge (final area), and The Scrapyard (starting area).

Please output the document with sections: Story Premise, Core Loop, Ability Progression Tree, Enemy Design Philosophy, and Level Verticality Notes.
```
