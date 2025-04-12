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
#include "GameConfig.h"
#include "Vector2.h"
#include "Snake.h"
#include "GameState.h"
#include "Rendering.h"
#include "Collisions.h"
#include "Camera.h"
#include "Food.h"
#include "Setting.h"
#include "StartInterface.h"
#include "Button.h"
#include "InputHandler.h"       
#include "GameInitializer.h"    
#include "SoundManager.h"       
#include "UI.h"                 
#pragma comment(lib, "winmm.lib") // Required for multimedia functions
#pragma warning(disable: 4996)	 // Disable security warnings for _tcscpy and _stprintf

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

// Global variables if not already defined
// Forward declarations for functions in other files
int GetHistoryIndexAtDistance(const std::deque<Vector2>& positions, float targetDistance);
void CheckCollisions();

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

// Remove mutex and condition variable
bool graphicsInitialized = false;

// Modify the Draw function to ensure thread safety when initializing graphics
void Draw() {
    // Set graphics as initialized
    graphicsInitialized = true;
    
    // The rest of the Draw function...
    BeginBatchDraw();
    while (GameState::Instance().isGameRunning) {
        auto& gameState = GameState::Instance();
        
        // Skip all updates if the game is paused, just maintain the current display
        if (!gameState.isPaused) {
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
            animationTimer += gameState.deltaTime;
            if (animationTimer > 1000.0f) {
                animationTimer = 0.0f;
            }
        }
        
        // Always draw the current state of the game
        DrawGameArea();
        
        // Create temporary PlayerSnake object to draw player snake
        PlayerSnake playerSnakeObj;
        playerSnakeObj.position = snake[0].position;
        playerSnakeObj.direction = snake[0].direction;
        playerSnakeObj.radius = snake[0].radius;
        playerSnakeObj.color = snake[0].color;
        
        // Copy snake body segments
        playerSnakeObj.segments.resize(snake[0].segments.size());
        for (size_t i = 0; i < snake[0].segments.size(); ++i) {
            playerSnakeObj.segments[i] = snake[0].segments[i];
        }
        
        DrawVisibleObjects(foodList, GameConfig::MAX_FOOD_COUNT, 
                          aiSnakeList.data(), 
                          static_cast<int>(aiSnakeList.size()), 
                          playerSnakeObj);

        // Update growth animation effect only when not paused
        if (!gameState.isPaused) {
            UpdateGrowthAnimation(gameState.deltaTime);
        }
                          
        // Draw UI elements
        DrawUI();
        
        FlushBatchDraw();
        // Add frame rate control
        Sleep(1000 / 60);  // Limit to approximately 60 FPS
    }
    EndBatchDraw();
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

            // Start drawing and input threads
            std::thread draw(Draw);
            std::thread input(EnterChanges);

            // Game running loop
            bool gameRunning = true;
            while (gameRunning) {
                // Check for pause - when paused, wait for user action before continuing
                if (GameState::Instance().isPaused) {
                    // Display pause menu and wait for user input
                    GameState::Instance().ShowPauseMenu();
                    
                    // Continue the loop after the user has made a selection
                    // The ShowPauseMenu function only returns after a selection is made
                    continue;
                }
                
                // Update game time - only happens when not paused
                if (GameState::Instance().isGameRunning) {
                    GameState::Instance().UpdateGameTime(GameState::Instance().deltaTime);
                }
                
                // Handle game end conditions
                if (!GameState::Instance().isGameRunning && GameState::Instance().showDeathMessage) {
                    // Stop drawing and input threads to prevent interference
                    GameState::Instance().isGameRunning = false;
                    
                    // Wait for drawing and input threads to end
                    input.join();
                    draw.join();
                    
                    // Ensure screen state is correct
                    BeginBatchDraw();
                    cleardevice();
                    EndBatchDraw();
                    
                    // Show death message after game ends, ensure in main thread
                    GameState::Instance().ShowDeathMessage();
                    GameState::Instance().showDeathMessage = false;
                    
                    // Set flag to exit game loop
                    gameRunning = false;
                }
                
                // Continue game if still running without death message
                if (!GameState::Instance().isGameRunning && !GameState::Instance().showDeathMessage) {
                    gameRunning = false;  // Exit game loop if game ended and death message processed
                }
                
                Sleep(10);  // Reduce CPU usage
            }

            // Clean up game resources
            if (GameState::Instance().isGameRunning) {
                GameState::Instance().isGameRunning = false;  // Ensure drawing thread exits
                input.join();
                draw.join();
            }

            StopBackgroundMusic();
            Sleep(500);  // Short delay to ensure resource cleanup
            
            // Determine what to do next
            if (GameState::Instance().returnToMenu) {
                GameState::Instance().returnToMenu = false;
                startGame = false;  // Exit game loop and return to menu loop
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

// Game Update function
void GameUpdate(std::chrono::steady_clock::time_point& lastTime, float& accumulator, float& totalElapsedTime) {
    // Calculate delta time
    auto currentTime = std::chrono::steady_clock::now();
    float deltaTime = std::chrono::duration<float>(currentTime - lastTime).count();
    lastTime = currentTime;

    // Prevent large time steps
    if (deltaTime > 0.25f) {
        deltaTime = 0.25f;
    }

    // Update accumulator
    accumulator += deltaTime;

    // Advance animation timer
    animationTimer += deltaTime;
    if (animationTimer > 1000.0f) {
        animationTimer = 0.0f;
    }

    // ... existing code ...
}

void GameRender(PlayerSnake& snake, AISnake aiSnakes[], FoodItem foodItems[], const int foodCount) {
    // ... existing code ...
    
    // Update growth animation if active
    UpdateGrowthAnimation(0.016f);
    
    // Continue with existing rendering
    // ... existing code ...
}


