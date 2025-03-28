/*
    名称:       MainGame.cpp
    创建时间:    2025/1/22 14:44:25
    作者:     PC-20230225XVVJ\Administrator
    
    描述: Greedy Snake 游戏的主要实现文件。
    包含核心游戏逻辑、渲染和输入处理。
*/
#include <graphics.h>
#include <conio.h>
#include <iostream>
#include <string>
#include <vector>
#include <thread>
#include <windows.h>
#include <mmsystem.h>
#include <math.h>
#include <queue>
#include <algorithm>
#include "Button.h"
#include "GameConfig.h"
#include "Vector2.h"
#include "Snake.h"
#include "GameState.h"
#include "Rendering.h"
#include "Collisions.h"
#include "SpatialGrid.h"
#include "Camera.h"
#include "Food.h"
#pragma comment(lib, "winmm.lib") // 多媒体函数所需
#pragma warning(disable: 4996)	 // 禁用关于 _tcscpy 和 _stprintf 的安全警告

// #define DEBUG_DRAW_TEXT(value, x, y) DebugDrawText(std::wstring(_T(#value": ")) + std::to_wstring(value), x, y, HSLtoRGB(0, 0, 255));

// 菜单选项枚举
enum class MenuOption {
    START, // 开始
    SETTINGS, // 设置
    ABOUT, // 关于
    EXIT // 退出
};

// 设置结构
struct GameSettings {
    float musicVolume = GameConfig::DEFAULT_VOLUME; // 音乐音量
    bool enableSound = true; // 启用声音
    int difficulty = 1;  // 1: 简单, 2: 普通, 3: 困难
    float snakeSpeed = GameConfig::DEFAULT_PLAYER_SPEED; // 蛇速度
};
// 蛇段颜色生成类
class ColorGenerator {
public:
    static int GenerateRandomColor() {
        int red = GenerateColorComponent(); // 生成红色分量
        int green = GenerateColorComponent(); // 生成绿色分量
        int blue = GenerateColorComponent(); // 生成蓝色分量
        return HSLtoRGB(red, green, blue); // 返回HSL颜色
    }

private:
    static int GenerateColorComponent() {
        return static_cast<int>((rand() % 5000 / 1000.0 + 1) * 255 / 6.0 + 0.5); // 生成颜色分量
    }
};

// 屏幕尺寸
const int windowWidth = GameConfig::WINDOW_WIDTH; // 窗口宽度
const int windowHeight = GameConfig::WINDOW_HEIGHT; // 窗口高度

// 游戏区域边界
const int playAreaWidth = GameConfig::WINDOW_WIDTH; // 游戏区域宽度
const int playAreaHeight = GameConfig::WINDOW_HEIGHT; // 游戏区域高度
const int playAreaMarginX = GameConfig::PLAY_AREA_MARGIN; // 游戏区域X边距
const int playAreaMarginY = GameConfig::PLAY_AREA_MARGIN; // 游戏区域Y边距

// 玩家状态
Vector2 playerPosition = GameConfig::PLAYER_DEFAULT_POS; // 玩家位置
Vector2 playerDirection(0, 1); // 玩家方向

std::vector<Button> buttonList; // 按钮列表

// 游戏计时
float deltaTime = GameState::Instance().deltaTime; // 时间增量

// 数组和集合
FoodItem foodList[GameConfig::MAX_FOOD_COUNT]; // 食物列表
std::vector<SnakeSegment> snakeSegments(5); // 蛇段列表

// AI蛇容器
std::vector<AISnake> aiSnakeList;

// Global variables if not already defined
std::vector<Snake> snake;

// Function implementations
void InitializePlayerSnake() {
    // Initialize with 5 segments
    snake.resize(5);
    Vector2 startPos = GameConfig::PLAYER_DEFAULT_POS;
    Vector2 startDir(0, 1);  // Starting direction downward
    
    for (int i = 0; i < 5; i++) {
        snake[i].position = startPos - startDir * (i * GameConfig::SNAKE_SEGMENT_SPACING);
        snake[i].direction = startDir;
        snake[i].radius = GameConfig::INITIAL_SNAKE_SIZE;
        snake[i].color = HSLtoRGB(255, 255, 255);  // White color
        snake[i].posRecords = std::queue<Vector2>();
    }
}

void UpdateCamera() {
    auto& gameState = GameState::Instance();
    Vector2 targetPos = snake[0].position - Vector2(GameConfig::WINDOW_WIDTH / 2, GameConfig::WINDOW_HEIGHT / 2);
    
    // Smooth camera movement
    gameState.camera.position = gameState.camera.position + 
        (targetPos - gameState.camera.position) * GameConfig::SMOOTH_CAMERA_FACTOR;
}

void UpdatePlayerSnake(float deltaTime) {
    // Update head
    snake[0].direction = GameState::Instance().targetDirection;
    snake[0].position = snake[0].position + snake[0].GetVelocity() * deltaTime;
    snake[0].Update(deltaTime);

    // Update body segments
    for (size_t i = 1; i < snake.size(); i++) {
        snake[i].UpdateBody(snake[i-1], snake[i]);
        snake[i].Update(deltaTime);
    }
}

void UpdateAISnakes(float deltaTime) {
    for (auto& aiSnake : aiSnakeList) {
        aiSnake.Update(std::vector<FoodItem>(foodList, foodList + GameConfig::MAX_FOOD_COUNT), 
                      deltaTime, 
                      snake[0].position);
    }
}

void UpdateFoods() {
    for (int i = 0; i < GameConfig::MAX_FOOD_COUNT; i++) {
        if (rand() % 100 < (GameState::Instance().foodSpawnRate * 100)) {
            InitFood(i, GameState::Instance().currentPlayerSpeed);
        }
    }
}

