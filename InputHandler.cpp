#include "InputHandler.h"
#include "GameConfig.h"
#include <windows.h>

// Global declaration (imported from Main.cpp)
extern Snake snake[1];

void EnterChanges() {
    ExMessage Message;
    Vector2 mouseWorldPos;

    while (GameState::Instance().isGameRunning) {
        if (peekmessage(&Message, EX_MOUSE | EX_KEY)) {
            switch (Message.message) {
            case WM_RBUTTONDOWN:
                GameState::Instance().isMouseControlEnabled = true;
                break;
            case WM_MOUSEMOVE:
                if (!GameState::Instance().isMouseControlEnabled)
                    break;
                mouseWorldPos = Vector2(Message.x, Message.y) + GameState::Instance().camera.position;
                GameState::Instance().targetDirection = (mouseWorldPos - snake[0].position).GetNormalize();
                break;
            case WM_LBUTTONDOWN:
                GameState::Instance().originalSpeed = GameState::Instance().currentPlayerSpeed;
                GameState::Instance().currentPlayerSpeed *= 2;
                GameState::Instance().recordInterval = GameConfig::DEFAULT_RECORD_INTERVAL / 2;
                break;
            case WM_LBUTTONUP:
                GameState::Instance().currentPlayerSpeed = GameState::Instance().originalSpeed;
                GameState::Instance().recordInterval = GameConfig::DEFAULT_RECORD_INTERVAL;
                break;
            case WM_KEYDOWN:
                GameState::Instance().isMouseControlEnabled = false;
                switch (Message.vkcode) {
                case VK_UP:
                    GameState::Instance().targetDirection = Vector2(0, -1);
                    break;
                case VK_DOWN:
                    GameState::Instance().targetDirection = Vector2(0, 1);
                    break;
                case VK_LEFT:
                    GameState::Instance().targetDirection = Vector2(-1, 0);
                    break;
                case VK_RIGHT:
                    GameState::Instance().targetDirection = Vector2(1, 0);
                    break;
                case VK_ESCAPE:
                    GameState::Instance().isPaused = true;
                    break;
                }
                break;
            }
        }
    }
}

void HandleMouseInput() {
    ExMessage msg = getmessage(EX_MOUSE);
    if (msg.message == WM_LBUTTONDOWN) {
        // Check exit icon click area
        const int exitIconX = 220;
        const int exitIconY = 10;
        const int iconSize = GameConfig::MENU_ICON_SIZE;

        if (msg.x >= exitIconX && msg.x <= exitIconX + iconSize &&
            msg.y >= exitIconY && msg.y <= exitIconY + iconSize) {
            // Trigger exit operation
            if (MessageBox(GetHWnd(), TEXT("Are you sure to exit game?"), TEXT("exit"), MB_YESNO) == IDYES) {
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