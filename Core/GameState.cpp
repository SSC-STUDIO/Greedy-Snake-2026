/**
 * @file GameState.cpp
 * @brief 游戏状态管理器 - 管理游戏状态、难度和计时
 */
#include "GameState.h"
#include "SessionConfig.h"
#include "../UI/UI.h"
#include "../Gameplay/GameConfig.h"
#include "../Gameplay/Snake.h"
#include <algorithm>
#include <cmath>
#include "../Utils/DrawHelpers.h"

// 静态成员初始化
bool GameState::exitGame = false;

namespace {

float SmoothUiProgress(float value) {
    const float clamped = (std::max)(0.0f, (std::min)(1.0f, value));
    return clamped * clamped * (3.0f - 2.0f * clamped);
}

}

/**
 * @brief 检查游戏状态
 * @param snake 蛇数组指针
 * 
 * 检查蛇是否在游戏区域内，处理岩浆伤害和死亡逻辑
 */
void CheckGameState(PlayerSnake& player) {
    auto& gameState = GameState::Instance();

    // Check invulnerability before allowing player to die from lava
    if (gameState.isInvulnerable) {
        gameState.ResetLavaTimer();
        return;  // No damage during invulnerability
    }

    const bool inPlayArea = IsCircleInsidePlayArea(player.position, player.radius);

    if (!inPlayArea) {
        if (!gameState.isInLava) {
            gameState.isInLava = true;
            gameState.timeInLava = 0;
        }

        gameState.timeInLava += gameState.deltaTime;
        if (gameState.timeInLava >= gameState.lavaWarningTime) {
            gameState.TriggerGameOver();
        }
    }
    else {
        gameState.ResetLavaTimer();
    }
}

void GameState::ResetForNewSession(const GameSettings& settings)
{
    std::lock_guard<std::mutex> lock(stateMutex);
    const Vector2 viewportCenter(
        static_cast<float>(GameConfig::WINDOW_WIDTH) / 2.0f,
        static_cast<float>(GameConfig::WINDOW_HEIGHT) / 2.0f);

    isMouseControlEnabled = false;
    isGameRunning = true;
    isPaused = false;
    isMenuShowing = false;
    targetDirection = Vector2(0, 1);
    camera.position = BuildCenteredCameraPosition(Vector2(0.0f, 0.0f));
    deltaTime = 1.0f / 30.0f;
    timeInLava = 0.0f;
    isInLava = false;
    foodEatenCount = 0;
    collisionFlashTimer = 0.0f;
    isCollisionFlashing = false;
    gameStartTime = 0.0f;
    isInvulnerable = true;
    showDeathMessage = false;
    finalScore = 0;
    returnToMenu = false;
    exitGame = false;
    isSpeedBoostActive = false;
    pausedWithSpeedBoost = false;
    gameplayMouseScreenPosition = viewportCenter;
    lastMouseActivationSample = viewportCenter;
    hasMouseActivationSample = false;
    ApplySessionSettings(settings);
}

/**
 * @brief 设置游戏难度
 * @param difficulty 难度枚举
 * 
 * 根据选择的难度设置相应的游戏参数
 */
void GameState::SetDifficulty(GameDifficulty difficulty)
{
    currentDifficulty = difficulty; 

    switch (currentDifficulty) {
    case GameDifficulty::Easy:
        currentPlayerSpeed = GameConfig::Difficulty::Easy::PLAYER_SPEED; 
        aiSnakeCount = GameConfig::Difficulty::Easy::AI_SNAKE_COUNT; 
        aiAggression = GameConfig::Difficulty::Easy::AI_AGGRESSION; 
        foodSpawnRate = GameConfig::Difficulty::Easy::FOOD_SPAWN_RATE; 
        lavaWarningTime = GameConfig::Difficulty::Easy::LAVA_WARNING_TIME;
        break;

    case GameDifficulty::Normal:
        currentPlayerSpeed = GameConfig::Difficulty::Normal::PLAYER_SPEED;
        aiSnakeCount = GameConfig::Difficulty::Normal::AI_SNAKE_COUNT; 
        aiAggression = GameConfig::Difficulty::Normal::AI_AGGRESSION; 
        foodSpawnRate = GameConfig::Difficulty::Normal::FOOD_SPAWN_RATE; 
        lavaWarningTime = GameConfig::Difficulty::Normal::LAVA_WARNING_TIME; 
        break;

    case GameDifficulty::Hard:
        currentPlayerSpeed = GameConfig::Difficulty::Hard::PLAYER_SPEED; 
        aiSnakeCount = GameConfig::Difficulty::Hard::AI_SNAKE_COUNT; 
        aiAggression = GameConfig::Difficulty::Hard::AI_AGGRESSION; 
        foodSpawnRate = GameConfig::Difficulty::Hard::FOOD_SPAWN_RATE; 
        lavaWarningTime = GameConfig::Difficulty::Hard::LAVA_WARNING_TIME; 
        break;
    }
}