void DrawGameArea() {
    // Clear screen
    setbkcolor(RGB(30, 30, 30));
    cleardevice();
    
    // Draw game boundaries
    setlinecolor(RGB(100, 100, 100));
    Vector2 topLeft(GameConfig::PLAY_AREA_LEFT, GameConfig::PLAY_AREA_TOP);
    Vector2 bottomRight(GameConfig::PLAY_AREA_RIGHT, GameConfig::PLAY_AREA_BOTTOM);
    Vector2 cameraPos = GameState::Instance().camera.position;
    
    rectangle(topLeft.x - cameraPos.x, topLeft.y - cameraPos.y,
             bottomRight.x - cameraPos.x, bottomRight.y - cameraPos.y);
}

void DrawFoods() {
    for (int i = 0; i < GameConfig::MAX_FOOD_COUNT; i++) {
        Vector2 screenPos = foodList[i].position - GameState::Instance().camera.position;
        DrawCircleWithCamera(screenPos, foodList[i].collisionRadius, foodList[i].colorValue);
    }
}

void DrawUI() {
    auto& gameState = GameState::Instance();
    
    // Draw score
    settextstyle(24, 0, _T("Arial"));
    settextcolor(WHITE);
    TCHAR scoreText[50];
    _stprintf(scoreText, _T("Score: %d"), gameState.foodEatenCount);
    outtextxy(10, 10, scoreText);
    
    // Draw warning if in lava
    if (gameState.isInLava) {
        settextcolor(RGB(255, 0, 0));
        TCHAR warningText[50];
        float timeLeft = GameConfig::LAVA_WARNING_TIME - gameState.timeInLava;
        _stprintf(warningText, _T("WARNING! Return to play area! %.1f"), timeLeft);
        outtextxy(GameConfig::WINDOW_WIDTH/2 - 150, 10, warningText);
    }
}

void CheckCollisions() {
    auto& gameState = GameState::Instance();
    
    // Skip collision check during invulnerability period
    if (!gameState.IsCollisionEnabled()) {
        return;
    }
    
    // Check collisions with AI snakes
    if (CollisionManager::CheckSnakeCollision(snake[0].position, snake[0].radius, aiSnakeList)) {
        gameState.isCollisionFlashing = true;
        gameState.collisionFlashTimer = GameConfig::COLLISION_FLASH_DURATION;
    }
    
    // Check food collisions
    for (int i = 0; i < GameConfig::MAX_FOOD_COUNT; i++) {
        if (CollisionManager::CheckCircleCollision(
            snake[0].position, snake[0].radius,
            foodList[i].position, foodList[i].collisionRadius)) {
            // Handle food collection
            InitFood(i, gameState.currentPlayerSpeed);
            gameState.AddFoodEaten();
            
            // Grow snake
            float growthAmount = (gameState.foodEatenCount == 0) ? 
                GameConfig::SNAKE_GROWTH_LARGE : GameConfig::SNAKE_GROWTH_SMALL;
            snake[0].radius = min(snake[0].radius + growthAmount, GameConfig::MAX_SNAKE_SIZE);
        }
    }
}

void CheckGameState() {
    auto& gameState = GameState::Instance();
    
    // Check if snake is outside play area
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
        }
    } else {
        gameState.ResetLavaTimer();
    }
}

// 初始化AI蛇
void InitializeAISnakes() {
    auto& gameState = GameState::Instance();
    aiSnakeList.resize(gameState.aiSnakeCount); // 调整AI蛇列表大小
    
    for (auto& aiSnake : aiSnakeList) {
        aiSnake.Init(); // 初始化AI蛇
        
        // 根据难度调整AI行为
        aiSnake.aggressionFactor = gameState.aiAggression; // 设置攻击性因子
        aiSnake.speedMultiplier = GameConfig::AI_MIN_SPEED + 
            (gameState.aiAggression * (GameConfig::AI_MAX_SPEED - GameConfig::AI_MIN_SPEED)); // 设置速度乘数
    }
    
    for (int i = 0; i < gameState.aiSnakeCount; ++i) {
        // 在中心周围以圆形分布生成蛇
        float angle = (i * 360.0f / gameState.aiSnakeCount) * 3.14159f / 180.0f; // 计算角度
        float distance = rand() % static_cast<int>(GameConfig::AI_SPAWN_RADIUS); // 随机生成距离
        
        float x = windowWidth/2 + cos(angle) * distance; // 计算X坐标
        float y = windowHeight/2 + sin(angle) * distance; // 计算Y坐标
        
        // 确保位置在安全区域内
        x = (((GameConfig::PLAY_AREA_LEFT + 100.0f) >((((GameConfig::PLAY_AREA_RIGHT - 100.0f) < (x)) ? (GameConfig::PLAY_AREA_RIGHT - 100.0f) : (x)))) ? (GameConfig::PLAY_AREA_LEFT + 100.0f) : ((((GameConfig::PLAY_AREA_RIGHT - 100.0f) < (x)) ? (GameConfig::PLAY_AREA_RIGHT - 100.0f) : (x))));
        y = (((GameConfig::PLAY_AREA_TOP + 100.0f) > ((((GameConfig::PLAY_AREA_BOTTOM - 100.0f) < (y)) ? (GameConfig::PLAY_AREA_BOTTOM - 100.0f) : (y)))) ? (GameConfig::PLAY_AREA_TOP + 100.0f) : ((((GameConfig::PLAY_AREA_BOTTOM - 100.0f) < (y)) ? (GameConfig::PLAY_AREA_BOTTOM - 100.0f) : (y))));
        
        // 随机起始方向
        float dirAngle = (rand() % 360) * 3.14159f / 180.0f; // 随机角度
        Vector2 direction(cos(dirAngle), sin(dirAngle)); // 计算方向
        
        // 初始化AI蛇的随机速度
        aiSnakeList[i].position = Vector2(x, y); // 设置位置
        aiSnakeList[i].direction = direction; // 设置方向
        aiSnakeList[i].radius = GameConfig::INITIAL_SNAKE_SIZE * 0.8f; // 设置半径
        aiSnakeList[i].color = HSLtoRGB(rand() % 360, 200, 200); // 设置颜色
        
        // 初始化段
        for (int j = 0; j < 5; j++) {
            aiSnakeList[i].segments[j].position = aiSnakeList[i].position - direction * (j + 1) * GameConfig::SNAKE_SEGMENT_SPACING; // 设置段位置
            aiSnakeList[i].segments[j].direction = direction; // 设置段方向
            aiSnakeList[i].segments[j].radius = aiSnakeList[i].radius; // 设置段半径
            aiSnakeList[i].segments[j].color = aiSnakeList[i].color; // 设置段颜色
        }
    }
}

