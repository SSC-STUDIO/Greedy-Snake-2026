#include <winsock2.h>
#include <windows.h>
#include <ctime>
#include <cstdlib>
#include <chrono>
#include <vector>
#include <algorithm>
#include <stdexcept>
#include "./Core/GameState.h"
#include "./Core/GameRuntime.h"
#include "./Core/ResourceManager.h"
#include "./Utils/InputHandler.h"
#include "./Utils/Setting.h"
#include "./UI/UI.h"
#include "./Gameplay/Food.h"
#include "./Gameplay/Snake.h"

namespace {

// 内存管理常量
constexpr size_t MAX_AI_SNAKES = 100;
constexpr size_t MAX_FOOD_ITEMS = 10000;
constexpr DWORD MAX_GAME_RUNTIME_MS = 86400000; // 24小时
constexpr int MAX_RESTART_ATTEMPTS = 3;

/**
 * @brief 验证内存分配是否成功
 * @tparam T 类型
 * @param ptr 指针
 * @return true 如果有效
 */
template<typename T>
bool ValidatePointer(const T* ptr) {
    return ptr != nullptr;
}

/**
 * @brief 安全地清理游戏运行时
 */
void SafeCleanupRuntime() {
    try {
        StopBackgroundMusic();
        
        auto& runtime = GameRuntime();
        
        // 安全地清理蛇对象
        runtime.snake.clear();
        runtime.snake.shrink_to_fit();
        
        // 清理食物数组
        if (runtime.foodList != nullptr) {
            // 使用RAII方式管理，不需要手动delete
            runtime.foodList = nullptr;
        }
        
        // 释放资源
        ResourceManager::Instance().UnloadAllResources();
    } catch (...) {
        OutputDebugStringA("SafeCleanupRuntime: Exception during cleanup\n");
    }
}

/**
 * @brief 验证游戏配置是否有效
 * @return true 如果配置有效
 */
bool ValidateGameConfig() {
    if (GameConfig::WINDOW_WIDTH <= 0 || GameConfig::WINDOW_HEIGHT <= 0) {
        OutputDebugStringA("ValidateGameConfig: Invalid window dimensions\n");
        return false;
    }
    
    if (GameConfig::MAX_AI_SNAKE_COUNT < 0 || GameConfig::MAX_AI_SNAKE_COUNT > static_cast<int>(MAX_AI_SNAKES)) {
        OutputDebugStringA("ValidateGameConfig: Invalid AI snake count\n");
        return false;
    }
    
    if (GameConfig::MAX_FOOD_COUNT <= 0 || GameConfig::MAX_FOOD_COUNT > static_cast<int>(MAX_FOOD_ITEMS)) {
        OutputDebugStringA("ValidateGameConfig: Invalid food count\n");
        return false;
    }
    
    return true;
}

/**
 * @brief 计算目标帧率
 * @return 目标FPS
 */
int CalculateTargetFPS() {
    float speed = GameState::Instance().currentPlayerSpeed;
    if (speed <= 0) {
        return 60;
    }
    
    // 限制最大帧率以防止CPU过载
    int fps = static_cast<int>(1000.0f / speed);
    if (fps < 30) fps = 30;
    if (fps > 120) fps = 120;
    
    return fps;
}

/**
 * @brief 计算帧延迟
 * @param fps 目标FPS
 * @return 每帧毫秒数
 */
int CalculateFrameDelay(int fps) {
    if (fps <= 0) return 16; // 默认60fps
    return 1000 / fps;
}

/**
 * @brief 更新游戏运行时间
 */
void UpdateGameRuntime() {
    auto now = std::chrono::steady_clock::now();
    static auto startTime = now;
    static auto lastFrameTime = now;
    
    auto& gs = GameState::Instance();
    
    // 计算增量时间
    std::chrono::duration<float> deltaTime = now - lastFrameTime;
    gs.deltaTime = deltaTime.count();
    
    // 限制deltaTime以防止物理计算异常
    const float MAX_DELTA_TIME = 1.0f; // 最大1秒
    if (gs.deltaTime <= 0 || gs.deltaTime > MAX_DELTA_TIME) {
        gs.deltaTime = 1.0f / 60.0f; // 默认60fps
    }
    
    lastFrameTime = now;
    
    // 计算总运行时间
    std::chrono::duration<float> runtime = now - startTime;
    gs.gameStartTime = runtime.count();
    
    // 检查最大运行时间（防止内存泄漏累积）
    auto runtimeMs = std::chrono::duration_cast<std::chrono::milliseconds>(runtime).count();
    if (runtimeMs > MAX_GAME_RUNTIME_MS) {
        OutputDebugStringA("UpdateGameRuntime: Maximum game runtime exceeded\n");
        gs.SetIsGameRunning(false);
    }
}

/**
 * @brief 初始化游戏世界
 * @return true 如果成功
 */
bool InitializeGameWorld() {
    try {
        auto& runtime = GameRuntime();
        auto& gs = GameState::Instance();
        
        // 验证AI蛇数量
        int aiCount = gs.aiSnakeCount;
        if (aiCount < 0) aiCount = 0;
        if (aiCount > GameConfig::MAX_AI_SNAKE_COUNT) {
            aiCount = GameConfig::MAX_AI_SNAKE_COUNT;
        }
        
        // 初始化AI蛇
        runtime.aiSnakes.resize(aiCount);
        for (int i = 0; i < aiCount; i++) {
            runtime.aiSnakes[i].Initialize();
            runtime.aiSnakes[i].position = GenerateRandomPosition();
            
            // 验证位置有效性
            if (runtime.aiSnakes[i].position.x < 0 || runtime.aiSnakes[i].position.y < 0) {
                runtime.aiSnakes[i].position = Vector2(100.0f, 100.0f);
            }
            
            runtime.aiSnakes[i].color = ColorGenerator::GenerateRandomColor();
            runtime.aiSnakes[i].aggressionFactor = gs.aiAggression;
        }
        
        // 初始化玩家蛇
        runtime.snake.clear();
        runtime.snake.reserve(1);
        
        PlayerSnake player;
        player.color = ColorGenerator::GenerateRandomColor();
        player.gridSnake = true;
        player.currentDir = RIGHT;
        player.nextDir = RIGHT;
        player.isDead = false;
        player.isDying = false;
        player.position = Vector2(GameConfig::PLAY_AREA_LEFT, GameConfig::PLAY_AREA_TOP);
        
        // 验证玩家位置
        if (player.position.x < 0 || player.position.y < 0) {
            player.position = Vector2(50.0f, 50.0f);
        }
        
        runtime.snake.push_back(player);
        
        // 初始化食物
        // 使用vector代替原始数组，更好的内存管理
        runtime.foodList = std::make_unique<std::vector<FoodItem>>(GameConfig::MAX_FOOD_COUNT);
        
        for (int i = 0; i < GameConfig::MAX_FOOD_COUNT; i++) {
            InitFood(runtime.foodList->data(), i, gs.currentPlayerSpeed);
        }
        
        gs.SetIsGameRunning(true);
        gs.ResetGameStartTime();
        
        return true;
    } catch (const std::exception& e) {
        OutputDebugStringA("InitializeGameWorld: Exception occurred\n");
        return false;
    }
}

/**
 * @brief 更新游戏状态
 */
void UpdateGame() {
    try {
        auto& runtime = GameRuntime();
        auto& gs = GameState::Instance();
        
        // 获取玩家蛇
        if (runtime.snake.empty()) {
            return;
        }
        
        PlayerSnake* player = dynamic_cast<PlayerSnake*>(&runtime.snake[0]);
        if (!player || player->isDead) {
            return;
        }
        
        // 更新游戏运行时间
        UpdateGameRuntime();
        
        // 处理AI蛇
        for (auto& aiSnake : runtime.aiSnakes) {
            if (aiSnake.isDead) continue;
            
            aiSnake.Update(
                runtime.foodList->data(),
                GameConfig::MAX_FOOD_COUNT,
                GetFoodSpatialGrid(),
                gs.deltaTime,
                player->position
            );
        }
        
        // 更新玩家蛇
        player->Update(gs.deltaTime);
        
        // 更新食物
        if (runtime.foodList) {
            UpdateFoods(runtime.foodList->data(), GameConfig::MAX_FOOD_COUNT);
        }
        
    } catch (const std::exception& e) {
        OutputDebugStringA("UpdateGame: Exception occurred\n");
    }
}

/**
 * @brief 渲染游戏画面
 */
void RenderGame() {
    try {
        BeginBatchDraw();
        cleardevice();
        
        auto& runtime = GameRuntime();
        auto& gs = GameState::Instance();
        
        // 绘制背景
        ResourceManager::Instance().DrawBackground();
        
        // 绘制食物
        if (runtime.foodList) {
            DrawFoods(runtime.foodList->data(), GameConfig::MAX_FOOD_COUNT);
        }
        
        // 绘制AI蛇
        for (auto& aiSnake : runtime.aiSnakes) {
            if (!aiSnake.isDead) {
                aiSnake.Draw(gs.mainCamera);
            }
        }
        
        // 绘制玩家蛇
        if (!runtime.snake.empty()) {
            runtime.snake[0].Draw(gs.mainCamera);
        }
        
        // 绘制UI
        DrawScore();
        
        // 绘制菜单按钮
        int exitIconX = 220;
        int exitIconY = 10;
        DrawExitButton(exitIconX, exitIconY, GameConfig::MENU_ICON_SIZE);
        
        if (gs.GetIsPaused()) {
            DrawPauseMenu();
        }
        
        FlushBatchDraw();
    } catch (const std::exception& e) {
        OutputDebugStringA("RenderGame: Exception occurred\n");
        EndBatchDraw();
    }
}

/**
 * @brief 游戏主循环
 */
void GameLoop() {
    int frameCount = 0;
    int restartAttempts = 0;
    
    while (GameState::Instance().GetIsGameRunning()) {
        try {
            // 计算目标帧率
            int targetFPS = CalculateTargetFPS();
            int frameDelay = CalculateFrameDelay(targetFPS);
            
            // 更新游戏逻辑
            UpdateGame();
            
            // 渲染画面
            RenderGame();
            
            // 处理鼠标输入
            HandleMouseInput();
            
            // 帧率控制
            Sleep(frameDelay);
            
            frameCount++;
            
            // 定期清理（每1000帧）
            if (frameCount >= 1000) {
                frameCount = 0;
                // 强制垃圾回收
                std::vector<FoodItem>().swap(std::vector<FoodItem>());
            }
            
            restartAttempts = 0; // 成功执行，重置重试计数
            
        } catch (const std::exception& e) {
            OutputDebugStringA("GameLoop: Exception in main loop\n");
            restartAttempts++;
            
            if (restartAttempts >= MAX_RESTART_ATTEMPTS) {
                OutputDebugStringA("GameLoop: Maximum restart attempts exceeded\n");
                GameState::Instance().SetIsGameRunning(false);
                break;
            }
            
            Sleep(100);
        }
    }
}

} // anonymous namespace

