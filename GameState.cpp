#include "GameState.h"

void GameState::SetDifficulty(GameDifficulty difficulty)
{
    currentDifficulty = difficulty; // 设置难度

    // 根据难度更新游戏参数
    switch (currentDifficulty) {
    case GameDifficulty::Easy:
        currentPlayerSpeed = GameConfig::Difficulty::Easy::PLAYER_SPEED; // 更新玩家速度
        aiSnakeCount = GameConfig::Difficulty::Easy::AI_SNAKE_COUNT; // 更新AI蛇数量
        aiAggression = GameConfig::Difficulty::Easy::AI_AGGRESSION; // 更新AI攻击性
        foodSpawnRate = GameConfig::Difficulty::Easy::FOOD_SPAWN_RATE; // 更新食物生成率
        lavaWarningTime = GameConfig::Difficulty::Easy::LAVA_WARNING_TIME; // 更新熔岩警告时间
        break;

    case GameDifficulty::Normal:
        currentPlayerSpeed = GameConfig::Difficulty::Normal::PLAYER_SPEED; // 更新玩家速度
        aiSnakeCount = GameConfig::Difficulty::Normal::AI_SNAKE_COUNT; // 更新AI蛇数量
        aiAggression = GameConfig::Difficulty::Normal::AI_AGGRESSION; // 更新AI攻击性
        foodSpawnRate = GameConfig::Difficulty::Normal::FOOD_SPAWN_RATE; // 更新食物生成率
        lavaWarningTime = GameConfig::Difficulty::Normal::LAVA_WARNING_TIME; // 更新熔岩警告时间
        break;

    case GameDifficulty::Hard:
        currentPlayerSpeed = GameConfig::Difficulty::Hard::PLAYER_SPEED; // 更新玩家速度
        aiSnakeCount = GameConfig::Difficulty::Hard::AI_SNAKE_COUNT; // 更新AI蛇数量
        aiAggression = GameConfig::Difficulty::Hard::AI_AGGRESSION; // 更新AI攻击性
        foodSpawnRate = GameConfig::Difficulty::Hard::FOOD_SPAWN_RATE; // 更新食物生成率
        lavaWarningTime = GameConfig::Difficulty::Hard::LAVA_WARNING_TIME; // 更新熔岩警告时间
        break;
    }
}

void GameState::ResetLavaTimer()
{
    timeInLava = 0.0f; // 重置熔岩计时器
    isInLava = false; // 设置为不在熔岩中
}

void GameState::AddFoodEaten()
{
    foodEatenCount++; // 增加吃掉的食物数量
    // 每吃10个食物重置计数器
    if (foodEatenCount >= 10) {
        foodEatenCount = 0;
    }
}

bool GameState::IsCollisionEnabled() const
{
    // 检查是否启用碰撞以及无敌时间是否结束
    if (!GameConfig::ENABLE_COLLISION) return false;
    return !isInvulnerable;
}

void GameState::UpdateGameTime(float dt)
{
    gameStartTime += dt;
    // 检查无敌时间是否结束
    if (isInvulnerable && gameStartTime >= GameConfig::COLLISION_GRACE_PERIOD) {
        isInvulnerable = false;
    }
}
