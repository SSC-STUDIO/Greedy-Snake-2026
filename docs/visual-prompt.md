# Rustgrave — 视觉风格锚定（第一步）

把下面的英文 Prompt 直接复制到 Midjourney 或 Stable Diffusion，用于生成游戏主视觉 / 概念图。

## Prompt for Visual AI（原文，请原样复制）

```
Pixel art 2D side-scrolling game concept art for "Rustgrave". Dark industrial wasteland underground, towering rusty steel girders, crumbling concrete pillars, hazardous orange chemical sludge pools. The protagonist is a small cloaked knight wielding a massive serrated greatsword, standing on a broken gear platform. Atmosphere is oppressive, melancholic, with heavy fog and faint neon emergency lights reflecting off wet metal surfaces. Color palette: desaturated dark greys, burnt sienna rust, toxic neon orange, and dim teal. 16-bit retro pixel style, strong contrast, volumetric lighting shafts through dust. Game mood: Hollow Knight meets Dark Souls in a junkyard.
```

## Midjourney 用法

- 建议后缀：`--ar 16:9 --stylize 250`（主视觉）；角色立绘可改 `--ar 3:4`。
- 需要更“死像素”时加：`--style raw` 并在 prompt 末尾强调 `no anti-aliasing, chunky pixels, 16-color palette`。
- 负面词（若使用 Niji / 允许 --no）：`blur, photorealistic, 3d, smooth gradient, anti-aliasing, cute chibi`。

## Stable Diffusion / 本地用法

- 模型倾向：像素 / 插画混合（例如 pixel-art LoRA + 暗色工业概念模型）。
- 分辨率：先出 1024×576 或 1216×704 概念图，再由像素画师按 `docs/art-spec.md` 降采样重绘，**不要把 AI 图直接当游戏资源**。
- 采样：Euler a / DPM++ 2M，CFG 5–7；打开 pixel-art LoRA 时权重 0.6–0.8。
- 始终锁定主色：`#3A3A3A` `#8B4513` `#CD5C5C` `#FF8C00` `#4A6B6B`。

## 画面必须出现的元素

1. 地下工业陵墓：锈蚀钢梁、崩裂混凝土柱。
2. 橙色有毒泥浆与湿金属上的应急霓虹反光。
3. 体型很小的披风骑士（Ember-Knight）+ 过大的锯齿巨剑。
4. 断裂齿轮平台。
5. 压抑、雾、尘埃中的体积光。

完整像素规格见 `docs/art-spec.md`。世界观与机制见 `docs/GDD.md`。
