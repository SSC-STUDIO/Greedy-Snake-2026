#include "../Core/SessionConfig.h"
#include "../Gameplay/GameConfig.h"
#include <cstdlib>
#include <iostream>
#include <cmath>

namespace {

void ExpectNear(float actual, float expected, float epsilon, const char* message) {
    if (std::fabs(actual - expected) > epsilon) {
        std::cerr << "FAILED: " << message << " expected=" << expected << " actual=" << actual << '\n';
        std::exit(1);
    }
}

void Expect(bool condition, const char* message) {
    if (!condition) {
        std::cerr << "FAILED: " << message << '\n';
        std::exit(1);
    }
}

void TestDefaultSettings() {
    const GameSettings settings = DefaultGameSettings();
    Expect(settings.difficulty == 1, "default difficulty should be normal");
    Expect(settings.snakeSpeed == 1, "default snake speed should be normal");
    Expect(settings.soundOn, "default sound should be on");
    Expect(settings.animationsOn, "default animations should be on");
    Expect(settings.antiAliasingOn, "default anti aliasing should be on");
}

void TestEasyDifficultyFastSpeed() {
    GameSettings settings = DefaultGameSettings();
    settings.difficulty = 0;
    settings.snakeSpeed = 2;

    const SessionTuning tuning = BuildSessionTuning(settings);
    Expect(tuning.playerSpeed == GameConfig::PLAYER_FAST_SPEED, "fast speed should map to fast player speed");
    Expect(tuning.aiSnakeCount == GameConfig::Difficulty::Easy::AI_SNAKE_COUNT, "easy difficulty should lower AI count");
    Expect(tuning.aiAggression == GameConfig::Difficulty::Easy::AI_AGGRESSION, "easy difficulty should lower AI aggression");
    Expect(tuning.lavaWarningTime == GameConfig::Difficulty::Easy::LAVA_WARNING_TIME, "easy difficulty should increase lava warning time");
}

void TestHardDifficultySlowSpeed() {
    GameSettings settings = DefaultGameSettings();
    settings.difficulty = 2;
    settings.snakeSpeed = 0;

    const SessionTuning tuning = BuildSessionTuning(settings);
    Expect(tuning.playerSpeed == GameConfig::PLAYER_SLOW_SPEED, "slow speed should map to slow player speed");
    Expect(tuning.aiSnakeCount == GameConfig::Difficulty::Hard::AI_SNAKE_COUNT, "hard difficulty should raise AI count");
    Expect(tuning.aiAggression == GameConfig::Difficulty::Hard::AI_AGGRESSION, "hard difficulty should raise AI aggression");
    Expect(tuning.foodSpawnRate == GameConfig::Difficulty::Hard::FOOD_SPAWN_RATE, "hard difficulty should use hard spawn rate");
}

void TestSessionResultResolution() {
    Expect(ResolveSessionResult(false, false) == GameSessionResult::Restart, "no flags should restart the session");
    Expect(ResolveSessionResult(false, true) == GameSessionResult::ReturnToMenu, "menu flag should return to menu");
    Expect(ResolveSessionResult(true, false) == GameSessionResult::ExitProgram, "exit flag should exit program");
}

void TestFrameTimingHelpers() {
    ExpectNear(ClampSessionDeltaTime(-1.0f), 0.0f, 0.0001f, "negative delta should clamp to zero");
    ExpectNear(ClampSessionDeltaTime(0.05f), 0.05f, 0.0001f, "normal delta should be preserved");
    ExpectNear(ClampSessionDeltaTime(1.5f), 0.1f, 0.0001f, "large delta should clamp to 100ms");

    ExpectNear(ComputeRemainingFrameBudget(0.0f), 1.0f / 60.0f, 0.0001f, "fresh frame should have full budget");
    ExpectNear(ComputeRemainingFrameBudget(0.010f), (1.0f / 60.0f) - 0.010f, 0.0001f, "partial frame should keep remaining budget");
    ExpectNear(ComputeRemainingFrameBudget(0.020f), 0.0f, 0.0001f, "over-budget frame should not sleep");
}

void TestCameraCenteringHelper() {
    const GreedSnake::Vector2 originCamera = BuildCenteredCameraPosition(GreedSnake::Vector2(0.0f, 0.0f));
    ExpectNear(originCamera.x, -static_cast<float>(GameConfig::WINDOW_WIDTH) / 2.0f, 0.0001f, "origin spawn should center camera horizontally");
    ExpectNear(originCamera.y, -static_cast<float>(GameConfig::WINDOW_HEIGHT) / 2.0f, 0.0001f, "origin spawn should center camera vertically");

    const GreedSnake::Vector2 offsetCamera = BuildCenteredCameraPosition(GreedSnake::Vector2(120.0f, -80.0f));
    ExpectNear(offsetCamera.x, 120.0f - static_cast<float>(GameConfig::WINDOW_WIDTH) / 2.0f, 0.0001f, "camera should follow spawn x");
    ExpectNear(offsetCamera.y, -80.0f - static_cast<float>(GameConfig::WINDOW_HEIGHT) / 2.0f, 0.0001f, "camera should follow spawn y");
}

void TestSpeedBoostResetHelper() {
    const ClearedSpeedBoostState state = BuildClearedSpeedBoostState(375.0f);
    ExpectNear(state.currentPlayerSpeed, 375.0f, 0.0001f, "speed reset should restore original speed");
    ExpectNear(state.recordInterval, GameConfig::DEFAULT_RECORD_INTERVAL, 0.0001f, "speed reset should restore default record interval");
    Expect(!state.isSpeedBoostActive, "speed reset should clear speed boost flag");
}

void TestAISpeedResolution() {
    ExpectNear(ResolveAISpeed(GameConfig::PLAYER_SLOW_SPEED, 0.5f), GameConfig::PLAYER_SLOW_SPEED * 0.5f, 0.0001f, "ai speed should scale with slow session speed");
    ExpectNear(ResolveAISpeed(GameConfig::PLAYER_FAST_SPEED, 0.8f), GameConfig::PLAYER_FAST_SPEED * 0.8f, 0.0001f, "ai speed should scale with fast session speed");
    ExpectNear(ResolveAISpeed(-10.0f, 0.8f), 0.0f, 0.0001f, "negative player speed should clamp to zero");
    ExpectNear(ResolveAISpeed(GameConfig::PLAYER_NORMAL_SPEED, -1.0f), 0.0f, 0.0001f, "negative ai multiplier should clamp to zero");
}

void TestCatchUpFollowSpeed() {
    const float leaderSpeed = GameConfig::PLAYER_NORMAL_SPEED;
    const float catchUpSpeed = ResolveCatchUpFollowSpeed(leaderSpeed);
    Expect(catchUpSpeed > leaderSpeed, "catch-up speed should exceed leader speed");
    ExpectNear(ResolveCatchUpFollowSpeed(-5.0f), 0.0f, 0.0001f, "negative leader speed should clamp to zero");
}

void TestUniformFollowSpacing() {
    const GreedSnake::Vector2 leaderPosition(120.0f, 64.0f);
    const GreedSnake::Vector2 followerPosition(92.0f, 64.0f);
    const GreedSnake::Vector2 fallbackDirection(1.0f, 0.0f);
    const GreedSnake::Vector2 followDirection = ResolveFollowDirection(
        leaderPosition,
        followerPosition,
        fallbackDirection);
    const GreedSnake::Vector2 resolvedPosition = ResolveUniformFollowPosition(
        leaderPosition,
        followerPosition,
        fallbackDirection,
        GameConfig::SNAKE_SEGMENT_SPACING);

    ExpectNear(followDirection.x, 1.0f, 0.0001f, "follower should aim directly toward leader on x axis");
    ExpectNear(followDirection.y, 0.0f, 0.0001f, "follower should not drift on y axis");
    ExpectNear((leaderPosition - resolvedPosition).Length(), GameConfig::SNAKE_SEGMENT_SPACING, 0.0001f,
        "resolved follow position should keep exact segment spacing");

    const GreedSnake::Vector2 overlappingPosition = ResolveUniformFollowPosition(
        leaderPosition,
        leaderPosition,
        GreedSnake::Vector2(0.0f, -1.0f),
        GameConfig::SNAKE_SEGMENT_SPACING);
    ExpectNear(overlappingPosition.x, leaderPosition.x, 0.0001f, "fallback direction should preserve x when vertical");
    ExpectNear(overlappingPosition.y, leaderPosition.y + GameConfig::SNAKE_SEGMENT_SPACING, 0.0001f,
        "fallback direction should place follower exactly one spacing behind leader");
}

void TestSessionAdvanceRule() {
    Expect(ShouldAdvanceSessionFrame(true, false), "running unpaused session should advance");
    Expect(!ShouldAdvanceSessionFrame(true, true), "paused session should not advance");
    Expect(!ShouldAdvanceSessionFrame(false, false), "stopped session should not advance");
}

void TestMouseSteeringDirection() {
    const GreedSnake::Vector2 zeroDirection = ResolveMouseSteeringDirection(
        GreedSnake::Vector2(320.0f, 240.0f),
        GreedSnake::Vector2(320.0f, 240.0f));
    ExpectNear(zeroDirection.x, 0.0f, 0.0001f, "mouse on snake should produce zero x direction");
    ExpectNear(zeroDirection.y, 0.0f, 0.0001f, "mouse on snake should produce zero y direction");

    const GreedSnake::Vector2 rightDirection = ResolveMouseSteeringDirection(
        GreedSnake::Vector2(360.0f, 240.0f),
        GreedSnake::Vector2(300.0f, 240.0f));
    ExpectNear(rightDirection.x, 1.0f, 0.0001f, "mouse to the right should steer right");
    ExpectNear(rightDirection.y, 0.0f, 0.0001f, "mouse to the right should not steer vertically");

    const GreedSnake::Vector2 diagonalDirection = ResolveMouseSteeringDirection(
        GreedSnake::Vector2(250.0f, 300.0f),
        GreedSnake::Vector2(220.0f, 260.0f));
    Expect(diagonalDirection.x > 0.0f, "offset cursor should preserve positive x steering");
    Expect(diagonalDirection.y > 0.0f, "offset cursor should preserve positive y steering");
}

void TestSmoothSteeringDirection() {
    const GreedSnake::Vector2 oppositeTurn = ResolveSmoothSteeringDirection(
        GreedSnake::Vector2(1.0f, 0.0f),
        GreedSnake::Vector2(-1.0f, 0.0f),
        0.3f);
    Expect(oppositeTurn.y > 0.0f, "exact opposite input should begin a real turn instead of stalling");
    Expect(oppositeTurn.x < 1.0f, "exact opposite input should move away from the original heading");

    const GreedSnake::Vector2 alignedTurn = ResolveSmoothSteeringDirection(
        GreedSnake::Vector2(0.0f, 1.0f),
        GreedSnake::Vector2(0.0f, 1.0f),
        0.3f);
    ExpectNear(alignedTurn.x, 0.0f, 0.0001f, "aligned turn should preserve x");
    ExpectNear(alignedTurn.y, 1.0f, 0.0001f, "aligned turn should preserve y");
}

void TestSweptCircleOverlap() {
    Expect(DoesSweptCircleOverlap(
        GreedSnake::Vector2(0.0f, 0.0f),
        GreedSnake::Vector2(32.0f, 0.0f),
        22.0f,
        GreedSnake::Vector2(16.0f, 0.0f),
        4.0f), "swept collision should catch food along the movement path");
    Expect(!DoesSweptCircleOverlap(
        GreedSnake::Vector2(0.0f, 0.0f),
        GreedSnake::Vector2(32.0f, 0.0f),
        22.0f,
        GreedSnake::Vector2(80.0f, 0.0f),
        4.0f), "swept collision should not report distant food");
    Expect(DoesSweptCircleOverlap(
        GreedSnake::Vector2(10.0f, 10.0f),
        GreedSnake::Vector2(10.0f, 10.0f),
        22.0f,
        GreedSnake::Vector2(25.0f, 10.0f),
        4.0f), "stationary overlap should still be detected");
}

void TestMouseActivationHelpers() {
    Expect(IsPointInsideGameplayViewport(GreedSnake::Vector2(0.0f, 0.0f)), "viewport origin should be usable");
    Expect(IsPointInsideGameplayViewport(GreedSnake::Vector2(
        static_cast<float>(GameConfig::WINDOW_WIDTH),
        static_cast<float>(GameConfig::WINDOW_HEIGHT))), "viewport max corner should be usable");
    Expect(!IsPointInsideGameplayViewport(GreedSnake::Vector2(-1.0f, 10.0f)), "negative x should be outside viewport");
    Expect(!IsPointInsideGameplayViewport(GreedSnake::Vector2(10.0f, static_cast<float>(GameConfig::WINDOW_HEIGHT) + 1.0f)), "y beyond window should be outside viewport");

    Expect(!HasMeaningfulMouseMovement(
        false,
        GreedSnake::Vector2(0.0f, 0.0f),
        GreedSnake::Vector2(20.0f, 20.0f)), "first mouse sample should not immediately activate mouse control");
    Expect(!HasMeaningfulMouseMovement(
        true,
        GreedSnake::Vector2(200.0f, 200.0f),
        GreedSnake::Vector2(205.0f, 204.0f)), "tiny cursor drift should not activate mouse control");
    Expect(HasMeaningfulMouseMovement(
        true,
        GreedSnake::Vector2(200.0f, 200.0f),
        GreedSnake::Vector2(214.0f, 200.0f)), "real mouse movement should activate mouse control");
}

void TestBoundaryWarningOverlay() {
    const BoundaryWarningOverlay centerOverlay = BuildBoundaryWarningOverlay(
        BuildCenteredCameraPosition(GreedSnake::Vector2(0.0f, 0.0f)));
    Expect(centerOverlay.leftDangerWidth == 0, "center camera should not warn on left edge");
    Expect(centerOverlay.rightDangerWidth == 0, "center camera should not warn on right edge");
    Expect(centerOverlay.topDangerHeight == 0, "center camera should not warn on top edge");
    Expect(centerOverlay.bottomDangerHeight == 0, "center camera should not warn on bottom edge");

    const BoundaryWarningOverlay leftOverlay = BuildBoundaryWarningOverlay(
        GreedSnake::Vector2(static_cast<float>(GameConfig::PLAY_AREA_LEFT) - 40.0f, 0.0f));
    Expect(leftOverlay.leftDangerWidth == 40, "camera past left wall should expose left warning width");
    Expect(leftOverlay.rightDangerWidth == 0, "left wall view should not warn on right edge");

    const BoundaryWarningOverlay bottomOverlay = BuildBoundaryWarningOverlay(
        GreedSnake::Vector2(0.0f, static_cast<float>(GameConfig::PLAY_AREA_BOTTOM) - static_cast<float>(GameConfig::WINDOW_HEIGHT) + 25.0f));
    Expect(bottomOverlay.bottomDangerHeight == 25, "camera past bottom wall should expose bottom warning height");
    Expect(bottomOverlay.topDangerHeight == 0, "bottom wall view should not warn on top edge");
}

void TestPlayAreaContactHelper() {
    Expect(IsCircleInsidePlayArea(GreedSnake::Vector2(0.0f, 0.0f), GameConfig::INITIAL_SNAKE_SIZE),
        "origin player circle should start inside play area");
    Expect(!IsCircleInsidePlayArea(
        GreedSnake::Vector2(static_cast<float>(GameConfig::PLAY_AREA_LEFT), 0.0f),
        GameConfig::INITIAL_SNAKE_SIZE),
        "touching the left wall with radius should count as outside play area");
    Expect(IsCircleInsidePlayArea(
        GreedSnake::Vector2(static_cast<float>(GameConfig::PLAY_AREA_LEFT) + GameConfig::INITIAL_SNAKE_SIZE, 0.0f),
        GameConfig::INITIAL_SNAKE_SIZE),
        "circle exactly inside the left wall should remain in play area");
    Expect(!IsCircleInsidePlayArea(
        GreedSnake::Vector2(0.0f, static_cast<float>(GameConfig::PLAY_AREA_BOTTOM)),
        GameConfig::INITIAL_SNAKE_SIZE),
        "touching the bottom wall with radius should count as outside play area");
}

}

int main() {
    TestDefaultSettings();
    TestEasyDifficultyFastSpeed();
    TestHardDifficultySlowSpeed();
    TestSessionResultResolution();
    TestFrameTimingHelpers();
    TestCameraCenteringHelper();
    TestSpeedBoostResetHelper();
    TestAISpeedResolution();
    TestCatchUpFollowSpeed();
    TestUniformFollowSpacing();
    TestSessionAdvanceRule();
    TestMouseSteeringDirection();
    TestSmoothSteeringDirection();
    TestSweptCircleOverlap();
    TestMouseActivationHelpers();
    TestBoundaryWarningOverlay();
    TestPlayAreaContactHelper();
    std::cout << "Logic tests passed\n";
    return 0;
}
