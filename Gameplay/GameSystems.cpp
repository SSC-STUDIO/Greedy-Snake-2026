#include "GameSystems.h"
#include "../Gameplay/GameConfig.h"
#include "../Core/Collisions.h"
#include "../Core/GameRuntime.h"
#include "../Core/GameState.h"

void UpdatePlayerSnake(float deltaTime) {
    auto& runtime = GameRuntime();
    PlayerSnake& player = static_cast<PlayerSnake&>(runtime.snake[0]);

    if (player.gridSnake) {
        player.MoveSnakeGrid(deltaTime);

        for (size_t i = 0; i < player.segments.size(); i++) {
            player.segments[i].currentTime += deltaTime;
        }
        return;
    }

    runtime.snake[0].direction = GameState::Instance().targetDirection;
    runtime.snake[0].position = runtime.snake[0].position + runtime.snake[0].GetVelocity() * deltaTime;
    runtime.snake[0].Update(deltaTime);

    for (size_t i = 0; i < runtime.snake[0].segments.size(); i++) {
        if (i == 0) {
            runtime.snake[0].UpdateBody(runtime.snake[0], runtime.snake[0].segments[i]);
        } else {
            runtime.snake[0].UpdateBody(runtime.snake[0].segments[i - 1], runtime.snake[0].segments[i]);
        }
        runtime.snake[0].segments[i].Update(deltaTime);
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
            runtime.snake[0].position);

        aiSnake.RecordPos();

        for (size_t i = 0; i < aiSnake.segments.size(); i++) {
            if (i == 0) {
                aiSnake.UpdateBody(aiSnake, aiSnake.segments[i]);
            } else {
                aiSnake.UpdateBody(aiSnake.segments[i - 1], aiSnake.segments[i]);
            }
            aiSnake.segments[i].Update(deltaTime);
        }

        for (auto& segment : aiSnake.segments) {
            segment.color = aiSnake.color;
            segment.radius = aiSnake.radius;
        }
    }
}

void UpdateCamera() {
    auto& runtime = GameRuntime();
    auto& gameState = GameState::Instance();
    Vector2 targetPos = runtime.snake[0].position - Vector2(
        static_cast<float>(GameConfig::WINDOW_WIDTH) / 2.0f,
        static_cast<float>(GameConfig::WINDOW_HEIGHT) / 2.0f);

    gameState.camera.position = gameState.camera.position +
        (targetPos - gameState.camera.position) * GameConfig::SMOOTH_CAMERA_FACTOR;
}

void RunCollisionChecks() {
    auto& runtime = GameRuntime();
    auto& gameState = GameState::Instance();

    if (!gameState.IsCollisionEnabled()) {
        return;
    }

    CollisionManager::CheckCollisions(
        runtime.snake,
        runtime.aiSnakeList.data(),
        static_cast<int>(runtime.aiSnakeList.size()),
        runtime.foodList,
        GameConfig::MAX_FOOD_COUNT);

    CheckGameState(runtime.snake);
}
