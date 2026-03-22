#pragma once
#include "../Gameplay/GameConfig.h"
#include "../Core/GameState.h"
#include "../Core/Vector2.h"
#include "../Core/Camera.h"
#include "../Utils/Rendering.h"
#include "Food.h"
#include <queue>
#include <deque>

/**
 * @file Snake.h
 * @brief 蛇类及相关结构的定义
 */

// FoodItem结构前向声明
struct FoodItem;
struct FoodSpatialGrid;
struct FoodSpatialGrid;

/**
 * @brief 蛇段结构体
 * 
 * 表示蛇的一个身体段，包含位置、方向和历史记录
 */
struct SnakeSegment {
    Vector2 position;                    // 蛇段位置
    Vector2 direction;                   // 蛇段方向
    std::queue<Vector2> positionHistory; // 位置历史记录
    int colorValue = HSLtoRGB(255.0f, 255.0f, 255.0f); // 颜色值（默认白色）
    float collisionRadius = GameConfig::INITIAL_SNAKE_SIZE; // 碰撞半径
    float timeSinceLastRecord = 0;       // 距离上次记录的时间

    Vector2 GetVelocity() const;        // 获取速度
    bool CanRecordPosition() const;      // 检查是否可以记录位置
};

/**
 * @brief 蛇基类
 * 
 * 定义了蛇的基本属性和行为，包括位置、方向、绘制和碰撞检测
 */
enum Direction { UP, DOWN, LEFT, RIGHT };

class Snake {
public:
    Vector2 position;
    Vector2 direction;
    Direction currentDir;
    Direction nextDir;
    std::queue<Vector2> posRecords;
    int color = HSLtoRGB(255.0f, 255.0f, 255.0f);
    float radius = GameConfig::INITIAL_SNAKE_SIZE;
    float currentTime = 0;
    float moveTimer = 0.0f;
    float moveInterval = 0.15f;
    std::vector<Snake> segments;
    bool gridSnake = true;

    virtual void Update(float deltaTime);
    Vector2 GetVelocity() const;
    bool IsBeginRecord() const;
    void RecordPos();
    Vector2 GetRecordTime() const;
    void UpdateBody(const Snake& lastBody, Snake& currentBody);
    virtual void Draw(const Camera& camera) const;
    virtual bool CheckCollisionWith(const Snake& other) const;
    virtual bool CheckCollisionWithPoint(const Vector2& point, float pointRadius) const;
    void MoveSnakeGrid(float deltaTime);
};

/**
 * @brief 玩家蛇类，继承自Snake
 * 
 * 添加了玩家特有属性如无敌时间、生命值和分数
 */
class PlayerSnake : public Snake {
public:
    std::vector<Snake> segments;
    bool isInvincible = false;
    float invincibilityTimer = 0.0f;
    int livesRemaining = 3;
    int score = 0;
    bool isDead = false;

    void Update(float deltaTime) override;
    void Draw(const Camera& camera) const override;
    bool CheckCollisionWith(const Snake& other) const override;
    void GrowSnake();
};

/**
 * @brief AI蛇类，继承自Snake
 * 
 * 实现了AI行为，包括方向变化、死亡动画和攻击性设置
 */
class AISnake : public Snake {
public:
    float directionChangeTimer = 0.0f;
    float speedMultiplier = 1.0f;
    float aggressionFactor = GameConfig::Difficulty::Normal::AI_AGGRESSION;
    std::vector<Snake> segments;
    std::deque<Vector2> recordedPositions;
    bool isDying = false;
    float deathTimer = 0.0f;
    int dyingSegmentIndex = -1;
    float segmentFadeTime = 0.2f;
    int foodValueOnDeath = 0;
    bool isDead = false;

    AISnake() {
        Initialize();
    }

    void Initialize();
    void Update(const FoodItem* foodItems, int foodCount, const FoodSpatialGrid* grid,
                float deltaTime, const Vector2& playerHeadPos);
    void Draw(const Camera& camera) const override;
    void UpdateDeathAnimation(float deltaTime);
    void StartDying(int foodValue);
    bool CheckCollisionWith(const Snake& other) const override;
    void CheckWallCollision();
};
