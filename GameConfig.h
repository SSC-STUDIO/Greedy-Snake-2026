#pragma once
#include "Vector2.h"
#include <graphics.h>

// Game configuration parameters
namespace GameConfig {
    constexpr int NUM_FRAMES = 350; // Frame count
    constexpr int FRAME_DELAY = 25; // Frame delay
    constexpr int MENU_ICON_SIZE = 40; // Menu icon size

    constexpr auto MAX_FOOD_COUNT = 5660; // Maximum food count
    constexpr float DEFAULT_PLAYER_SPEED = 250.0f; // Default player speed
    constexpr float DEFAULT_RECORD_INTERVAL = 0.05f; // Default record interval
    constexpr float SNAKE_GROWTH_RATE = 0.1f;  // Snake growth rate after eating food
    constexpr float SMOOTH_CAMERA_FACTOR = 0.1f; // Smooth camera movement factor
    constexpr int WINDOW_WIDTH = 760; // Window width
    constexpr int WINDOW_HEIGHT = 760; // Window height
    constexpr int PLAY_AREA_MARGIN = 100; // Game area margin
    constexpr float SNAKE_SEGMENT_SPACING = 30.0f; // Snake segment spacing
    
    // Add missing constants
    constexpr float PLAYER_SLOW_SPEED = 180.0f; // Snake slow speed
    constexpr float PLAYER_NORMAL_SPEED = 250.0f; // Snake normal speed
    constexpr float PLAYER_FAST_SPEED = 320.0f; // Snake fast speed
    extern bool SOUND_ON; // Sound toggle (using extern declaration to avoid multiple definitions)
    
    // Modify game area boundaries to accommodate new window size
    constexpr int PLAY_AREA_LEFT = -WINDOW_WIDTH * 10;        // Expand 10 window widths to the left
    constexpr int PLAY_AREA_RIGHT = WINDOW_WIDTH * 10;        // Expand 10 window widths to the right
    constexpr int PLAY_AREA_TOP = -WINDOW_HEIGHT * 10;        // Expand 10 window heights upward
    constexpr int PLAY_AREA_BOTTOM = WINDOW_HEIGHT * 10;      // Expand 10 window heights downward
    constexpr float LAVA_WARNING_TIME = 5.0f;  // Time allowed before death in lava
    constexpr float INITIAL_SNAKE_SIZE = 22.0f;  // Initial snake radius
    constexpr float SNAKE_GROWTH_SMALL = 0.1f;  // Growth amount after eating food
    constexpr float SNAKE_GROWTH_LARGE = 1.0f;  // Growth amount after eating 10 food items
    constexpr int AI_SNAKE_COUNT = 20;        // AI snake count reduced to 20
    constexpr float AI_DIRECTION_CHANGE_TIME = 2.0f; // AI direction change time
    constexpr float AI_VIEW_RANGE = 300.0f; // AI view range
    constexpr float AI_SPAWN_RADIUS = 2000.0f;  // Add spawn radius to distribute AI snakes
    constexpr float AI_MIN_SPEED = 0.5f;        // AI minimum speed multiplier
    constexpr float AI_MAX_SPEED = 0.9f;        // AI maximum speed multiplier
    constexpr float DEFAULT_VOLUME = 1.0f;  // Default volume level
    constexpr float VOLUME_STEP = 0.1f;     // Volume adjustment step
    constexpr float MAX_SNAKE_SIZE = 20.0f; // Set maximum snake size
    const Vector2 PLAYER_DEFAULT_POS(WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2); // Player default position
    
    // Add collision-related configuration in GameConfig namespace
    constexpr float COLLISION_FLASH_DURATION = 0.5f;     // Collision flash duration
    constexpr bool ENABLE_COLLISION = true;              // Whether to enable collisions
    constexpr float COLLISION_GRACE_PERIOD = 3.0f;       // Invincibility time after game start (seconds) - changed to 3 seconds
    
    // Difficulty-related configuration
    namespace Difficulty {
        // Easy difficulty
        struct Easy {
            static constexpr float PLAYER_SPEED = 200.0f; // Player speed
            static constexpr int AI_SNAKE_COUNT = 10; // AI snake count
            static constexpr float AI_AGGRESSION = 0.3f; // AI aggression
            static constexpr float FOOD_SPAWN_RATE = 1.2f; // Food spawn rate
            static constexpr float LAVA_WARNING_TIME = 7.0f; // Lava warning time
        };

        // Normal difficulty
        struct Normal {
            static constexpr float PLAYER_SPEED = 250.0f; // Player speed
            static constexpr int AI_SNAKE_COUNT = 20; // AI snake count
            static constexpr float AI_AGGRESSION = 0.6f; // AI aggression
            static constexpr float FOOD_SPAWN_RATE = 1.0f; // Food spawn rate
            static constexpr float LAVA_WARNING_TIME = 5.0f; // Lava warning time
        };

        // Hard difficulty
        struct Hard {
            static constexpr float PLAYER_SPEED = 300.0f; // Player speed
            static constexpr int AI_SNAKE_COUNT = 30; // AI snake count
            static constexpr float AI_AGGRESSION = 0.9f; // AI aggression
            static constexpr float FOOD_SPAWN_RATE = 0.8f; // Food spawn rate
            static constexpr float LAVA_WARNING_TIME = 3.0f; // Lava warning time
        };
    }
}

enum ButtonType {
    StartGame, // Start game
    Setting, // Settings
    About, // About
    Exit, // Exit
    Num // Button count
};

// Snake segment color generation class
class ColorGenerator {
public:
    static int GenerateRandomColor() {
        int red = GenerateColorComponent(); // Generate red component
        int green = GenerateColorComponent(); // Generate green component
        int blue = GenerateColorComponent(); // Generate blue component
        return HSLtoRGB(red, green, blue); // Return HSL color
    }

private:
    static int GenerateColorComponent() {
        return static_cast<int>((rand() % 5000 / 1000.0 + 1) * 255 / 6.0 + 0.5); // Generate color component
    }
};