void EnterChanges(void)
{
    ExMessage Message; // 消息
    Vector2 mouseWorldPos; // 鼠标世界位置

    while (GameState::Instance().isGameRunning) // 游戏运行时
    {
        Message = getmessage(EX_MOUSE | EX_KEY); // 获取消息

        switch (Message.message) // 处理消息
        {
        case WM_RBUTTONDOWN: // 右键按下
            GameState::Instance().isMouseControlEnabled = true; // 启用鼠标控制
            break;
        case WM_MOUSEMOVE: // 鼠标移动
            if (!GameState::Instance().isMouseControlEnabled)
                break; // 如果未启用鼠标控制，退出
            mouseWorldPos = Vector2(Message.x, Message.y) + GameState::Instance().camera.position; // 更新鼠标世界位置
            GameState::Instance().targetDirection = (mouseWorldPos - snake.back().position).GetNormalize(); // 更新目标方向
            break;
        case WM_LBUTTONDOWN: // 左键按下
            GameState::Instance().originalSpeed = GameState::Instance().currentPlayerSpeed; // 记录原始速度
            GameState::Instance().currentPlayerSpeed *= 2; // 加速
            GameState::Instance().recordInterval = GameConfig::DEFAULT_RECORD_INTERVAL / 2; // 减少记录间隔
            break;
        case WM_LBUTTONUP: // 左键抬起
            GameState::Instance().currentPlayerSpeed = GameState::Instance().originalSpeed; // 恢复原始速度
            GameState::Instance().recordInterval = GameConfig::DEFAULT_RECORD_INTERVAL; // 恢复记录间隔
            break;
        case WM_KEYDOWN: // 键盘按下
            GameState::Instance().isMouseControlEnabled = false; // 禁用鼠标控制
            switch (Message.vkcode) // 处理按键
            {
            case VK_UP: // 上键
                GameState::Instance().targetDirection = Vector2(0, -1); // 设置目标方向
                break;
            case VK_DOWN: // 下键
                GameState::Instance().targetDirection = Vector2(0, 1); // 设置目标方向
                break;
            case VK_LEFT: // 左键
                GameState::Instance().targetDirection = Vector2(-1, 0); // 设置目标方向
                break;
            case VK_RIGHT: // 右键
                GameState::Instance().targetDirection = Vector2(1, 0); // 设置目标方向
                break;
            case VK_ESCAPE: // ESC键
                GameState::Instance().isGameRunning = false; // 结束游戏
                break;
            }
            break;
        }
    }
}

// 替换原有的CheckCollision函数调用
// CheckCollision(pos1, radius1, pos2, radius2) -> CollisionManager::CheckCircleCollision(pos1, radius1, pos2, radius2)
// ... existing code ...

// 将绘制逻辑拆分为多个函数
void DrawVisibleObjects() {
    // 计算可见区域
    Vector2 cameraPos = GameState::Instance().camera.position;
    float screenLeft = cameraPos.x;
    float screenRight = cameraPos.x + GameConfig::WINDOW_WIDTH;
    float screenTop = cameraPos.y;
    float screenBottom = cameraPos.y + GameConfig::WINDOW_HEIGHT;
    
    // 扩展可见区域，考虑到大型对象可能部分可见
    float margin = 100.0f;  // 足够大的边距
    screenLeft -= margin;
    screenRight += margin;
    screenTop -= margin;
    screenBottom += margin;
    
    // 只绘制可见区域内的食物
    for (int i = 0; i < GameConfig::MAX_FOOD_COUNT; ++i) {
        const auto& food = foodList[i];
        if (food.position.x >= screenLeft && food.position.x <= screenRight &&
            food.position.y >= screenTop && food.position.y <= screenBottom) {
            Vector2 foodScreenPos = food.position - cameraPos;
            DrawCircleWithCamera(foodScreenPos, food.collisionRadius, food.colorValue);
        }
    }
    
    // 只绘制可见区域内的AI蛇
    for (const auto& aiSnake : aiSnakeList) {
        if (aiSnake.position.x >= screenLeft && aiSnake.position.x <= screenRight &&
            aiSnake.position.y >= screenTop && aiSnake.position.y <= screenBottom) {
            // 绘制AI蛇头
            Vector2 windowPos = aiSnake.position - cameraPos;
            DrawCircleWithCamera(windowPos, aiSnake.radius, aiSnake.color);
            DrawSnakeEyes(windowPos, aiSnake.direction, aiSnake.radius);
            
            // 绘制AI蛇身
            for (const auto& segment : aiSnake.segments) {
                if (segment.position.x >= screenLeft && segment.position.x <= screenRight &&
                    segment.position.y >= screenTop && segment.position.y <= screenBottom) {
                    Vector2 segmentPos = segment.position - cameraPos;
                    DrawCircleWithCamera(segmentPos, segment.radius, segment.color);
                }
            }
        }
    }
    
    // 绘制玩家蛇
    // 玩家蛇总是可见的，因为相机跟随玩家
    for (const auto& segment : snake) {
        Vector2 segmentPos = segment.position - cameraPos;
        DrawCircleWithCamera(segmentPos, segment.radius, segment.color); 
    }
}

