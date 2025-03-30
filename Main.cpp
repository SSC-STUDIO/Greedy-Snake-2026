#include <graphics.h>
#include <conio.h>
#include <tchar.h>
#include <string>
#include <vector>
#include <thread>
#include <windows.h>
#include <math.h>
#include <queue>
#include <algorithm>
//#include <deque>
#include <mutex>
#include <ctime>
#include "GameConfig.h"
#include "Vector2.h"
#include "Snake.h"
#include "GameState.h"
#include "Rendering.h"
#include "Collisions.h"
#include "SpatialGrid.h"
#include "Camera.h"
#include "Food.h"
#include "Setting.h"
#include "StartInterface.h"
#include "Button.h"
#pragma comment(lib, "winmm.lib") // 多媒体函数所需
//#pragma warning(disable: 4996)	 // 禁用关于 _tcscpy 和 _stprintf 的安全警告

// #define DEBUG_DRAW_TEXT(value, x, y) DebugDrawText(std::wstring(_T(#value": ")) + std::to_wstring(value), x, y, HSLtoRGB(0, 0, 255));

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

// 游戏计时
float deltaTime = GameState::Instance().deltaTime; // 时间增量

// 数组和集合
FoodItem foodList[GameConfig::MAX_FOOD_COUNT];  // 食物列表
std::vector<SnakeSegment> snakeSegments(5); // 蛇段列表
  
// AI蛇容器
std::vector<AISnake> aiSnakeList;               // AI蛇列表

// Global variables if not already defined
Snake snake[1];                                // 玩家蛇
int GetHistoryIndexAtDistance(const std::deque<Vector2>& positions, float targetDistance);
void ShowDeathMessage(int score);

