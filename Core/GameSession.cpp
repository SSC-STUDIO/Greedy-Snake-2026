#include "GameSession.h"

#include "GameRuntime.h"
#include "GameState.h"
#include "ResourceManager.h"
#include "Collisions.h"
#include "../Gameplay/Food.h"
#include "../Gameplay/GameInitializer.h"
#include "../Gameplay/GameSystems.h"
#include "../Gameplay/Snake.h"
#include "../Gameplay/GameConfig.h"
#include "../UI/UI.h"
#include "../Utils/InputHandler.h"
#include "../Utils/Rendering.h"
#include <thread>
#include <windows.h>

using Vector2 = GreedSnake::Vector2;

GameSession::GameSession(const GameSettings& settings)
    : settings_(settings) {
}

GameSessionResult GameSession::Run() {
    Initialize();
    PlaySessionIntroSequence(_T("Sector A-01"), _T("Survive the swarm and own the arena"), RGB(63, 177, 219));

    auto& gameState = GameState::Instance();
    while (gameState.GetIsGameRunning()) {
        const GreedSnake::TimePoint frameStart = GreedSnake::Now();
        const float deltaTime = ClampSessionDeltaTime(frameRateCalculator_.Update());
        PollGameplayInput();

        const bool isGameRunning = gameState.GetIsGameRunning();
        const bool isPaused = gameState.GetIsPaused();
        if (!isGameRunning) {
            break;
        }

        if (ShouldAdvanceSessionFrame(isGameRunning, isPaused)) {
            UpdateFrame(deltaTime);
        }

        RenderFrame();

        if (gameState.ShouldExitProgram()) {
            break;
        }

        if (gameState.IsDeathMessagePending()) {
            gameState.ShowDeathMessage();
            gameState.ClearDeathMessage();
            break;
        }

        const float frameElapsedSeconds = GreedSnake::DeltaSeconds(frameStart, GreedSnake::Now());
        const float remainingFrameBudget = ComputeRemainingFrameBudget(frameElapsedSeconds);
        if (remainingFrameBudget > 0.0f) {
            std::this_thread::sleep_for(GreedSnake::Seconds(remainingFrameBudget));
        }
    }

    return ResolveSessionResult(gameState.ShouldExitProgram(), gameState.ShouldReturnToMenu());
}

void GameSession::Initialize() {
    auto& runtime = GameRuntime();
    runtime.aiSnakeList.clear();

    GameState::Instance().ResetForNewSession(settings_);
    ResourceManager::Instance().PlayBackgroundMusic();

    InitializePlayerSnake();
    InitializeFood();
    InitializeAISnakes();
}

void GameSession::InitializePlayerSnake() {
    auto& player = GameRuntime().playerSnake;
    const Vector2 centerPos(0.0f, 0.0f);
    const Vector2 cameraPos = BuildCenteredCameraPosition(centerPos);

    player.isDead = false;
    player.isInvincible = false;
    player.invincibilityTimer = 0.0f;
    player.score = 0;
    player.livesRemaining = 3;
    player.currentTime = 0.0f;
    player.moveTimer = 0.0f;
    player.posRecords = std::queue<Vector2>();
    player.previousPosition = centerPos;
    player.position = centerPos;
    player.direction = Vector2(0, 1);
    player.radius = GameConfig::INITIAL_SNAKE_SIZE;
    player.color = RGB(0, 200, 100);
    player.gridSnake = false;
    player.currentDir = GreedSnake::Direction::Down;
    player.nextDir = GreedSnake::Direction::Down;
    player.segments.clear();
    player.segments.resize(5);

    GameState::Instance().SetCameraPosition(cameraPos);

    for (size_t i = 0; i < player.segments.size(); ++i) {
        player.segments[i].position =
            centerPos - Vector2(0, 1) * (static_cast<float>(i + 1) * GameConfig::SNAKE_SEGMENT_SPACING);
        player.segments[i].direction = Vector2(0, 1);
        player.segments[i].radius = GameConfig::INITIAL_SNAKE_SIZE;
        player.segments[i].color = RGB(0, 200, 100);
        player.segments[i].currentTime = 0.0f;
        player.segments[i].posRecords = std::queue<Vector2>();
        player.segments[i].gridSnake = false;
    }
}

void GameSession::InitializeFood() {
    auto& runtime = GameRuntime();
    auto& gameState = GameState::Instance();

    for (int i = 0; i < GameConfig::MAX_FOOD_COUNT; ++i) {
        InitFood(runtime.foodList, i, gameState.currentPlayerSpeed);
    }
}

void GameSession::UpdateFrame(float deltaTime) {
    auto& gameState = GameState::Instance();
    gameState.SetDeltaTime(deltaTime);

    UpdateCamera();
    UpdatePlayerSnake(deltaTime);
    UpdateAISnakes(deltaTime);
    UpdateFoods(GameRuntime().foodList, GameConfig::MAX_FOOD_COUNT);
    RunCollisionChecks();
    gameState.UpdateGameTime(deltaTime);
}

void GameSession::RenderFrame() {
    auto& runtime = GameRuntime();
    auto& gameState = GameState::Instance();

    BeginBatchDraw();
    DrawGameArea();
    DrawVisibleObjects(
        runtime.foodList,
        GameConfig::MAX_FOOD_COUNT,
        runtime.aiSnakeList.data(),
        static_cast<int>(runtime.aiSnakeList.size()),
        runtime.playerSnake);

    if (!gameState.GetIsPaused()) {
        UpdateGrowthAnimation(gameState.GetDeltaTime());
    }

    DrawUI();
    if (gameState.GetIsPaused()) {
        DrawPauseMenu();
    }
    EndBatchDraw();
}
