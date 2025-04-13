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
#include <mutex>
#include <ctime>
#include <condition_variable>
#include <iostream>
#include <chrono>
#include <mmsystem.h>
#include "Core/GameConfig.h"
#include "Core/Vector2.h"
#include "Gameplay/Snake.h"
#include "Gameplay/GameState.h"
#include "Utils/Rendering.h"
#include "Gameplay/Collisions.h"
#include "Core/Camera.h"
#include "Gameplay/Food.h"
#include "UI/Setting.h"
#include "UI/Button.h"
#include "Utils/InputHandler.h"       
#include "Gameplay/GameInitializer.h"           
#include "UI/UI.h"                 
#pragma comment(lib, "winmm.lib") // Required for multimedia functions
#pragma warning(disable: 4996)	 // Disable security warnings for _tcscpy and _stprintf

// Define the extern variables declared in GameConfig.h
bool GameConfig::SOUND_ON = true;
bool GameConfig::ANIMATIONS_ON = true;

// Screen dimensions
const int windowWidth = GameConfig::WINDOW_WIDTH;
const int windowHeight = GameConfig::WINDOW_HEIGHT;

// Game area boundaries
const int playAreaWidth = GameConfig::WINDOW_WIDTH;
const int playAreaHeight = GameConfig::WINDOW_HEIGHT;
const int playAreaMarginX = GameConfig::PLAY_AREA_MARGIN;
const int playAreaMarginY = GameConfig::PLAY_AREA_MARGIN;

// Player status
Vector2 playerPosition = GameConfig::PLAYER_DEFAULT_POS;
Vector2 playerDirection(0, 1);

// Game timing
float deltaTime = GameState::Instance().deltaTime;

// Animation timer for visual effects
float animationTimer = 0.0f;

// External function declaration for the growth animation update
extern void UpdateGrowthAnimation(float deltaTime);

// Arrays and collections
FoodItem foodList[GameConfig::MAX_FOOD_COUNT];
std::vector<SnakeSegment> snakeSegments(5);
  
// AI snake container
std::vector<AISnake> aiSnakeList;

// Player snake
Snake snake[1];

// Game system class
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
        // Initialize food
        foodItems.resize(GameConfig::MAX_FOOD_COUNT);
        for (int i = 0; i < GameConfig::MAX_FOOD_COUNT; ++i) {
            InitFood(foodList, i, GameState::Instance().currentPlayerSpeed);
        }
        
        // Initialize player snake
        InitializePlayerSnake();
        
        // Initialize AI snakes
        InitializeAISnakes();
        
        // Reset game state
        GameState::Instance().Initial();
    }
    
    void Update(float deltaTime) {
        if (!GameState::Instance().isGameRunning) return;
        
        // Update camera
        UpdateCamera();
        
        // Update player snake
        UpdatePlayerSnake(deltaTime);
        
        // Update AI snakes
        UpdateAISnakes(deltaTime);
        
        // Update food
        UpdateFoods(foodList, GameConfig::MAX_FOOD_COUNT);
        
        // Check collisions
        CheckCollisions();
        
        // Update game state
        GameState::Instance().UpdateGameTime(deltaTime);
    }
    
    void Draw() {
        if (!GameState::Instance().isGameRunning) return;
        
        BeginBatchDraw();
        
        // Draw game area
        DrawGameArea();
        
        // Draw food - using correct function signature
        DrawFoods(foodItems.data(), foodItems.size());  // Pass correct parameters if needed

        // Draw AI snakes
        for (const auto& aiSnake : aiSnakes) {
            aiSnake.Draw(camera);
        }
        
        // Draw player snake
        playerSnake.Draw(camera);
        
        // Draw UI
        DrawUI();
        
        EndBatchDraw();
    }
};

