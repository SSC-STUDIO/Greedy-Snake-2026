#include "Vector2.h"
#include "GameConfig.h"
#include "Camera.h"

// 游戏状态管理
class GameState {
public:
    static GameState& Instance() {
        static GameState instance; // 单例
        return instance;
    }

    void Initial() {
        Instance() = GameState(); // 初始化
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

private:
    GameState() = default; // 私有构造函数
};
