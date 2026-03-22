# Greedy Snake Game 2025

A feature-rich modern Snake game with beautiful graphics, smooth animations, and intelligent AI opponents.

## 🎮 Game Features

- **🎯 Dual Control System** - Support for keyboard and mouse controls
- **🎨 Beautiful Graphics** - Modern visual effects and smooth animations
- **🎵 Audio System** - Background music and dynamic sound effects
- **⚙️ Customizable Settings** - Volume, difficulty, and sound toggles
- **🤖 AI Opponents** - Intelligent AI snakes add challenge
- **🌟 Dynamic Systems** - Real-time food spawning and lava areas
- **⚡ Smooth Experience** - 60FPS smooth movement and camera following
- **🎭 Modern UI** - Intuitive button and menu interface

## 📋 System Requirements

- **Operating System**: Windows 10/11
- **Compiler**: Visual Studio 2019+ (Recommended)
- **Graphics Library**: EasyX Graphics Library
- **Memory**: Minimum 2GB RAM
- **Storage**: 100MB available space

## 🚀 Quick Start

### Installation Steps

1. **Clone Project**
   ```bash
   git clone https://github.com/Crs10259/Greed-Snake-2025.git
   ```

2. **Environment Setup**
   - Install Visual Studio 2019 or higher
   - Download and install [EasyX Graphics Library](https://easyx.cn/)
   - Ensure Windows SDK is installed

3. **Build and Run**
   - Open `Greed-Snake-2025.sln`
   - Select Release configuration
   - Press `Ctrl+F5` to build and run

## 🕹️ Controls

### Basic Controls
| Key | Function |
|-----|----------|
| ↑↓←→ | Control snake movement |
| Mouse Movement | Alternative direction control |
| Left Click | Speed up |
| Right Click | Enable mouse control |
| ESC | Exit game |
| P | Pause game |
| S | Resume game |

### Menu Operations
- **Left Mouse Click** - Select menu items
- **ESC** - Return to previous menu

## 🎯 Gameplay

### Game Objective
Control your snake to collect food, avoid walls and AI snakes, and become the longest snake in the game!

### Game Mechanics
- **🍎 Collect Food** - Increase length and score
- **🔥 Avoid Lava** - Lava areas cause continuous damage
- **🤖 AI Competition** - Compete with intelligent AI snakes for food
- **📈 Progressive Difficulty** - Difficulty increases as the game progresses
- **👁️ Camera Following** - View automatically follows your snake

### Difficulty Levels
| Level | Features |
|-------|----------|
| Easy | AI moves slowly, low lava damage |
| Normal | Balanced gameplay experience |
| Hard | High AI intelligence, high lava damage |

## 🏗️ Project Architecture

```
Greed-Snake-2025/
├── Core/                  # Core Systems
│   ├── GameState.*       # Game state management
│   ├── ResourceManager.* # Resource and audio lifecycle
│   ├── ThreadManager.*   # Render/input thread management
│   ├── Camera.*          # Camera system
│   ├── Collisions.*      # Collision detection
│   └── Vector2.*         # 2D vector class
├── Gameplay/              # Game Logic
│   ├── Snake.*           # Snake class definitions
│   ├── Food.*            # Food system
│   └── GameInitializer.* # Game initialization
├── Utils/                 # Utility Classes
│   ├── Rendering.*       # Rendering system
│   ├── InputHandler.*    # Input handling
│   └── Setting.*         # Settings management
├── UI/                    # User Interface
│   ├── UI.*              # Main interface
│   └── Button.*          # Button components
└── Resources/             # Resource Files
    ├── *.png             # Image resources
    └── *.wav             # Audio files
```

## 🛠️ Technology Stack

- **Core Language**: C++17
- **Graphics Library**: EasyX Graphics Library
- **Audio API**: Windows Multimedia API (winmm.lib)
- **Concurrency**: std::thread, std::mutex
- **Memory Management**: RAII and smart pointers

## 📝 Development Notes

### Compiler Options
- **Warning Level**: Level 3
- **Character Set**: Unicode
- **Runtime Library**: Multi-threaded (/MT)
- **Preprocessor**: `_CRT_SECURE_NO_WARNINGS`

### Code Standards
- Use Chinese comments for better readability
- Follow RAII principles for resource management
- Implement singleton pattern for game state
- Thread-safe state management implementation
- The active runtime entry is `Main.cpp`, with core managers handling resources and thread infrastructure

## 🐛 FAQ

**Q: Game won't start?**
A: Make sure EasyX Graphics Library is installed and Visual Studio is configured correctly.

**Q: No sound?**
A: Check volume settings and ensure audio files exist in the Resources directory.

**Q: Game lag?**
A: Close other GPU-intensive programs or lower graphics quality in settings.

## 🤝 Contributing

Issues and Pull Requests are welcome!

1. Fork this repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📞 Contact Us

- **Email**: 961521953@qq.com
- **GitHub Issues**: [Submit Issues](https://github.com/Crs10259/Greed-Snake-2025/issues)
- **Project Homepage**: [GitHub](https://github.com/Crs10259/Greed-Snake-2025)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Thanks for playing!** 🎮✨

---

[English Documentation](README_EN.md) | [简体中文文档](README.md)
