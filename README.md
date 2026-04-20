# 贪吃蛇游戏 2025

一个功能丰富的现代贪吃蛇游戏，具有精美的图形、流畅的动画和智能AI对手。

## 🎮 游戏特性

- **🎯 双重控制系统** - 支持键盘和鼠标控制
- **🎨 精美图形** - 现代化的视觉效果和流畅动画
- **🎵 音效系统** - 背景音乐和动态音效
- **⚙️ 自定义设置** - 音量、难度、音效开关
- **🤖 AI对手** - 智能AI蛇增加游戏挑战
- **🌟 动态系统** - 实时食物生成和熔岩区域
- **⚡ 流畅体验** - 60FPS流畅移动和相机跟随
- **🎭 现代UI** - 直观的按钮和菜单界面

## 📋 系统要求

- **操作系统**: Windows 10/11
- **编译器**: Visual Studio 2019+ (推荐)
- **图形库**: EasyX Graphics Library
- **内存**: 最少 2GB RAM
- **存储**: 100MB 可用空间

## 🚀 快速开始

### 安装步骤

1. **克隆项目**
   ```bash
   git clone https://github.com/Crs10259/Greed-Snake-2025.git
   ```

2. **环境准备**
   - 安装 Visual Studio 2019 或更高版本
   - 下载并安装 [EasyX 图形库](https://easyx.cn/)
   - 确保 Windows SDK 已安装

3. **编译运行**
   - 打开 `Greed-Snake-2025.sln`
   - 选择 Release 配置
   - 按下 `Ctrl+F5` 编译并运行

## 🕹️ 操作说明

### 基础控制
| 按键 | 功能 |
|------|------|
| ↑↓←→ | 控制蛇移动方向 |
| 鼠标移动 | 替代方向控制 |
| 左键 | 加速移动 |
| 右键 | 启用鼠标控制 |
| ESC | 退出游戏 |
| P | 暂停游戏 |
| S | 继续游戏 |

### 菜单操作
- **鼠标左键** - 选择菜单项
- **ESC** - 返回上级菜单

## 🎯 游戏玩法

### 游戏目标
控制蛇收集食物，避免撞墙和AI蛇，成为游戏中最长的蛇！

### 游戏机制
- **🍎 收集食物** - 增加长度和分数
- **🔥 避开熔岩** - 熔岩区域会持续造成伤害
- **🤖 AI竞争** - 与智能AI蛇争夺食物
- **📈 难度递增** - 随着游戏进行难度逐渐提升
- **👁️ 相机跟随** - 自动跟随你的蛇移动视角

### 难度等级
| 等级 | 特点 |
|------|------|
| 简单 | AI移动缓慢，熔岩伤害低 |
| 普通 | 平衡的游戏体验 |
| 困难 | AI智能高，熔岩伤害大 |

## 🏗️ 项目架构

```
Greed-Snake-2025/
├── Core/                  # 核心系统
│   ├── GameState.*       # 游戏状态管理
│   ├── ResourceManager.* # 资源与音频生命周期
│   ├── ThreadManager.*   # 渲染/输入线程管理
│   ├── Camera.*          # 相机系统
│   ├── Collisions.*      # 碰撞检测
│   └── Vector2.*         # 2D向量类
├── Gameplay/              # 游戏逻辑
│   ├── Snake.*           # 蛇类定义
│   ├── Food.*            # 食物系统
│   └── GameInitializer.* # 游戏初始化
├── Utils/                 # 工具类
│   ├── Rendering.*       # 渲染系统
│   ├── InputHandler.*    # 输入处理
│   └── Setting.*         # 设置管理
├── UI/                    # 用户界面
│   ├── UI.*              # 主界面
│   └── Button.*          # 按钮组件
└── Resource/              # 资源文件
    ├── *.png             # 图片资源
    └── *.wav             # 音频文件
```

## 🛠️ 开发技术栈

- **核心语言**: C++17
- **图形库**: EasyX Graphics Library
- **音频API**: Windows Multimedia API (winmm.lib)
- **并发编程**: std::thread, std::mutex
- **内存管理**: RAII 和智能指针

## 📝 开发说明

### 编译选项
- **警告级别**: Level 3
- **字符集**: Unicode
- **运行库**: Multi-threaded (/MT)
- **预处理器**: `_CRT_SECURE_NO_WARNINGS`

### 代码规范
- 使用中文注释提高可读性
- 遵循 RAII 原则管理资源
- 采用单例模式管理游戏状态
- 实现线程安全的状态管理
- 当前运行入口是 `Main.cpp`，核心 manager 负责资源和线程基础设施

## 🐛 常见问题

**Q: 游戏无法启动？**
A: 请确保已安装 EasyX 图形库并且 Visual Studio 配置正确。

**Q: 音效无法播放？**
A: 检查音量设置和音频文件是否存在于 Resources 目录。

**Q: 游戏卡顿？**
A: 建议关闭其他占用GPU的程序，或在设置中降低画质。

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 📞 联系我们

- **邮箱**: 961521953@qq.com
- **GitHub Issues**: [提交问题](https://github.com/Crs10259/Greed-Snake-2025/issues)
- **项目主页**: [GitHub](https://github.com/Crs10259/Greed-Snake-2025)

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

---

**感谢游玩！** 🎮✨

---

[English Documentation](README_EN.md) | [简体中文文档](README.md)
