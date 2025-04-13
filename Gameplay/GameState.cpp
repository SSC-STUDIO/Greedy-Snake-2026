#include "GameState.h"
#include "../Core/Camera.h"
#include "../UI/UI.h"
#include "../Core/GameConfig.h"

// Add static variables initializations
DWORD GameState::lastTime = GetTickCount();
bool GameState::exitGame = false;

void CheckGameState(Snake* snake) {
    auto& gameState = GameState::Instance();
    
    bool inPlayArea = snake[0].position.x >= GameConfig::PLAY_AREA_LEFT &&
        snake[0].position.x <= GameConfig::PLAY_AREA_RIGHT &&
        snake[0].position.y >= GameConfig::PLAY_AREA_TOP &&
        snake[0].position.y <= GameConfig::PLAY_AREA_BOTTOM;

    if (!inPlayArea) {
        if (!gameState.isInLava) {
            gameState.isInLava = true;
            gameState.timeInLava = 0;
        }

        gameState.timeInLava += gameState.deltaTime;
        if (gameState.timeInLava >= GameConfig::LAVA_WARNING_TIME) {
            gameState.isGameRunning = false;
            gameState.showDeathMessage = true;
            gameState.finalScore = gameState.foodEatenCount;
        }
    }
    else {
        gameState.ResetLavaTimer();
    }
}

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
    cleardevice();

	// Stop background music
    StopBackgroundMusic();

    // Play game over sound
    PlaySound(_T(".\\Resource\\SoundEffects\\Game-Over.wav"), NULL, SND_FILENAME | SND_ASYNC);
    
    setfillcolor(RGB(0, 0, 0));
    solidrectangle(0, 0, GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT);
    
    const int msgBoxWidth = 400;
    const int msgBoxHeight = 300;
    const int msgBoxX = (GameConfig::WINDOW_WIDTH - msgBoxWidth) / 2;
    const int msgBoxY = (GameConfig::WINDOW_HEIGHT - msgBoxHeight) / 2;
    
    setfillcolor(RGB(50, 50, 50));
    solidroundrect(msgBoxX, msgBoxY, msgBoxX + msgBoxWidth, msgBoxY + msgBoxHeight, 20, 20);
    
    setlinecolor(RGB(150, 150, 150));
    roundrect(msgBoxX, msgBoxY, msgBoxX + msgBoxWidth, msgBoxY + msgBoxHeight, 20, 20);
    
    settextstyle(32, 0, _T("Arial"));
    settextcolor(RGB(255, 50, 50));
    
    const TCHAR* title = _T("GAME OVER");
    int titleWidth = textwidth(title);
    outtextxy(msgBoxX + (msgBoxWidth - titleWidth) / 2, msgBoxY + 30, title);
    
    settextstyle(24, 0, _T("Arial"));
    settextcolor(RGB(255, 255, 255));
    
    TCHAR scoreText[50];
    _stprintf_s(scoreText, _T("Your score: %d"), finalScore);
    int scoreWidth = textwidth(scoreText);
    outtextxy(msgBoxX + (msgBoxWidth - scoreWidth) / 2, msgBoxY + 100, scoreText);
    
    const int btnWidth = 160;
    const int btnHeight = 50;
    const int btnY = msgBoxY + msgBoxHeight - 80;
    
    setfillcolor(RGB(50, 150, 50));
    solidroundrect(msgBoxX + 40, btnY, msgBoxX + 40 + btnWidth, btnY + btnHeight, 10, 10);
    
    setfillcolor(RGB(150, 50, 50));
    solidroundrect(msgBoxX + msgBoxWidth - 40 - btnWidth, btnY, msgBoxX + msgBoxWidth - 40, btnY + btnHeight, 10, 10);
    
    settextstyle(20, 0, _T("Arial"));
    settextcolor(RGB(255, 255, 255));
    
    const TCHAR* restartText = _T("Restart");
    const TCHAR* menuText = _T("Main Menu");
    int restartWidth = textwidth(restartText);
    int menuWidth = textwidth(menuText);
    
    outtextxy(msgBoxX + 40 + (btnWidth - restartWidth) / 2, btnY + (btnHeight - textheight(restartText)) / 2, restartText);
    outtextxy(msgBoxX + msgBoxWidth - 40 - btnWidth + (btnWidth - menuWidth) / 2, btnY + (btnHeight - textheight(menuText)) / 2, menuText);
    
    settextstyle(16, 0, _T("Arial"));
    const TCHAR* promptText = _T("Click button or press R to restart, M to return to menu");
    int promptWidth = textwidth(promptText);
    outtextxy(msgBoxX + (msgBoxWidth - promptWidth) / 2, 
              msgBoxY + msgBoxHeight - 30,
              promptText);
    
    FlushBatchDraw();
    Sleep(500);
    
    bool buttonSelected = false;
    flushmessage();
    
    while (!buttonSelected) {
        if (_kbhit()) {
            int key = _getch();
            if (key == 'r' || key == 'R') {
                this->returnToMenu = false;
                buttonSelected = true;
            }
            else if (key == 'm' || key == 'M' || key == VK_ESCAPE) {
                this->returnToMenu = true;
                buttonSelected = true;
            }
        }
        
        if (GetAsyncKeyState(VK_LBUTTON) & 0x8000) {
            POINT pt;
            GetCursorPos(&pt);
            ScreenToClient(GetHWnd(), &pt);
            
            if (pt.x >= msgBoxX + 40 && pt.x <= msgBoxX + 40 + btnWidth &&
               pt.y >= btnY && pt.y <= btnY + btnHeight) {
                this->returnToMenu = false;
                buttonSelected = true;
            }
            
            if (pt.x >= msgBoxX + msgBoxWidth - 40 - btnWidth && 
               pt.x <= msgBoxX + msgBoxWidth - 40 &&
               pt.y >= btnY && pt.y <= btnY + btnHeight) {
                this->returnToMenu = true;
                buttonSelected = true;
            }
        }
        
        Sleep(50);
    }
}

void GameState::ShowPauseMenu() {
    // 使用互斥锁保护对共享状态的修改
    std::lock_guard<std::mutex> lock(stateMutex);
    
    // 强制暂停游戏并设置菜单显示标志
    isPaused = true;
    isMenuShowing = true;
    
    // No longer need to draw here as this will be handled in the regular drawing code
    // No longer need to enter a blocking loop waiting for input
    // Just set the state flags and return
    
    // Clear any pending messages to avoid immediate unpausing
    flushmessage();
}

void GameState::Update(float deltaTime) {
    // Update invulnerability status
    if (isInvulnerable && gameStartTime >= GameConfig::COLLISION_GRACE_PERIOD) {
        isInvulnerable = false;
    }
    
    // Update collision flash
    if (isCollisionFlashing) {
        collisionFlashTimer -= deltaTime;
        if (collisionFlashTimer <= 0.0f) {
            isCollisionFlashing = false;
        }
    }
    
    // Update time in lava if player is outside play area
    if (isInLava) {
        timeInLava += deltaTime;
        if (timeInLava >= lavaWarningTime) {
            isGameRunning = false;
            showDeathMessage = true;
            finalScore = foodEatenCount;
        }
    }
}
