#include "GameSystems.h"
#include "../Gameplay/GameConfig.h"
#include "../Core/Collisions.h"
#include "../Core/GameRuntime.h"
#include "../Core/SessionConfig.h"
#include "../Core/GameState.h"

void UpdatePlayerSnake(float deltaTime) {
    auto& runtime = GameRuntime();
    PlayerSnake& player = runtime.playerSnake;
    auto& gameState = GameState::Instance();

    if (player.gridSnake) {
        player.previousPosition = player.position;
        player.MoveSnakeGrid(deltaTime);

        for (size_t i = 0; i < player.segments.size(); i++) {
            player.segments[i].currentTime += deltaTime;
        }
        return;
    }

    // 获取目标方向并平滑转向
    Vector2 targetDir = gameState.GetTargetDirection();
    if (targetDir.Length() > 0.0f) {
        // 平滑转向（原版风格）- 提高响应速度
        float turnSpeed = 0.3f;
        player.direction = ResolveSmoothSteeringDirection(player.direction, targetDir, turnSpeed);
    }

    // 根据速度更新位置（连续移动模式）
    player.previousPosition = player.position;
    Vector2 velocity = player.direction * gameState.currentPlayerSpeed;
    player.position = player.position + velocity * deltaTime;

    // 记录位置供蛇身跟随
    player.Snake::Update(deltaTime);

    // 更新蛇身段
    for (size_t i = 0; i < runtime.playerSnake.segments.size(); i++) {
        if (i == 0) {
            runtime.playerSnake.UpdateBody(runtime.playerSnake, runtime.playerSnake.segments[i]);
        } else {
            runtime.playerSnake.UpdateBody(runtime.playerSnake.segments[i - 1], runtime.playerSnake.segments[i]);
        }
        runtime.playerSnake.segments[i].Update(deltaTime);
    }
}

void UpdateAISnakes(float deltaTime) {
    auto& runtime = GameRuntime();
    const FoodSpatialGrid* foodGrid = GetFoodSpatialGrid();

    for (auto& aiSnake : runtime.aiSnakeList) {
        aiSnake.Update(
            runtime.foodList,
            GameConfig::MAX_FOOD_COUNT,
            foodGrid,
            deltaTime,
            runtime.playerSnake.position);
    }
}

void UpdateCamera() {
    auto& runtime = GameRuntime();
    auto& gameState = GameState::Instance();
    Vector2 targetPos = runtime.playerSnake.position - Vector2(
        static_cast<float>(GameConfig::WINDOW_WIDTH) / 2.0f,
        static_cast<float>(GameConfig::WINDOW_HEIGHT) / 2.0f);

    gameState.camera.position = gameState.camera.position +
        (targetPos - gameState.camera.position) * GameConfig::SMOOTH_CAMERA_FACTOR;
}

void RunCollisionChecks() {
    auto& runtime = GameRuntime();

    // Always run collision checks, invulnerability handled internally
    CollisionManager::CheckCollisions(
        runtime.playerSnake,
        runtime.aiSnakeList.data(),
        static_cast<int>(runtime.aiSnakeList.size()),
        runtime.foodList,
        GameConfig::MAX_FOOD_COUNT);

    CheckGameState(runtime.playerSnake);
}
