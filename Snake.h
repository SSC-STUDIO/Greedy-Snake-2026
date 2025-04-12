#pragma once
#include "GameConfig.h"
#include "GameState.h"
#include "Vector2.h"
#include "Camera.h"
#include "Rendering.h"
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

    AISnake() {
        Init(); // Initialize
    }

    void Init();

    void Update(const std::vector<FoodItem>& foodItems, float deltaTime, const Vector2& playerHeadPos);

    // void UpdateSegments();
    bool CheckCollisionWith(const Snake& other) const override;
};