// Function implementations
void InitializePlayerSnake() {
    Vector2 startPos = GameConfig::PLAYER_DEFAULT_POS; // 声明并初始化startPos
    Vector2 startDir(0, 1);  // 向下的起始方向
                           
    // 初始化蛇头
    snake[0].position = startPos;
    snake[0].direction = startDir;
    snake[0].radius = GameConfig::INITIAL_SNAKE_SIZE;
    snake[0].color = HSLtoRGB(255, 255, 255);  // 白色
    snake[0].posRecords = std::queue<Vector2>();
    
    // 调整蛇身体段的大小
    snake[0].segments.resize(4);  // 4个身体段 + 1个头 = 5个部分
    
    // 初始化蛇身体段
    for (size_t i = 0; i < snake[0].segments.size(); i++) {
        snake[0].segments[i].position = startPos - startDir * ((i+1) * GameConfig::SNAKE_SEGMENT_SPACING);
        snake[0].segments[i].direction = startDir;
        snake[0].segments[i].radius = GameConfig::INITIAL_SNAKE_SIZE;
        snake[0].segments[i].color = HSLtoRGB(255, 255, 255);  // 白色
        snake[0].segments[i].posRecords = std::queue<Vector2>();
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
    // 更新头部               
    snake[0].direction = GameState::Instance().targetDirection;
    snake[0].position = snake[0].position + snake[0].GetVelocity() * deltaTime;
    snake[0].Update(deltaTime);

    // 更新身体段
    for (size_t i = 0; i < snake[0].segments.size(); i++) {
        if (i == 0) {
            snake[0].UpdateBody(snake[0], snake[0].segments[i]);
        }
        else {
            snake[0].UpdateBody(snake[0].segments[i-1], snake[0].segments[i]);
        }
        snake[0].segments[i].Update(deltaTime);
    }
}

void UpdateAISnakes(float deltaTime) {
    for (auto& aiSnake : aiSnakeList) {
        aiSnake.Update(std::vector<FoodItem>(foodList, foodList + GameConfig::MAX_FOOD_COUNT), 
                      deltaTime, 
                      snake[0].position);
        
        float snakeSpeed = GameState::Instance().currentPlayerSpeed * 0.75f; // 设置为玩家蛇速度的75%
        aiSnake.position = aiSnake.position + aiSnake.direction * snakeSpeed * deltaTime;
        
        aiSnake.RecordPos();
        
        for (size_t i = 0; i < aiSnake.segments.size(); i++) {
            if (i == 0) {
                aiSnake.UpdateBody(aiSnake, aiSnake.segments[i]);
            } else {
                aiSnake.UpdateBody(aiSnake.segments[i-1], aiSnake.segments[i]);
            }
            aiSnake.segments[i].Update(deltaTime);
        }
        
        for (auto& segment : aiSnake.segments) {
            segment.color = aiSnake.color;
            segment.radius = aiSnake.radius;
        }
    }
}

int GetHistoryIndexAtDistance(const std::deque<Vector2>& positions, float targetDistance) {
    if (positions.size() < 2) return 0;
    
    float currentDistance = 0.0f;
    
    // 从    最近的位置向后查找
    for (int i = positions.size() - 2; i >= 0; i--) {
        float segmentLength = (positions[i+1] - positions[i]).GetLength();
        currentDistance += segmentLength;
        
        if (currentDistance >= targetDistance) {
            // 找到大于等于目标距离的位置
            // 如果需要的话，可以在这里进行插值以获得更精确的位置
            return i;
        }
    }
    
    // 如果找不到足够远的点，就返回最早的历史点
    return 0;
}

// 初始化AI蛇
void InitializeAISnakes() {
    auto& gameState = GameState::Instance();
    aiSnakeList.resize(gameState.aiSnakeCount);
    
    for (auto& aiSnake : aiSnakeList) {
        aiSnake.Init();
        
        // 根据难度调整AI行为
        aiSnake.aggressionFactor = gameState.aiAggression; // 设置攻击性因子
        
        aiSnake.speedMultiplier = 1.0f; 
    }
    
    for (int i = 0; i < gameState.aiSnakeCount; ++i) {
        // 在中心周围以圆形分布生成蛇
        float angle = (i * 360.0f / gameState.aiSnakeCount) * 3.14159f / 180.0f;
        float distance = rand() % static_cast<int>(GameConfig::AI_SPAWN_RADIUS);
        
        float x = windowWidth/2 + cos(angle) * distance;
        float y = windowHeight/2 + sin(angle) * distance;
        
        // 确保位置在安全区域内
        x = max(GameConfig::PLAY_AREA_LEFT + 100.0f, min(GameConfig::PLAY_AREA_RIGHT - 100.0f, x));
        y = max(GameConfig::PLAY_AREA_TOP + 100.0f, min(GameConfig::PLAY_AREA_BOTTOM - 100.0f, y));
        
        // 随机起始方向
        float dirAngle = (rand() % 360) * 3.14159f / 180.0f;
        Vector2 direction(cos(dirAngle), sin(dirAngle));
        
        // 初始化AI蛇的位置和方向
        aiSnakeList[i].position = Vector2(x, y);
        aiSnakeList[i].direction = direction;
        aiSnakeList[i].radius = GameConfig::INITIAL_SNAKE_SIZE * 0.8f;
        aiSnakeList[i].color = HSLtoRGB(rand() % 360, 200, 200);
        
        // 初始化蛇的身体段，确保间距相等
        for (int j = 0; j < 5; j++) {
            // 设置固定间距
            aiSnakeList[i].segments[j].position = aiSnakeList[i].position - 
                direction * (j + 1) * GameConfig::SNAKE_SEGMENT_SPACING;
            aiSnakeList[i].segments[j].direction = direction;
            aiSnakeList[i].segments[j].radius = aiSnakeList[i].radius;
            aiSnakeList[i].segments[j].color = aiSnakeList[i].color;
        }
        
        // 初始化位置历史记录
        aiSnakeList[i].recordedPositions.clear();
        for (int j = 0; j < 20; j++) {
            // 从尾部到头部填充初始历史记录
            aiSnakeList[i].recordedPositions.push_back(
                aiSnakeList[i].position - direction * j * (GameConfig::SNAKE_SEGMENT_SPACING / 4.0f));
        }
    }
}

void EnterChanges(void) {
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
                    GameState::Instance().isGameRunning = false;
                    break;
                }
                break;
            }
        }
    }
}

