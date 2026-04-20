#include "CollisionSubsystems.h"
#include "../Gameplay/Snake.h"
#include "../Gameplay/Food.h"
#include "../Core/GameState.h"
#include "../Core/Collisions.h"
#include "../Core/SessionConfig.h"
#include "../ModernCore/Random.h"
#include <windows.h>
#include <algorithm>
#include <vector>
#pragma warning(disable: 4996)

using Vector2 = GreedSnake::Vector2;
using GreedSnake::Random;

namespace CollisionSubsystems {
    namespace {
    void ConsumePlayerFood(PlayerSnake& player, FoodItem& foodItem) {
        const int eatenFoodColor = foodItem.colorValue;
        foodItem.collisionRadius = 0;
        GameState::Instance().AddFoodEaten();
        player.GrowSnake();
        TriggerGrowthAnimation(player.position, eatenFoodColor, player.radius);
        if (GameConfig::SOUND_ON) {
            PlaySound(_T(".\\Resource\\SoundEffects\\Button-Click.wav"), NULL, SND_FILENAME | SND_ASYNC);
        }
    }
    }

    bool CheckWallCollision(const Vector2& pos, float radius) {
        return !IsCircleInsidePlayArea(pos, radius);
    }

    bool CheckPlayerWallCollision(PlayerSnake& player) {
        if (GameState::Instance().isInvulnerable) {
            return false;
        }

        // Boundary contact is handled by CheckGameState() so the lava warning timer can run.
        return CheckWallCollision(player.position, player.radius);
    }

    bool CheckPlayerSelfCollision(PlayerSnake& player) {
        // Continuous movement makes self-overlap common during tight turns.
        // Allow the player to pass through their own body; walls and AI remain lethal.
        (void)player;
        return false;
    }

    bool CheckPlayerAICollision(PlayerSnake& player, AISnake* aiSnakes, int aiSnakeCount) {
        // Check invulnerability before allowing player to die
        if (GameState::Instance().isInvulnerable) {
            return false;  // No collision damage during invulnerability
        }

        for (int i = 0; i < aiSnakeCount; ++i) {
            AISnake& aiSnake = aiSnakes[i];
            if (aiSnake.radius <= 0 || aiSnake.isDead) continue;

            // 玩家头与AI蛇头碰撞
            if (CollisionManager::CheckCircleCollision(
                    player.position, player.radius,
                    aiSnake.position, aiSnake.radius)) {
                player.isDead = true;
                GameState::Instance().TriggerGameOver();
                return true;
            }

            // 玩家头与AI蛇身体段碰撞
            for (const auto& seg : aiSnake.segments) {
                if (seg.radius <= 0) continue;
                if (CollisionManager::CheckCircleCollision(
                        player.position, player.radius,
                        seg.position, seg.radius)) {
                    player.isDead = true;
                    GameState::Instance().TriggerGameOver();
                    return true;
                }
            }
        }
        return false;
    }

    void SpawnFoodFromSnake(const AISnake& aiSnake, FoodItem* foodList, int foodCount) {
        // 生成蛇头位置的食物（带随机偏移）
        for (int k = 0; k < foodCount; ++k) {
            if (foodList[k].collisionRadius <= 0) {
                // Add small random offset so foods don't stack perfectly
                float offsetX = GreedSnake::Random::Float(-15.0f, 15.0f);
                float offsetY = GreedSnake::Random::Float(-15.0f, 15.0f);
                foodList[k].position = aiSnake.position + Vector2(offsetX, offsetY);
                foodList[k].colorValue = aiSnake.color;
                foodList[k].collisionRadius = GreedSnake::Random::Float(2.0f, 7.0f); // Same size as normal food
                break;
            }
        }

        // 生成蛇身体段位置的食物（带随机偏移）
        for (size_t segIdx = 0; segIdx < aiSnake.segments.size(); ++segIdx) {
            for (int k = 0; k < foodCount; ++k) {
                if (foodList[k].collisionRadius <= 0) {
                    // Add small random offset so foods don't stack perfectly
                    float offsetX = GreedSnake::Random::Float(-15.0f, 15.0f);
                    float offsetY = GreedSnake::Random::Float(-15.0f, 15.0f);
                    foodList[k].position = aiSnake.segments[segIdx].position + Vector2(offsetX, offsetY);
                    foodList[k].colorValue = aiSnake.color;
                    foodList[k].collisionRadius = GreedSnake::Random::Float(2.0f, 7.0f); // Same size as normal food
                    break;
                }
            }
        }
    }

    void CheckAISnakeCollisions(AISnake& aiSnake, const PlayerSnake& player,
                                FoodItem* foodList, int foodCount) {
        if (aiSnake.radius <= 0 || aiSnake.isDead || aiSnake.isDying) return;

        // AI蛇与玩家身体段碰撞
        for (const auto& playerSeg : player.segments) {
            if (CollisionManager::CheckCircleCollision(
                    aiSnake.position, aiSnake.radius,
                    playerSeg.position, playerSeg.radius)) {
                aiSnake.StartDying(1);
                SpawnFoodFromSnake(aiSnake, foodList, foodCount);
                return;
            }
        }

        // AI蛇身体段与玩家身体段碰撞
        for (const auto& aiSeg : aiSnake.segments) {
            if (aiSeg.radius <= 0) continue;
            for (const auto& playerSeg : player.segments) {
                if (CollisionManager::CheckCircleCollision(
                        aiSeg.position, aiSeg.radius,
                        playerSeg.position, playerSeg.radius)) {
                    aiSnake.StartDying(1);
                    SpawnFoodFromSnake(aiSnake, foodList, foodCount);
                    return;
                }
            }
            if (aiSnake.isDying) break;
        }
    }

