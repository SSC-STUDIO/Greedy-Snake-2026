#pragma once
#include "../Core/GameConfig.h"
#include "GameState.h"
#include "../Core/Vector2.h"
#include "../Core/Camera.h"
#include "../Utils/Rendering.h"
#include "Food.h"
#include <queue>

struct FoodItem;

struct SnakeSegment {
    Vector2 position; // Snake segment position
    Vector2 direction; // Snake segment direction
    std::queue<Vector2> positionHistory; // Position history record
    int colorValue = HSLtoRGB(255, 255, 255);      // Default white
    float collisionRadius = GameConfig::INITIAL_SNAKE_SIZE;        // Default collision radius
    float timeSinceLastRecord = 0; // Time since last record

    Vector2 GetVelocity() const;

    bool CanRecordPosition() const;
};

// Snake class
class Snake {
public:
    Vector2 position;
    Vector2 direction;
    std::queue<Vector2> posRecords;
    int color = HSLtoRGB(255, 255, 255);
    float radius = GameConfig::INITIAL_SNAKE_SIZE;
    float currentTime = 0;
    std::vector<Snake> segments;

    virtual void Update(float deltaTime);

    Vector2 GetVelocity() const;

    bool IsBeginRecord() const;

    void RecordPos();

    Vector2 GetRecordTime() const;
    void UpdateBody(const Snake& lastBody, Snake& currentBody);
    virtual void Draw(const Camera& camera) const;

    virtual bool CheckCollisionWith(const Snake& other) const;
    
    virtual bool CheckCollisionWithPoint(const Vector2& point, float pointRadius) const;
};

// Player snake class
class PlayerSnake : public Snake {
public:
    std::vector<Snake> segments;
    bool isInvincible = false;           // Whether player is invincible
    float invincibilityTimer = 0.0f;     // Invincibility timer
    int livesRemaining = 3;              // Remaining lives
    int score = 0;                       // Player score

    void Update(float deltaTime) override;

    void Draw(const Camera& camera) const override;
    bool CheckCollisionWith(const Snake& other) const override;
};

// AI snake class
class AISnake : public Snake {
public:
    float directionChangeTimer = 0.0f; // Direction change timer
    float speedMultiplier = 1.0f; // Speed multiplier
    float aggressionFactor = GameConfig::Difficulty::Normal::AI_AGGRESSION; // Add aggression factor
    std::vector<Snake> segments;  // Add AI snake body segments
    std::deque<Vector2> recordedPositions; 
    
    // 添加AI蛇死亡动画相关状态
    bool isDying = false;           // 是否正在死亡
    float deathTimer = 0.0f;        // 死亡动画计时器
    int dyingSegmentIndex = -1;     // 当前正在消失的段索引，-1表示头部
    float segmentFadeTime = 0.2f;   // 每个段消失所需的时间
    int foodValueOnDeath = 0;       // 死亡时提供的食物价值

    AISnake() {
        Init(); // Initialize
    }

    void Init();

    void Update(const std::vector<FoodItem>& foodItems, float deltaTime, const Vector2& playerHeadPos);

    // 添加Draw方法重写
    void Draw(const Camera& camera) const override;
    
    // 处理AI蛇的死亡，更新死亡动画
    void UpdateDeathAnimation(float deltaTime);
    
    // 开始死亡过程
    void StartDying(int foodValue);

    // void UpdateSegments();
    bool CheckCollisionWith(const Snake& other) const override;
};