void Draw() {
    while (GameState::Instance().isGameRunning) {
        BeginBatchDraw();

        // 更新相机
        UpdateCamera();

        // 绘制游戏区域
        DrawGameArea();
        
        // 绘制食物
        DrawVisibleObjects();

        // 绘制UI元素
        DrawUI();

        // 检查游戏状态
        CheckGameState();

        EndBatchDraw();
    }
}

// ... 其他拆分函数实现 ...



void InitSnake(int i, const Vector2& pos, const Vector2& currentDir) {
    snake[i].position = pos - currentDir * (i * GameConfig::SNAKE_SEGMENT_SPACING); // 初始化蛇段位置
    snake[i].color = HSLtoRGB(255, 255, 255); // 设置颜色
    snake[i].radius = GameConfig::INITIAL_SNAKE_SIZE;  // 使用初始大小
    snake[i].direction = currentDir; // 设置方向
    snake[i].currentTime = 0; // 当前时间
    snake[i].posRecords = std::queue<Vector2>(); // 初始化位置记录
}

// 将重复的食物位置生成逻辑提取为函数
Vector2 GenerateRandomPosition() {
    float x = GameConfig::PLAY_AREA_LEFT + 
              rand() % (GameConfig::PLAY_AREA_RIGHT - GameConfig::PLAY_AREA_LEFT);
    float y = GameConfig::PLAY_AREA_TOP + 
              rand() % (GameConfig::PLAY_AREA_BOTTOM - GameConfig::PLAY_AREA_TOP);
    return Vector2(x, y);
}

void InitFood(int i, float speed) {
    foodList[i].position = GenerateRandomPosition();
    foodList[i].moveSpeed = speed;
    foodList[i].colorValue = ColorGenerator::GenerateRandomColor();
    foodList[i].collisionRadius = (rand() % 5000) / 1000.0f + 2;

    // 根据难度调整食物生成概率
    if (rand() % 100 < (GameState::Instance().foodSpawnRate * 100)) {
        foodList[i].position = GenerateRandomPosition();
    }
}

void ChangeGlobalSpeed(float newSpeed) {
    GameState::Instance().currentPlayerSpeed = newSpeed; // 改变全局速度
}

bool IsCircleInScreen(const Vector2& center, float r) {
    Vector2 minPoint = Vector2(center.x - r, center.y - r); // 计算最小点
    Vector2 maxPoint = Vector2(center.x + r, center.y + r); // 计算最大点

    return !(maxPoint.x < 0 || minPoint.x > GameConfig::WINDOW_WIDTH || maxPoint.y < 0 || minPoint.y > GameConfig::WINDOW_HEIGHT); // 检查是否在屏幕内
}

void DrawCircleWithCamera(const Vector2& screenPos, float r, int c) {
    if (!IsCircleInScreen(screenPos, r)) {
        return; // 如果不在屏幕内，返回
    }
    setlinecolor(c); // 设置线条颜色
    setfillcolor(c); // 设置填充颜色
    fillcircle(screenPos.x, screenPos.y, r); // 绘制圆
}

void DebugDrawText(const std::wstring& text, int x, int y, int color) {
    settextcolor(color); // 设置文本颜色
    outtextxy(x, y, text.c_str()); // 绘制文本
}

void PlayBackgroundMusic() {
    mciSendString(_T("open ..\\Resource\\Greed-Snake.mp3 alias Greed-Snake"), NULL, NULL, NULL); // 打开音乐文件
    mciSendString(_T("play Greed-Snake repeat"), NULL, NULL, NULL); // 播放音乐
    SetVolume(GameConfig::DEFAULT_VOLUME);  // 设置初始音量
}

