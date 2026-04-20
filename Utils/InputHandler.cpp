#include "InputHandler.h"
#include <windows.h>
#include "../Core/GameRuntime.h"
#include "../Core/SessionConfig.h"
#include "../UI/UI.h"
#include "../Gameplay/Snake.h"

namespace {
Vector2 CaptureGameplayMousePosition() {
    POINT mousePoint;
    GetCursorPos(&mousePoint);
    ScreenToClient(GetHWnd(), &mousePoint);
    return Vector2(static_cast<float>(mousePoint.x), static_cast<float>(mousePoint.y));
}

void UpdateMouseSteering(GameState& gameState) {
    if (!gameState.IsMouseControlEnabled()) {
        return;
    }

    const Vector2 mousePosition = CaptureGameplayMousePosition();
    if (!IsPointInsideGameplayViewport(mousePosition)) {
        return;
    }

    gameState.SetGameplayMouseScreenPosition(mousePosition);

    auto& runtime = GameRuntime();
    const Vector2 playerScreenPosition = runtime.playerSnake.position - gameState.camera.position;
    const Vector2 direction = ResolveMouseSteeringDirection(mousePosition, playerScreenPosition);
    if (direction.LengthSquared() > 0.0f) {
        gameState.SetTargetDirection(direction);
    }
}

void UpdateMouseStateFromMessage(GameState& gameState, const ExMessage& message) {
    const Vector2 mousePosition(static_cast<float>(message.x), static_cast<float>(message.y));
    if (!IsPointInsideGameplayViewport(mousePosition)) {
        return;
    }

    gameState.ConsumeMouseMovementForActivation(mousePosition);

    if (message.message == WM_LBUTTONDOWN || message.message == WM_RBUTTONDOWN) {
        gameState.SetGameplayMouseScreenPosition(mousePosition);
        gameState.SetMouseControlEnabled(true);
    }
}

void DrainPausedGameplayMessages(GameState& gameState) {
    ExMessage message;
    while (peekmessage(&message, EX_MOUSE | EX_KEY)) {
        (void)message;
    }

    const Vector2 mousePosition = CaptureGameplayMousePosition();
    if (IsPointInsideGameplayViewport(mousePosition)) {
        gameState.PrimeMouseTracking(mousePosition);
    }
}
}

void PollGameplayInput() {
    auto& gameState = GameState::Instance();

    if (!gameState.GetIsGameRunning()) {
        return;
    }

    if (gameState.GetIsPaused()) {
        if ((GetAsyncKeyState(VK_ESCAPE) & 0x01) || (GetAsyncKeyState('P') & 0x01) || (GetAsyncKeyState('S') & 0x01)) {
            gameState.ResumeGameplay();
        } else if (GetAsyncKeyState('M') & 0x01) {
            gameState.RequestReturnToMenu();
        } else if (GetAsyncKeyState('Q') & 0x01) {
            gameState.RequestExit();
        }
        DrainPausedGameplayMessages(gameState);
        return;
    }

    if ((GetAsyncKeyState(VK_ESCAPE) & 0x01) || (GetAsyncKeyState('P') & 0x01)) {
        gameState.ShowPauseMenu();
        return;
    }

    ExMessage message;
    while (peekmessage(&message, EX_MOUSE | EX_KEY)) {
        switch (message.message) {
            case WM_MOUSEMOVE:
                UpdateMouseStateFromMessage(gameState, message);
                break;
            case WM_RBUTTONDOWN:
                UpdateMouseStateFromMessage(gameState, message);
                break;
            case WM_LBUTTONDOWN:
                UpdateMouseStateFromMessage(gameState, message);
                gameState.StartSpeedBoost();
                break;
            case WM_LBUTTONUP:
                gameState.StopSpeedBoost();
                break;
            case WM_KEYDOWN:
                gameState.SetMouseControlEnabled(false);
                switch (message.vkcode) {
                    case VK_UP:
                        gameState.SetTargetDirection(Vector2(0, -1));
                        break;
                    case VK_DOWN:
                        gameState.SetTargetDirection(Vector2(0, 1));
                        break;
                    case VK_LEFT:
                        gameState.SetTargetDirection(Vector2(-1, 0));
                        break;
                    case VK_RIGHT:
                        gameState.SetTargetDirection(Vector2(1, 0));
                        break;
                }
                break;
        }
    }

    UpdateMouseSteering(gameState);
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
                GameState::Instance().RequestExit();
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
