# Rustgrave — 音频与氛围（第五步）

给作曲 / 音效师，或喂给音乐生成工具。下面英文块为原始 Prompt，请原样复制。

## Audio Mood Prompt（原文，请原样复制）

```
Atmospheric soundtrack for "Rustgrave". Ambient industrial drones mixed with lonely, echoing piano notes. Combat music features heavy, distorted percussion sounds like clashing anvils and broken chainsaws. Sound effects should have heavy low-end thuds for footsteps on metal, and high-frequency sharp clinks for sword parries.
```

## 分层建议

### 探索层（Furnace Hub / Scrapyard）

- 低频工业 drone，缓慢相位，像没熄灭的炉膛。
- 稀疏的回响钢琴，音程偏向小调与空心五度，不要旋律太完整。
- 远景：滴水、断裂齿轮偶发转动、应急灯继电器咔哒。

### 战斗层

- 铁砧对撞、失真链锯、金属废料刮擦作为节奏组。
- Kick 用低端 thud，不要电子舞曲的干净 808。
- 弹反成功时：极短的高频 clink + 一瞬 drone 被“切开”的静音，再回到压迫底噪。

### 生态区音色偏移

| 区域 | 氛围偏移 |
| --- | --- |
| Scrapyard | 风穿过空心梁，钢琴最清晰 |
| Gutterworks | 流水与气泡，drone 变湿、带合唱 |
| Kiln | 高频嘶嘶、低频炉吼，钢琴几乎消失 |
| Hollow Stack | 垂直风切、回声更长，脚步更空 |
| Abyssal Forge | 以上全部叠在一起，加入极低频心跳式脉冲 |

## 关键 SFX（落地实现时）

| 事件 | 质感 |
| --- | --- |
| 金属脚步 | 低端 thud，落地比抬脚更重 |
| 挥砍 wind-up | 布料与锈铁摩擦，略长 |
| 命中 | 钝的铁块，不要轻快刀音 |
| **弹反** | 高频尖 clink，可带极短响度闪避 |
| 冲刺 | 短促空气压缩 + 披风 |
| 毒素积累 | 细碎气泡 / 腐蚀嘶声，满槽时心跳 |
| 插入锈核 | 齿轮咬合 + 余烬爆响 |

当前脚手架 **不含音频资源**；此文档供后续音频制作直接使用。
