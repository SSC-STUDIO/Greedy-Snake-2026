#include "Collisions.h"
#include "CollisionSubsystems.h"
#include "..\Gameplay\Snake.h"
#include "..\Gameplay\Food.h"
#include "..\Gameplay\GameConfig.h"
#include "../Utils/DrawHelpers.h"
#include "../ModernCore/Vector2.h"
#include <cmath>
#include <vector>
#pragma warning(disable: 4996)

using Vector2 = GreedSnake::Vector2;

struct GrowthAnimation {
    bool active = false;
    float timer = 0.0f;
    float duration = 0.3f;
    Vector2 position;
    int color;
    float baseRadius;
};

static GrowthAnimation playerGrowthAnim;

bool CollisionManager::CheckCircleCollision(const Vector2& pos1, float radius1, const Vector2& pos2, float radius2) {
    const Vector2 delta = pos1 - pos2;
    const float distanceSq = delta.LengthSquared();
    const float radiusSum = radius1 + radius2;
    return distanceSq < (radiusSum * radiusSum);
}

bool CollisionManager::CheckSnakeCollision(const Snake& snake1, const Snake& snake2) {
    return snake1.CheckCollisionWith(snake2) || snake2.CheckCollisionWith(snake1);
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

void TriggerGrowthAnimation(const Vector2& position, int color, float radius) {
    playerGrowthAnim.active = true;
    playerGrowthAnim.timer = 0.0f;
    playerGrowthAnim.position = position;
    playerGrowthAnim.color = color;
    playerGrowthAnim.baseRadius = radius;
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

void CollisionManager::CheckCollisions(PlayerSnake& player, AISnake* aiSnakes, int aiSnakeCount,
                                       FoodItem* foodList, int foodCount) {
    auto& gameState = GameState::Instance();

    if (player.isDead) return;

    // 1. 玩家伤害性碰撞检测 - 检查无敌状态
    if (gameState.IsCollisionEnabled()) {
        // Wall contact is non-lethal here; CheckGameState applies the lava warning timer.
        CollisionSubsystems::CheckPlayerWallCollision(player);
        if (CollisionSubsystems::CheckPlayerSelfCollision(player)) return;
        if (CollisionSubsystems::CheckPlayerAICollision(player, aiSnakes, aiSnakeCount)) return;
    }

    // 2. AI 蛇碰撞检测 - 不受玩家无敌影响
    for (int i = 0; i < aiSnakeCount; ++i) {
        AISnake& aiSnake = aiSnakes[i];

        // AI 蛇与玩家身体段碰撞
        CollisionSubsystems::CheckAISnakeCollisions(aiSnake, player, foodList, foodCount);

        // AI 蛇与墙壁碰撞
        CollisionSubsystems::CheckAIWallCollision(aiSnake, foodList, foodCount);

        // AI 蛇自身碰撞
        CollisionSubsystems::CheckAISelfCollision(aiSnake, foodList, foodCount);
    }

    // 3. 食物碰撞检测 - 无敌期间也能吃食物
    CollisionSubsystems::CheckPlayerFoodCollision(player, foodList, foodCount);

    for (int i = 0; i < aiSnakeCount; ++i) {
        AISnake& aiSnake = aiSnakes[i];
        CollisionSubsystems::CheckAIFoodCollision(aiSnake, foodList, foodCount);
    }
}
