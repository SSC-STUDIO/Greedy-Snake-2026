#include "InputHandler.h"
#include <windows.h>
#include "../Core/GameRuntime.h"
#include "../UI/UI.h"
#include "../Gameplay/Snake.h"

void EnterChanges() {
    auto& runtime = GameRuntime();
    while (GameState::Instance().GetIsGameRunning()) {
        if (GameState::Instance().GetIsPaused()) {
            if (GetAsyncKeyState(VK_ESCAPE) & 0x01) {
                GameState::Instance().SetIsPaused(false);
                GameState::Instance().SetIsMenuShowing(false);
            }
            Sleep(10);
            continue;
        }

        if (GetAsyncKeyState(VK_ESCAPE) & 0x01) {
            GameState::Instance().ShowPauseMenu();
            continue;
        }

        ExMessage Message;
        if (peekmessage(&Message, EX_KEY)) {
            if (Message.message == WM_KEYDOWN) {
                PlayerSnake& player = static_cast<PlayerSnake&>(runtime.snake[0]);

                switch (Message.vkcode) {
                case VK_UP:
                    player.nextDir = UP;
                    break;
                case VK_DOWN:
                    player.nextDir = DOWN;
                    break;
                case VK_LEFT:
                    player.nextDir = LEFT;
                    break;
                case VK_RIGHT:
                    player.nextDir = RIGHT;
                    break;
                }
            }
        }

        Sleep(10);
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