void InitSnake(int i, const Vector2& pos, const Vector2& currentDir) {
    if (i == 0) {
        // 初始化蛇头
        snake[0].position = pos;
        snake[0].color = HSLtoRGB(255, 255, 255);
        snake[0].radius = GameConfig::INITIAL_SNAKE_SIZE;
        snake[0].direction = currentDir;
        snake[0].currentTime = 0;
        snake[0].posRecords = std::queue<Vector2>();
    } else {
        // 初始化蛇身体段
        int segmentIndex = i - 1;
        if (segmentIndex < 0 || segmentIndex >= static_cast<int>(snake[0].segments.size())) {
            snake[0].segments.resize(segmentIndex + 1);
        }
        snake[0].segments[segmentIndex].position = pos - currentDir * (i * GameConfig::SNAKE_SEGMENT_SPACING);
        snake[0].segments[segmentIndex].color = HSLtoRGB(255, 255, 255);
        snake[0].segments[segmentIndex].radius = GameConfig::INITIAL_SNAKE_SIZE;
        snake[0].segments[segmentIndex].direction = currentDir;
        snake[0].segments[segmentIndex].currentTime = 0;
        snake[0].segments[segmentIndex].posRecords = std::queue<Vector2>();
    }
}

void ChangeGlobalSpeed(float newSpeed) {
    GameState::Instance().currentPlayerSpeed = newSpeed; // 改变全局速度
}

void Draw() {
    while (GameState::Instance().isGameRunning) {
        BeginBatchDraw();

        // 更新相机
        UpdateCamera();

        // 绘制游戏区域
        DrawGameArea();
        
        // 更新和绘制游戏对象
        UpdatePlayerSnake(GameState::Instance().deltaTime);
        UpdateAISnakes(GameState::Instance().deltaTime);
        UpdateFoods(foodList, GameConfig::MAX_FOOD_COUNT);
        
        // 创建临时PlayerSnake对象来绘制玩家蛇
        PlayerSnake playerSnakeObj;
        playerSnakeObj.position = snake[0].position;
        playerSnakeObj.direction = snake[0].direction;
        playerSnakeObj.radius = snake[0].radius;
        playerSnakeObj.color = snake[0].color;
        
        // 复制蛇身体段
        playerSnakeObj.segments.resize(snake[0].segments.size());
        for (size_t i = 0; i < snake[0].segments.size(); ++i) {
            playerSnakeObj.segments[i] = snake[0].segments[i];
        }
        
        DrawVisibleObjects(foodList, GameConfig::MAX_FOOD_COUNT, 
                          aiSnakeList.data(), 
                          static_cast<int>(aiSnakeList.size()), 
                          playerSnakeObj);

        // 绘制UI元素
        DrawUI();

        CheckGameState(snake);  
        
        // 检查碰撞
        CheckCollisions();

        EndBatchDraw();
        
        // 添加帧率控制
        Sleep(1000 / 60);  // 限制约60FPS
    }
}