void GameState::ApplySessionSettings(const GameSettings& settings)
{
    SessionTuning tuning = BuildSessionTuning(settings);

    difficulty = settings.difficulty;
    currentPlayerSpeed = tuning.playerSpeed;
    originalSpeed = tuning.playerSpeed;
    recordInterval = GameConfig::DEFAULT_RECORD_INTERVAL;
    aiSnakeCount = tuning.aiSnakeCount;
    aiAggression = tuning.aiAggression;
    foodSpawnRate = tuning.foodSpawnRate;
    lavaWarningTime = tuning.lavaWarningTime;

    switch (settings.difficulty) {
        case 0:
            currentDifficulty = GameDifficulty::Easy;
            break;
        case 2:
            currentDifficulty = GameDifficulty::Hard;
            break;
        case 1:
        default:
            currentDifficulty = GameDifficulty::Normal;
            break;
    }
}

void GameState::ResetLavaTimer()
{
    timeInLava = 0.0f; 
    isInLava = false;
}

void GameState::AddFoodEaten()
{
    foodEatenCount++; 
}

bool GameState::IsCollisionEnabled() const
{
    if (!GameConfig::ENABLE_COLLISION) return false;
    return !isInvulnerable;
}

float GameState::GetRemainingLavaWarningTime() const
{
    const float remainingTime = lavaWarningTime - timeInLava;
    return remainingTime > 0.0f ? remainingTime : 0.0f;
}

float GameState::GetRemainingInvulnerabilityTime() const
{
    const float remainingTime = GameConfig::COLLISION_GRACE_PERIOD - gameStartTime;
    return remainingTime > 0.0f ? remainingTime : 0.0f;
}

GameUISnapshot GameState::GetUISnapshot() const
{
    std::lock_guard<std::mutex> lock(stateMutex);

    GameUISnapshot snapshot;
    snapshot.score = foodEatenCount;
    snapshot.isInvulnerable = isInvulnerable;
    snapshot.remainingInvulnerabilityTime =
        (std::max)(0.0f, GameConfig::COLLISION_GRACE_PERIOD - gameStartTime);
    snapshot.isInLava = isInLava;
    snapshot.remainingLavaWarningTime = (std::max)(0.0f, lavaWarningTime - timeInLava);
    snapshot.isPaused = isPaused;
    snapshot.isMenuShowing = isMenuShowing;
    return snapshot;
}

void GameState::TriggerGameOver()
{
    isGameRunning = false;
    showDeathMessage = true;
    finalScore = foodEatenCount;
}

bool GameState::IsDeathMessagePending() const
{
    std::lock_guard<std::mutex> lock(stateMutex);
    return !isGameRunning && showDeathMessage;
}

bool GameState::IsSessionFinished() const
{
    std::lock_guard<std::mutex> lock(stateMutex);
    return !isGameRunning && !showDeathMessage;
}

void GameState::ClearDeathMessage()
{
    std::lock_guard<std::mutex> lock(stateMutex);
    showDeathMessage = false;
}

void GameState::ResumeGameplay()
{
    std::lock_guard<std::mutex> lock(stateMutex);
    const bool shouldRestoreHeldBoost = pausedWithSpeedBoost && ((GetAsyncKeyState(VK_LBUTTON) & 0x8000) != 0);
    if (shouldRestoreHeldBoost) {
        RestoreSpeedBoostStateLocked();
    } else {
        ResetSpeedBoostStateLocked();
    }
    pausedWithSpeedBoost = false;
    isPaused = false;
    isMenuShowing = false;
}

bool GameState::ConsumeMouseMovementForActivation(const Vector2& position)
{
    std::lock_guard<std::mutex> lock(stateMutex);

    const bool shouldActivate = HasMeaningfulMouseMovement(
        hasMouseActivationSample,
        lastMouseActivationSample,
        position);
    gameplayMouseScreenPosition = position;
    lastMouseActivationSample = position;
    hasMouseActivationSample = true;

    if (shouldActivate) {
        isMouseControlEnabled = true;
    }

    return shouldActivate;
}

