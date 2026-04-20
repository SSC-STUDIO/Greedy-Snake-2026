#pragma once

#include "AppSettings.h"
#include "../ModernCore/Vector2.h"

struct SessionTuning {
    float playerSpeed = 250.0f;
    int aiSnakeCount = 20;
    float aiAggression = 0.6f;
    float foodSpawnRate = 1.0f;
    float lavaWarningTime = 5.0f;
};

enum class GameSessionResult {
    Restart,
    ReturnToMenu,
    ExitProgram
};

struct ClearedSpeedBoostState {
    float currentPlayerSpeed = 250.0f;
    float recordInterval = 0.05f;
    bool isSpeedBoostActive = false;
};

struct BoundaryWarningOverlay {
    int leftDangerWidth = 0;
    int rightDangerWidth = 0;
    int topDangerHeight = 0;
    int bottomDangerHeight = 0;
};

GameSettings DefaultGameSettings();
void RefreshPlayAreaBounds();
float ResolvePlayerSpeed(int snakeSpeedSetting);
SessionTuning BuildSessionTuning(const GameSettings& settings);
GameSessionResult ResolveSessionResult(bool exitRequested, bool returnToMenu);
float ClampSessionDeltaTime(float deltaSeconds);
float ComputeRemainingFrameBudget(float frameElapsedSeconds);
GreedSnake::Vector2 BuildCenteredCameraPosition(const GreedSnake::Vector2& focusPosition);
ClearedSpeedBoostState BuildClearedSpeedBoostState(float originalSpeed);
float ResolveAISpeed(float playerSpeed, float speedMultiplier);
float ResolveCatchUpFollowSpeed(float leaderSpeed);
bool ShouldAdvanceSessionFrame(bool isGameRunning, bool isPaused);
bool IsPointInsideGameplayViewport(const GreedSnake::Vector2& screenPosition);
bool HasMeaningfulMouseMovement(
    bool hasPreviousSample,
    const GreedSnake::Vector2& previousMouseScreenPosition,
    const GreedSnake::Vector2& currentMouseScreenPosition);
GreedSnake::Vector2 ResolveMouseSteeringDirection(
    const GreedSnake::Vector2& mouseScreenPosition,
    const GreedSnake::Vector2& playerScreenPosition);
GreedSnake::Vector2 ResolveSmoothSteeringDirection(
    const GreedSnake::Vector2& currentDirection,
    const GreedSnake::Vector2& targetDirection,
    float turnWeight);
bool DoesSweptCircleOverlap(
    const GreedSnake::Vector2& startPosition,
    const GreedSnake::Vector2& endPosition,
    float movingRadius,
    const GreedSnake::Vector2& stationaryPosition,
    float stationaryRadius);
GreedSnake::Vector2 ResolveFollowDirection(
    const GreedSnake::Vector2& leaderPosition,
    const GreedSnake::Vector2& followerPosition,
    const GreedSnake::Vector2& fallbackDirection);
GreedSnake::Vector2 ResolveUniformFollowPosition(
    const GreedSnake::Vector2& leaderPosition,
    const GreedSnake::Vector2& followerPosition,
    const GreedSnake::Vector2& fallbackDirection,
    float spacing);
bool IsCircleInsidePlayArea(const GreedSnake::Vector2& position, float radius);
BoundaryWarningOverlay BuildBoundaryWarningOverlay(const GreedSnake::Vector2& cameraPosition);
