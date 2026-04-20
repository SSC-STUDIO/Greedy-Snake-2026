#include "SessionConfig.h"

#include "../Gameplay/GameConfig.h"
#include <algorithm>
#include <cmath>

namespace GameConfig {
int WINDOW_WIDTH = BASE_WINDOW_WIDTH;
int WINDOW_HEIGHT = BASE_WINDOW_HEIGHT;
int PLAY_AREA_LEFT = -BASE_WINDOW_WIDTH * 10;
int PLAY_AREA_RIGHT = BASE_WINDOW_WIDTH * 10;
int PLAY_AREA_TOP = -BASE_WINDOW_HEIGHT * 10;
int PLAY_AREA_BOTTOM = BASE_WINDOW_HEIGHT * 10;
bool SOUND_ON = true;
bool ANIMATIONS_ON = true;
bool ANTIALIASING_ON = true;
bool FULLSCREEN_ON = true;
}

namespace {
constexpr float kMaxSessionDeltaSeconds = 0.1f;
constexpr float kTargetFrameSeconds = 1.0f / 60.0f;
constexpr float kMouseActivationDistancePixels = 8.0f;

int NormalizeDifficulty(int difficulty) {
    if (difficulty < 0) {
        return 0;
    }
    if (difficulty > 2) {
        return 2;
    }
    return difficulty;
}

int ClampOverlayPixels(float pixels, int maxPixels) {
    const float nonNegativePixels = (std::max)(0.0f, pixels);
    return (std::min)(static_cast<int>(std::ceil(nonNegativePixels)), maxPixels);
}
}

GameSettings DefaultGameSettings() {
    GameSettings settings;
    settings.volume = GameConfig::DEFAULT_VOLUME;
    settings.difficulty = 1;
    settings.soundOn = true;
    settings.snakeSpeed = 1;
    settings.animationsOn = true;
    settings.antiAliasingOn = true;
    settings.fullscreenOn = true;
    return settings;
}

void RefreshPlayAreaBounds() {
    GameConfig::PLAY_AREA_LEFT = -GameConfig::WINDOW_WIDTH * 10;
    GameConfig::PLAY_AREA_RIGHT = GameConfig::WINDOW_WIDTH * 10;
    GameConfig::PLAY_AREA_TOP = -GameConfig::WINDOW_HEIGHT * 10;
    GameConfig::PLAY_AREA_BOTTOM = GameConfig::WINDOW_HEIGHT * 10;
}

float ResolvePlayerSpeed(int snakeSpeedSetting) {
    switch (snakeSpeedSetting) {
        case 0:
            return GameConfig::PLAYER_SLOW_SPEED;
        case 2:
            return GameConfig::PLAYER_FAST_SPEED;
        case 1:
        default:
            return GameConfig::PLAYER_NORMAL_SPEED;
    }
}

SessionTuning BuildSessionTuning(const GameSettings& settings) {
    SessionTuning tuning;
    tuning.playerSpeed = ResolvePlayerSpeed(settings.snakeSpeed);

    switch (NormalizeDifficulty(settings.difficulty)) {
        case 0:
            tuning.aiSnakeCount = GameConfig::Difficulty::Easy::AI_SNAKE_COUNT;
            tuning.aiAggression = GameConfig::Difficulty::Easy::AI_AGGRESSION;
            tuning.foodSpawnRate = GameConfig::Difficulty::Easy::FOOD_SPAWN_RATE;
            tuning.lavaWarningTime = GameConfig::Difficulty::Easy::LAVA_WARNING_TIME;
            break;
        case 2:
            tuning.aiSnakeCount = GameConfig::Difficulty::Hard::AI_SNAKE_COUNT;
            tuning.aiAggression = GameConfig::Difficulty::Hard::AI_AGGRESSION;
            tuning.foodSpawnRate = GameConfig::Difficulty::Hard::FOOD_SPAWN_RATE;
            tuning.lavaWarningTime = GameConfig::Difficulty::Hard::LAVA_WARNING_TIME;
            break;
        case 1:
        default:
            tuning.aiSnakeCount = GameConfig::Difficulty::Normal::AI_SNAKE_COUNT;
            tuning.aiAggression = GameConfig::Difficulty::Normal::AI_AGGRESSION;
            tuning.foodSpawnRate = GameConfig::Difficulty::Normal::FOOD_SPAWN_RATE;
            tuning.lavaWarningTime = GameConfig::Difficulty::Normal::LAVA_WARNING_TIME;
            break;
    }

    return tuning;
}

