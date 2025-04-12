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
    // Draw semi-transparent overlay
    setfillcolor(RGB(0, 0, 0, 180)); // Semi-transparent black
    solidrectangle(0, 0, GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT);
    
    // Draw pause menu box
    int pauseBoxWidth = 400;
    int pauseBoxHeight = 300;
    int pauseBoxX = (GameConfig::WINDOW_WIDTH - pauseBoxWidth) / 2;
    int pauseBoxY = (GameConfig::WINDOW_HEIGHT - pauseBoxHeight) / 2;
    
    // Draw the pause menu box
    setfillcolor(RGB(40, 40, 40));
    solidroundrect(pauseBoxX, pauseBoxY, pauseBoxX + pauseBoxWidth, pauseBoxY + pauseBoxHeight, 15, 15);
    
    // Draw menu title
    settextstyle(32, 0, _T("Arial"));
    settextcolor(WHITE);
    const TCHAR* pauseTitle = _T("GAME PAUSED");
    int titleWidth = textwidth(pauseTitle);
    outtextxy(pauseBoxX + (pauseBoxWidth - titleWidth) / 2, pauseBoxY + 30, pauseTitle);
    
    // Draw menu buttons
    int btnWidth = 280;
    int btnHeight = 50;
    int btnX = pauseBoxX + (pauseBoxWidth - btnWidth) / 2;
    int btnY = pauseBoxY + 100;
    int btnSpacing = 20;
    
    // Resume button
    setfillcolor(RGB(60, 120, 60));
    solidroundrect(btnX, btnY, btnX + btnWidth, btnY + btnHeight, 10, 10);
    settextstyle(24, 0, _T("Arial"));
    const TCHAR* resumeText = _T("Resume Game");
    int resumeWidth = textwidth(resumeText);
    outtextxy(btnX + (btnWidth - resumeWidth) / 2, btnY + (btnHeight - textheight(resumeText)) / 2, resumeText);
    
    // Main menu button
    btnY += btnHeight + btnSpacing;
    setfillcolor(RGB(80, 80, 150));
    solidroundrect(btnX, btnY, btnX + btnWidth, btnY + btnHeight, 10, 10);
    const TCHAR* menuText = _T("Return to Main Menu");
    int menuWidth = textwidth(menuText);
    outtextxy(btnX + (btnWidth - menuWidth) / 2, btnY + (btnHeight - textheight(menuText)) / 2, menuText);
    
    // Exit game button
    btnY += btnHeight + btnSpacing;
    setfillcolor(RGB(150, 60, 60));
    solidroundrect(btnX, btnY, btnX + btnWidth, btnY + btnHeight, 10, 10);
    const TCHAR* exitText = _T("Exit Game");
    int exitWidth = textwidth(exitText);
    outtextxy(btnX + (btnWidth - exitWidth) / 2, btnY + (btnHeight - textheight(exitText)) / 2, exitText);
    
    // Draw key hints
    settextstyle(16, 0, _T("Arial"));
    const TCHAR* promptText = _T("Press ESC to resume, M for menu, Q to quit");
    int promptWidth = textwidth(promptText);
    outtextxy(pauseBoxX + (pauseBoxWidth - promptWidth) / 2, 
              pauseBoxY + pauseBoxHeight - 30,
              promptText);
    
    FlushBatchDraw();
    
    // Process user input for pause menu
    bool pauseActive = true;
    ExMessage msg;
    flushmessage(); // Clear any pending messages to ensure we only process new inputs
    
    // Button areas
    int resumeBtnY = pauseBoxY + 100;
    int menuBtnY = resumeBtnY + btnHeight + btnSpacing;
    int exitBtnY = menuBtnY + btnHeight + btnSpacing;
    
    // Keep looping until the user makes a selection
    // This is critical to block the main thread until a choice is made
    while (pauseActive) {
        // Check for key presses
        if (_kbhit()) {
            int key = _getch();
            if (key == VK_ESCAPE) {
                this->isPaused = false;
                pauseActive = false;
            }
            else if (key == 'm' || key == 'M') {
                this->isPaused = false;
                this->isGameRunning = false;
                this->returnToMenu = true;
                pauseActive = false;
            }
            else if (key == 'q' || key == 'Q') {
                this->isPaused = false;
                this->isGameRunning = false;
                pauseActive = false;
                exit(0); // Force exit the game
            }
        }
        
        // Poll for mouse events
        if (peekmessage(&msg, EX_MOUSE)) {
            if (msg.message == WM_LBUTTONDOWN) {
                // Check if clicked on resume button
                if (msg.x >= btnX && msg.x <= btnX + btnWidth && 
                    msg.y >= resumeBtnY && msg.y <= resumeBtnY + btnHeight) {
                    this->isPaused = false;
                    pauseActive = false;
                }
                
                // Check if clicked on main menu button
                if (msg.x >= btnX && msg.x <= btnX + btnWidth && 
                    msg.y >= menuBtnY && msg.y <= menuBtnY + btnHeight) {
                    this->isPaused = false;
                    this->isGameRunning = false;
                    this->returnToMenu = true;
                    pauseActive = false;
                }
                
                // Check if clicked on exit button
                if (msg.x >= btnX && msg.x <= btnX + btnWidth && 
                    msg.y >= exitBtnY && msg.y <= exitBtnY + btnHeight) {
                    this->isPaused = false;
                    this->isGameRunning = false;
                    pauseActive = false;
                    exit(0); // Force exit the game
                }
            }
        }
        
        // Redraw the pause menu to ensure it remains visible
        // This is important to prevent the menu from being overwritten by other drawing operations
        FlushBatchDraw();
        
        Sleep(50); // Reduce CPU usage but still be responsive
    }
    
    // Make sure the pause flag is cleared when exiting
    this->isPaused = false;
}