void GameState::ResetMouseTracking(const Vector2& position)
{
    std::lock_guard<std::mutex> lock(stateMutex);
    gameplayMouseScreenPosition = position;
    lastMouseActivationSample = position;
    hasMouseActivationSample = false;
}

void GameState::PrimeMouseTracking(const Vector2& position)
{
    std::lock_guard<std::mutex> lock(stateMutex);
    gameplayMouseScreenPosition = position;
    lastMouseActivationSample = position;
    hasMouseActivationSample = true;
}

void GameState::StartSpeedBoost()
{
    std::lock_guard<std::mutex> lock(stateMutex);
    if (isSpeedBoostActive) {
        return;
    }

    originalSpeed = currentPlayerSpeed;
    currentPlayerSpeed *= 2.0f;
    recordInterval = GameConfig::DEFAULT_RECORD_INTERVAL / 2.0f;
    isSpeedBoostActive = true;
}

void GameState::StopSpeedBoost()
{
    std::lock_guard<std::mutex> lock(stateMutex);
    ResetSpeedBoostStateLocked();
}

void GameState::SetCameraPosition(const Vector2& position)
{
    std::lock_guard<std::mutex> lock(stateMutex);
    camera.position = position;
}

void GameState::RequestReturnToMenu()
{
    {
        std::lock_guard<std::mutex> lock(stateMutex);
        ResetSpeedBoostStateLocked();
        pausedWithSpeedBoost = false;
        returnToMenu = true;
        isPaused = false;
        isMenuShowing = false;
        isGameRunning = false;
        showDeathMessage = false;
    }

    StopBackgroundMusic();
}

void GameState::RequestExit()
{
    std::lock_guard<std::mutex> lock(stateMutex);
    ResetSpeedBoostStateLocked();
    pausedWithSpeedBoost = false;
    exitGame = true;
    returnToMenu = false;
    isPaused = false;
    isMenuShowing = false;
    isGameRunning = false;
    showDeathMessage = false;
}

bool GameState::ShouldReturnToMenu() const
{
    std::lock_guard<std::mutex> lock(stateMutex);
    return returnToMenu;
}

bool GameState::ShouldExitProgram() const
{
    std::lock_guard<std::mutex> lock(stateMutex);
    return exitGame;
}

void GameState::ClearSessionOutcome()
{
    std::lock_guard<std::mutex> lock(stateMutex);
    returnToMenu = false;
}

void GameState::ResetSpeedBoostStateLocked()
{
    const ClearedSpeedBoostState state = BuildClearedSpeedBoostState(originalSpeed);
    currentPlayerSpeed = state.currentPlayerSpeed;
    recordInterval = state.recordInterval;
    isSpeedBoostActive = state.isSpeedBoostActive;
}

void GameState::RestoreSpeedBoostStateLocked()
{
    if (isSpeedBoostActive) {
        return;
    }

    originalSpeed = currentPlayerSpeed;
    currentPlayerSpeed *= 2.0f;
    recordInterval = GameConfig::DEFAULT_RECORD_INTERVAL / 2.0f;
    isSpeedBoostActive = true;
}

void GameState::UpdateGameTime(float dt)
{
    // Don't update time if game is paused
    if (isPaused) return;
    
    gameStartTime += dt;
    
    if (isInvulnerable && gameStartTime >= GameConfig::COLLISION_GRACE_PERIOD) {
        isInvulnerable = false;
    }
}

