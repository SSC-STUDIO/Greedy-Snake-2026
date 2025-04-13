#include "Collisions.h"
#include "Snake.h"
#include "Food.h"
#include "..\Core\GameConfig.h" // Include GameConfig to access ANIMATIONS_ON
#include <cmath> // For sin/cos in particle effects
#pragma warning(disable: 4996)	 // Disable security warnings for _tcscpy and _stprintf

extern float animationTimer;

// Track snake growth animation
struct GrowthAnimation {
    bool active = false;
    float timer = 0.0f;
    float duration = 0.3f;
    Vector2 position;
    int color;
    float baseRadius;
};

// Global growth animation tracker
static GrowthAnimation playerGrowthAnim;

// Add helper function for AI snake eating animation effects
void DrawEatAISnakeEffect(const Vector2& position, int color, float radius) {
    // Play explosion sound
    PlaySound(_T(".\\Resource\\SoundEffects\\Explosion.wav"), NULL, SND_FILENAME | SND_ASYNC);
    
    // Get screen position
    Vector2 screenPos = position - GameState::Instance().camera.position;
    
    // Draw expanding circles
    for (int i = 1; i <= 3; i++) {
        float expandRatio = 0.5f + i * 0.5f;
        setlinecolor(color);
        setlinestyle(PS_SOLID, 2);
        circle(screenPos.x, screenPos.y, radius * expandRatio);
    }
    
    // Draw particle explosion
    int numParticles = 16;
    for (int i = 0; i < numParticles; i++) {
        float angle = (float)i / numParticles * 2 * 3.14159f;
        float particleRadius = radius * 0.3f;
        float distance = radius * 1.5f;
        
        // Calculate particle position
        float x = screenPos.x + cos(angle) * distance;
        float y = screenPos.y + sin(angle) * distance;
        
        // Draw particle
        setfillcolor(color);
        solidcircle(x, y, particleRadius);
    }
    
    // Draw glow effect
    setfillcolor(RGB(GetRValue(color)/3, GetGValue(color)/3, GetBValue(color)/3));
    setfillstyle(BS_SOLID, NULL, NULL);
    float glowRadius = radius * 3.0f;
    fillcircle(screenPos.x, screenPos.y, glowRadius);
    
    // Draw inner bright flash
    setfillcolor(RGB(255, 255, 255));
    solidcircle(screenPos.x, screenPos.y, radius * 0.8f);
}

// Add helper function for AI snake hitting player animation effects
void DrawAISnakeHitPlayerEffect(const Vector2& position, int color, float radius) {
    // Play impact sound
    PlaySound(_T(".\\Resource\\SoundEffects\\Impact.wav"), NULL, SND_FILENAME | SND_ASYNC);
    
    // Get screen position
    Vector2 screenPos = position - GameState::Instance().camera.position;
    
    // Draw warning/danger effect with red color
    setlinecolor(RGB(255, 0, 0));
    setlinestyle(PS_SOLID, 3);
    
    // Draw concentric circles that appear like a danger zone
    for (int i = 1; i <= 4; i++) {
        float expandRatio = 0.5f + i * 0.4f;
        circle(screenPos.x, screenPos.y, radius * expandRatio);
    }
    
    // Draw "X" shape to indicate collision/impact
    int xSize = radius * 2.0f;
    setlinestyle(PS_SOLID, 4);
    line(screenPos.x - xSize, screenPos.y - xSize, screenPos.x + xSize, screenPos.y + xSize);
    line(screenPos.x + xSize, screenPos.y - xSize, screenPos.x - xSize, screenPos.y + xSize);
    
    // Draw red impact flash
    setfillcolor(RGB(255, 50, 50));
    setfillstyle(BS_SOLID, NULL, NULL);
    float flashRadius = radius * 2.0f;
    fillcircle(screenPos.x, screenPos.y, flashRadius);
    
    // Draw white center to indicate impact point
    setfillcolor(RGB(255, 255, 255));
    fillcircle(screenPos.x, screenPos.y, radius * 0.8f);
    
    // Draw shockwave particles
    int numParticles = 12;
    for (int i = 0; i < numParticles; i++) {
        float angle = (float)i / numParticles * 2 * 3.14159f;
        float particleRadius = radius * 0.25f;
        float distance = radius * 2.0f;
        
        // Calculate particle position
        float x = screenPos.x + cos(angle) * distance;
        float y = screenPos.y + sin(angle) * distance;
        
        // Draw particle
        setfillcolor(RGB(255, 0, 0));
        solidcircle(x, y, particleRadius);
    }
}

