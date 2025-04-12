#include "GameInitializer.h"
#include "GameConfig.h"
#include "Collisions.h"
#include <algorithm>

// Global variables (imported from Main.cpp)
extern FoodItem foodList[GameConfig::MAX_FOOD_COUNT];
extern std::vector<AISnake> aiSnakeList;
extern Snake snake[1];
extern Vector2 playerPosition;
extern Vector2 playerDirection;

void InitializePlayerSnake() {
    Vector2 startPos = GameConfig::PLAYER_DEFAULT_POS;
    Vector2 startDir(0, 1);  // Starting direction (downward)
                           
    // Initialize snake head
    snake[0].position = startPos;
    snake[0].direction = startDir;
    snake[0].radius = GameConfig::INITIAL_SNAKE_SIZE;
    snake[0].color = HSLtoRGB(255, 255, 255);  // White
    snake[0].posRecords = std::queue<Vector2>();
    
    // Adjust snake body segment size
    snake[0].segments.resize(4);  // 4 body segments + 1 head = 5 parts
    
    // Initialize snake body segments
    for (size_t i = 0; i < snake[0].segments.size(); i++) {
        snake[0].segments[i].position = startPos - startDir * ((i+1) * GameConfig::SNAKE_SEGMENT_SPACING);
        snake[0].segments[i].direction = startDir;
        snake[0].segments[i].radius = GameConfig::INITIAL_SNAKE_SIZE;
        snake[0].segments[i].color = HSLtoRGB(255, 255, 255);  // White
        snake[0].segments[i].posRecords = std::queue<Vector2>();
    }
}

void InitializeAISnakes() {
    auto& gameState = GameState::Instance();
    aiSnakeList.resize(gameState.aiSnakeCount);
    
    for (auto& aiSnake : aiSnakeList) {
        aiSnake.Init();
        
        // Adjust AI behavior based on difficulty
        aiSnake.aggressionFactor = gameState.aiAggression;
        aiSnake.speedMultiplier = 1.0f; 
    }
    
    for (int i = 0; i < gameState.aiSnakeCount; ++i) {
        // Distribute snakes in a circular pattern around center
        float angle = (i * 360.0f / gameState.aiSnakeCount) * 3.14159f / 180.0f;
        float distance = rand() % static_cast<int>(GameConfig::AI_SPAWN_RADIUS);
        
        float x = GameConfig::WINDOW_WIDTH/2 + cos(angle) * distance;
        float y = GameConfig::WINDOW_HEIGHT/2 + sin(angle) * distance;
        
        // Ensure position is within safe area
        x = max(GameConfig::PLAY_AREA_LEFT + 100.0f, min(GameConfig::PLAY_AREA_RIGHT - 100.0f, x));
        y = max(GameConfig::PLAY_AREA_TOP + 100.0f, min(GameConfig::PLAY_AREA_BOTTOM - 100.0f, y));
        
        // Random starting direction
        float dirAngle = (rand() % 360) * 3.14159f / 180.0f;
        Vector2 direction(cos(dirAngle), sin(dirAngle));
        
        // Initialize AI snake position and direction
        aiSnakeList[i].position = Vector2(x, y);
        aiSnakeList[i].direction = direction;
        aiSnakeList[i].radius = GameConfig::INITIAL_SNAKE_SIZE * 0.8f;
        aiSnakeList[i].color = HSLtoRGB(rand() % 360, 200, 200);
        
        // Initialize snake body segments, ensuring equal spacing
        for (int j = 0; j < 5; j++) {
            // Set fixed spacing
            aiSnakeList[i].segments[j].position = aiSnakeList[i].position - 
                direction * (j + 1) * GameConfig::SNAKE_SEGMENT_SPACING;
            aiSnakeList[i].segments[j].direction = direction;
            aiSnakeList[i].segments[j].radius = aiSnakeList[i].radius;
            aiSnakeList[i].segments[j].color = aiSnakeList[i].color;
        }
        
        // Initialize position history
        aiSnakeList[i].recordedPositions.clear();
        for (int j = 0; j < 20; j++) {
            // Fill initial history from tail to head
            aiSnakeList[i].recordedPositions.push_back(
                aiSnakeList[i].position - direction * j * (GameConfig::SNAKE_SEGMENT_SPACING / 4.0f));
        }
    }
}