GameSessionResult ResolveSessionResult(bool exitRequested, bool returnToMenu) {
    if (exitRequested) {
        return GameSessionResult::ExitProgram;
    }

    if (returnToMenu) {
        return GameSessionResult::ReturnToMenu;
    }

    return GameSessionResult::Restart;
}

float ClampSessionDeltaTime(float deltaSeconds) {
    if (deltaSeconds < 0.0f) {
        return 0.0f;
    }

    return (std::min)(deltaSeconds, kMaxSessionDeltaSeconds);
}

float ComputeRemainingFrameBudget(float frameElapsedSeconds) {
    if (frameElapsedSeconds >= kTargetFrameSeconds) {
        return 0.0f;
    }

    return kTargetFrameSeconds - (std::max)(0.0f, frameElapsedSeconds);
}

GreedSnake::Vector2 BuildCenteredCameraPosition(const GreedSnake::Vector2& focusPosition) {
    return GreedSnake::Vector2(
        focusPosition.x - static_cast<float>(GameConfig::WINDOW_WIDTH) / 2.0f,
        focusPosition.y - static_cast<float>(GameConfig::WINDOW_HEIGHT) / 2.0f);
}

ClearedSpeedBoostState BuildClearedSpeedBoostState(float originalSpeed) {
    ClearedSpeedBoostState state;
    state.currentPlayerSpeed = originalSpeed;
    state.recordInterval = GameConfig::DEFAULT_RECORD_INTERVAL;
    state.isSpeedBoostActive = false;
    return state;
}

float ResolveAISpeed(float playerSpeed, float speedMultiplier) {
    return (std::max)(0.0f, playerSpeed) * (std::max)(0.0f, speedMultiplier);
}

float ResolveCatchUpFollowSpeed(float leaderSpeed) {
    const float normalizedLeaderSpeed = (std::max)(0.0f, leaderSpeed);
    return normalizedLeaderSpeed * 1.25f;
}

bool ShouldAdvanceSessionFrame(bool isGameRunning, bool isPaused) {
    return isGameRunning && !isPaused;
}

bool IsPointInsideGameplayViewport(const GreedSnake::Vector2& screenPosition) {
    return screenPosition.x >= 0.0f &&
        screenPosition.x <= static_cast<float>(GameConfig::WINDOW_WIDTH) &&
        screenPosition.y >= 0.0f &&
        screenPosition.y <= static_cast<float>(GameConfig::WINDOW_HEIGHT);
}

bool HasMeaningfulMouseMovement(
    bool hasPreviousSample,
    const GreedSnake::Vector2& previousMouseScreenPosition,
    const GreedSnake::Vector2& currentMouseScreenPosition) {
    if (!hasPreviousSample) {
        return false;
    }

    const GreedSnake::Vector2 movement = currentMouseScreenPosition - previousMouseScreenPosition;
    return movement.LengthSquared() >=
        (kMouseActivationDistancePixels * kMouseActivationDistancePixels);
}

GreedSnake::Vector2 ResolveMouseSteeringDirection(
    const GreedSnake::Vector2& mouseScreenPosition,
    const GreedSnake::Vector2& playerScreenPosition) {
    const GreedSnake::Vector2 rawDirection = mouseScreenPosition - playerScreenPosition;
    if (rawDirection.LengthSquared() <= 0.0f) {
        return GreedSnake::Vector2();
    }

    return rawDirection.Normalized();
}

GreedSnake::Vector2 ResolveSmoothSteeringDirection(
    const GreedSnake::Vector2& currentDirection,
    const GreedSnake::Vector2& targetDirection,
    float turnWeight) {
    const GreedSnake::Vector2 normalizedTarget = targetDirection.Normalized();
    if (normalizedTarget.LengthSquared() <= 0.0001f) {
        return currentDirection.Normalized();
    }

    const GreedSnake::Vector2 normalizedCurrent = currentDirection.LengthSquared() > 0.0001f
        ? currentDirection.Normalized()
        : normalizedTarget;
    const float clampedTurnWeight = (std::clamp)(turnWeight, 0.0f, 1.0f);
    const float directionAlignment = normalizedCurrent.Dot(normalizedTarget);

    if (directionAlignment <= -0.999f) {
        const GreedSnake::Vector2 perpendicularTurn(-normalizedCurrent.y, normalizedCurrent.x);
        return (normalizedCurrent * (1.0f - clampedTurnWeight) +
            perpendicularTurn * clampedTurnWeight).Normalized();
    }

    return (normalizedCurrent * (1.0f - clampedTurnWeight) +
        normalizedTarget * clampedTurnWeight).Normalized();
}