// Modify the Draw function to ensure thread safety when initializing graphics
void Draw() {
    // 添加错误处理
    try {
        // The rest of the Draw function...
        
        while (GameState::Instance().GetIsGameRunning()) {
            auto& gameState = GameState::Instance();
            BeginBatchDraw();
            
            // 安全地获取暂停状态
            bool isPaused = gameState.GetIsPaused();
            
            // Skip all updates if the game is paused, just maintain the current display
            if (!isPaused) {
                // Update camera
                UpdateCamera();
                
                // Update game objects only when not paused
                UpdatePlayerSnake(gameState.deltaTime);
                UpdateAISnakes(gameState.deltaTime);
                UpdateFoods(foodList, GameConfig::MAX_FOOD_COUNT);
                
                // Check collision and game state only when not paused
                CheckGameState(snake);  
                CheckCollisions();
                
                // Update animation timer only when not paused
                {
                    std::lock_guard<std::mutex> lock(gameState.stateMutex);
                    animationTimer += gameState.deltaTime;
                    if (animationTimer > 1000.0f) {
                        animationTimer = 0.0f;
                    }
                }
            }
            
            // Always draw the current state of the game
            DrawGameArea();
            
            // Create thread-safe copy of snake object
            PlayerSnake playerSnakeObj;
            {
                std::lock_guard<std::mutex> lock(gameState.stateMutex);
                playerSnakeObj.position = snake[0].position;
                playerSnakeObj.direction = snake[0].direction;
                playerSnakeObj.radius = snake[0].radius;
                playerSnakeObj.color = snake[0].color;
                
                // Copy snake body segments
                playerSnakeObj.segments.resize(snake[0].segments.size());
                for (size_t i = 0; i < snake[0].segments.size(); ++i) {
                    playerSnakeObj.segments[i] = snake[0].segments[i];
                }
            }
            
            DrawVisibleObjects(foodList, GameConfig::MAX_FOOD_COUNT, 
                              aiSnakeList.data(), 
                              static_cast<int>(aiSnakeList.size()), 
                              playerSnakeObj);

            // Update growth animation effect only when not paused
            if (!isPaused) {
                UpdateGrowthAnimation(gameState.deltaTime);
            }
                          
            // Draw UI elements
            DrawUI();
            
            EndBatchDraw();
            // Add frame rate control
            Sleep(1000 / 60);  // Limit to approximately 60 FPS
        }
    }
    catch (const std::exception& e) {
        // 捕获并记录严重错误
        OutputDebugStringA(e.what());
        MessageBox(GetHWnd(), _T("Drawing thread encountered an error"), _T("Error"), MB_OK | MB_ICONERROR);
        
        // 确保游戏能正常退出
        GameState::Instance().SetIsGameRunning(false);
    }
}

