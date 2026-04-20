#pragma once

#include "../ModernCore/Vector2.h"
#include "../Gameplay/GameConfig.h"

using Vector2 = GreedSnake::Vector2;

// 前向声明
class Snake;
class PlayerSnake;
class AISnake;
struct FoodItem;

namespace CollisionSubsystems {
    // 墙壁碰撞检测
    bool CheckWallCollision(const Vector2& pos, float radius);

    // 玩家碰撞检测
    bool CheckPlayerWallCollision(PlayerSnake& player);
    bool CheckPlayerSelfCollision(PlayerSnake& player);
    bool CheckPlayerAICollision(PlayerSnake& player, AISnake* aiSnakes, int aiSnakeCount);

    // AI 蛇碰撞检测
    void CheckAISnakeCollisions(AISnake& aiSnake, const PlayerSnake& player,
                                FoodItem* foodList, int foodCount);
    bool CheckAIWallCollision(AISnake& aiSnake, FoodItem* foodList, int foodCount);
    bool CheckAISelfCollision(AISnake& aiSnake, FoodItem* foodList, int foodCount);

    // 食物碰撞检测
    void CheckPlayerFoodCollision(PlayerSnake& player, FoodItem* foodList, int foodCount);
    void CheckAIFoodCollision(AISnake& aiSnake, FoodItem* foodList, int foodCount);

    // 辅助函数：生成食物
    void SpawnFoodFromSnake(const AISnake& aiSnake, FoodItem* foodList, int foodCount);
}