bool DoesSweptCircleOverlap(
    const GreedSnake::Vector2& startPosition,
    const GreedSnake::Vector2& endPosition,
    float movingRadius,
    const GreedSnake::Vector2& stationaryPosition,
    float stationaryRadius) {
    const float combinedRadius = (std::max)(0.0f, movingRadius) + (std::max)(0.0f, stationaryRadius);
    const GreedSnake::Vector2 sweep = endPosition - startPosition;
    const float sweepLengthSquared = sweep.LengthSquared();

    if (sweepLengthSquared <= 0.0001f) {
        return stationaryPosition.DistanceSquaredTo(endPosition) <= combinedRadius * combinedRadius;
    }

    const float projectedT = (stationaryPosition - startPosition).Dot(sweep) / sweepLengthSquared;
    const float clampedT = (std::clamp)(projectedT, 0.0f, 1.0f);
    const GreedSnake::Vector2 closestPoint = startPosition + sweep * clampedT;
    return stationaryPosition.DistanceSquaredTo(closestPoint) <= combinedRadius * combinedRadius;
}

GreedSnake::Vector2 ResolveFollowDirection(
    const GreedSnake::Vector2& leaderPosition,
    const GreedSnake::Vector2& followerPosition,
    const GreedSnake::Vector2& fallbackDirection) {
    const GreedSnake::Vector2 offset = leaderPosition - followerPosition;
    if (offset.LengthSquared() > 0.0001f) {
        return offset.Normalized();
    }

    if (fallbackDirection.LengthSquared() > 0.0001f) {
        return fallbackDirection.Normalized();
    }

    return GreedSnake::Vector2(0.0f, 1.0f);
}

GreedSnake::Vector2 ResolveUniformFollowPosition(
    const GreedSnake::Vector2& leaderPosition,
    const GreedSnake::Vector2& followerPosition,
    const GreedSnake::Vector2& fallbackDirection,
    float spacing) {
    const GreedSnake::Vector2 followDirection =
        ResolveFollowDirection(leaderPosition, followerPosition, fallbackDirection);
    return leaderPosition - followDirection * (std::max)(0.0f, spacing);
}

bool IsCircleInsidePlayArea(const GreedSnake::Vector2& position, float radius) {
    const float nonNegativeRadius = (std::max)(0.0f, radius);
    return position.x - nonNegativeRadius >= static_cast<float>(GameConfig::PLAY_AREA_LEFT) &&
        position.x + nonNegativeRadius <= static_cast<float>(GameConfig::PLAY_AREA_RIGHT) &&
        position.y - nonNegativeRadius >= static_cast<float>(GameConfig::PLAY_AREA_TOP) &&
        position.y + nonNegativeRadius <= static_cast<float>(GameConfig::PLAY_AREA_BOTTOM);
}

BoundaryWarningOverlay BuildBoundaryWarningOverlay(const GreedSnake::Vector2& cameraPosition) {
    BoundaryWarningOverlay overlay;
    overlay.leftDangerWidth = ClampOverlayPixels(
        static_cast<float>(GameConfig::PLAY_AREA_LEFT) - cameraPosition.x,
        GameConfig::WINDOW_WIDTH);
    overlay.rightDangerWidth = ClampOverlayPixels(
        cameraPosition.x + static_cast<float>(GameConfig::WINDOW_WIDTH) - static_cast<float>(GameConfig::PLAY_AREA_RIGHT),
        GameConfig::WINDOW_WIDTH);
    overlay.topDangerHeight = ClampOverlayPixels(
        static_cast<float>(GameConfig::PLAY_AREA_TOP) - cameraPosition.y,
        GameConfig::WINDOW_HEIGHT);
    overlay.bottomDangerHeight = ClampOverlayPixels(
        cameraPosition.y + static_cast<float>(GameConfig::WINDOW_HEIGHT) - static_cast<float>(GameConfig::PLAY_AREA_BOTTOM),
        GameConfig::WINDOW_HEIGHT);
    return overlay;
}
