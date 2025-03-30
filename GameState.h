#pragma once
#include "Vector2.h"
#include "GameConfig.h"
#include "Camera.h"
#include "Snake.h"
#include <mutex> // 添加互斥锁头文件


// 使用前向声明而不是直接包含
class Snake;
class PlayerSnake;
class AISnake;

// 游戏状态管理
class GameState {
public:
    static GameState& Instance() {
        static GameState instance; // 单例
        return instance;
    }

    void Initial() {
        // 不使用赋值，而是重置每个成员
        auto& instance = Instance();
        instance.currentPlayerSpeed = GameConfig::DEFAULT_PLAYER_SPEED;
        instance.recordInterval = GameConfig::DEFAULT_RECORD_INTERVAL;
        instance.isMouseControlEnabled = true;
        instance.isGameRunning = true;
        instance.playerPosition = Vector2();
        instance.targetDirection = Vector2(0, 1);
        instance.deltaTime = 1.0f / 30.0f;
        instance.originalSpeed = GameConfig::DEFAULT_PLAYER_SPEED;
        instance.timeInLava = 0.0f;
        instance.isInLava = false;
        instance.foodEatenCount = 0;
        instance.aiAggression = GameConfig::Difficulty::Normal::AI_AGGRESSION;
        instance.foodSpawnRate = GameConfig::Difficulty::Normal::FOOD_SPAWN_RATE;
        instance.aiSnakeCount = GameConfig::Difficulty::Normal::AI_SNAKE_COUNT;
        instance.lavaWarningTime = GameConfig::Difficulty::Normal::LAVA_WARNING_TIME;
        instance.collisionFlashTimer = 0.0f;
        instance.isCollisionFlashing = false;
        instance.gameStartTime = 0.0f;
        instance.isInvulnerable = true;
        instance.showDeathMessage = false;
        instance.finalScore = 0;
        instance.returnToMenu = false;
        instance.currentDifficulty = GameDifficulty::Normal;
    }

    float currentPlayerSpeed = GameConfig::DEFAULT_PLAYER_SPEED; // 当前玩家速度
    float recordInterval = GameConfig::DEFAULT_RECORD_INTERVAL; // 记录间隔
    bool isMouseControlEnabled = true; // 是否启用鼠标控制
    bool isGameRunning = true; // 游戏是否运行
    Camera camera; // 相机
    Vector2 playerPosition; // 玩家位置
    Vector2 targetDirection{ 0, 1 }; // 目标方向
    float deltaTime = 1.0f / 30.0f; // 时间增量
    float originalSpeed = GameConfig::DEFAULT_PLAYER_SPEED; // 原始速度
    float timeInLava = 0.0f;  // 在熔岩中花费的时间
    bool isInLava = false;    // 蛇是否在熔岩中
    int foodEatenCount = 0;  // 吃掉的食物数量
    float aiAggression = GameConfig::Difficulty::Normal::AI_AGGRESSION; // AI攻击性
    float foodSpawnRate = GameConfig::Difficulty::Normal::FOOD_SPAWN_RATE; // 食物生成率
    int aiSnakeCount = GameConfig::Difficulty::Normal::AI_SNAKE_COUNT; // AI蛇数量
    float lavaWarningTime = GameConfig::Difficulty::Normal::LAVA_WARNING_TIME; // 熔岩警告时间

    float collisionFlashTimer = 0.0f;      // 碰撞闪烁计时器
    bool isCollisionFlashing = false;      // 是否在碰撞闪烁中
    float gameStartTime = 0.0f;            // 游戏开始时间
    bool isInvulnerable = true;            // 是否处于无敌状态
    bool showDeathMessage = false;         // 是否显示死亡消息
    int finalScore = 0;                    // 最终得分

    bool returnToMenu = false;  // 是否返回主菜单

    enum class GameDifficulty {
        Easy, // 简单
        Normal, // 普通
        Hard // 困难
    };

    GameDifficulty currentDifficulty = GameDifficulty::Normal; // 当前难度

    void SetDifficulty(GameDifficulty difficulty);

    void ResetLavaTimer();

    void AddFoodEaten();

    bool IsCollisionEnabled() const;

    void UpdateGameTime(float dt);

    // 添加互斥锁用于线程同步
    std::mutex stateMutex;

private:
    GameState() = default; // 私有构造函数
};

void CheckGameState(Snake* snake);