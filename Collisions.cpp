#include "Collisions.h"
#include "Snake.h"
#include "Food.h"
#pragma warning(disable: 4996)	 // Disable security warnings for _tcscpy and _stprintf

bool CollisionManager::CheckCircleCollision(const Vector2& pos1, float radius1, const Vector2& pos2, float radius2) {
    float distance = (pos1 - pos2).GetLength();
    return distance < (radius1 + radius2);
}

bool CollisionManager::CheckSnakeCollision(const Snake& snake1, const Snake& snake2) {
    return snake1.CheckCollisionWith(snake2) || snake2.CheckCollisionWith(snake1);
}

void CollisionManager::CheckCollisions(Snake* snake, AISnake* aiSnakes, int aiSnakeCount, 
                                       FoodItem* foodList, int foodCount) {
    auto& gameState = GameState::Instance();

    if (!gameState.IsCollisionEnabled()) {
        if (gameState.isInvulnerable) {
            // Display invincibility status near snake head
            settextcolor(RGB(255, 255, 0));  // Bright yellow
            settextstyle(18, 0, _T("微软雅黑"));

            Vector2 textPos = snake[0].position - GameState::Instance().camera.position;
            textPos.y -= 40;  // Display above snake head

            // Show remaining invincibility time
            TCHAR invulnerableText[50];
            float remainingInvulnerableTime = GameConfig::COLLISION_GRACE_PERIOD - gameState.gameStartTime;
            if (remainingInvulnerableTime < 0) remainingInvulnerableTime = 0;
            _stprintf(invulnerableText, _T("Invincible: %.1fs"), remainingInvulnerableTime);

            // Calculate text width and center the display
            int textWidth = textwidth(invulnerableText);
            outtextxy(textPos.x - textWidth / 2, textPos.y, invulnerableText);
        }
        return;
    }

    // 1. Check player collision with AI snakes
    for (int i = 0; i < aiSnakeCount; ++i) {
        AISnake& aiSnake = aiSnakes[i];
        
        // Skip AI snakes that have been removed
        if (aiSnake.radius <= 0) continue;
        
        // Check collision between player head and AI snake
        bool playerHeadHitAI = CheckCircleCollision(
            snake[0].position, snake[0].radius,
            aiSnake.position, aiSnake.radius);
            
        if (playerHeadHitAI) {
            if (!gameState.isInvulnerable) {
                // When player head collides with AI snake, if player has no invincibility, player dies
                gameState.isCollisionFlashing = true;
                gameState.collisionFlashTimer = GameConfig::COLLISION_FLASH_DURATION;
                gameState.isGameRunning = false;
                gameState.showDeathMessage = true;
                gameState.finalScore = gameState.foodEatenCount;
            }
        }
        
        // Check if AI snake head collided with player body
        bool aiHitPlayerBody = false;
        
        // Check collision between AI snake and player body (excluding head, only check body segments)
        for (size_t j = 0; j < snake[0].segments.size(); ++j) {
            if (CheckCircleCollision(
                aiSnake.position, aiSnake.radius,
                snake[0].segments[j].position, snake[0].segments[j].radius)) {
                aiHitPlayerBody = true;
                break;
            }
        }
        
        // If AI snake head hits player body, convert AI snake to food
        if (aiHitPlayerBody) {
            // Find an available food slot
            for (int j = 0; j < foodCount; ++j) {
                if (foodList[j].collisionRadius <= 0) {
                    // Set AI snake position as food position
                    foodList[j].position = aiSnake.position;
                    foodList[j].colorValue = aiSnake.color;
                    foodList[j].collisionRadius = aiSnake.radius * 0.8f; // Food slightly smaller
                    
                    // Remove this AI snake
                    aiSnake.radius = 0; // Set radius to 0 to indicate removal
                    break;
                }
            }
        }
    }

    // 2. Check collisions between AI snakes
    for (int i = 0; i < aiSnakeCount; i++) {
        // Skip AI snakes that have been removed
        if (aiSnakes[i].radius <= 0) continue;
        
        for (int j = i + 1; j < aiSnakeCount; j++) {
            // Skip AI snakes that have been removed
            if (aiSnakes[j].radius <= 0) continue;
            
            // Check head-to-head collision
            if (CheckCircleCollision(
                aiSnakes[i].position, aiSnakes[i].radius,
                aiSnakes[j].position, aiSnakes[j].radius)) {

                // Collision rebound - snakes move in opposite directions
                Vector2 collisionDir = (aiSnakes[i].position - aiSnakes[j].position).GetNormalize();
                aiSnakes[i].direction = collisionDir;
                aiSnakes[j].direction = -collisionDir;
            }
        }
    }

    // 3. Check player collision with food
    for (int i = 0; i < foodCount; i++) {
        if (foodList[i].collisionRadius > 0 && // Only check valid food
            CheckCircleCollision(
                snake[0].position, snake[0].radius,
                foodList[i].position, foodList[i].collisionRadius)) {

            // Mark food as eaten
            foodList[i].collisionRadius = 0;

            // Handle food collection
            gameState.AddFoodEaten();

            // Grow snake body
            float growthAmount = (gameState.foodEatenCount == 0) ?
                GameConfig::SNAKE_GROWTH_LARGE : GameConfig::SNAKE_GROWTH_SMALL;
            snake[0].radius = min(snake[0].radius + growthAmount, GameConfig::MAX_SNAKE_SIZE);
        }
    }

    // 4. Check AI snake collision with food
    for (int i = 0; i < aiSnakeCount; ++i) {
        // Skip AI snakes that have been removed
        if (aiSnakes[i].radius <= 0) continue;
        
        AISnake& aiSnake = aiSnakes[i];
        for (int j = 0; j < foodCount; j++) {
            if (foodList[j].collisionRadius > 0 && // Only check valid food
                CheckCircleCollision(
                    aiSnake.position, aiSnake.radius,
                    foodList[j].position, foodList[j].collisionRadius)) {

                // Mark food as eaten
                foodList[j].collisionRadius = 0;

                // AI snake also grows after eating food
                aiSnake.radius = min(aiSnake.radius + GameConfig::SNAKE_GROWTH_SMALL, GameConfig::MAX_SNAKE_SIZE);
            }
        }
    }
}