// 设置对话框
void ShowSettings() {
    static GameSettings settings; // 设置

    // 填充整个窗口
    setfillcolor(RGB(30, 30, 30)); // 设置背景颜色
    solidrectangle(0, 0, windowWidth, windowHeight); // 绘制背景矩形
    
    // 绘制标题
    settextstyle(48, 0, _T("Arial")); // 设置文本样式
    settextcolor(RGB(255, 255, 255)); // 设置文本颜色
    const TCHAR* title = _T("Settings"); // 标题文本
    int titleWidth = textwidth(title); // 获取标题宽度
    outtextxy(windowWidth/2 - titleWidth/2, 50, title); // 绘制标题
    
    // 绘制设置面板
    setfillcolor(RGB(50, 50, 50)); // 设置面板颜色
    const int panelMargin = 50;  // 边距
    solidroundrect(panelMargin, 120,  // 调整位置
        windowWidth - panelMargin, windowHeight - panelMargin,
                  20, 20); // 绘制面板
    
    settextstyle(32, 0, _T("Arial")); // 设置文本样式
    
    // 音量控制
    const int startY = 200; // 起始Y坐标
    const int lineHeight = 80; // 行高
    outtextxy(panelMargin + 50, startY, _T("Volume:")); // 绘制音量文本
    
    // 绘制音量滑块背景
    const int sliderWidth = windowWidth - panelMargin * 2 - 300; // 滑块宽度
    const int sliderHeight = 30; // 滑块高度
    const int sliderX = panelMargin + 200; // 滑块X坐标
    const int sliderY = startY; // 滑块Y坐标
    
    setfillcolor(RGB(70, 70, 70)); // 设置滑块背景颜色
    solidroundrect(sliderX, sliderY, sliderX + sliderWidth, sliderY + sliderHeight, 10, 10); // 绘制滑块背景
    
    // 绘制音量级别
    setfillcolor(RGB(100, 200, 100)); // 设置滑块填充颜色
    int filledWidth = static_cast<int>(settings.musicVolume * sliderWidth); // 计算填充宽度
    solidroundrect(sliderX, sliderY, sliderX + filledWidth, sliderY + sliderHeight, 10, 10); // 绘制填充滑块
    
    // 绘制音量百分比
    TCHAR volumeText[20]; // 音量文本
    _stprintf(volumeText, _T("%d%%"), static_cast<int>(settings.musicVolume * 100)); // 格式化音量文本
    outtextxy(sliderX + sliderWidth + 20, sliderY, volumeText); // 绘制音量文本
    
    // 难度选择
    outtextxy(panelMargin + 50, startY + lineHeight, _T("Difficulty:")); // 绘制难度文本
    const TCHAR* difficulties[] = {_T("Easy"), _T("Normal"), _T("Hard")}; // 难度选项
    for(int i = 0; i < 3; i++) {
        const int btnWidth = 120; // 按钮宽度
        const int btnX = panelMargin + 200 + i * (btnWidth + 20); // 按钮X坐标
        setfillcolor(settings.difficulty == i + 1 ? RGB(100, 200, 100) : RGB(70, 70, 70)); // 设置按钮颜色
        solidroundrect(btnX, startY + lineHeight,
                      btnX + btnWidth, startY + lineHeight + 40,
                      10, 10); // 绘制按钮
        // 中心对齐文本
        int textWidth = textwidth(difficulties[i]); // 获取文本宽度
        outtextxy(btnX + (btnWidth - textWidth)/2, 
                 startY + lineHeight + 5, 
                 difficulties[i]); // 绘制难度文本
    }
    
    // 声音切换
    outtextxy(panelMargin + 50, startY + lineHeight * 2, _T("Sound:")); // 绘制声音文本
    setfillcolor(settings.enableSound ? RGB(100, 200, 100) : RGB(70, 70, 70)); // 设置声音按钮颜色
    solidroundrect(panelMargin + 200, startY + lineHeight * 2,
                  panelMargin + 300, startY + lineHeight * 2 + 40,
                  10, 10); // 绘制声音按钮
    const TCHAR* soundText = settings.enableSound ? _T("ON") : _T("OFF"); // 声音状态文本
    int textWidth = textwidth(soundText); // 获取文本宽度
    outtextxy(panelMargin + 200 + (100 - textWidth)/2, 
             startY + lineHeight * 2 + 5,
             soundText); // 绘制声音状态文本
    
    // 使用 Button 类创建按钮
    Button saveButton; // 保存按钮
    Button cancelButton; // 取消按钮
    const int btnWidth = 150; // 按钮宽度
    const int btnHeight = 50; // 按钮高度
    const int btnY = windowHeight - panelMargin - btnHeight - 50; // 按钮Y坐标
    
    saveButton.Initial(_T("Save"), Vector2(windowWidth/2 - btnWidth - 20, btnY), Vector2(windowWidth/2 - 20, btnY + btnHeight), RGB(100, 200, 100)); // 初始化保存按钮
    cancelButton.Initial(_T("Cancel"), Vector2(windowWidth/2 + 20, btnY), Vector2(windowWidth/2 + btnWidth + 20, btnY + btnHeight), RGB(200, 100, 100)); // 初始化取消按钮
    
    // 处理设置输入
    bool settingsOpen = true; // 设置窗口是否打开
    while(settingsOpen) {
        ExMessage m = getmessage(EX_MOUSE | EX_KEY); // 获取消息
        Vector2 mousePos = Vector2(m.x, m.y); // 鼠标位置
        
        // 绘制按钮
        saveButton.DrawButton(mousePos); // 绘制保存按钮
        cancelButton.DrawButton(mousePos); // 绘制取消按钮
        
        if(m.message == WM_LBUTTONDOWN) { // 左键按下
            // 处理音量滑块
            if(m.x >= sliderX && m.x <= sliderX + sliderWidth &&
               m.y >= sliderY && m.y <= sliderY + sliderHeight) {
                settings.musicVolume = static_cast<float>(m.x - sliderX) / sliderWidth; // 更新音量
                settings.musicVolume = (((0.0f) > ((((1.0f) < (settings.musicVolume)) ? (1.0f) : (settings.musicVolume)))) ? (0.0f) : ((((1.0f) < (settings.musicVolume)) ? (1.0f) : (settings.musicVolume)))); // 限制音量范围
                
                // 立即更新音量以反馈
                SetVolume(settings.musicVolume);
                
                // 重新绘制设置界面以更新滑块
                ShowSettings();
            }
            
            // 处理难度按钮
            for(int i = 0; i < 3; i++) {
                const int btnWidth = 120; // 按钮宽度
                const int btnX = panelMargin + 200 + i * (btnWidth + 20); // 按钮X坐标
                if(m.x >= btnX && m.x <= btnX + btnWidth &&
                   m.y >= startY + lineHeight && m.y <= startY + lineHeight + 40) {
                    settings.difficulty = i + 1; // 更新难度
                    
                    // 更新游戏难度
                    GameState::Instance().SetDifficulty(static_cast<GameState::GameDifficulty>(i));
                    
                    ShowSettings();  // 刷新设置界面
                    break;
                }
            }
            
            // 处理声音切换
            if(m.x >= panelMargin + 200 && m.x <= panelMargin + 300 &&
               m.y >= startY + lineHeight * 2 && m.y <= startY + lineHeight * 2 + 40) {
                settings.enableSound = !settings.enableSound; // 切换声音状态
                // 重新绘制设置界面以更新切换状态
                ShowSettings();
            }
            
            // 处理保存/取消
            if (saveButton.IsOnButton(mousePos)) {
                ApplySettings(settings); // 应用设置
                settingsOpen = false; // 关闭设置窗口
            }
            else if (cancelButton.IsOnButton(mousePos)) {
                settingsOpen = false; // 关闭设置窗口
            }
        }
        else if(m.message == WM_MOUSEMOVE && (m.wheel & MK_LBUTTON)) { // 鼠标移动并按下左键
            // 处理音量滑块拖动
            if(m.x >= sliderX && m.x <= sliderX + sliderWidth &&
               m.y >= sliderY && m.y <= sliderY + sliderHeight) {
                settings.musicVolume = static_cast<float>(m.x - sliderX) / sliderWidth; // 更新音量
                settings.musicVolume = (((0.0f) > ((((1.0f) < (settings.musicVolume)) ? (1.0f) : (settings.musicVolume)))) ? (0.0f) : ((((1.0f) < (settings.musicVolume)) ? (1.0f) : (settings.musicVolume)))); // 限制音量范围
                
                // 立即更新音量以反馈
                SetVolume(settings.musicVolume);
                
                // 重新绘制设置界面以更新滑块
                ShowSettings();
            }
        }
        else if(m.message == WM_KEYDOWN && m.vkcode == VK_ESCAPE) { // ESC键按下
            settingsOpen = false; // 关闭设置窗口
        }
    }
}