    bool CheckAIWallCollision(AISnake& aiSnake, FoodItem* foodList, int foodCount) {
        if (aiSnake.radius <= 0 || aiSnake.isDead || aiSnake.isDying) return false;

        if (CheckWallCollision(aiSnake.position, aiSnake.radius)) {
            aiSnake.StartDying(1);
            SpawnFoodFromSnake(aiSnake, foodList, foodCount);
            return true;
        }
        return false;
    }

    bool CheckAISelfCollision(AISnake& aiSnake, FoodItem* foodList, int foodCount) {
        if (aiSnake.radius <= 0 || aiSnake.isDead || aiSnake.isDying) return false;

        for (size_t j = 1; j < aiSnake.segments.size(); j++) {
            const auto& seg = aiSnake.segments[j];
            if (seg.radius <= 0) continue;
            if (CollisionManager::CheckCircleCollision(
                    aiSnake.position, aiSnake.radius * 0.8f,
                    seg.position, seg.radius * 0.5f)) {
                aiSnake.StartDying(1);
                SpawnFoodFromSnake(aiSnake, foodList, foodCount);
                return true;
            }
        }
        return false;
    }

    void CheckPlayerFoodCollision(PlayerSnake& player, FoodItem* foodList, int foodCount) {
        const Vector2 startPosition = player.previousPosition;
        const Vector2 endPosition = player.position;

        // Use spatial grid for efficient food collision detection
        const FoodSpatialGrid* foodGrid = GetFoodSpatialGrid();
        if (!foodGrid) {
            // Fallback to simple iteration if grid not available
            for (int i = 0; i < foodCount; i++) {
                if (foodList[i].collisionRadius <= 0) continue;
                if (DoesSweptCircleOverlap(
                        startPosition,
                        endPosition,
                        player.radius,
                        foodList[i].position,
                        foodList[i].collisionRadius)) {
                    ConsumePlayerFood(player, foodList[i]);
                }
            }
            return;
        }

        // Query only nearby foods
        std::vector<int> nearbyFoods;
        const float queryPadding = player.radius * 2.0f;
        Vector2 minPos(
            (std::min)(startPosition.x, endPosition.x) - queryPadding,
            (std::min)(startPosition.y, endPosition.y) - queryPadding);
        Vector2 maxPos(
            (std::max)(startPosition.x, endPosition.x) + queryPadding,
            (std::max)(startPosition.y, endPosition.y) + queryPadding);
        foodGrid->QueryRect(minPos, maxPos, nearbyFoods);

        for (int idx : nearbyFoods) {
            if (idx < 0 || idx >= foodCount) continue;
            if (foodList[idx].collisionRadius <= 0) continue;

            if (DoesSweptCircleOverlap(
                    startPosition,
                    endPosition,
                    player.radius,
                    foodList[idx].position,
                    foodList[idx].collisionRadius)) {
                ConsumePlayerFood(player, foodList[idx]);
            }
        }
    }

    void CheckAIFoodCollision(AISnake& aiSnake, FoodItem* foodList, int foodCount) {
        if (aiSnake.radius <= 0 || aiSnake.isDead || aiSnake.isDying) return;

        // Use spatial grid for efficient food collision detection
        const FoodSpatialGrid* foodGrid = GetFoodSpatialGrid();
        if (!foodGrid) {
            // Fallback to simple iteration
            for (int j = 0; j < foodCount; j++) {
                if (foodList[j].collisionRadius <= 0) continue;
                if (CollisionManager::CheckCircleCollision(
                        aiSnake.position, aiSnake.radius,
                        foodList[j].position, foodList[j].collisionRadius)) {
                    foodList[j].collisionRadius = 0;
                }
            }
            return;
        }

        // Query only nearby foods
        std::vector<int> nearbyFoods;
        Vector2 minPos(aiSnake.position.x - aiSnake.radius * 2, aiSnake.position.y - aiSnake.radius * 2);
        Vector2 maxPos(aiSnake.position.x + aiSnake.radius * 2, aiSnake.position.y + aiSnake.radius * 2);
        foodGrid->QueryRect(minPos, maxPos, nearbyFoods);

        for (int idx : nearbyFoods) {
            if (idx < 0 || idx >= foodCount) continue;
            if (foodList[idx].collisionRadius <= 0) continue;

            if (CollisionManager::CheckCircleCollision(
                    aiSnake.position, aiSnake.radius,
                    foodList[idx].position, foodList[idx].collisionRadius)) {
                foodList[idx].collisionRadius = 0;
            }
        }
    }
} // namespace CollisionSubsystems
