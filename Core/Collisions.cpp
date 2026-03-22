#include "Collisions.h"
#include "..\Gameplay\Snake.h"
#include "..\Gameplay\Food.h"
#include "..\Gameplay\GameConfig.h"
#include "../Utils/DrawHelpers.h"
#include <cmath>
#include <vector>
#pragma warning(disable: 4996)

struct GrowthAnimation {
    bool active = false;
    float timer = 0.0f;
    float duration = 0.3f;
    Vector2 position;
    int color;
    float baseRadius;
};

static GrowthAnimation playerGrowthAnim;

namespace {
bool CheckCircleCollision(const Vector2& pos1, float radius1, const Vector2& pos2, float radius2) {
    return CollisionManager::CheckCircleCollision(pos1, radius1, pos2, radius2);
}
}

void DrawSnakeGrowthEffect(float animProgress, const Vector2& position, int color, float radius) {
    Vector2 screenPos = position - GameState::Instance().camera.position;

    float pulseScale = 1.0f + (1.0f - animProgress) * 0.5f;

    setfillcolor(color);
    setlinecolor(color);
    fillcircle(screenPos.x, screenPos.y, radius * pulseScale);

    setlinestyle(PS_SOLID, 2);
    for (int i = 0; i < 3; i++) {
        float rippleRadius = radius * (1.0f + (i+1) * 0.3f * (1.0f - animProgress));
        setlinecolor(RGB(GetRValue(color), GetGValue(color), GetBValue(color)));
        circle(screenPos.x, screenPos.y, rippleRadius);
    }

    int numSparkles = 8;
    for (int i = 0; i < numSparkles; i++) {
        float angle = (float)i / numSparkles * 2 * 3.14159f;
        float sparkDist = radius * (1.5f + animProgress);
        float sparkX = screenPos.x + cos(angle) * sparkDist;
        float sparkY = screenPos.y + sin(angle) * sparkDist;

        float sparkSize = radius * 0.2f * (1.0f - animProgress);

        setfillcolor(RGB(255, 255, 255));
        fillcircle(sparkX, sparkY, sparkSize);
    }
}

void UpdateGrowthAnimation(float deltaTime) {
    if (playerGrowthAnim.active) {
        playerGrowthAnim.timer += deltaTime;

        if (playerGrowthAnim.timer < playerGrowthAnim.duration) {
            float progress = playerGrowthAnim.timer / playerGrowthAnim.duration;
            DrawSnakeGrowthEffect(
                progress,
                playerGrowthAnim.position,
                playerGrowthAnim.color,
                playerGrowthAnim.baseRadius
            );
        } else {
            playerGrowthAnim.active = false;
        }
    }
}

bool CollisionManager::CheckCircleCollision(const Vector2& pos1, float radius1, const Vector2& pos2, float radius2) {
    const Vector2 delta = pos1 - pos2;
    const float distanceSq = delta.GetSquaredLength();
    const float radiusSum = radius1 + radius2;
    return distanceSq < (radiusSum * radiusSum);
}

bool CollisionManager::CheckSnakeCollision(const Snake& snake1, const Snake& snake2) {
    return snake1.CheckCollisionWith(snake2) || snake2.CheckCollisionWith(snake1);
}

bool CheckWallCollision(const Vector2& pos, float radius) {
    float gridSize = GameConfig::GRID_CELL_SIZE;
    float halfGrid = gridSize / 2.0f;

    if (pos.x - radius < halfGrid || pos.x + radius > GameConfig::WINDOW_WIDTH - halfGrid ||
        pos.y - radius < halfGrid || pos.y + radius > GameConfig::WINDOW_HEIGHT - halfGrid) {
        return true;
    }
    return false;
}

