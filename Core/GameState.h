/**
 * @file GameState.h
 * @brief 游戏状态管理器头文件
 */

#pragma once
#include "../Core/Vector2.h"
#include "../Gameplay/GameConfig.h"
#include "../Core/Camera.h"
#include "../Gameplay/Snake.h"
#include <mutex>
#include <easyx.h>
#include <conio.h> 
#include <windows.h> 
#pragma warning(disable: 4996)

// 前向声明避免循环包含
class Snake;
class PlayerSnake;
class AISnake;

struct GameUISnapshot {
    int score = 0;
    bool isInvulnerable = false;
    float remainingInvulnerabilityTime = 0.0f;
    bool isInLava = false;
    float remainingLavaWarningTime = 0.0f;
    bool isPaused = false;
    bool isMenuShowing = false;
};

/**
 * @brief 游戏状态管理类
 * 
 * 使用单例模式管理游戏状态、难度设置和时间控制
 */
class GameState {
public:
    static GameState& Instance() {
        static GameState instance; 
        return instance;
    }

    void Initial() {
        // Use a lock to protect initialization
        std::lock_guard<std::mutex> lock(stateMutex);
        
        // Reset each member instead of using assignment
        auto& instance = Instance();
        instance.currentPlayerSpeed = GameConfig::DEFAULT_PLAYER_SPEED;
        instance.recordInterval = GameConfig::DEFAULT_RECORD_INTERVAL;
        instance.isMouseControlEnabled = true;
        instance.isGameRunning = true;
        instance.isPaused = false;
        instance.isMenuShowing = false; 
        instance.targetDirection = Vector2(0, 1);
        instance.deltaTime = 1.0f / 30.0f;
        instance.originalSpeed = GameConfig::DEFAULT_PLAYER_SPEED;
        instance.timeInLava = 0.0f;
        instance.isInLava = false;
        instance.foodEatenCount = 0;
        instance.aiAggression = GameConfig::Difficulty::Normal::AI_AGGRESSION;
        instance.foodSpawnRate = GameConfig::Difficulty::Normal::FOOD_SPAWN_RATE;
        instance.aiSnakeCount = GameConfig::Difficulty::Normal::AI_SNAKE_COUNT;
        instance.lavaWarningTime = GameConfig::Difficulty::Normal::LAVA_WARNING_TIME;
        instance.collisionFlashTimer = 0.0f;
        instance.isCollisionFlashing = false;
        instance.gameStartTime = 0.0f;
        instance.isInvulnerable = true;
        instance.showDeathMessage = false;
        instance.finalScore = 0;
        instance.returnToMenu = false;
        instance.currentDifficulty = GameDifficulty::Normal;
        instance.difficulty = 1; // Default to normal difficulty
        
        // Reset static members
        exitGame = false;
        lastTime = GetTickCount();
    }
    
    // Thread-safe getters and setters for commonly accessed state
    bool GetIsPaused() {
        std::lock_guard<std::mutex> lock(stateMutex);
        return isPaused;
    }
    
    void SetIsPaused(bool paused) {
        std::lock_guard<std::mutex> lock(stateMutex);
        isPaused = paused;
    }
    
    bool GetIsMenuShowing() {
        std::lock_guard<std::mutex> lock(stateMutex);
        return isMenuShowing;
    }
    
    void SetIsMenuShowing(bool showing) {
        std::lock_guard<std::mutex> lock(stateMutex);
        isMenuShowing = showing;
    }
    
    bool GetIsGameRunning() {
        std::lock_guard<std::mutex> lock(stateMutex);
        return isGameRunning;
    }
    
    void SetIsGameRunning(bool running) {
        std::lock_guard<std::mutex> lock(stateMutex);
        isGameRunning = running;
    }
    
    Vector2 GetTargetDirection() {
        std::lock_guard<std::mutex> lock(stateMutex);
        return targetDirection;
    }
    
    void SetTargetDirection(const Vector2& direction) {
        std::lock_guard<std::mutex> lock(stateMutex);
        targetDirection = direction;
    }

    // Variables that need to be accessed frequently should use the getter/setter methods
    float currentPlayerSpeed = GameConfig::DEFAULT_PLAYER_SPEED; // Current player speed
    float recordInterval = GameConfig::DEFAULT_RECORD_INTERVAL; // Record interval
    bool isMouseControlEnabled = true; // Whether mouse control is enabled
    bool isGameRunning = true; // Whether the game is running
    bool isPaused = false; // Whether the game is paused
    bool isMenuShowing = false; 
    Camera camera; // Camera
    Vector2 targetDirection{ 0, 1 }; // Target direction
    float deltaTime = 1.0f / 30.0f; // Time increment
    float originalSpeed = GameConfig::DEFAULT_PLAYER_SPEED; // Original speed
    float timeInLava = 0.0f;  // Time spent in lava
    bool isInLava = false;    // Whether snake is in lava
    int foodEatenCount = 0;  // Number of food items eaten
    float aiAggression = GameConfig::Difficulty::Normal::AI_AGGRESSION; // AI aggression
    float foodSpawnRate = GameConfig::Difficulty::Normal::FOOD_SPAWN_RATE; // Food spawn rate
    int aiSnakeCount = GameConfig::Difficulty::Normal::AI_SNAKE_COUNT; // AI snake count
    float lavaWarningTime = GameConfig::Difficulty::Normal::LAVA_WARNING_TIME; // Lava warning time

    float collisionFlashTimer = 0.0f;      // Collision flash timer
    bool isCollisionFlashing = false;      // Whether in collision flash
    float gameStartTime = 0.0f;            // Game start time
    bool isInvulnerable = true;            // Whether invulnerable
    bool showDeathMessage = false;         // Whether to show death message
    int finalScore = 0;                    // Final score

    bool returnToMenu = false;  // Whether to return to menu
    
    // Add difficulty setting member
    int difficulty = 1;  // Game difficulty: 0-Easy, 1-Normal, 2-Hard

    enum class GameDifficulty {
        Easy, // Easy
        Normal, // Normal
        Hard // Hard
    };

    GameDifficulty currentDifficulty = GameDifficulty::Normal; // Current difficulty

    // Static members for game timing and control
    static DWORD lastTime; // Last time measured for game timing
    static bool exitGame; // Whether to exit the game completely

    void SetDifficulty(GameDifficulty difficulty);

    void ResetLavaTimer();

    void AddFoodEaten();

    bool IsCollisionEnabled() const;
    float GetRemainingLavaWarningTime() const;
    float GetRemainingInvulnerabilityTime() const;
    GameUISnapshot GetUISnapshot() const;
    void TriggerGameOver();
    bool IsDeathMessagePending() const;
    bool IsSessionFinished() const;
    void ClearDeathMessage();

    void UpdateGameTime(float dt);

    void ShowDeathMessage(); // Modified to non-const, so it can modify member variables

    void ShowPauseMenu();

    // Add mutex for thread synchronization
    mutable std::mutex stateMutex;

    unsigned int worldSeed = 0; 

private:
    GameState() = default; // Private constructor
    GameState(const GameState&) = delete;
    GameState& operator=(const GameState&) = delete;
};

void CheckGameState(Snake* snake);