int main() {
    // 初始化随机数种子
    std::srand(static_cast<unsigned int>(std::time(nullptr)));
    
    // 初始化Winsock
    WSADATA wsaData;
    if (WSAStartup(MAKEWORD(2, 2), &wsaData) != 0) {
        MessageBox(nullptr, TEXT("WSAStartup failed"), TEXT("Error"), MB_OK | MB_ICONERROR);
        return 1;
    }
    
    // 验证游戏配置
    if (!ValidateGameConfig()) {
        WSACleanup();
        MessageBox(nullptr, TEXT("Invalid game configuration"), TEXT("Error"), MB_OK | MB_ICONERROR);
        return 1;
    }
    
    // 初始化图形窗口
    initgraph(GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT);
    SetWindowText(GetHWnd(), TEXT("Greed Snake 2025"));
    
    // 加载资源
    if (!ResourceManager::Instance().LoadAllResources()) {
        MessageBox(GetHWnd(), TEXT("Failed to load resources"), TEXT("Error"), MB_OK | MB_ICONERROR);
        closegraph();
        WSACleanup();
        return 1;
    }
    
    // 初始化音频
    InitializeAudio();
    PlayBackgroundMusic();
    
    // 设置音量
    SetVolume(GameConfig::DEFAULT_VOLUME);
    
    int menuResult;
    do {
        // 显示主菜单
        menuResult = ShowMainMenu();
        
        switch (menuResult) {
        case MenuOption::StartGame: {
            // 初始化游戏世界
            if (!InitializeGameWorld()) {
                MessageBox(GetHWnd(), TEXT("Failed to initialize game"), TEXT("Error"), MB_OK | MB_ICONERROR);
                break;
            }
            
            // 启动输入处理线程
            std::thread inputThread(EnterChanges);
            
            // 游戏主循环
            GameLoop();
            
            // 等待输入线程结束
            if (inputThread.joinable()) {
                inputThread.join();
            }
            
            break;
        }
        case MenuOption::Settings: {
            ShowSettings(GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT);
            break;
        }
        case MenuOption::Exit: {
            break;
        }
        default: {
            break;
        }
        }
    } while (menuResult != MenuOption::Exit);
    
    // 清理资源
    SafeCleanupRuntime();
    
    // 关闭图形窗口
    closegraph();
    
    // 清理Winsock
    WSACleanup();
    
    return 0;
}