bool CollisionManager::CheckCircleCollision(const Vector2& pos1, float radius1, const Vector2& pos2, float radius2) {
    float distance = (pos1 - pos2).GetLength();
    return distance < (radius1 + radius2);
}

bool CollisionManager::CheckSnakeCollision(const Snake& snake1, const Snake& snake2) {
    return snake1.CheckCollisionWith(snake2) || snake2.CheckCollisionWith(snake1);
}

// Add function to draw growth effect
void DrawSnakeGrowthEffect(float animProgress, const Vector2& position, int color, float radius) {
    // Get screen position
    Vector2 screenPos = position - GameState::Instance().camera.position;
    
    // Calculate pulse effect (starts large, then shrinks back to normal)
    float pulseScale = 1.0f + (1.0f - animProgress) * 0.5f;
    
    // Draw pulsing circle
    setfillcolor(color);
    setlinecolor(color);
    fillcircle(screenPos.x, screenPos.y, radius * pulseScale);
    
    // Draw ripple effect
    setlinestyle(PS_SOLID, 2);
    for (int i = 0; i < 3; i++) {
        float rippleRadius = radius * (1.0f + (i+1) * 0.3f * (1.0f - animProgress));
        setlinecolor(RGB(GetRValue(color), GetGValue(color), GetBValue(color)));
        circle(screenPos.x, screenPos.y, rippleRadius);
    }
    
    // Draw sparkle effects
    int numSparkles = 8;
    for (int i = 0; i < numSparkles; i++) {
        float angle = (float)i / numSparkles * 2 * 3.14159f;
        float sparkDist = radius * (1.5f + animProgress);
        float sparkX = screenPos.x + cos(angle) * sparkDist;
        float sparkY = screenPos.y + sin(angle) * sparkDist;
        
        // Size of sparkle decreases over time
        float sparkSize = radius * 0.2f * (1.0f - animProgress);
        
        setfillcolor(RGB(255, 255, 255));
        fillcircle(sparkX, sparkY, sparkSize);
    }
}

// Update the growth animation
void UpdateGrowthAnimation(float deltaTime) {
    if (playerGrowthAnim.active) {
        playerGrowthAnim.timer += deltaTime;
        
        // If animation is still running, draw the effect
        if (playerGrowthAnim.timer < playerGrowthAnim.duration) {
            float progress = playerGrowthAnim.timer / playerGrowthAnim.duration;
            DrawSnakeGrowthEffect(
                progress,
                playerGrowthAnim.position,
                playerGrowthAnim.color,
                playerGrowthAnim.baseRadius
            );
        } else {
            // End animation when duration is over
            playerGrowthAnim.active = false;
        }
    }
}

