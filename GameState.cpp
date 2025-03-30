#include "GameState.h"


void CheckGameState(Snake* snake) {
    auto& gameState = GameState::Instance();

    // Check if snake is outside play area
    bool inPlayArea = snake[0].position.x >= GameConfig::PLAY_AREA_LEFT &&
        snake[0].position.x <= GameConfig::PLAY_AREA_RIGHT &&
        snake[0].position.y >= GameConfig::PLAY_AREA_TOP &&
        snake[0].position.y <= GameConfig::PLAY_AREA_BOTTOM;

    if (!inPlayArea) {
        if (!gameState.isInLava) {
            gameState.isInLava = true;
            gameState.timeInLava = 0;
        }

        gameState.timeInLava += gameState.deltaTime;
        if (gameState.timeInLava >= GameConfig::LAVA_WARNING_TIME) {
            gameState.isGameRunning = false;
        }
    }
    else {
        gameState.ResetLavaTimer();
    }
}

void GameState::SetDifficulty(GameDifficulty difficulty)
{
    currentDifficulty = difficulty; 

    switch (currentDifficulty) {
    case GameDifficulty::Easy:
        currentPlayerSpeed = GameConfig::Difficulty::Easy::PLAYER_SPEED; // ��������ٶ�
        aiSnakeCount = GameConfig::Difficulty::Easy::AI_SNAKE_COUNT; // ����AI������
        aiAggression = GameConfig::Difficulty::Easy::AI_AGGRESSION; // ����AI������
        foodSpawnRate = GameConfig::Difficulty::Easy::FOOD_SPAWN_RATE; // ����ʳ��������
        lavaWarningTime = GameConfig::Difficulty::Easy::LAVA_WARNING_TIME; // �������Ҿ���ʱ��
        break;

    case GameDifficulty::Normal:
        currentPlayerSpeed = GameConfig::Difficulty::Normal::PLAYER_SPEED; // ��������ٶ�
        aiSnakeCount = GameConfig::Difficulty::Normal::AI_SNAKE_COUNT; // ����AI������
        aiAggression = GameConfig::Difficulty::Normal::AI_AGGRESSION; // ����AI������
        foodSpawnRate = GameConfig::Difficulty::Normal::FOOD_SPAWN_RATE; // ����ʳ��������
        lavaWarningTime = GameConfig::Difficulty::Normal::LAVA_WARNING_TIME; // �������Ҿ���ʱ��
        break;

    case GameDifficulty::Hard:
        currentPlayerSpeed = GameConfig::Difficulty::Hard::PLAYER_SPEED; // ��������ٶ�
        aiSnakeCount = GameConfig::Difficulty::Hard::AI_SNAKE_COUNT; // ����AI������
        aiAggression = GameConfig::Difficulty::Hard::AI_AGGRESSION; // ����AI������
        foodSpawnRate = GameConfig::Difficulty::Hard::FOOD_SPAWN_RATE; // ����ʳ��������
        lavaWarningTime = GameConfig::Difficulty::Hard::LAVA_WARNING_TIME; // �������Ҿ���ʱ��
        break;
    }
}

void GameState::ResetLavaTimer()
{
    timeInLava = 0.0f; 
    isInLava = false;
}

void GameState::AddFoodEaten()
{
    foodEatenCount++; 
    if (foodEatenCount >= 10) {
        foodEatenCount = 0;
    }
}

bool GameState::IsCollisionEnabled() const
{
    if (!GameConfig::ENABLE_COLLISION) return false;
    return !isInvulnerable;
}

void GameState::UpdateGameTime(float dt)
{
    gameStartTime += dt;
    
    // 更新无敌时间状态
    if (isInvulnerable && gameStartTime >= GameConfig::COLLISION_GRACE_PERIOD) {
        isInvulnerable = false;
    }
}