// 关于对话框
void ShowAbout() {
    // 填充整个窗口
    setfillcolor(RGB(30, 30, 30)); // 设置背景颜色
    solidrectangle(0, 0, windowWidth, windowHeight); // 绘制背景矩形
    
    // 绘制标题
    settextstyle(48, 0, _T("Arial")); // 设置文本样式
    settextcolor(RGB(255, 255, 255)); // 设置文本颜色
    const TCHAR* title = _T("About"); // 标题文本
    int titleWidth = textwidth(title); // 获取标题宽度
    outtextxy(windowWidth/2 - titleWidth/2, 50, title); // 绘制标题
    
    // 绘制关于面板
    setfillcolor(RGB(50, 50, 50)); // 设置面板颜色
    const int panelMargin = 50;  // 边距
    solidroundrect(panelMargin, 120,  // 调整位置
        windowWidth - panelMargin, windowHeight - panelMargin,
                  20, 20); // 绘制面板
    
    settextstyle(25, 0, _T("Arial")); // 设置文本样式
    const TCHAR* aboutText[] = {
        _T("Greedy Snake Game"), // 游戏名称
        _T("Version 1.0"), // 版本
        _T("Created by: Chen Runsen"), // 创建者
        _T("2025 All Rights Reserved"), // 版权所有
        _T(""), // 空行
        _T("Controls:"), // 控制说明
        _T("Arrow Keys - Move snake"), // 箭头键 - 移动蛇
        _T("Mouse - Alternative control"), // 鼠标 - 替代控制
        _T("Left Click - Speed up"), // 左键点击 - 加速
        _T("Right Click - Enable mouse control"), // 右键点击 - 启用鼠标控制
        _T("P - Pause game"), // P - 暂停游戏
        _T("S - Resume game"), // S - 恢复游戏
        _T("ESC - Exit game") // ESC - 退出游戏
    };
    
    const int startY = 150; // 起始Y坐标
    const int lineHeight = 35; // 行高
    for(int i = 0; i < sizeof(aboutText)/sizeof(aboutText[0]); i++) {
        int textWidth = textwidth(aboutText[i]); // 获取文本宽度
        outtextxy(windowWidth/2 - textWidth/2, startY + i * lineHeight, aboutText[i]); // 绘制关于文本
    }
    
    // 确定按钮
    const int btnWidth = 150; // 按钮宽度
    const int btnHeight = 50; // 按钮高度
    const int btnY = windowHeight - panelMargin - btnHeight - 30; // 按钮Y坐标
    
    setfillcolor(RGB(100, 200, 100)); // 设置按钮颜色
    solidroundrect(windowWidth/2 - btnWidth/2, btnY,
        windowWidth/2 + btnWidth/2, btnY + btnHeight,
                  10, 10); // 绘制按钮
    
    settextstyle(32, 0, _T("Arial")); // 设置文本样式
    const TCHAR* btnText = _T("OK"); // 按钮文本
    int btnTextWidth = textwidth(btnText); // 获取按钮文本宽度
    outtextxy(windowWidth/2 - btnTextWidth/2,
             btnY + (btnHeight - textheight(btnText))/2,
             btnText); // 绘制按钮文本
    
    // 等待按钮点击或ESC
    while(true) {
        ExMessage m = getmessage(EX_MOUSE | EX_KEY); // 获取消息
        if(m.message == WM_LBUTTONDOWN) { // 左键按下
            if(m.x >= windowWidth/2 - btnWidth/2 && m.x <= windowWidth/2 + btnWidth/2 &&
               m.y >= btnY && m.y <= btnY + btnHeight) {
                break; // 退出循环
            }
        }
        else if(m.message == WM_KEYDOWN && m.vkcode == VK_ESCAPE) { // ESC键按下
            break; // 退出循环
        }
    }
}

