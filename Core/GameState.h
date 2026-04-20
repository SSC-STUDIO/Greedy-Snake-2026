/**
 * @file GameState.h
 * @brief 游戏状态管理器头文件
 */

#pragma once
#include "AppSettings.h"
#include "Camera.h"
#include "../ModernCore/Vector2.h"
#include "../Gameplay/GameConfig.h"
#include <mutex>
#include <easyx.h>
#include <conio.h>
#include <windows.h>
#pragma warning(disable: 4996)

using Vector2 = GreedSnake::Vector2;

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

    void ResetForNewSession(const GameSettings& settings);
    void ApplySessionSettings(const GameSettings& settings);
    
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

    float GetDeltaTime() const {
        std::lock_guard<std::mutex> lock(stateMutex);
        return deltaTime;
    }

    void SetDeltaTime(float dt) {
        std::lock_guard<std::mutex> lock(stateMutex);
        deltaTime = dt;
    }

    bool IsMouseControlEnabled() const {
        std::lock_guard<std::mutex> lock(stateMutex);
        return isMouseControlEnabled;
    }

    void SetMouseControlEnabled(bool enabled) {
        std::lock_guard<std::mutex> lock(stateMutex);
        isMouseControlEnabled = enabled;
    }

    Vector2 GetGameplayMouseScreenPosition() const {
        std::lock_guard<std::mutex> lock(stateMutex);
        return gameplayMouseScreenPosition;
    }

    void SetGameplayMouseScreenPosition(const Vector2& position) {
        std::lock_guard<std::mutex> lock(stateMutex);
        gameplayMouseScreenPosition = position;
    }

    bool ConsumeMouseMovementForActivation(const Vector2& position);
    void ResetMouseTracking(const Vector2& position);
    void PrimeMouseTracking(const Vector2& position);

    void ResumeGameplay();
    void StartSpeedBoost();
    void StopSpeedBoost();
    void SetCameraPosition(const Vector2& position);
    void RequestReturnToMenu();
    void RequestExit();
    bool ShouldReturnToMenu() const;
    bool ShouldExitProgram() const;
    void ClearSessionOutcome();

    // Variables that need to be accessed frequently should use the getter/setter methods
    float currentPlayerSpeed = GameConfig::DEFAULT_PLAYER_SPEED; // Current player speed
    float recordInterval = GameConfig::DEFAULT_RECORD_INTERVAL; // Record interval
    bool isMouseControlEnabled = false; // Whether mouse control is enabled
    bool isGameRunning = true; // Whether the game is running
    bool isPaused = false; // Whether the game is paused
    bool isMenuShowing = false; 
    Camera camera; // Camera
    Vector2 targetDirection{ 0, 1 }; // Target direction
    float deltaTime = 1.0f / 30.0f; // Time increment
    float originalSpeed = GameConfig::DEFAULT_PLAYER_SPEED; // Original speed
    bool isSpeedBoostActive = false; // Whether left mouse acceleration is active
    Vector2 gameplayMouseScreenPosition{
        static_cast<float>(GameConfig::WINDOW_WIDTH) / 2.0f,
        static_cast<float>(GameConfig::WINDOW_HEIGHT) / 2.0f
    };
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

    // Static members for game control
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
    void ResetSpeedBoostStateLocked();
    void RestoreSpeedBoostStateLocked();

    Vector2 lastMouseActivationSample{
        static_cast<float>(GameConfig::WINDOW_WIDTH) / 2.0f,
        static_cast<float>(GameConfig::WINDOW_HEIGHT) / 2.0f
    };
    bool hasMouseActivationSample = false;
    bool pausedWithSpeedBoost = false;

    GameState() = default; // Private constructor
    GameState(const GameState&) = delete;
    GameState& operator=(const GameState&) = delete;
};

void CheckGameState(PlayerSnake& player);
