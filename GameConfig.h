#pragma once
#include "Vector2.h"
#include <graphics.h>

// 游戏配置参数
namespace GameConfig {
    constexpr int NUM_FRAMES = 350; // 帧数
    constexpr int FRAME_DELAY = 25; // 帧延迟
    constexpr int MENU_ICON_SIZE = 40; // 菜单图标大小

    constexpr auto MAX_FOOD_COUNT = 5660; // 最大食物数量
    constexpr float DEFAULT_PLAYER_SPEED = 250.0f; // 默认玩家速度
    constexpr float DEFAULT_RECORD_INTERVAL = 0.05f; // 默认记录间隔
    constexpr float SNAKE_GROWTH_RATE = 0.1f;  // 吃食物后蛇的增长量
    constexpr float SMOOTH_CAMERA_FACTOR = 0.1f; // 平滑相机移动因子
    constexpr int WINDOW_WIDTH = 760; // 窗口宽度
    constexpr int WINDOW_HEIGHT = 760; // 窗口高度
    constexpr int PLAY_AREA_MARGIN = 100; // 游戏区域边距
    constexpr float SNAKE_SEGMENT_SPACING = 30.0f; // 蛇段间距
    
    // 修改游戏区域边界以适应新窗口大小
    constexpr int PLAY_AREA_LEFT = -WINDOW_WIDTH * 10;        // 向左扩展10个窗口宽度
    constexpr int PLAY_AREA_RIGHT = WINDOW_WIDTH * 10;        // 向右扩展10个窗口宽度
    constexpr int PLAY_AREA_TOP = -WINDOW_HEIGHT * 10;        // 向上扩展10个窗口高度
    constexpr int PLAY_AREA_BOTTOM = WINDOW_HEIGHT * 10;      // 向下扩展10个窗口高度
    constexpr float LAVA_WARNING_TIME = 5.0f;  // 在熔岩中死亡前允许的时间
    constexpr float INITIAL_SNAKE_SIZE = 22.0f;  // 初始蛇半径
    constexpr float SNAKE_GROWTH_SMALL = 0.1f;  // 吃食物后的增长量
    constexpr float SNAKE_GROWTH_LARGE = 1.0f;  // 吃10个食物后的增长量
    constexpr int AI_SNAKE_COUNT = 20;        // AI蛇数量减少到20
    constexpr float AI_DIRECTION_CHANGE_TIME = 2.0f; // AI方向改变时间
    constexpr float AI_VIEW_RANGE = 300.0f; // AI视野范围
    constexpr float AI_SPAWN_RADIUS = 2000.0f;  // 添加生成半径以分散AI蛇
    constexpr float AI_MIN_SPEED = 0.5f;        // AI最小速度倍率
    constexpr float AI_MAX_SPEED = 0.9f;        // AI最大速度倍率
    constexpr float DEFAULT_VOLUME = 1.0f;  // 默认音量级别
    constexpr float VOLUME_STEP = 0.1f;     // 音量调整步长
    constexpr float MAX_SNAKE_SIZE = 20.0f; // 设置蛇的最大大小
    const Vector2 PLAYER_DEFAULT_POS(WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2); // 玩家默认位置
    
    // 在GameConfig命名空间中添加碰撞相关配置
    constexpr float COLLISION_FLASH_DURATION = 0.5f;     // 碰撞闪烁持续时间
    constexpr bool ENABLE_COLLISION = true;              // 是否启用碰撞
    constexpr float COLLISION_GRACE_PERIOD = 3.0f;       // 游戏开始后的无敌时间（秒）- 改为3秒
    
    // 难度相关配置
    namespace Difficulty {
        // 简单难度
        struct Easy {
            static constexpr float PLAYER_SPEED = 200.0f; // 玩家速度
            static constexpr int AI_SNAKE_COUNT = 10; // AI蛇数量
            static constexpr float AI_AGGRESSION = 0.3f; // AI攻击性
            static constexpr float FOOD_SPAWN_RATE = 1.2f; // 食物生成率
            static constexpr float LAVA_WARNING_TIME = 7.0f; // 熔岩警告时间
        };

        // 普通难度
        struct Normal {
            static constexpr float PLAYER_SPEED = 250.0f; // 玩家速度
            static constexpr int AI_SNAKE_COUNT = 20; // AI蛇数量
            static constexpr float AI_AGGRESSION = 0.6f; // AI攻击性
            static constexpr float FOOD_SPAWN_RATE = 1.0f; // 食物生成率
            static constexpr float LAVA_WARNING_TIME = 5.0f; // 熔岩警告时间
        };

        // 困难难度
        struct Hard {
            static constexpr float PLAYER_SPEED = 300.0f; // 玩家速度
            static constexpr int AI_SNAKE_COUNT = 30; // AI蛇数量
            static constexpr float AI_AGGRESSION = 0.9f; // AI攻击性
            static constexpr float FOOD_SPAWN_RATE = 0.8f; // 食物生成率
            static constexpr float LAVA_WARNING_TIME = 3.0f; // 熔岩警告时间
        };
    }
}

enum ButtonType {
    StartGame, // 开始游戏
    Setting, // 设置
    About, // 关于
    Exit, // 退出
    Num // 按钮数量
};

// 蛇段颜色生成类
class ColorGenerator {
public:
    static int GenerateRandomColor() {
        int red = GenerateColorComponent(); // 生成红色分量
        int green = GenerateColorComponent(); // 生成绿色分量
        int blue = GenerateColorComponent(); // 生成蓝色分量
        return HSLtoRGB(red, green, blue); // 返回HSL颜色
    }

private:
    static int GenerateColorComponent() {
        return static_cast<int>((rand() % 5000 / 1000.0 + 1) * 255 / 6.0 + 0.5); // 生成颜色分量
    }
};