// 设置应用函数
void ApplySettings(const GameSettings& settings) {
    GameState::Instance().currentPlayerSpeed = settings.snakeSpeed; // 设置当前玩家速度
    
    if(settings.enableSound) {
        mciSendString(_T("resume Greed-Snake"), NULL, NULL, NULL); // 恢复音乐
        SetVolume(settings.musicVolume); // 设置音量
    } else {
        mciSendString(_T("pause Greed-Snake"), NULL, NULL, NULL); // 暂停音乐
    }
}

void DrawMenu() {
    ExMessage m; // 消息
    peekmessage(&m, EX_MOUSE); // 预取消息
    Vector2 mousePos = Vector2(m.x, m.y); // 鼠标位置

    // for (int i = 0; i < ButtonType::Num; ++i) {
    //     buttonList[i].DrawButton(mousePos); // 绘制按钮
    // }
    // 将 ButtonType::Num 替换为 buttonList.size()
    for (int i = 0; i < buttonList.size(); ++i) {
        buttonList[i].DrawButton(mousePos); // 绘制按钮
    }
}

// 在消息处理循环中添加退出图标点击事件
void HandleMouseInput() {
    ExMessage msg = getmessage(EX_MOUSE); // 获取消息
    if (msg.message == WM_LBUTTONDOWN) { // 左键按下
        // 检查退出图标点击区域
        const int exitIconX = 220; // 退出图标的X坐标
        const int exitIconY = 10;   // 退出图标的Y坐标
        const int iconSize = GameConfig::MENU_ICON_SIZE; // 图标大小

        if (msg.x >= exitIconX && msg.x <= exitIconX + iconSize &&
            msg.y >= exitIconY && msg.y <= exitIconY + iconSize) {
            // 触发退出操作
            if (MessageBox(GetHWnd(), TEXT("Are you sure to exit game?"), TEXT("exit"), MB_YESNO) == IDYES) {
                GameState::Instance().isGameRunning = false; // 设置游戏状态为不运行
            }
        }
    }
}

// 检查位置是否在安全区域
bool IsInSafeArea(const Vector2& pos) {
    return pos.x >= GameConfig::PLAY_AREA_LEFT && 
           pos.x <= GameConfig::PLAY_AREA_RIGHT &&
           pos.y >= GameConfig::PLAY_AREA_TOP && 
           pos.y <= GameConfig::PLAY_AREA_BOTTOM; // 检查是否在安全区域
}

// 音量控制函数
void SetVolume(float volume) {
    // 确保音量在0到1之间
    volume = (((0.0f) >((((1.0f) < (volume)) ? (1.0f) : (volume)))) ? (0.0f) : ((((1.0f) < (volume)) ? (1.0f) : (volume))));
    
    // 将音量转换为Windows音量范围（0-1000）
    int windowsVolume = static_cast<int>(volume * 1000); // 转换音量

    TCHAR command[100]; // 命令缓冲区
    _stprintf(command, _T("setaudio Greed-Snake volume to %d"), windowsVolume); // 格式化命令
    mciSendString(command, NULL, 0, NULL); // 发送命令
}

// 播放开始动画
void PlayStartAnimation() {
    // 定义帧文件的路径和文件扩展名
    const TCHAR* path = _T("..\\Resource\\Greed-Snake-Start-Animation-Frames\\"); // 帧文件路径
    const TCHAR* ext = _T(".bmp"); // 文件扩展名

    mciSendString(_T("open ..\\Resource\\Greed-Snake-Start-Animation.mp3 alias Start-Animation"), NULL, NULL, NULL); // 打开动画音乐
    mciSendString(_T("play Start-Animation"), NULL, NULL, NULL); // 播放动画音乐
    Sleep(6000); // 等待6秒

    // 声明 IMAGE 结构体变量
    IMAGE FImg;    

    // 使用循环加载和显示每一帧
    for (int i = 0; i <= GameConfig::NUM_FRAMES; i++) {
        TCHAR frameFileName[MAX_PATH];  // 确保缓冲区足够大以存储完整路径
        _stprintf_s(frameFileName, MAX_PATH, _T("%sframe_%d%s"), path, i, ext); // 格式化帧文件名

        // 加载图像
        loadimage(&FImg, frameFileName); // 加载图像

        IMAGE scaledG; // 缩放图像
        scaledG.Resize(GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT); // 缩放图像以适应窗口
        StretchBlt(GetImageHDC(&scaledG), 0, 0, GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT,
            GetImageHDC(&FImg), 0, 0, FImg.getwidth(), FImg.getheight(), SRCCOPY); // 绘制图像
        // 在窗口的(0,0)位置绘制图像
        putimage(0, 0, &scaledG);

        // 等待指定的延迟时间
        Sleep(GameConfig::FRAME_DELAY); // 等待帧延迟
    }
}

void StopBackgroundMusic() {
    mciSendString(_T("stop Greed-Snake"), NULL, NULL, NULL); // 停止音乐
}

// 游戏系统类
class GameSystem {
private:
    std::vector<FoodItem> foodItems;
    PlayerSnake playerSnake;
    std::vector<AISnake> aiSnakes;
    Camera camera;
    
public:
    GameSystem() {
        InitializeGame();
    }
    