int main() {
    // Initialize graphics first in the main thread
    initgraph(GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT);

    // Play start animation
    PlayStartAnimation();

    LoadButton(); // Load buttons

    // Main program loop - keep running until exit is selected
    bool quitProgram = false;
    
    while (!quitProgram) {
        // Load and scale background image before each menu display
        IMAGE backgroundImage;
        loadimage(&backgroundImage, _T(".\\Resource\\Greed-Snake-BG.png")); // Load background image

        // Scale background to fit window
        IMAGE scaledBG;
        scaledBG.Resize(GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT);
        StretchBlt(GetImageHDC(&scaledBG), 0, 0, GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT,
            GetImageHDC(&backgroundImage), 0, 0, backgroundImage.getwidth(), backgroundImage.getheight(), SRCCOPY);

        // Apply the background image
        BeginBatchDraw();
        putimage(0, 0, &scaledBG);
        EndBatchDraw();

        // Menu loop
        bool showMenu = true;
        bool startGame = false;
        
        while (showMenu && !quitProgram) {
            // Use ShowGameMenu function from UI.h to display menu
            int menuChoice = ShowGameMenu();
            
            switch (menuChoice) {
                case StartGame:
                    cleardevice();
                    startGame = true;
                    showMenu = false;
                    break;
                    
                case Setting:
                    ShowSettings(windowWidth, windowHeight);
                    // Redraw background after settings
                    putimage(0, 0, &scaledBG);
                    break;
                    
                case About:
                    ShowAbout();
                    // Redraw background after about screen
                    putimage(0, 0, &scaledBG);
                    break;
                    
                case Exit:
                    quitProgram = true;
                    showMenu = false;
                    break;
                    
                default:
                    break;
            }
        }

        // Game main loop
        while (startGame && !quitProgram) {
            GameState::Instance().Initial();
            InitGlobal();

            PlayBackgroundMusic();

            // Initialize player snake
            Vector2 centerPos(windowWidth / 2, (windowHeight / 2));
            snake[0].position = centerPos;
            snake[0].direction = Vector2(1, 0);
            snake[0].radius = GameConfig::INITIAL_SNAKE_SIZE;
            snake[0].color = HSLtoRGB(255, 255, 255);

            // Initialize snake body segments
            snake[0].segments.resize(4);
            for (int i = 0; i < snake[0].segments.size(); i++) {
                snake[0].segments[i].position = centerPos - Vector2(1, 0) * ((i+1) * GameConfig::SNAKE_SEGMENT_SPACING);
                snake[0].segments[i].direction = Vector2(1, 0);
                snake[0].segments[i].radius = GameConfig::INITIAL_SNAKE_SIZE;
                snake[0].segments[i].color = HSLtoRGB(255, 255, 255);
            }

            // Initialize food positions
            for (int i = 0; i < GameConfig::MAX_FOOD_COUNT; ++i) {
                InitFood(foodList, i, GameState::Instance().currentPlayerSpeed);
            }

            // Initialize AI snakes
            InitializeAISnakes();

            // 添加线程异常处理
            std::exception_ptr drawThreadException = nullptr;
            std::exception_ptr inputThreadException = nullptr;
            
            // 使用异步函数调用，可以捕获异常
            std::thread draw([&drawThreadException]() {
                try {
                    Draw();
                } catch(...) {
                    drawThreadException = std::current_exception();
                }
            });
            
            std::thread input([&inputThreadException]() {
                try {
                    EnterChanges();
                } catch(...) {
                    inputThreadException = std::current_exception();
                }
            });

            // Game running loop
            bool gameRunning = true;
            while (gameRunning) {
                // 检查线程是否发生异常
                if (drawThreadException) {
                    try {
                        std::rethrow_exception(drawThreadException);
                    } catch (const std::exception& e) {
                        MessageBox(GetHWnd(), _T("Drawing thread error occurred"), _T("Error"), MB_OK | MB_ICONERROR);
                        OutputDebugStringA(e.what());
                    }
                    GameState::Instance().SetIsGameRunning(false);
                    gameRunning = false;
                    break;
                }
                
                if (inputThreadException) {
                    try {
                        std::rethrow_exception(inputThreadException);
                    } catch (const std::exception& e) {
                        MessageBox(GetHWnd(), _T("Input thread error occurred"), _T("Error"), MB_OK | MB_ICONERROR);
                        OutputDebugStringA(e.what());
                    }
                    GameState::Instance().SetIsGameRunning(false);
                    gameRunning = false;
                    break;
                }
                
                // 检查是否通过ESC菜单选择退出游戏
                bool shouldExit;
                {
                    std::lock_guard<std::mutex> lock(GameState::Instance().stateMutex);
                    shouldExit = GameState::Instance().exitGame;
                }
                
                if (shouldExit) {
                    quitProgram = true;
                    gameRunning = false;
                    GameState::Instance().SetIsGameRunning(false);
                    break;
                }
                
                // 安全地获取游戏状态
                bool isGameRunning, isPaused, showDeathMessage;
                {
                    std::lock_guard<std::mutex> lock(GameState::Instance().stateMutex);
                    isGameRunning = GameState::Instance().isGameRunning;
                    isPaused = GameState::Instance().isPaused;
                    showDeathMessage = GameState::Instance().showDeathMessage;
                }
                
                // Update game time - only happens when not paused
                if (isGameRunning && !isPaused) {
                    GameState::Instance().UpdateGameTime(GameState::Instance().deltaTime);
                }
                
                // Handle game end conditions
                if (!isGameRunning && showDeathMessage) {
                    // Stop drawing and input threads to prevent interference
                    GameState::Instance().SetIsGameRunning(false);
                    
                    // 安全地等待线程结束
                    if (input.joinable()) input.join();
                    if (draw.joinable()) draw.join();
                    
                    cleardevice();
                    
                    // Show death message after game ends, ensure in main thread
                    GameState::Instance().ShowDeathMessage();
                    {
                        std::lock_guard<std::mutex> lock(GameState::Instance().stateMutex);
                        GameState::Instance().showDeathMessage = false;
                    }
                    
                    // Set flag to exit game loop
                    gameRunning = false;
                }
                
                // 重新安全地获取游戏状态
                {
                    std::lock_guard<std::mutex> lock(GameState::Instance().stateMutex);
                    isGameRunning = GameState::Instance().isGameRunning;
                    showDeathMessage = GameState::Instance().showDeathMessage;
                }
                
                // Continue game if still running without death message
                if (!isGameRunning && !showDeathMessage) {
                    gameRunning = false;  // Exit game loop if game ended and death message processed
                }
                
                Sleep(10);  // Reduce CPU usage
            }

            // Clean up game resources
            {
                std::lock_guard<std::mutex> lock(GameState::Instance().stateMutex);
                if (GameState::Instance().isGameRunning) {
                    GameState::Instance().isGameRunning = false;  // Ensure drawing thread exits
                }
            }
            
            // 安全地等待线程结束
            if (input.joinable()) input.join();
            if (draw.joinable()) draw.join();
            
            Sleep(500);  // Short delay to ensure resource cleanup
            
            // Determine what to do next
            if (GameState::Instance().returnToMenu) {
                GameState::Instance().returnToMenu = false;
                startGame = false;  // Exit game loop and return to menu loop
            } else if (GameState::Instance().exitGame) {
                quitProgram = true;  // 如果选择了退出，则设置标志退出整个程序
            } else {
                // Keep startGame true to restart game
            }
        }
    }

    // Clean up audio resources before exiting
    CleanupAudioResources();
    closegraph(); // Close graphics window
    return 0; // Exit program
}

