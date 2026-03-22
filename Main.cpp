#include <graphics.h>
#include <tchar.h>
#include <io.h>
#include <thread>
#include <mutex>
#include <exception>
#include <algorithm>
#include <windows.h>
#include <mmsystem.h>
#include "Gameplay/GameConfig.h"
#include "Core/Vector2.h"
#include "Core/GameRuntime.h"
#include "Gameplay/Snake.h"
#include "Core/GameState.h"
#include "Core/ResourceManager.h"
#include "Core/ThreadManager.h"
#include "Utils/Rendering.h"
#include "Core/Collisions.h"
#include "Gameplay/Food.h"
#include "Utils/Setting.h"
#include "Utils/InputHandler.h"
#include "Gameplay/GameInitializer.h"
#include "Gameplay/GameSystems.h"
#include "UI/UI.h"

#pragma comment(lib, "winmm.lib")
#pragma warning(disable: 4996)

bool GameConfig::SOUND_ON = true;
bool GameConfig::ANIMATIONS_ON = true;

const int windowWidth = GameConfig::WINDOW_WIDTH;
const int windowHeight = GameConfig::WINDOW_HEIGHT;

GameRuntimeContext gGameRuntime;

namespace {
void DrawMenuBackground() {
    BeginBatchDraw();
    ResourceManager::Instance().DrawBackground();
    EndBatchDraw();
}

float CalculateFrameDeltaTime() {
    const DWORD currentTime = GetTickCount();
    const DWORD elapsedTime = currentTime - GameState::lastTime;
    GameState::lastTime = currentTime;

    float deltaSeconds = static_cast<float>(elapsedTime) / 1000.0f;
    if (deltaSeconds <= 0.0f) {
        deltaSeconds = 1.0f / 60.0f;
    }

    return (std::min)(deltaSeconds, 0.1f);
}

void CopyPlayerSnapshot(PlayerSnake& snapshot) {
    auto& runtime = GameRuntime();
    auto& gameState = GameState::Instance();
    std::lock_guard<std::mutex> lock(gameState.stateMutex);

    snapshot.position = runtime.snake[0].position;
    snapshot.direction = runtime.snake[0].direction;
    snapshot.radius = runtime.snake[0].radius;
    snapshot.color = runtime.snake[0].color;

    snapshot.segments.resize(runtime.snake[0].segments.size());
    for (size_t i = 0; i < runtime.snake[0].segments.size(); ++i) {
        snapshot.segments[i] = runtime.snake[0].segments[i];
    }
}

void UpdateAnimationTimer(float frameDeltaTime) {
    auto& runtime = GameRuntime();
    auto& gameState = GameState::Instance();
    std::lock_guard<std::mutex> lock(gameState.stateMutex);

    runtime.animationTimer += frameDeltaTime;
    if (runtime.animationTimer > 1000.0f) {
        runtime.animationTimer = 0.0f;
    }
}

void InitializePlayerSnakeForSession() {
    auto& runtime = GameRuntime();
    const Vector2 centerPos(windowWidth / 2.0f, windowHeight / 2.0f);

    runtime.snake[0].position = centerPos;
    runtime.snake[0].direction = Vector2(1, 0);
    runtime.snake[0].currentDir = RIGHT;
    runtime.snake[0].nextDir = RIGHT;
    runtime.snake[0].radius = GameConfig::INITIAL_SNAKE_SIZE;
    runtime.snake[0].color = HSLtoRGB(255, 255, 255);
    runtime.snake[0].moveTimer = 0.0f;
    runtime.snake[0].gridSnake = true;

    runtime.snake[0].segments.resize(4);
    for (size_t i = 0; i < runtime.snake[0].segments.size(); ++i) {
        runtime.snake[0].segments[i].position =
            centerPos - Vector2(1, 0) * (static_cast<float>(i + 1) * GameConfig::SNAKE_SEGMENT_SPACING);
        runtime.snake[0].segments[i].direction = Vector2(1, 0);
        runtime.snake[0].segments[i].radius = GameConfig::INITIAL_SNAKE_SIZE;
        runtime.snake[0].segments[i].color = HSLtoRGB(255, 255, 255);
    }
}

void InitializeFoodForSession() {
    auto& runtime = GameRuntime();
    for (int i = 0; i < GameConfig::MAX_FOOD_COUNT; ++i) {
        InitFood(runtime.foodList, i, GameState::Instance().currentPlayerSpeed);
    }
}

void InitializeGameSession() {
    GameState::Instance().Initial();
    ResourceManager::Instance().PlayBackgroundMusic();
    InitializePlayerSnakeForSession();
    InitializeFoodForSession();
    InitializeAISnakes();
}

void StopRunningGame() {
    auto& gameState = GameState::Instance();
    std::lock_guard<std::mutex> lock(gameState.stateMutex);

    if (gameState.isGameRunning) {
        gameState.isGameRunning = false;
    }
}

bool ShouldExitProgram() {
    std::lock_guard<std::mutex> lock(GameState::Instance().stateMutex);
    return GameState::Instance().exitGame;
}

bool ShouldShowDeathMessage() {
    return GameState::Instance().IsDeathMessagePending();
}

bool IsGameSessionComplete() {
    return GameState::Instance().IsSessionFinished();
}

void ShowDeathMessageAndStop(ThreadManager& threadManager) {
    GameState::Instance().SetIsGameRunning(false);
    threadManager.JoinAllThreads();

    cleardevice();
    GameState::Instance().ShowDeathMessage();
    GameState::Instance().ClearDeathMessage();
}

void ApplySessionOutcome(bool& startGame, bool& quitProgram) {
    auto& gameState = GameState::Instance();
    std::lock_guard<std::mutex> lock(gameState.stateMutex);

    if (gameState.returnToMenu) {
        gameState.returnToMenu = false;
        startGame = false;
    } else if (gameState.exitGame) {
        quitProgram = true;
    }
}

void RunRenderLoop();

bool TickGameSession(ThreadManager& threadManager, bool& quitProgram) {
    if (threadManager.HasExceptions()) {
        threadManager.CheckAndRethrowExceptions();
        GameState::Instance().SetIsGameRunning(false);
        return false;
    }

    if (ShouldExitProgram()) {
        quitProgram = true;
        GameState::Instance().SetIsGameRunning(false);
        return false;
    }

    if (ShouldShowDeathMessage()) {
        ShowDeathMessageAndStop(threadManager);
        return false;
    }

    return !IsGameSessionComplete();
}

void RunSingleGameSession(bool& startGame, bool& quitProgram) {
    InitializeGameSession();

    ThreadManager threadManager;
    threadManager.StartRenderThread([]() { RunRenderLoop(); });
    threadManager.StartInputThread([]() { EnterChanges(); });

    while (TickGameSession(threadManager, quitProgram)) {
        Sleep(10);
    }

    StopRunningGame();
    threadManager.JoinAllThreads();
    Sleep(500);

    ApplySessionOutcome(startGame, quitProgram);
}

void HandleMenuChoice(int menuChoice, bool& showMenu, bool& startGame, bool& quitProgram) {
    switch (menuChoice) {
        case StartGame:
            cleardevice();
            startGame = true;
            showMenu = false;
            break;

        case Setting:
            ShowSettings(windowWidth, windowHeight);
            DrawMenuBackground();
            break;

        case About:
            ShowAbout();
            DrawMenuBackground();
            break;

        case Exit:
            quitProgram = true;
            showMenu = false;
            break;

        default:
            break;
    }
}

void RunMenuCycle(bool& quitProgram) {
    DrawMenuBackground();

    bool showMenu = true;
    bool startGame = false;

    while (showMenu && !quitProgram) {
        const int menuChoice = ShowGameMenu();
        HandleMenuChoice(menuChoice, showMenu, startGame, quitProgram);
    }

    while (startGame && !quitProgram) {
        RunSingleGameSession(startGame, quitProgram);
    }
}

void RunRenderLoop() {
    auto& runtime = GameRuntime();
    try {
        while (GameState::Instance().GetIsGameRunning()) {
            auto& gameState = GameState::Instance();
            const float frameDeltaTime = CalculateFrameDeltaTime();
            const bool isPaused = gameState.GetIsPaused();

            BeginBatchDraw();

            if (!isPaused) {
                {
                    std::lock_guard<std::mutex> lock(gameState.stateMutex);
                    gameState.deltaTime = frameDeltaTime;
                }

                UpdateCamera();
                UpdatePlayerSnake(gameState.deltaTime);
                UpdateAISnakes(gameState.deltaTime);
                UpdateFoods(runtime.foodList, GameConfig::MAX_FOOD_COUNT);
                CheckGameState(runtime.snake);
                RunCollisionChecks();
                gameState.UpdateGameTime(gameState.deltaTime);
                UpdateAnimationTimer(gameState.deltaTime);
            }

            DrawGameArea();

            PlayerSnake playerSnapshot;
            CopyPlayerSnapshot(playerSnapshot);

            DrawVisibleObjects(
                runtime.foodList,
                GameConfig::MAX_FOOD_COUNT,
                runtime.aiSnakeList.data(),
                static_cast<int>(runtime.aiSnakeList.size()),
                playerSnapshot);

            if (!isPaused) {
                UpdateGrowthAnimation(gameState.deltaTime);
            }

            DrawUI();
            EndBatchDraw();
            Sleep(1000 / 60);
        }
    } catch (const std::exception& e) {
        OutputDebugStringA(e.what());
        MessageBox(GetHWnd(), _T("绘制线程遇到错误"), _T("错误"), MB_OK | MB_ICONERROR);
        GameState::Instance().SetIsGameRunning(false);
    }
}
}

int main() {
    initgraph(GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT);

    ResourceManager& resourceManager = ResourceManager::Instance();
    resourceManager.LoadAllResources();
    resourceManager.ScaleBackgroundImage(windowWidth, windowHeight);

    PlayStartAnimation();

    bool quitProgram = false;
    while (!quitProgram) {
        RunMenuCycle(quitProgram);
    }

    resourceManager.CleanupAudio();
    closegraph();
    return 0;
}