    void InitializeGame() {
        // 初始化食物
        foodItems.resize(GameConfig::MAX_FOOD_COUNT);
        for (int i = 0; i < GameConfig::MAX_FOOD_COUNT; ++i) {
            InitFood(i, GameState::Instance().currentPlayerSpeed);
        }
        
        // 初始化玩家蛇
        InitializePlayerSnake();
        
        // 初始化AI蛇
        InitializeAISnakes();
        
        // 重置游戏状态
        GameState::Instance().Initial();
    }
    
    void Update(float deltaTime) {
        if (!GameState::Instance().isGameRunning) return;
        
        // 更新相机
        UpdateCamera();
        
        // 更新玩家蛇
        UpdatePlayerSnake(deltaTime);
        
        // 更新AI蛇
        UpdateAISnakes(deltaTime);
        
        // 更新食物
        UpdateFoods();
        
        // 检查碰撞
        CheckCollisions();
        
        // 更新游戏状态
        GameState::Instance().UpdateGameTime(deltaTime);
    }
    
    void Draw() {
        if (!GameState::Instance().isGameRunning) return;
        
        BeginBatchDraw();
        
        // 绘制游戏区域
        DrawGameArea();
        
        // 绘制食物
        DrawFoods();

        // 绘制AI蛇
        for (const auto& aiSnake : aiSnakes) {
            aiSnake.Draw(camera);
        }
        
        // 绘制玩家蛇
        playerSnake.Draw(camera);
        
        // 绘制UI
        DrawUI();
        
        EndBatchDraw();
    }
    
    // ... 其他方法 ...
};

// 添加网格系统来优化碰撞检测
class SpatialGrid {
private:
    struct Cell {
        std::vector<int> foodIndices;
        std::vector<int> aiSnakeIndices;
        bool hasPlayerSnake = false;
    };
    
    std::vector<Cell> grid;
    int gridWidth, gridHeight;
    float cellSize;
    
public:
    SpatialGrid(float worldWidth, float worldHeight, float cellSize) 
        : cellSize(cellSize) {
        gridWidth = static_cast<int>(worldWidth / cellSize) + 1;
        gridHeight = static_cast<int>(worldHeight / cellSize) + 1;
        grid.resize(gridWidth * gridHeight);
    }
    
    void Clear() {
        for (auto& cell : grid) {
            cell.foodIndices.clear();
            cell.aiSnakeIndices.clear();
            cell.hasPlayerSnake = false;
        }
    }
    
    void AddFood(int foodIndex, const Vector2& position) {
        int cellX = static_cast<int>((position.x - GameConfig::PLAY_AREA_LEFT) / cellSize);
        int cellY = static_cast<int>((position.y - GameConfig::PLAY_AREA_TOP) / cellSize);
        
        if (IsValidCell(cellX, cellY)) {
            grid[cellY * gridWidth + cellX].foodIndices.push_back(foodIndex);
        }
    }
    
    void AddAISnake(int snakeIndex, const Vector2& position) {
        int cellX = static_cast<int>((position.x - GameConfig::PLAY_AREA_LEFT) / cellSize);
        int cellY = static_cast<int>((position.y - GameConfig::PLAY_AREA_TOP) / cellSize);
        
        if (IsValidCell(cellX, cellY)) {
            grid[cellY * gridWidth + cellX].aiSnakeIndices.push_back(snakeIndex);
        }
    }
    
    void AddPlayerSnake(const Vector2& position) {
        int cellX = static_cast<int>((position.x - GameConfig::PLAY_AREA_LEFT) / cellSize);
        int cellY = static_cast<int>((position.y - GameConfig::PLAY_AREA_TOP) / cellSize);
        
        if (IsValidCell(cellX, cellY)) {
            grid[cellY * gridWidth + cellX].hasPlayerSnake = true;
        }
    }
    
    std::vector<int> GetNearbyFoods(const Vector2& position, float radius) {
        std::vector<int> result;
        GetNearbyCellContents(position, radius, [&](const Cell& cell) {
            result.insert(result.end(), cell.foodIndices.begin(), cell.foodIndices.end());
        });
        return result;
    }
    
    std::vector<int> GetNearbyAISnakes(const Vector2& position, float radius) {
        std::vector<int> result;
        GetNearbyCellContents(position, radius, [&](const Cell& cell) {
            result.insert(result.end(), cell.aiSnakeIndices.begin(), cell.aiSnakeIndices.end());
        });
        return result;
    }
    
    bool IsPlayerSnakeNearby(const Vector2& position, float radius) {
        bool found = false;
        GetNearbyCellContents(position, radius, [&](const Cell& cell) {
            if (cell.hasPlayerSnake) found = true;
        });
        return found;
    }
    
private:
    bool IsValidCell(int x, int y) const {
        return x >= 0 && x < gridWidth && y >= 0 && y < gridHeight;
    }
    
    template <typename Func>
    void GetNearbyCellContents(const Vector2& position, float radius, Func callback) {
        int minCellX = static_cast<int>((position.x - radius - GameConfig::PLAY_AREA_LEFT) / cellSize);
        int maxCellX = static_cast<int>((position.x + radius - GameConfig::PLAY_AREA_LEFT) / cellSize);
        int minCellY = static_cast<int>((position.y - radius - GameConfig::PLAY_AREA_TOP) / cellSize);
        int maxCellY = static_cast<int>((position.y + radius - GameConfig::PLAY_AREA_TOP) / cellSize);
        
        minCellX = std::max(0, minCellX);
        maxCellX = std::min(gridWidth - 1, maxCellX);
        minCellY = std::max(0, minCellY);
        maxCellY = std::min(gridHeight - 1, maxCellY);
        
        for (int y = minCellY; y <= maxCellY; ++y) {
            for (int x = minCellX; x <= maxCellX; ++x) {
                callback(grid[y * gridWidth + x]);
            }
        }
    }
};