void CollisionManager::CheckCollisions(Snake* snake, AISnake* aiSnakes, int aiSnakeCount,
                                       FoodItem* foodList, int foodCount) {
    auto& gameState = GameState::Instance();
    PlayerSnake& player = static_cast<PlayerSnake&>(snake[0]);

    if (player.isDead) return;

    if (!gameState.IsCollisionEnabled()) {
        return;
    }

    bool playerAteFood = false;

    if (CheckWallCollision(player.position, player.radius)) {
        player.isDead = true;
        gameState.TriggerGameOver();
        return;
    }

    for (size_t i = 1; i < player.segments.size(); i++) {
        const auto& seg = player.segments[i];
        if (CheckCircleCollision(player.position, player.radius * 0.8f, seg.position, seg.radius * 0.5f)) {
            player.isDead = true;
            gameState.TriggerGameOver();
            return;
        }
    }

    for (int i = 0; i < aiSnakeCount; ++i) {
        AISnake& aiSnake = aiSnakes[i];

        if (aiSnake.radius <= 0 || aiSnake.isDead) continue;

        if (CheckCircleCollision(player.position, player.radius, aiSnake.position, aiSnake.radius)) {
            player.isDead = true;
            gameState.TriggerGameOver();
            return;
        }

        for (const auto& seg : aiSnake.segments) {
            if (seg.radius <= 0) continue;
            if (CheckCircleCollision(player.position, player.radius, seg.position, seg.radius)) {
                player.isDead = true;
                gameState.TriggerGameOver();
                return;
            }
        }

        for (const auto& playerSeg : player.segments) {
            if (CheckCircleCollision(aiSnake.position, aiSnake.radius, playerSeg.position, playerSeg.radius)) {
                aiSnake.StartDying(1);

                for (int k = 0; k < foodCount; ++k) {
                    if (foodList[k].collisionRadius <= 0) {
                        foodList[k].position = aiSnake.position;
                        foodList[k].colorValue = aiSnake.color;
                        foodList[k].collisionRadius = GameConfig::GRID_CELL_SIZE / 2.0f;
                        break;
                    }
                }

                for (size_t segIdx = 0; segIdx < aiSnake.segments.size(); ++segIdx) {
                    for (int k = 0; k < foodCount; ++k) {
                        if (foodList[k].collisionRadius <= 0) {
                            foodList[k].position = aiSnake.segments[segIdx].position;
                            foodList[k].colorValue = aiSnake.color;
                            foodList[k].collisionRadius = GameConfig::GRID_CELL_SIZE / 2.0f;
                            break;
                        }
                    }
                }
                break;
            }
        }

        for (const auto& aiSeg : aiSnake.segments) {
            if (aiSeg.radius <= 0) continue;
            for (const auto& playerSeg : player.segments) {
                if (CheckCircleCollision(aiSeg.position, aiSeg.radius, playerSeg.position, playerSeg.radius)) {
                    aiSnake.StartDying(1);

                    for (int k = 0; k < foodCount; ++k) {
                        if (foodList[k].collisionRadius <= 0) {
                            foodList[k].position = aiSnake.position;
                            foodList[k].colorValue = aiSnake.color;
                            foodList[k].collisionRadius = GameConfig::GRID_CELL_SIZE / 2.0f;
                            break;
                        }
                    }

                    for (size_t segIdx = 0; segIdx < aiSnake.segments.size(); ++segIdx) {
                        for (int k = 0; k < foodCount; ++k) {
                            if (foodList[k].collisionRadius <= 0) {
                                foodList[k].position = aiSnake.segments[segIdx].position;
                                foodList[k].colorValue = aiSnake.color;
                                foodList[k].collisionRadius = GameConfig::GRID_CELL_SIZE / 2.0f;
                                break;
                            }
                        }
                    }
                    break;
                }
            }
            if (aiSnake.isDying) break;
        }
    }

    for (int i = 0; i < aiSnakeCount; ++i) {
        AISnake& aiSnake = aiSnakes[i];
        if (aiSnake.radius <= 0 || aiSnake.isDead || aiSnake.isDying) continue;

        if (CheckWallCollision(aiSnake.position, aiSnake.radius)) {
            aiSnake.StartDying(1);

            for (int k = 0; k < foodCount; ++k) {
                if (foodList[k].collisionRadius <= 0) {
                    foodList[k].position = aiSnake.position;
                    foodList[k].colorValue = aiSnake.color;
                    foodList[k].collisionRadius = GameConfig::GRID_CELL_SIZE / 2.0f;
                    break;
                }
            }

            for (size_t segIdx = 0; segIdx < aiSnake.segments.size(); ++segIdx) {
                for (int k = 0; k < foodCount; ++k) {
                    if (foodList[k].collisionRadius <= 0) {
                        foodList[k].position = aiSnake.segments[segIdx].position;
                        foodList[k].colorValue = aiSnake.color;
                        foodList[k].collisionRadius = GameConfig::GRID_CELL_SIZE / 2.0f;
                        break;
                    }
                }
            }
        }

        for (size_t j = 1; j < aiSnake.segments.size(); j++) {
            const auto& seg = aiSnake.segments[j];
            if (seg.radius <= 0) continue;
            if (CheckCircleCollision(aiSnake.position, aiSnake.radius * 0.8f, seg.position, seg.radius * 0.5f)) {
                aiSnake.StartDying(1);

                for (int k = 0; k < foodCount; ++k) {
                    if (foodList[k].collisionRadius <= 0) {
                        foodList[k].position = aiSnake.position;
                        foodList[k].colorValue = aiSnake.color;
                        foodList[k].collisionRadius = GameConfig::GRID_CELL_SIZE / 2.0f;
                        break;
                    }
                }

                for (size_t segIdx = 0; segIdx < aiSnake.segments.size(); ++segIdx) {
                    for (int k = 0; k < foodCount; ++k) {
                        if (foodList[k].collisionRadius <= 0) {
                            foodList[k].position = aiSnake.segments[segIdx].position;
                            foodList[k].colorValue = aiSnake.color;
                            foodList[k].collisionRadius = GameConfig::GRID_CELL_SIZE / 2.0f;
                            break;
                        }
                    }
                }
                break;
            }
        }
    }

    const float searchRadius = player.radius + 10.0f;
    for (int i = 0; i < foodCount; i++) {
        if (foodList[i].collisionRadius <= 0) continue;

        if (CheckCircleCollision(player.position, player.radius, foodList[i].position, foodList[i].collisionRadius)) {
            foodList[i].collisionRadius = 0;

            gameState.AddFoodEaten();

            player.GrowSnake();

            playerAteFood = true;

            if (GameConfig::SOUND_ON) {
                PlaySound(_T(".\\Resource\\SoundEffects\\Button-Click.wav"), NULL, SND_FILENAME | SND_ASYNC);
            }
        }
    }

    for (int i = 0; i < aiSnakeCount; ++i) {
        AISnake& aiSnake = aiSnakes[i];
        if (aiSnake.radius <= 0 || aiSnake.isDead || aiSnake.isDying) continue;

        for (int j = 0; j < foodCount; j++) {
            if (foodList[j].collisionRadius <= 0) continue;

            if (CheckCircleCollision(aiSnake.position, aiSnake.radius, foodList[j].position, foodList[j].collisionRadius)) {
                foodList[j].collisionRadius = 0;
            }
        }
    }
}