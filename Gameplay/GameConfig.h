#pragma once
#include "../ModernCore/Vector2.h"
#include "../ModernCore/Random.h"
#include <graphics.h>

using Vector2 = GreedSnake::Vector2;

// Game configuration parameters
namespace GameConfig {
    constexpr int FRAME_DELAY = 30;
    constexpr int NUM_FRAMES = 350; // Frame count - re-added
    constexpr int MENU_ICON_SIZE = 40; // Menu icon size
    constexpr int BASE_WINDOW_WIDTH = 760;
    constexpr int BASE_WINDOW_HEIGHT = 760;

    constexpr auto MAX_FOOD_COUNT = 5660; // Maximum food count
    constexpr float DEFAULT_PLAYER_SPEED = 250.0f; // Default player speed
    constexpr float DEFAULT_RECORD_INTERVAL = 0.05f; // Default record interval
    constexpr float SNAKE_GROWTH_RATE = 0.1f;  // Snake growth rate after eating food
    constexpr float SMOOTH_CAMERA_FACTOR = 0.1f; // Smooth camera movement factor
    extern int WINDOW_WIDTH; // Window width
    extern int WINDOW_HEIGHT; // Window height
    constexpr int GRID_CELL_SIZE = 38; // Grid cell size for AI movement (760/38=20 cells)
    constexpr int PLAY_AREA_MARGIN = 100; // Game area margin
    constexpr float SNAKE_SEGMENT_SPACING = 24.0f; // Tighter snake segment spacing
    constexpr float PLAYER_SLOW_SPEED = 180.0f; // Snake slow speed
    constexpr float PLAYER_NORMAL_SPEED = 250.0f; // Snake normal speed
    constexpr float PLAYER_FAST_SPEED = 320.0f; // Snake fast speed
    extern bool SOUND_ON; // Sound toggle (using extern declaration to avoid multiple definitions)
    extern bool ANIMATIONS_ON; // Animations toggle
    extern bool ANTIALIASING_ON; // Anti-aliasing toggle for scaled assets

    // Modify game area boundaries to accommodate new window size
    extern int PLAY_AREA_LEFT;        // Expand 10 window widths to the left
    extern int PLAY_AREA_RIGHT;       // Expand 10 window widths to the right
    extern int PLAY_AREA_TOP;         // Expand 10 window heights upward
    extern int PLAY_AREA_BOTTOM;      // Expand 10 window heights downward
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
    constexpr int FOOD_GRID_CELL_SIZE = 200;    // Spatial grid cell size for food queries
    constexpr float DEFAULT_VOLUME = 1.0f;  // Default volume level
    constexpr float VOLUME_STEP = 0.1f;     // Volume adjustment step
    constexpr float MAX_SNAKE_SIZE = 20.0f; // Set maximum snake size
    
    // Add collision-related configuration in GameConfig namespace
    constexpr float COLLISION_FLASH_DURATION = 0.5f;     // Collision flash duration
    constexpr bool ENABLE_COLLISION = true;              // Whether to enable collisions
    constexpr float COLLISION_GRACE_PERIOD = 5.0f;       // Invincibility time after game start (seconds) - changed to 5 seconds
	extern bool FULLSCREEN_ON; // Fullscreen mode toggle
    constexpr int MAX_AI_SNAKES = 20; // Maximum number of AI snakes

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
        return HSLtoRGB(static_cast<float>(red), static_cast<float>(green), static_cast<float>(blue)); // Return HSL color
    }

private:
    static int GenerateColorComponent() {
        const int random_bucket = GreedSnake::Random::Int(0, 4999);
        return static_cast<int>((random_bucket / 1000.0 + 1) * 255 / 6.0 + 0.5); // Generate color component
    }
};
