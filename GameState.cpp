#include "GameState.h"


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
    if (foodEatenCount >= 10) {
        foodEatenCount = 0;
    }
}

bool GameState::IsCollisionEnabled() const
{
    if (!GameConfig::ENABLE_COLLISION) return false;
    return !isInvulnerable;
}

void GameState::UpdateGameTime(float dt)
{
    gameStartTime += dt;
    
    // Update invincibility status
    if (isInvulnerable && gameStartTime >= GameConfig::COLLISION_GRACE_PERIOD) {
        isInvulnerable = false;
    }
}

void GameState::ShowDeathMessage() {
    // Clear screen
    cleardevice();
    
    // Create semi-transparent overlay
    setfillcolor(RGB(0, 0, 0));  // Use pure black
    solidrectangle(0, 0, GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT);
    
    // Draw message box
    const int msgBoxWidth = 400;
    const int msgBoxHeight = 300;
    const int msgBoxX = (GameConfig::WINDOW_WIDTH - msgBoxWidth) / 2;
    const int msgBoxY = (GameConfig::WINDOW_HEIGHT - msgBoxHeight) / 2;
    
    // Draw message box background
    setfillcolor(RGB(50, 50, 50));
    solidroundrect(msgBoxX, msgBoxY, msgBoxX + msgBoxWidth, msgBoxY + msgBoxHeight, 20, 20);
    
    // Draw border
    setlinecolor(RGB(150, 150, 150));
    roundrect(msgBoxX, msgBoxY, msgBoxX + msgBoxWidth, msgBoxY + msgBoxHeight, 20, 20);
    
    // Draw title
    settextstyle(32, 0, _T("Arial"));
    settextcolor(RGB(255, 50, 50));
    const TCHAR* title = _T("Game Over");
    int titleWidth = textwidth(title);
    outtextxy(msgBoxX + (msgBoxWidth - titleWidth) / 2, msgBoxY + 30, title);
    
    // Draw score
    settextstyle(24, 0, _T("Arial"));
    settextcolor(RGB(255, 255, 255));
    TCHAR scoreText[50];
    _stprintf(scoreText, _T("Your Score: %d"), this->foodEatenCount);
    int scoreWidth = textwidth(scoreText);
    outtextxy(msgBoxX + (msgBoxWidth - scoreWidth) / 2, msgBoxY + 100, scoreText);
    
    // Create two buttons
    const int btnWidth = 160;
    const int btnHeight = 50;
    const int btnY = msgBoxY + msgBoxHeight - 80;
    
    // Restart game button
    setfillcolor(RGB(50, 150, 50));
    solidroundrect(msgBoxX + 40, btnY, msgBoxX + 40 + btnWidth, btnY + btnHeight, 10, 10);
    
    // Return to menu button
    setfillcolor(RGB(150, 50, 50));
    solidroundrect(msgBoxX + msgBoxWidth - 40 - btnWidth, btnY, msgBoxX + msgBoxWidth - 40, btnY + btnHeight, 10, 10);
    
    // Button text
    settextstyle(20, 0, _T("Arial"));
    settextcolor(RGB(255, 255, 255));
    const TCHAR* restartText = _T("restart");
    const TCHAR* menuText = _T("return to menu");
    int restartWidth = textwidth(restartText);
    int menuWidth = textwidth(menuText);
    
    outtextxy(msgBoxX + 40 + (btnWidth - restartWidth) / 2, btnY + (btnHeight - textheight(restartText)) / 2, restartText);
    outtextxy(msgBoxX + msgBoxWidth - 40 - btnWidth + (btnWidth - menuWidth) / 2, btnY + (btnHeight - textheight(menuText)) / 2, menuText);
    
    // Draw prompt message
    settextstyle(16, 0, _T("Arial"));
    const TCHAR* promptText = _T("Click button or press R to restart, M to return to menu");
    int promptWidth = textwidth(promptText);
    outtextxy(msgBoxX + (msgBoxWidth - promptWidth) / 2, 
              msgBoxY + msgBoxHeight - 20, 
              promptText);
    
    // Refresh screen
    FlushBatchDraw();  // Ensure drawn content is displayed
    Sleep(500);  // Short delay to prevent accidental clicks
    
    // Prepare to handle mouse and keyboard
    bool buttonSelected = false;
    flushmessage();  // Clear message queue
    
    while (!buttonSelected) {
        if (_kbhit()) {
            int key = _getch();
            if (key == 'r' || key == 'R') {
                this->returnToMenu = false;  // Don't return to menu, restart game
                buttonSelected = true;
            }
            else if (key == 'm' || key == 'M' || key == VK_ESCAPE) {
                this->returnToMenu = true;   // Return to menu
                buttonSelected = true;
            }
        }
        
        // Check for mouse clicks
        if (GetAsyncKeyState(VK_LBUTTON) & 0x8000) {
            POINT pt;
            GetCursorPos(&pt);
            ScreenToClient(GetHWnd(), &pt);
            
            // Check if restart button was clicked
            if (pt.x >= msgBoxX + 40 && pt.x <= msgBoxX + 40 + btnWidth &&
                pt.y >= btnY && pt.y <= btnY + btnHeight) {
                this->returnToMenu = false;  // Don't return to menu, restart game
                buttonSelected = true;
            }
            
            // Check if return to menu button was clicked
            if (pt.x >= msgBoxX + msgBoxWidth - 40 - btnWidth && 
                pt.x <= msgBoxX + msgBoxWidth - 40 &&
                pt.y >= btnY && pt.y <= btnY + btnHeight) {
                this->returnToMenu = true;   // Return to menu
                buttonSelected = true;
            }
        }
        
        Sleep(50);  // Reduce CPU usage
    }
}
