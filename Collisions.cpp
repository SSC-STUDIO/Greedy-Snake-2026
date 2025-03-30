#include "Collisions.h"
#include "Snake.h" // 在实现文件中包含，避免循环引用
#pragma warning(disable: 4996)	 // 禁用关于 _tcscpy 和 _stprintf 的安全警告

bool CollisionManager::CheckCircleCollision(const Vector2& pos1, float radius1, const Vector2& pos2, float radius2) {
    float distance = (pos1 - pos2).GetLength();
    return distance < (radius1 + radius2);
}

bool CollisionManager::CheckSnakeCollision(const Snake& snake1, const Snake& snake2) {
    // 使用多态功能，调用实际对象的碰撞检测方法
    return snake1.CheckCollisionWith(snake2) || snake2.CheckCollisionWith(snake1);
}

void CollisionManager::CheckCollisions(Snake* snake, AISnake* aiSnakes, int aiSnakeCount, 
                                       FoodItem* foodList, int foodCount) {
    auto& gameState = GameState::Instance();

    if (!gameState.IsCollisionEnabled()) {
        // 当玩家处于无敌状态时显示无敌提示
        if (gameState.isInvulnerable) {
            // 在蛇头附近显示无敌状态图标或文字
            settextcolor(RGB(255, 255, 0));  // 明黄色
            settextstyle(18, 0, _T("微软雅黑"));

            Vector2 textPos = snake[0].position - GameState::Instance().camera.position;
            textPos.y -= 40;  // 在蛇头上方显示

            // 显示剩余无敌时间
            TCHAR invulnerableText[50];
            float remainingInvulnerableTime = GameConfig::COLLISION_GRACE_PERIOD - gameState.gameStartTime;
            if (remainingInvulnerableTime < 0) remainingInvulnerableTime = 0;
            _stprintf(invulnerableText, _T("无敌: %.1fs"), remainingInvulnerableTime);

            // 计算文本宽度并居中显示
            int textWidth = textwidth(invulnerableText);
            outtextxy(textPos.x - textWidth / 2, textPos.y, invulnerableText);
        }
        return;
    }

    // 1. 检查玩家与AI蛇的碰撞
    bool playerHitAI = false;
    for (int i = 0; i < aiSnakeCount; ++i) {
        const AISnake& aiSnake = aiSnakes[i];
        if (aiSnake.CheckCollisionWith(snake[0]) || snake[0].CheckCollisionWith(aiSnake)) {
            playerHitAI = true;
            break;
        }
    }

    // 2. 检查AI蛇之间的碰撞
    for (int i = 0; i < aiSnakeCount; i++) {
        for (int j = i + 1; j < aiSnakeCount; j++) {
            // 检查头与头的碰撞
            if (CheckCircleCollision(
                aiSnakes[i].position, aiSnakes[i].radius,
                aiSnakes[j].position, aiSnakes[j].radius)) {

                // 碰撞反弹 - 两蛇向相反方向移动
                Vector2 collisionDir = (aiSnakes[i].position - aiSnakes[j].position).GetNormalize();
                aiSnakes[i].direction = collisionDir;
                aiSnakes[j].direction = -collisionDir;
            }
        }
    }

    // 3. 如果玩家与AI蛇碰撞
    if (playerHitAI) {
        gameState.isCollisionFlashing = true;
        gameState.collisionFlashTimer = GameConfig::COLLISION_FLASH_DURATION;

        // 玩家死亡
        if (!gameState.isInvulnerable) {
            // 简化：只设置游戏状态和死亡消息标志
            gameState.isGameRunning = false;
            gameState.showDeathMessage = true;
            gameState.finalScore = gameState.foodEatenCount;  // 保存最终得分
        }
    }

    // 4. 检查玩家与食物的碰撞
    for (int i = 0; i < foodCount; i++) {
        if (foodList[i].collisionRadius > 0 && // 只检查有效的食物
            CheckCircleCollision(
                snake[0].position, snake[0].radius,
                foodList[i].position, foodList[i].collisionRadius)) {

            // 将食物标记为已吃掉
            foodList[i].collisionRadius = 0;

            // 处理食物收集
            gameState.AddFoodEaten();

            // 增长蛇身
            float growthAmount = (gameState.foodEatenCount == 0) ?
                GameConfig::SNAKE_GROWTH_LARGE : GameConfig::SNAKE_GROWTH_SMALL;
            snake[0].radius = min(snake[0].radius + growthAmount, GameConfig::MAX_SNAKE_SIZE);
        }
    }

    // 5. 检查AI蛇与食物的碰撞
    for (int i = 0; i < aiSnakeCount; ++i) {
        AISnake& aiSnake = aiSnakes[i];
        for (int j = 0; j < foodCount; j++) {
            if (foodList[j].collisionRadius > 0 && // 只检查有效的食物
                CheckCircleCollision(
                    aiSnake.position, aiSnake.radius,
                    foodList[j].position, foodList[j].collisionRadius)) {

                // 将食物标记为已吃掉
                foodList[j].collisionRadius = 0;

                // AI蛇吃到食物后也会变大
                aiSnake.radius = min(aiSnake.radius + GameConfig::SNAKE_GROWTH_SMALL, GameConfig::MAX_SNAKE_SIZE);
            }
        }
    }
}

