#include "InputHandler.h"
#include <windows.h>
#include "../Core/GameRuntime.h"
#include "../UI/UI.h"
#include "../Gameplay/Snake.h"

namespace {

// 输入验证常量
constexpr int MAX_INPUT_QUEUE_SIZE = 100;
constexpr DWORD MAX_INPUT_AGE_MS = 5000; // 5秒

/**
 * @brief 验证方向是否有效
 * @param dir 方向
 * @return true 如果有效
 */
bool IsValidDirection(Direction dir) {
    return dir >= UP && dir <= RIGHT;
}

/**
 * @brief 验证位置是否在安全区域内
 * @param pos 位置
 * @return true 如果在安全区域内
 */
bool IsInBounds(const Vector2& pos) {
    const float MIN_BOUND = -10000.0f;
    const float MAX_BOUND = 10000.0f;
    return pos.x >= MIN_BOUND && pos.x <= MAX_BOUND &&
           pos.y >= MIN_BOUND && pos.y <= MAX_BOUND;
}

/**
 * @brief 获取相反方向
 * @param dir 当前方向
 * @return 相反方向
 */
Direction GetOppositeDirection(Direction dir) {
    switch (dir) {
        case UP: return DOWN;
        case DOWN: return UP;
        case LEFT: return RIGHT;
        case RIGHT: return LEFT;
        default: return dir;
    }
}

} // anonymous namespace

void EnterChanges() {
    auto& runtime = GameRuntime();
    
    // 输入处理计数器，防止无限循环
    int inputProcessCount = 0;
    const int MAX_INPUT_PROCESS = 1000;
    
    while (GameState::Instance().GetIsGameRunning()) {
        // 防止无限循环
        inputProcessCount++;
        if (inputProcessCount > MAX_INPUT_PROCESS) {
            inputProcessCount = 0;
            Sleep(100);
            continue;
        }

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
            // 验证消息类型
            if (Message.message != WM_KEYDOWN) {
                continue;
            }

            // 获取玩家蛇
            if (runtime.snake.empty()) {
                continue;
            }

            PlayerSnake* player = dynamic_cast<PlayerSnake*>(&runtime.snake[0]);
            if (!player) {
                continue;
            }

            Direction newDir = player->nextDir;
            bool validInput = false;

            switch (Message.vkcode) {
            case VK_UP:
                newDir = UP;
                validInput = true;
                break;
            case VK_DOWN:
                newDir = DOWN;
                validInput = true;
                break;
            case VK_LEFT:
                newDir = LEFT;
                validInput = true;
                break;
            case VK_RIGHT:
                newDir = RIGHT;
                validInput = true;
                break;
            default:
                // 忽略未识别的按键
                break;
            }

            // 验证方向变化
            if (validInput && IsValidDirection(newDir)) {
                // 防止180度转向（直接反向）
                Direction opposite = GetOppositeDirection(player->currentDir);
                if (newDir != opposite) {
                    player->nextDir = newDir;
                }
            }
        }

        Sleep(10);
    }
}

void HandleMouseInput() {
    ExMessage msg;
    
    // 使用peekmessage避免阻塞
    if (!peekmessage(&msg, EX_MOUSE)) {
        return;
    }
    
    // 只处理左键点击
    if (msg.message != WM_LBUTTONDOWN) {
        return;
    }

    // 验证鼠标坐标
    if (msg.x < 0 || msg.y < 0) {
        return;
    }

    // 安全检查：限制坐标范围
    const int MAX_COORD = 10000;
    if (msg.x > MAX_COORD || msg.y > MAX_COORD) {
        OutputDebugStringA("HandleMouseInput: Mouse coordinates out of range\n");
        return;
    }

    const int exitIconX = 220;
    const int exitIconY = 10;
    const int iconSize = GameConfig::MENU_ICON_SIZE;
    
    // 验证iconSize
    if (iconSize <= 0 || iconSize > MAX_COORD) {
        return;
    }

    // 检查是否点击退出图标
    if (msg.x >= exitIconX && msg.x <= exitIconX + iconSize &&
        msg.y >= exitIconY && msg.y <= exitIconY + iconSize) {
        
        // 使用MessageBox前验证窗口句柄
        HWND hwnd = GetHWnd();
        if (!hwnd || !IsWindow(hwnd)) {
            OutputDebugStringA("HandleMouseInput: Invalid window handle\n");
            return;
        }

        int result = MessageBox(hwnd, TEXT("Are you sure to exit game?"), TEXT("Exit"), MB_YESNO | MB_ICONQUESTION);
        if (result == IDYES) {
            StopBackgroundMusic();
            GameState::Instance().isGameRunning = false;
        }
    }
}

bool IsInSafeArea(const Vector2& pos) {
    // 验证输入参数
    if (!IsInBounds(pos)) {
        return false;
    }

    // 验证游戏区域配置
    if (GameConfig::PLAY_AREA_LEFT >= GameConfig::PLAY_AREA_RIGHT ||
        GameConfig::PLAY_AREA_TOP >= GameConfig::PLAY_AREA_BOTTOM) {
        OutputDebugStringA("IsInSafeArea: Invalid play area configuration\n");
        return false;
    }

    return pos.x >= GameConfig::PLAY_AREA_LEFT &&
           pos.x <= GameConfig::PLAY_AREA_RIGHT &&
           pos.y >= GameConfig::PLAY_AREA_TOP &&
           pos.y <= GameConfig::PLAY_AREA_BOTTOM;
}

/**
 * @brief 验证并处理键盘输入队列
 * @return true 如果成功处理
 */
bool ProcessInputQueue() {
    static int queueSize = 0;
    
    if (queueSize > MAX_INPUT_QUEUE_SIZE) {
        OutputDebugStringA("ProcessInputQueue: Input queue overflow, clearing\n");
        queueSize = 0;
        // 清空输入队列
        ExMessage msg;
        while (peekmessage(&msg, EX_KEY)) {
            // 消费所有消息
        }
        return false;
    }
    
    queueSize = 0;
    return true;
}

/**
 * @brief 安全地获取键盘状态
 * @param vKey 虚拟键码
 * @return 键的状态
 */
SHORT SafeGetAsyncKeyState(int vKey) {
    // 验证虚拟键码范围
    if (vKey < 0x01 || vKey > 0xFE) {
        return 0;
    }
    
    return GetAsyncKeyState(vKey);
}