void PlayBackgroundMusic() {
    mciSendString(_T("open ..\\Resource\\Greed-Snake-Start-Animation.mp3 alias Greed-Snake"), NULL, NULL, NULL); // 打开音乐文件
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

// 播放开始动画
void PlayStartAnimation() {
    // 定义帧文件的路径和文件扩展名
    const TCHAR* path = _T(".\\Resource\\Greed-Snake-Start-Animation-Frames\\"); // 帧文件路径
    const TCHAR* ext = _T(".bmp"); // 文件扩展名

    mciSendString(_T("open .\\Resource\\Greed-Snake-Start-Animation.mp3 alias Start-Animation"), NULL, NULL, NULL); // 打开动画音乐
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
            InitFood(foodList, i, GameState::Instance().currentPlayerSpeed);
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
        UpdateFoods(foodList, GameConfig::MAX_FOOD_COUNT);
        
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
        
        // 绘制食物 - 使用正确的函数签名
        DrawFoods(foodItems.data(), foodItems.size());  // 如果需要，应该传递正确的参数

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
};

void InitGlobal() {
    playerPosition = GameConfig::PLAYER_DEFAULT_POS; // 初始化玩家位置
    
    // 不使用resize，初始化蛇头和预置几个身体段
    snake[0].position = GameConfig::PLAYER_DEFAULT_POS;
    snake[0].direction = Vector2(0, 1);
    snake[0].radius = GameConfig::INITIAL_SNAKE_SIZE;
    snake[0].color = HSLtoRGB(255, 255, 255);
    
    // 预置4个身体段
    snake[0].segments.resize(4);
    for (size_t i = 0; i < snake[0].segments.size(); i++) {
        snake[0].segments[i].position = GameConfig::PLAYER_DEFAULT_POS - Vector2(0, 1) * ((i+1) * GameConfig::SNAKE_SEGMENT_SPACING);
        snake[0].segments[i].direction = Vector2(0, 1);
        snake[0].segments[i].radius = GameConfig::INITIAL_SNAKE_SIZE;
        snake[0].segments[i].color = HSLtoRGB(255, 255, 255);
    }
}

void ShowDeathMessage(int score) {
    // 保存当前画面状态
    BeginBatchDraw();
    
    // 创建半透明遮罩
    setfillcolor(RGB(0, 0, 0));  // 使用纯黑色
    solidrectangle(0, 0, GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT);
    
    // 绘制消息框
    const int msgBoxWidth = 400;
    const int msgBoxHeight = 250;
    const int msgBoxX = (GameConfig::WINDOW_WIDTH - msgBoxWidth) / 2;
    const int msgBoxY = (GameConfig::WINDOW_HEIGHT - msgBoxHeight) / 2;
    
    // 绘制消息框背景
    setfillcolor(RGB(50, 50, 50));
    solidroundrect(msgBoxX, msgBoxY, msgBoxX + msgBoxWidth, msgBoxY + msgBoxHeight, 20, 20);
    
    // 绘制边框
    setlinecolor(RGB(150, 150, 150));
    roundrect(msgBoxX, msgBoxY, msgBoxX + msgBoxWidth, msgBoxY + msgBoxHeight, 20, 20);
    
    // 绘制标题
    settextstyle(32, 0, _T("Arial"));
    settextcolor(RGB(255, 50, 50));
    const TCHAR* title = _T("游戏结束");
    int titleWidth = textwidth(title);
    outtextxy(msgBoxX + (msgBoxWidth - titleWidth) / 2, msgBoxY + 30, title);
    
    // 绘制分数
    settextstyle(24, 0, _T("Arial"));
    settextcolor(RGB(255, 255, 255));
    TCHAR scoreText[50];
    _stprintf(scoreText, _T("您的得分: %d"), score);
    int scoreWidth = textwidth(scoreText);
    outtextxy(msgBoxX + (msgBoxWidth - scoreWidth) / 2, msgBoxY + 100, scoreText);
    
    // 绘制按钮
    const int btnWidth = 120;
    const int btnHeight = 40;
    const int btnY = msgBoxY + msgBoxHeight - 70;
    
    // 重新开始按钮
    setfillcolor(RGB(100, 150, 100));
    solidroundrect(msgBoxX + msgBoxWidth/2 - btnWidth - 20, btnY, 
                  msgBoxX + msgBoxWidth/2 - 20, btnY + btnHeight, 10, 10);
    
    settextstyle(20, 0, _T("Arial"));
    settextcolor(RGB(255, 255, 255));
    //const TCHAR* restartText = _T("重新开始");  // 用正确的中文代替 "xxxx
    const TCHAR* restartText = _T("xxxx");  // 用正确的中文代替 "xxxx"
    int restartWidth = textwidth(restartText);
    outtextxy(msgBoxX + msgBoxWidth/2 - btnWidth/2 - 20, 
             btnY + (btnHeight - textheight(restartText))/2, restartText);
    
    // 返回菜单按钮
    setfillcolor(RGB(150, 100, 100));
    solidroundrect(msgBoxX + msgBoxWidth/2 + 20, btnY, 
                  msgBoxX + msgBoxWidth/2 + btnWidth + 20, btnY + btnHeight, 10, 10);
    
    const TCHAR* menuText = _T("返回菜单");
    int menuWidth = textwidth(menuText);
    outtextxy(msgBoxX + msgBoxWidth/2 + 20 + (btnWidth - menuWidth)/2, 
             btnY + (btnHeight - textheight(menuText))/2, menuText);
    
    // 显示当前帧
    EndBatchDraw();
    
    // 等待用户点击
    bool waitingForClick = true;
    while (waitingForClick) {
        // 使用阻塞方式获取消息，确保我们能接收到点击
        ExMessage msg = getmessage(EX_MOUSE);
        if (msg.message == WM_LBUTTONDOWN) {
            // 检查是否点击"重新开始"按钮
            if (msg.x >= msgBoxX + msgBoxWidth/2 - btnWidth - 20 && 
                msg.x <= msgBoxX + msgBoxWidth/2 - 20 &&
                msg.y >= btnY && msg.y <= btnY + btnHeight) {
                
                // 重新开始游戏
                GameState::Instance().isGameRunning = true;
                GameState::Instance().gameStartTime = 0.0f;
                GameState::Instance().isInvulnerable = true;
                GameState::Instance().foodEatenCount = 0;
                
                // 重新初始化游戏组件
                InitGlobal();
                InitializePlayerSnake();
                for (int i = 0; i < GameConfig::MAX_FOOD_COUNT; ++i) {
                    InitFood(foodList, i, GameState::Instance().currentPlayerSpeed);
                }
                InitializeAISnakes();
                
                waitingForClick = false;
            }
            // 检查是否点击"返回菜单"按钮
            else if (msg.x >= msgBoxX + msgBoxWidth/2 + 20 && 
                     msg.x <= msgBoxX + msgBoxWidth/2 + btnWidth + 20 &&
                     msg.y >= btnY && msg.y <= btnY + btnHeight) {
                
                // 返回主菜单
                GameState::Instance().returnToMenu = true;
                waitingForClick = false;
            }
        }
    }
}

int main() {
    // 初始化游戏窗口
    initgraph(GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT);

    // 播放开始动画
    PlayStartAnimation();

    LoadButton(); // 加载按钮

    // 加载并缩放背景图像
    IMAGE backgroundImage;
    loadimage(&backgroundImage, _T(".\\Resource\\Greed-Snake-BG.png")); // 加载背景图像

    // 缩放背景以适应窗口
    IMAGE scaledBG;
    scaledBG.Resize(GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT);
    StretchBlt(GetImageHDC(&scaledBG), 0, 0, GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT,
        GetImageHDC(&backgroundImage), 0, 0, backgroundImage.getwidth(), backgroundImage.getheight(), SRCCOPY);

GAME_START_INTERFACE:
    putimage(0, 0, &scaledBG); // 绘制背景

    // 设置菜单文本样式
    settextstyle(32, 0, _T("Arial"));
    settextcolor(RGB(255, 255, 255));
    setbkmode(TRANSPARENT);

    // 显示主菜单
    DrawMenu();

    // 菜单循环
    MenuOption selectedOption = MenuOption::START; // 选中的菜单选项
    while (true) {
        ExMessage m = getmessage(EX_MOUSE);
        const Vector2 mousePos = Vector2(m.x, m.y);
        if (m.message == WM_LBUTTONDOWN) {
            if (buttonList[StartGame].IsOnButton(mousePos)) {
                cleardevice();  // 清除屏幕而不是创建新窗口
                goto START_GAME;  // 跳转到游戏初始化
            }
            else if (buttonList[Setting].IsOnButton(mousePos)) {
                ShowSettings(); // 显示设置
                putimage(0, 0, &scaledBG);  // 恢复背景
                DrawMenu(); // 重新绘制菜单
                continue;
            }
            else if (buttonList[About].IsOnButton(mousePos)) {
                ShowAbout(); // 显示关于
                putimage(0, 0, &scaledBG);  // 恢复背景
                DrawMenu(); // 重新绘制菜单
                continue;
            }
            else if (buttonList[Exit].IsOnButton(mousePos)) {
                closegraph(); // 关闭图形窗口
                return 0; // 退出程序
            }
        }
    }

START_GAME:
    GameState::Instance().Initial();
    InitGlobal();

    PlayBackgroundMusic();

    // 初始化玩家蛇
    Vector2 centerPos(windowWidth / 2, (windowHeight / 2));
    snake[0].position = centerPos;
    snake[0].direction = Vector2(1, 0);
    snake[0].radius = GameConfig::INITIAL_SNAKE_SIZE;
    snake[0].color = HSLtoRGB(255, 255, 255);

    // 初始化蛇身体段
    snake[0].segments.resize(4);
    for (int i = 0; i < snake[0].segments.size(); i++) {
        snake[0].segments[i].position = centerPos - Vector2(1, 0) * ((i+1) * GameConfig::SNAKE_SEGMENT_SPACING);
        snake[0].segments[i].direction = Vector2(1, 0);
        snake[0].segments[i].radius = GameConfig::INITIAL_SNAKE_SIZE;
        snake[0].segments[i].color = HSLtoRGB(255, 255, 255);
    }

    // 初始化食物位置
    for (int i = 0; i < GameConfig::MAX_FOOD_COUNT; ++i) {
        InitFood(foodList, i, GameState::Instance().currentPlayerSpeed);
    }

    // 初始化AI蛇
    InitializeAISnakes();

    // 启动绘制和输入线程
    std::thread draw(Draw);
    std::thread input(EnterChanges);

    // 主游戏循环
    while (true) {
        // 更新游戏时间
        if (GameState::Instance().isGameRunning) {
            GameState::Instance().UpdateGameTime(GameState::Instance().deltaTime);
        }
        
        // 处理游戏结束情况
        if (!GameState::Instance().isGameRunning && GameState::Instance().showDeathMessage) {
            // 首先等待绘制线程进入安全状态
            Sleep(50);  // 简单的同步方法，让绘制线程完成当前帧
            
            // 显示死亡消息并重置标志
            ShowDeathMessage(GameState::Instance().foodEatenCount);
            GameState::Instance().showDeathMessage = false;
            
            // 如果选择了"返回主菜单"，退出游戏循环
            if (GameState::Instance().returnToMenu) {
                break;
            }
        }
        
        // 如果游戏仍在运行但没有死亡消息，继续游戏
        if (!GameState::Instance().isGameRunning && !GameState::Instance().showDeathMessage) {
            break;  // 如果游戏已经结束且死亡消息已处理，退出游戏循环
        }
        
        Sleep(10);  // 减少CPU使用率
    }

    // 清理游戏资源
    GameState::Instance().isGameRunning = false;  // 确保绘制线程退出
    input.join();
    draw.join();

    StopBackgroundMusic();
    Sleep(500);  // 短暂延迟确保资源清理
    
    if (GameState::Instance().returnToMenu) {
        GameState::Instance().returnToMenu = false;
        goto GAME_START_INTERFACE;  // 跳转到主菜单
    }

    closegraph(); // 关闭图形窗口
    return 0; // 退出程序
}

void CheckCollisions() {
    auto& gameState = GameState::Instance();
    
    // 简化检查玩家是否处于无敌状态的代码
    if (!gameState.IsCollisionEnabled()) {
        if (gameState.isInvulnerable) {
            // 在蛇头附近显示无敌状态文字
            settextcolor(RGB(255, 255, 0));  // 明黄色
            settextstyle(18, 0, _T("微软雅黑"));
            
            Vector2 textPos = snake[0].position - gameState.camera.position;
            textPos.y -= 40;  // 在蛇头上方显示
            
            // 显示剩余无敌时间
            TCHAR invulnerableText[50];
            float remainingInvulnerableTime = GameConfig::COLLISION_GRACE_PERIOD - gameState.gameStartTime;
            if (remainingInvulnerableTime < 0) remainingInvulnerableTime = 0;
            _stprintf(invulnerableText, _T("无敌: %.1fs"), remainingInvulnerableTime);
            
            // 计算文本宽度并居中显示
            int textWidth = textwidth(invulnerableText);
            outtextxy(textPos.x - textWidth/2, textPos.y, invulnerableText);
        }
        return;
    }

    CollisionManager::CheckCollisions(
        snake, 
        aiSnakeList.data(), 
        static_cast<int>(aiSnakeList.size()), 
        foodList, 
        GameConfig::MAX_FOOD_COUNT
    );

    CheckGameState(snake);
}


