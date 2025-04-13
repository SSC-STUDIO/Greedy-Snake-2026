#include "InputHandler.h"
#include "..\Core\GameConfig.h"
#include <windows.h>
#include "..\UI\UI.h"

// Global declaration (imported from Main.cpp)
extern Snake snake[1];

void EnterChanges() {
    while (GameState::Instance().GetIsGameRunning()) {
        // Handle mouse movement for direction
        if (GameState::Instance().isMouseControlEnabled && !GameState::Instance().GetIsPaused()) {
            POINT mousePoint;
            GetCursorPos(&mousePoint);
            ScreenToClient(GetHWnd(), &mousePoint);
            
            Vector2 mousePosition(mousePoint.x, mousePoint.y);
            Vector2 screenCenter(GameConfig::WINDOW_WIDTH / 2, GameConfig::WINDOW_HEIGHT / 2);
            Vector2 direction = (mousePosition - screenCenter).GetNormalize();
            
            if (direction.GetLength() > 0.0f) {
                GameState::Instance().SetTargetDirection(direction);
            }
        }
        
        // Check for ESC key press for pausing
        if (GetAsyncKeyState(VK_ESCAPE) & 0x01) {
            // Toggle pause state
            if (!GameState::Instance().GetIsPaused()) {
                GameState::Instance().ShowPauseMenu();
            } else if (GameState::Instance().GetIsMenuShowing()) {
                GameState::Instance().SetIsPaused(false);
                GameState::Instance().SetIsMenuShowing(false);
            }
        }
        
        // Handle pause menu inputs when paused and menu is showing
        if (GameState::Instance().GetIsPaused() && GameState::Instance().GetIsMenuShowing()) {
            // Handle keyboard inputs for pause menu
            if (_kbhit()) {
                int key = _getch();
                if (key == 'r' || key == 'R') {
                    GameState::Instance().SetIsPaused(false);
                    GameState::Instance().SetIsMenuShowing(false);
                } 
                else if (key == 'm' || key == 'M') {
                    StopBackgroundMusic();
                    GameState::Instance().SetIsGameRunning(false);
                    {
                        std::lock_guard<std::mutex> lock(GameState::Instance().stateMutex);
                        GameState::Instance().returnToMenu = true;
                    }
                    GameState::Instance().SetIsMenuShowing(false);
                } 
                else if (key == 'q' || key == 'Q') {
                    StopBackgroundMusic();
                    GameState::Instance().SetIsGameRunning(false);
                    {
                        std::lock_guard<std::mutex> lock(GameState::Instance().stateMutex);
                        GameState::Instance().exitGame = true;
                    }
                    GameState::Instance().SetIsMenuShowing(false);
                }
            }
            
            // Handle mouse inputs for pause menu
            ExMessage msg;
            if (peekmessage(&msg, EM_MOUSE)) {
                if (msg.message == WM_LBUTTONDOWN) {
                    // Calculate button positions
                    int pauseBoxWidth = 400;
                    int pauseBoxHeight = 350;
                    int pauseBoxX = (GameConfig::WINDOW_WIDTH - pauseBoxWidth) / 2;
                    int pauseBoxY = (GameConfig::WINDOW_HEIGHT - pauseBoxHeight) / 2;
                    int btnWidth = 280;
                    int btnHeight = 50;
                    int btnX = pauseBoxX + (pauseBoxWidth - btnWidth) / 2;
                    int btnSpacing = 20;
                    
                    // Continue game button
                    if (msg.x >= btnX && msg.x <= btnX + btnWidth && 
                        msg.y >= pauseBoxY + 100 && msg.y <= pauseBoxY + 100 + btnHeight) {
                        GameState::Instance().SetIsPaused(false);
                        GameState::Instance().SetIsMenuShowing(false);
                    }
                    // Main menu button
                    else if (msg.x >= btnX && msg.x <= btnX + btnWidth && 
                             msg.y >= pauseBoxY + 100 + btnHeight + btnSpacing && 
                             msg.y <= pauseBoxY + 100 + btnHeight*2 + btnSpacing) {
                        StopBackgroundMusic();
                        GameState::Instance().SetIsGameRunning(false);
                        {
                            std::lock_guard<std::mutex> lock(GameState::Instance().stateMutex);
                            GameState::Instance().returnToMenu = true;
                        }
                        GameState::Instance().SetIsMenuShowing(false);
                    }
                    // Exit game button
                    else if (msg.x >= btnX && msg.x <= btnX + btnWidth && 
                             msg.y >= pauseBoxY + 100 + (btnHeight + btnSpacing)*2 && 
                             msg.y <= pauseBoxY + 100 + (btnHeight + btnSpacing)*2 + btnHeight) {
                        StopBackgroundMusic();
                        GameState::Instance().SetIsGameRunning(false);
                        {
                            std::lock_guard<std::mutex> lock(GameState::Instance().stateMutex);
                            GameState::Instance().exitGame = true;
                        }
                        GameState::Instance().SetIsMenuShowing(false);
                    }
                }
            }
        }
        else {
            // Process regular game inputs when not in pause menu
            ExMessage Message;
            if (peekmessage(&Message, EX_MOUSE | EX_KEY)) {
                switch (Message.message) {
                case WM_RBUTTONDOWN:
                    {
                        std::lock_guard<std::mutex> lock(GameState::Instance().stateMutex);
                        GameState::Instance().isMouseControlEnabled = true;
                    }
                    break;
                case WM_MOUSEMOVE:
                    if (!GameState::Instance().isMouseControlEnabled || GameState::Instance().GetIsPaused())
                        break;
                    {
                        Vector2 mouseWorldPos = Vector2(Message.x, Message.y) + GameState::Instance().camera.position;
                        GameState::Instance().SetTargetDirection((mouseWorldPos - snake[0].position).GetNormalize());
                    }
                    break;
                case WM_LBUTTONDOWN:
                    {
                        std::lock_guard<std::mutex> lock(GameState::Instance().stateMutex);
                        GameState::Instance().originalSpeed = GameState::Instance().currentPlayerSpeed;
                        GameState::Instance().currentPlayerSpeed *= 2;
                        GameState::Instance().recordInterval = GameConfig::DEFAULT_RECORD_INTERVAL / 2;
                    }
                    break;
                case WM_LBUTTONUP:
                    {
                        std::lock_guard<std::mutex> lock(GameState::Instance().stateMutex);
                        GameState::Instance().currentPlayerSpeed = GameState::Instance().originalSpeed;
                        GameState::Instance().recordInterval = GameConfig::DEFAULT_RECORD_INTERVAL;
                    }
                    break;
                case WM_KEYDOWN:
                    {
                        std::lock_guard<std::mutex> lock(GameState::Instance().stateMutex);
                        GameState::Instance().isMouseControlEnabled = false;
                    }
                    switch (Message.vkcode) {
                    case VK_UP:
                        GameState::Instance().SetTargetDirection(Vector2(0, -1));
                        break;
                    case VK_DOWN:
                        GameState::Instance().SetTargetDirection(Vector2(0, 1));
                        break;
                    case VK_LEFT:
                        GameState::Instance().SetTargetDirection(Vector2(-1, 0));
                        break;
                    case VK_RIGHT:
                        GameState::Instance().SetTargetDirection(Vector2(1, 0));
                        break;
                    }
                    break;
                }
            }
        }
    }
}

void HandleMouseInput() {
    ExMessage msg = getmessage(EX_MOUSE);
    if (msg.message == WM_LBUTTONDOWN) {
        const int exitIconX = 220;
        const int exitIconY = 10;
        const int iconSize = GameConfig::MENU_ICON_SIZE;

        if (msg.x >= exitIconX && msg.x <= exitIconX + iconSize &&
            msg.y >= exitIconY && msg.y <= exitIconY + iconSize) {
            if (MessageBox(GetHWnd(), TEXT("Are you sure to exit game?"), TEXT("exit"), MB_YESNO) == IDYES) {
                StopBackgroundMusic();
                GameState::Instance().isGameRunning = false;
            }
        }
    }
}

bool IsInSafeArea(const Vector2& pos) {
    return pos.x >= GameConfig::PLAY_AREA_LEFT && 
           pos.x <= GameConfig::PLAY_AREA_RIGHT &&
           pos.y >= GameConfig::PLAY_AREA_TOP && 
           pos.y <= GameConfig::PLAY_AREA_BOTTOM;
} 