void GameState::ShowDeathMessage() {
    StopBackgroundMusic();
    PlaySound(_T(".\\Resource\\SoundEffects\\Game-Over.wav"), NULL, SND_FILENAME | SND_ASYNC);

    const int panelWidth = 560;
    const int panelHeight = 438;
    const int panelLeft = (GameConfig::WINDOW_WIDTH - panelWidth) / 2;
    const int panelTop = (GameConfig::WINDOW_HEIGHT - panelHeight) / 2;
    const int panelRight = panelLeft + panelWidth;
    const int panelBottom = panelTop + panelHeight;

    const int scoreCardTop = panelTop + 116;
    const int scoreCardBottom = scoreCardTop + 118;

    const int buttonWidth = 214;
    const int buttonHeight = 60;
    const int buttonTop = panelBottom - 104;
    const int restartLeft = panelLeft + 34;
    const int menuLeft = panelRight - 34 - buttonWidth;

    Vector2 mousePos(static_cast<float>(GameConfig::WINDOW_WIDTH / 2), static_cast<float>(GameConfig::WINDOW_HEIGHT / 2));
    bool buttonSelected = false;
    returnToMenu = false;
    flushmessage();
    const DWORD introStartTick = GetTickCount();

    auto selectOutcome = [&](bool goToMenu) {
        returnToMenu = goToMenu;
        if (GameConfig::SOUND_ON) {
            PlaySound(_T(".\\Resource\\SoundEffects\\Button-Click.wav"), NULL, SND_FILENAME | SND_ASYNC);
        }
        buttonSelected = true;
    };

    BeginBatchDraw();

    while (!buttonSelected) {
        const float introProgress = GameConfig::ANIMATIONS_ON
            ? (std::min)(1.0f, static_cast<float>(GetTickCount() - introStartTick) / 280.0f)
            : 1.0f;
        const float reveal = SmoothUiProgress(introProgress);
        const bool allowInput = introProgress >= 1.0f;
        const int panelOffsetY = static_cast<int>((1.0f - reveal) * 34.0f);
        const int drawPanelTop = panelTop + panelOffsetY;
        const int drawPanelBottom = panelBottom + panelOffsetY;
        const int drawScoreCardTop = scoreCardTop + panelOffsetY;
        const int drawScoreCardBottom = scoreCardBottom + panelOffsetY;
        const int drawButtonTop = buttonTop + panelOffsetY;

        ExMessage message;
        while (peekmessage(&message, EX_MOUSE | EX_KEY)) {
            if (message.message == WM_MOUSEMOVE || message.message == WM_LBUTTONDOWN || message.message == WM_LBUTTONUP) {
                mousePos = Vector2(static_cast<float>(message.x), static_cast<float>(message.y));
            }

            if (!allowInput) {
                continue;
            }

            if (message.message == WM_KEYDOWN) {
                if (message.vkcode == 'R' || message.vkcode == VK_RETURN || message.vkcode == VK_SPACE) {
                    selectOutcome(false);
                    break;
                }

                if (message.vkcode == 'M' || message.vkcode == VK_ESCAPE) {
                    selectOutcome(true);
                    break;
                }
            }

            if (message.message == WM_LBUTTONDOWN) {
                const bool onRestart =
                    mousePos.x >= restartLeft && mousePos.x <= restartLeft + buttonWidth &&
                    mousePos.y >= drawButtonTop && mousePos.y <= drawButtonTop + buttonHeight;
                const bool onMenu =
                    mousePos.x >= menuLeft && mousePos.x <= menuLeft + buttonWidth &&
                    mousePos.y >= drawButtonTop && mousePos.y <= drawButtonTop + buttonHeight;

                if (onRestart) {
                    selectOutcome(false);
                    break;
                }

                if (onMenu) {
                    selectOutcome(true);
                    break;
                }
            }
        }

        const bool restartHovered = allowInput &&
            mousePos.x >= restartLeft && mousePos.x <= restartLeft + buttonWidth &&
            mousePos.y >= drawButtonTop && mousePos.y <= drawButtonTop + buttonHeight;
        const bool menuHovered = allowInput &&
            mousePos.x >= menuLeft && mousePos.x <= menuLeft + buttonWidth &&
            mousePos.y >= drawButtonTop && mousePos.y <= drawButtonTop + buttonHeight;
        const float pulse = 0.5f + 0.5f * sinf(GetTickCount() * 0.0052f);

        setfillcolor(RGB(7, 10, 18));
        solidrectangle(0, 0, GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT);
        setfillcolor(RGB(42, 16, 18));
        solidcircle(120, 110, static_cast<int>(110 + 10 * pulse));
        setfillcolor(RGB(17, 32, 48));
        solidcircle(GameConfig::WINDOW_WIDTH - 92, GameConfig::WINDOW_HEIGHT - 110, static_cast<int>(136 + 12 * pulse));

        setfillcolor(RGB(5, 9, 17));
        solidroundrect(panelLeft + 6, drawPanelTop + 8, panelRight + 6, drawPanelBottom + 8, 28, 28);
        setfillcolor(RGB(17, 24, 37));
        solidroundrect(panelLeft, drawPanelTop, panelRight, drawPanelBottom, 28, 28);
        setlinecolor(RGB(110, 64, 68));
        roundrect(panelLeft, drawPanelTop, panelRight, drawPanelBottom, 28, 28);

        setfillcolor(RGB(118, 35, 44));
        solidroundrect(panelLeft + 28, drawPanelTop + 26, panelLeft + 168, drawPanelTop + 60, 14, 14);
        setfillcolor(RGB(154, 42, 54));
        solidroundrect(panelLeft + 34, drawPanelTop + 100, panelLeft + 34 + static_cast<int>(192.0f * reveal), drawPanelTop + 110, 8, 8);
        setbkmode(TRANSPARENT);
        settextstyle(18, 0, _T("Bahnschrift"));
        settextcolor(RGB(255, 235, 237));
        outtextxy(panelLeft + 48, drawPanelTop + 31, _T("Run Lost"));

        settextstyle(50, 0, _T("Bahnschrift"));
        settextcolor(RGB(245, 248, 255));
        outtextxy(panelLeft + 30, drawPanelTop + 78, _T("GAME OVER"));

        settextstyle(20, 0, _T("Segoe UI"));
        settextcolor(RGB(188, 199, 216));
        outtextxy(panelLeft + 34, drawPanelTop + 154, _T("You were overwhelmed this round. Restart instantly or"));
        outtextxy(panelLeft + 34, drawPanelTop + 182, _T("return to the menu to adjust the run before diving back in."));

        setfillcolor(RGB(26, 35, 52));
        solidroundrect(panelLeft + 34, drawScoreCardTop, panelRight - 34, drawScoreCardBottom, 22, 22);
        setlinecolor(RGB(78, 103, 141));
        roundrect(panelLeft + 34, drawScoreCardTop, panelRight - 34, drawScoreCardBottom, 22, 22);

        settextstyle(20, 0, _T("Bahnschrift"));
        settextcolor(RGB(175, 201, 229));
        outtextxy(panelLeft + 58, drawScoreCardTop + 26, _T("Final Score"));
        settextstyle(44, 0, _T("Bahnschrift"));
        settextcolor(RGB(255, 230, 145));
        TCHAR scoreValue[32];
        _stprintf_s(scoreValue, _T("%d"), finalScore);
        outtextxy(panelRight - 70 - textwidth(scoreValue), drawScoreCardTop + 16, scoreValue);

        setfillcolor(RGB(22, 31, 46));
        solidroundrect(panelLeft + 34, drawScoreCardBottom + 24, panelRight - 34, drawScoreCardBottom + 108, 20, 20);
        settextstyle(18, 0, _T("Segoe UI"));
        settextcolor(RGB(181, 201, 224));
        outtextxy(panelLeft + 56, drawScoreCardBottom + 48, _T("R / Enter: restart immediately"));
        outtextxy(panelLeft + 56, drawScoreCardBottom + 76, _T("M / Esc: back to the main menu"));

        auto drawActionButton = [&](int left, LPCTSTR label, COLORREF baseColor, COLORREF hoverColor, bool hovered) {
            const COLORREF shadow = hovered ? RGB(23, 66, 98) : RGB(8, 15, 24);
            const COLORREF fill = hovered ? hoverColor : baseColor;
            setfillcolor(shadow);
            solidroundrect(left + 3, drawButtonTop + 5, left + buttonWidth + 3, drawButtonTop + buttonHeight + 5, 18, 18);
            setfillcolor(fill);
            solidroundrect(left, drawButtonTop, left + buttonWidth, drawButtonTop + buttonHeight, 18, 18);
            setlinecolor(hovered ? RGB(210, 241, 255) : RGB(116, 177, 220));
            roundrect(left, drawButtonTop, left + buttonWidth, drawButtonTop + buttonHeight, 18, 18);
            settextstyle(24, 0, _T("Bahnschrift"));
            settextcolor(RGB(246, 250, 255));
            outtextxy(left + (buttonWidth - textwidth(label)) / 2, drawButtonTop + (buttonHeight - textheight(label)) / 2, label);
        };

        drawActionButton(restartLeft, _T("Restart Run"), RGB(49, 148, 211), RGB(77, 179, 240), restartHovered);
        drawActionButton(menuLeft, _T("Main Menu"), RGB(57, 76, 101), RGB(90, 115, 146), menuHovered);

        FlushBatchDraw();
        Sleep(16);
    }

    EndBatchDraw();
}

void GameState::ShowPauseMenu() {
    // 使用互斥锁保护对共享状态的修改
    std::lock_guard<std::mutex> lock(stateMutex);

    pausedWithSpeedBoost = isSpeedBoostActive;
    ResetSpeedBoostStateLocked();

    // 强制暂停游戏并设置菜单显示标志
    isPaused = true;
    isMenuShowing = true;
    
    // No longer need to draw here as this will be handled in the regular drawing code
    // No longer need to enter a blocking loop waiting for input
    // Just set the state flags and return
    
    // Clear any pending messages to avoid immediate unpausing
    flushmessage();
}