void InitGlobal() {
    playerPosition = GameConfig::PLAYER_DEFAULT_POS;
    
    // Don't use resize, initialize snake head and preset some body segments
    snake[0].position = GameConfig::PLAYER_DEFAULT_POS;
    snake[0].direction = Vector2(0, 1);
    snake[0].radius = GameConfig::INITIAL_SNAKE_SIZE;
    snake[0].color = HSLtoRGB(255, 255, 255);
    
    // Preset 4 body segments
    snake[0].segments.resize(4);
    for (size_t i = 0; i < snake[0].segments.size(); i++) {
        snake[0].segments[i].position = GameConfig::PLAYER_DEFAULT_POS - Vector2(0, 1) * ((i+1) * GameConfig::SNAKE_SEGMENT_SPACING);
        snake[0].segments[i].direction = Vector2(0, 1);
        snake[0].segments[i].radius = GameConfig::INITIAL_SNAKE_SIZE;
        snake[0].segments[i].color = HSLtoRGB(255, 255, 255);
    }
}

void InitSnake(int i, const Vector2& pos, const Vector2& currentDir) {
    if (i == 0) {
        // Initialize snake head
        snake[0].position = pos;
        snake[0].color = HSLtoRGB(255, 255, 255);
        snake[0].radius = GameConfig::INITIAL_SNAKE_SIZE;
        snake[0].direction = currentDir;
        snake[0].currentTime = 0;
        snake[0].posRecords = std::queue<Vector2>();
    } else {
        // Initialize snake body segment
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
    GameState::Instance().currentPlayerSpeed = newSpeed;
}

void UpdatePlayerSnake(float deltaTime) {
    // Update head               
    snake[0].direction = GameState::Instance().targetDirection;
    snake[0].position = snake[0].position + snake[0].GetVelocity() * deltaTime;
    snake[0].Update(deltaTime);

    // Update body segments
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
        
        float snakeSpeed = GameState::Instance().currentPlayerSpeed * 0.75f; // Set to 75% of player snake speed
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

void UpdateCamera() {
    auto& gameState = GameState::Instance();
    Vector2 targetPos = snake[0].position - Vector2(GameConfig::WINDOW_WIDTH / 2, GameConfig::WINDOW_HEIGHT / 2);
    
    // Smooth camera movement
    gameState.camera.position = gameState.camera.position + 
        (targetPos - gameState.camera.position) * GameConfig::SMOOTH_CAMERA_FACTOR;
}

void CheckCollisions() {
    auto& gameState = GameState::Instance();
    
    // Simplified code to check if player is in invincible state
    if (!gameState.IsCollisionEnabled()) {
        if (gameState.isInvulnerable) {
            // Display invincibility status text near snake head
            settextcolor(RGB(255, 255, 0));  // Bright yellow
            settextstyle(18, 0, _T("微软雅黑"));
            
            Vector2 textPos = snake[0].position - gameState.camera.position;
            textPos.y -= 40;  // Display above snake head
            
            // Show remaining invincibility time
            TCHAR invulnerableText[50];
            float remainingInvulnerableTime = GameConfig::COLLISION_GRACE_PERIOD - gameState.gameStartTime;
            if (remainingInvulnerableTime < 0) remainingInvulnerableTime = 0;
            _stprintf(invulnerableText, _T("Invincible: %.1fs"), remainingInvulnerableTime);
            
            // Calculate text width and center the display
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

int GetHistoryIndexAtDistance(const std::deque<Vector2>& positions, float targetDistance) {
    if (positions.size() < 2) return 0;
    
    float currentDistance = 0.0f;
    
    // Search from the most recent position backwards
    for (int i = positions.size() - 2; i >= 0; i--) {
        float segmentLength = (positions[i+1] - positions[i]).GetLength();
        currentDistance += segmentLength;
        
        if (currentDistance >= targetDistance) {
            // Found position at or beyond target distance
            return i;
        }
    }
    
    // If we can't find a point far enough, return the earliest history point
    return 0;
} 