void CollisionManager::CheckCollisions(Snake* snake, AISnake* aiSnakes, int aiSnakeCount, 
                                       FoodItem* foodList, int foodCount) {
    auto& gameState = GameState::Instance();
    
    if (!gameState.IsCollisionEnabled()) {
        if (gameState.isInvulnerable) {
            // Display invincibility status near snake head - but only if animations are enabled
            if (GameConfig::ANIMATIONS_ON) {
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
        }
        return;
    }

    // Added flag to track if we need to spawn a new AI snake
    bool needNewAiSnake = false;

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
                // Create animation effect when player hits AI snake and dies
                if (GameConfig::ANIMATIONS_ON) {
                    DrawAISnakeHitPlayerEffect(snake[0].position, snake[0].color, snake[0].radius);
                }
                
                // When player head collides with AI snake, if player has no invincibility, player dies
                gameState.isCollisionFlashing = true;
                gameState.collisionFlashTimer = GameConfig::COLLISION_FLASH_DURATION;
                gameState.isGameRunning = false;
                gameState.showDeathMessage = true;
                gameState.finalScore = gameState.foodEatenCount;
            }
        }
        
        // Check if AI snake (both head and body) collided with player (head or body)
        bool aiCollidedWithPlayer = false;
        Vector2 collisionPosition; // Store collision position for animation
        
        // First check if AI head hit player head
        if (CheckCircleCollision(
            aiSnake.position, aiSnake.radius,
            snake[0].position, snake[0].radius)) {
            aiCollidedWithPlayer = true;
            collisionPosition = (aiSnake.position + snake[0].position) * 0.5f; // Calculate midpoint of collision
        }
        
        // Check if AI head hit player body segments
        if (!aiCollidedWithPlayer) {
            for (size_t j = 0; j < snake[0].segments.size(); ++j) {
                if (CheckCircleCollision(
                    aiSnake.position, aiSnake.radius,
                    snake[0].segments[j].position, snake[0].segments[j].radius)) {
                    aiCollidedWithPlayer = true;
                    collisionPosition = (aiSnake.position + snake[0].segments[j].position) * 0.5f; // Calculate midpoint of collision
                    break;
                }
            }
        }
        
        // Check if AI body segments hit player head
        if (!aiCollidedWithPlayer) {
            for (size_t j = 0; j < aiSnake.segments.size(); ++j) {
                if (CheckCircleCollision(
                    aiSnake.segments[j].position, aiSnake.segments[j].radius,
                    snake[0].position, snake[0].radius)) {
                    aiCollidedWithPlayer = true;
                    collisionPosition = (aiSnake.segments[j].position + snake[0].position) * 0.5f; // Calculate midpoint of collision
                    break;
                }
            }
        }
        
        // Check if AI body segments hit player body segments
        if (!aiCollidedWithPlayer) {
            for (size_t j = 0; j < aiSnake.segments.size(); ++j) {
                for (size_t k = 0; k < snake[0].segments.size(); ++k) {
                    if (CheckCircleCollision(
                        aiSnake.segments[j].position, aiSnake.segments[j].radius,
                        snake[0].segments[k].position, snake[0].segments[k].radius)) {
                        aiCollidedWithPlayer = true;
                        collisionPosition = (aiSnake.segments[j].position + snake[0].segments[k].position) * 0.5f; // Calculate midpoint of collision
                        break;
                    }
                }
                if (aiCollidedWithPlayer) break;
            }
        }
        
        // If AI snake collided with any part of player snake, convert AI to food
        if (aiCollidedWithPlayer) {
            // Show animation effect for AI-player collision
            if (GameConfig::ANIMATIONS_ON) {
                DrawAISnakeHitPlayerEffect(collisionPosition, aiSnake.color, aiSnake.radius);
            }
            
            // Save the AI snake's data for animation effects
            Vector2 aiHeadPos = aiSnake.position;
            int aiColor = aiSnake.color;
            float aiRadius = aiSnake.radius;
            std::vector<Vector2> segmentPositions;
            
            // Store all segment positions for animation
            segmentPositions.push_back(aiHeadPos);
            for (const auto& segment : aiSnake.segments) {
                segmentPositions.push_back(segment.position);
            }
            
            // Find available food slots to convert entire AI snake to food
            // First convert head
            for (int k = 0; k < foodCount; ++k) {
                if (foodList[k].collisionRadius <= 0) {
                    // Convert AI head to food
                    foodList[k].position = aiSnake.position;
                    foodList[k].colorValue = aiSnake.color;
                    foodList[k].collisionRadius = aiSnake.radius * 0.8f;
                    
                    // Increase player score
                    gameState.AddFoodEaten();
                    break;
                }
            }
            
            // Then convert each segment to food
            for (size_t segIndex = 0; segIndex < aiSnake.segments.size(); ++segIndex) {
                for (int k = 0; k < foodCount; ++k) {
                    if (foodList[k].collisionRadius <= 0) {
                        // Convert AI segment to food
                        foodList[k].position = aiSnake.segments[segIndex].position;
                        foodList[k].colorValue = aiSnake.color;
                        foodList[k].collisionRadius = aiSnake.segments[segIndex].radius * 0.8f;
                        break;
                    }
                }
            }
            
            // Remove this AI snake
            aiSnake.radius = 0;
            
            // Set flag to spawn a new AI snake
            needNewAiSnake = true;
            
            // Display enhanced animation effects - only if animations are enabled
            if (GameConfig::ANIMATIONS_ON) {
                // Create explosion effects for the entire AI snake
                for (const Vector2& pos : segmentPositions) {
                    DrawEatAISnakeEffect(pos, aiColor, aiRadius);
                }
                
                // Display score text
                Vector2 textPos = snake[0].position - GameState::Instance().camera.position;
                settextcolor(RGB(255, 215, 0)); 
                settextstyle(36, 0, _T("Arial"));
                TCHAR scoreText[50];
                _stprintf(scoreText, _T("+%d"), 5); 
                int textWidth = textwidth(scoreText);
                outtextxy(textPos.x - textWidth / 2, textPos.y - 60, scoreText);
            }
            
            // Grow player snake
            snake[0].radius = min(snake[0].radius + GameConfig::SNAKE_GROWTH_SMALL, GameConfig::MAX_SNAKE_SIZE);
            
            // Add a new segment to the player snake
            size_t numSegments = snake[0].segments.size();
            if (numSegments > 0) {
                Snake newSegment;
                newSegment.position = snake[0].segments[numSegments - 1].position;
                newSegment.direction = snake[0].segments[numSegments - 1].direction;
                newSegment.radius = snake[0].segments[numSegments - 1].radius;
                newSegment.color = snake[0].segments[numSegments - 1].color;
                newSegment.posRecords = std::queue<Vector2>();
                newSegment.currentTime = 0;
                
                // Add the new segment to the snake
                snake[0].segments.push_back(newSegment);
            }
        }
    }

    // If needed, spawn a new AI snake to replace the one that was removed
    if (needNewAiSnake) {
        // Find an empty slot (where radius = 0)
        for (int i = 0; i < aiSnakeCount; ++i) {
            if (aiSnakes[i].radius <= 0) {
                // Spawn a new snake at a random position far from the player
                float spawnAngle = (rand() % 360) * 3.14159f / 180.0f;
                float spawnDistance = GameConfig::AI_SPAWN_RADIUS * 0.8f + (rand() % 1000);
                
                // Calculate spawn position away from player
                Vector2 spawnPos = snake[0].position + Vector2(cos(spawnAngle), sin(spawnAngle)) * spawnDistance;
                
                // Ensure spawn position is within play area
                spawnPos.x = max(GameConfig::PLAY_AREA_LEFT + 200.0f, min(GameConfig::PLAY_AREA_RIGHT - 200.0f, spawnPos.x));
                spawnPos.y = max(GameConfig::PLAY_AREA_TOP + 200.0f, min(GameConfig::PLAY_AREA_BOTTOM - 200.0f, spawnPos.y));
                
                // Random direction
                float dirAngle = (rand() % 360) * 3.14159f / 180.0f;
                Vector2 direction(cos(dirAngle), sin(dirAngle));
                
                // Initialize new AI snake
                aiSnakes[i].Init();
                aiSnakes[i].position = spawnPos;
                aiSnakes[i].direction = direction;
                aiSnakes[i].radius = GameConfig::INITIAL_SNAKE_SIZE * 0.8f;
                aiSnakes[i].color = HSLtoRGB(rand() % 360, 200, 200);
                aiSnakes[i].aggressionFactor = gameState.aiAggression;
                
                // Initialize snake body segments
                for (int j = 0; j < 5; j++) {
                    if (j < aiSnakes[i].segments.size()) {
                        aiSnakes[i].segments[j].position = spawnPos - direction * (j + 1) * GameConfig::SNAKE_SEGMENT_SPACING;
                        aiSnakes[i].segments[j].direction = direction;
                        aiSnakes[i].segments[j].radius = aiSnakes[i].radius;
                        aiSnakes[i].segments[j].color = aiSnakes[i].color;
                    }
                }
                
                // Only replace one snake at a time to prevent frame drops
                break;
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

                // Calculate collision position (midpoint between the two snake heads)
                Vector2 collisionPos = (aiSnakes[i].position + aiSnakes[j].position) * 0.5f;
                
                // Show collision animation effect
                if (GameConfig::ANIMATIONS_ON) {
                    // Use a blend of the two snake colors for the collision effect
                    int color1 = aiSnakes[i].color;
                    int color2 = aiSnakes[j].color;
                    int blendedColor = RGB(
                        (GetRValue(color1) + GetRValue(color2)) / 2,
                        (GetGValue(color1) + GetGValue(color2)) / 2,
                        (GetBValue(color1) + GetBValue(color2)) / 2
                    );
                    
                    // Draw smaller impact effect at collision point
                    float effectRadius = (aiSnakes[i].radius + aiSnakes[j].radius) / 2;
                    DrawAISnakeHitPlayerEffect(collisionPos, blendedColor, effectRadius);
                }

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

            // Play food eaten animation effect - only if animations are enabled
            if (GameConfig::ANIMATIONS_ON) {
                Vector2 eatEffectPos = foodList[i].position - GameState::Instance().camera.position;
                // Draw a halo effect
                setlinecolor(foodList[i].colorValue);
                circle(eatEffectPos.x, eatEffectPos.y, foodList[i].collisionRadius * 2);
                circle(eatEffectPos.x, eatEffectPos.y, foodList[i].collisionRadius * 2.5);
                
                // Display score animation
                settextcolor(RGB(255, 215, 0)); // Gold
                settextstyle(20, 0, _T("Arial"));
                TCHAR scoreText[50];
                _stprintf(scoreText, _T("+1"));
                outtextxy(eatEffectPos.x - 10, eatEffectPos.y - 25, scoreText);
                
                // Start growth animation
                playerGrowthAnim.active = true;
                playerGrowthAnim.timer = 0.0f;
                playerGrowthAnim.position = snake[0].position;
                playerGrowthAnim.color = snake[0].color;
                playerGrowthAnim.baseRadius = snake[0].radius;
            }

            // Mark food as eaten
            foodList[i].collisionRadius = 0;

            // Handle food collection
            gameState.AddFoodEaten();

            // Grow snake body by increasing radius
            float growthAmount = (gameState.foodEatenCount == 0) ?
                GameConfig::SNAKE_GROWTH_LARGE : GameConfig::SNAKE_GROWTH_SMALL;
            snake[0].radius = min(snake[0].radius + growthAmount, GameConfig::MAX_SNAKE_SIZE);
            
            // Add a new segment to the snake's body
            size_t numSegments = snake[0].segments.size();
            if (numSegments > 0) {
                // Create new segment based on the last existing segment
                Snake newSegment;
                newSegment.position = snake[0].segments[numSegments - 1].position;
                newSegment.direction = snake[0].segments[numSegments - 1].direction;
                newSegment.radius = snake[0].segments[numSegments - 1].radius;
                newSegment.color = snake[0].segments[numSegments - 1].color;
                newSegment.posRecords = std::queue<Vector2>();
                newSegment.currentTime = 0;
                
                // Add the new segment to the snake
                snake[0].segments.push_back(newSegment);
            }
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

void CheckPlayerAISnakeCollision(PlayerSnake& player, AISnake& enemy)
{
    // If AI snake is dying or player is invincible, skip collision detection
    if (enemy.isDying || player.isInvincible) {
        return;
    }

    // Check collision between player head and AI body
    for (size_t i = 0; i < enemy.segments.size(); i++) {
        Vector2 distance = player.position - enemy.segments[i].position;
        if (distance.GetLength() < player.radius + enemy.segments[i].radius) {
            if (!player.isInvincible) {
                // When hitting AI snake body, player loses a life
                player.isInvincible = true;
                player.invincibilityTimer = 0;
                if (player.livesRemaining > 0) {
                    player.livesRemaining--;
                    if (GameConfig::SOUND_ON) {
                        PlaySound(_T(".\\Resource\\SoundEffects\\hit.wav"), NULL, SND_FILENAME | SND_ASYNC);
                    }
                }
            }
            return;
        }
    }
    
    // Check collision between player head and AI head
    Vector2 headDistance = player.position - enemy.position;
    if (headDistance.GetLength() < player.radius + enemy.radius) {
        // If player head collides with AI snake head
        if (!player.isInvincible) {
            // Determine who eats whom based on snake size comparison
            if (player.segments.size() >= enemy.segments.size()) {
                // Player eats AI snake, calculate food value
                int foodValue = static_cast<int>(enemy.segments.size()) * 10;
                // Start AI snake death animation
                enemy.StartDying(foodValue);
                
                // Player earns score after eating AI snake
                player.score += foodValue;
                
                // Play eating sound effect
                if (GameConfig::SOUND_ON) {
                    PlaySound(_T(".\\Resource\\SoundEffects\\Snake-eat.wav"), NULL, SND_FILENAME | SND_ASYNC);
                }
            } else {
                // AI snake eats player, player loses a life
                player.isInvincible = true;
                player.invincibilityTimer = 0;
                if (player.livesRemaining > 0) {
                    player.livesRemaining--;
                    if (GameConfig::SOUND_ON) {
                        PlaySound(_T(".\\Resource\\SoundEffects\\hit.wav"), NULL, SND_FILENAME | SND_ASYNC);
                    }
                }
            }
        }
        return;
    }
    
    // Check collision between player body and AI head
    for (size_t i = 0; i < player.segments.size(); i++) {
        Vector2 distance = enemy.position - player.segments[i].position;
        if (distance.GetLength() < enemy.radius + player.segments[i].radius) {
            // AI snake hits player body, AI snake dies
            int foodValue = static_cast<int>(enemy.segments.size()) * 5;
            enemy.StartDying(foodValue);
            
            // Player earns score
            player.score += foodValue;
            
            // Play sound effect
            if (GameConfig::SOUND_ON) {
                PlaySound(_T(".\\Resource\\SoundEffects\\Snake-eat.wav"), NULL, SND_FILENAME | SND_ASYNC);
            }
            return;
        }
    }
}
