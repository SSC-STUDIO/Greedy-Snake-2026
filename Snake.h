#include "GameConfig.h"
#include "GameState.h"
#include "Vector2.h"
#include "Camera.h"
#include "Rendering.h"
#include "Food.h"
#include <queue>

struct SnakeSegment {
    Vector2 position; // 蛇段位置
    Vector2 direction; // 蛇段方向
    std::queue<Vector2> positionHistory; // 位置历史记录
    int colorValue = HSLtoRGB(255, 255, 255);      // 默认白色
    float collisionRadius = GameConfig::INITIAL_SNAKE_SIZE;        // 默认碰撞半径
    float timeSinceLastRecord = 0; // 距离上次记录的时间

    Vector2 GetVelocity() const;

    bool CanRecordPosition() const;
};

// Snake类
class Snake {
public:
    Vector2 position;
    Vector2 direction;
    std::queue<Vector2> posRecords;
    int color = HSLtoRGB(255, 255, 255);
    float radius = GameConfig::INITIAL_SNAKE_SIZE;
    float currentTime = 0;

    virtual void Update(float deltaTime);

    Vector2 GetVelocity() const;

    bool IsBeginRecord() const;

    void RecordPos();

    Vector2 GetRecordTime() const;
    void UpdateBody(const Snake& lastBody, Snake& currentBody);
    virtual void Draw(const Camera& camera) const;
};

// 玩家蛇类
class PlayerSnake : public Snake {
public:
    std::vector<Snake> segments;

    void Update(float deltaTime) override;

    void Draw(const Camera& camera) const override;
};

// AI蛇类
class AISnake : public Snake {
public:
    float directionChangeTimer = 0.0f; // 方向改变计时器
    float speedMultiplier = 1.0f; // 速度乘数
    float aggressionFactor = GameConfig::Difficulty::Normal::AI_AGGRESSION; // 添加攻击性因子
    std::vector<Snake> segments;  // 添加AI蛇身体的段

    AISnake() {
        Init(); // 初始化
    }

    void Init();

    void Update(const std::vector<FoodItem>& foodItems, float deltaTime, const Vector2& playerHeadPos);

    void UpdateSegments();
};