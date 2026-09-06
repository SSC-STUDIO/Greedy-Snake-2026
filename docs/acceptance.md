# Rustgrave 验收记录

## 真实输入通关

`tools/run_input_acceptance.ps1 -Rendered` 使用键盘动作驱动标题屏、新游戏、能力获取、毒池脱困、压力板、废料堆、融门、钩锁高台、Boss 战、死亡复活、退出继续和炉心选择。2026-09-05 的独立运行分别完成复燃与熄灭结局，日志报告 `normal input only`，没有引擎错误。

## 显示与天气

世界输出固定为 640×360，UI 设计单位为 1280×720。已检查 1280×720、1366×768、1920×1080、2560×1440、3840×2160、1280×800、2560×1600、3440×1440；16:9 使用最大整数倍率，其他比例居中留黑边。视觉矩阵（`-Supplement`，30 张）沿走廊自西向东覆盖起点、毒池、中段（齿轮台/喷吐者/压板）、门区（堡垒残墙/锈门）、东翼、Boss 场、炉心室内外，各配昼、夜雨、雾三种天气，另有暂停、字幕和结局菜单。

渲染矩阵是离屏/窗口输出验证，记录内容矩形和性能；它不冒充物理显示器实测，也不替代真实输入通关。它冻结 `WorldClock`，所以毒雾、落叶、风摆这类环境动态不会出现在图里；要看动态请用 `tools/run_peek_live.ps1`（时钟运行，每个机位停几秒后出图到 `screenshots/peek/`，不是验收门；`-Lit` 先点燃所有余烬巢，`-Night` 换成夜雨，`-Weather fog|clear|rain|ember_wind|rust_rain|haze` 指定天气，`-Active` 让敌人 AI 照常运行）。

`.tscn` 不支持 `#` 注释：节点块里的 `##` 行会吃掉紧随其后的属性（`Plat_760_184` 曾因此掉到原点、喷吐者悬空）。`level01_layout_test` 现在断言每个平台不在原点、每个落地敌人脚下有平台、同类敌人不重叠、每个敌人只有一张身体精灵。

## 自动化结果

- Godot 测试套件：245/245，通过；0 engine errors。
- 输入验收：rekindle 与 snuff 均通过；包含 Boss 击杀后的死亡/重生和 Continue。
- 补充视觉验收：`screenshots/acceptance/display/supplement/report.json`。
- 主视觉验收：`screenshots/acceptance/display/report.json`。

## 可恢复性

实施前快照位于 `C:\Users\Administrator\.codex\artifacts\rustgrave-before-20260905-112740.zip`。存档迁移前保留 `.before_progress_repair.bak`，保存写入成功后才替换内存快照。
