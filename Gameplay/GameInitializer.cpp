#include "GameInitializer.h"
#include "../Gameplay/GameConfig.h"
#include "../Gameplay/Snake.h"
#include "../Core/GameRuntime.h"
#include "../ModernCore/Random.h"
#include "../ModernCore/Direction.h"
#include "../ModernCore/Vector2.h"
#include <algorithm>
#include <cmath>

using GreedSnake::Random;
using GreedSnake::Direction;
using Vector2 = GreedSnake::Vector2;

void InitializeAISnakes() {
    auto& runtime = GameRuntime();
    auto& gameState = GameState::Instance();
    runtime.aiSnakeList.resize(gameState.aiSnakeCount);

    for (auto& aiSnake : runtime.aiSnakeList) {
        aiSnake.Initialize();
        aiSnake.aggressionFactor = gameState.aiAggression;
        // Random speed multiplier for variety (0.5 to 0.8 of player speed)
        aiSnake.speedMultiplier = Random::Float(0.5f, 0.8f);
        // Randomize initial direction
        float dirAngle = Random::Float(0.0f, 360.0f) * 3.14159f / 180.0f;
        aiSnake.direction = Vector2(cos(dirAngle), sin(dirAngle));
    }

    for (int i = 0; i < gameState.aiSnakeCount; ++i) {
        const float angle = (static_cast<float>(i) * 360.0f / gameState.aiSnakeCount) * 3.14159f / 180.0f;
        const float distance = Random::Float(300.0f, static_cast<float>(GameConfig::AI_SPAWN_RADIUS));

        // 玩家在大地图中心(0,0)，AI蛇应该在玩家周围生成
        float x = cos(angle) * distance;
        float y = sin(angle) * distance;

        x = (std::max)(GameConfig::PLAY_AREA_LEFT + 100.0f, (std::min)(GameConfig::PLAY_AREA_RIGHT - 100.0f, x));
        y = (std::max)(GameConfig::PLAY_AREA_TOP + 100.0f, (std::min)(GameConfig::PLAY_AREA_BOTTOM - 100.0f, y));

        const float dirAngle = Random::Float(0.0f, 360.0f) * 3.14159f / 180.0f;
        const Vector2 direction(cos(dirAngle), sin(dirAngle));

        Direction aiDir = Direction::Right;
        if (abs(direction.x) > abs(direction.y)) {
            aiDir = direction.x > 0 ? Direction::Right : Direction::Left;
        } else {
            aiDir = direction.y > 0 ? Direction::Down : Direction::Up;
        }

        runtime.aiSnakeList[i].position = Vector2(x, y);
        runtime.aiSnakeList[i].direction = direction;
        runtime.aiSnakeList[i].currentDir = aiDir;
        runtime.aiSnakeList[i].nextDir = aiDir;
        runtime.aiSnakeList[i].radius = GameConfig::INITIAL_SNAKE_SIZE * 0.8f;
        runtime.aiSnakeList[i].color = HSLtoRGB(Random::Float(0.0f, 360.0f), 200.0f, 200.0f);
        runtime.aiSnakeList[i].gridSnake = false;  // Use smooth continuous movement
        runtime.aiSnakeList[i].moveTimer = 0.0f;

        for (int j = 0; j < 5; j++) {
            runtime.aiSnakeList[i].segments[j].position = runtime.aiSnakeList[i].position -
                direction * (static_cast<float>(j + 1) * GameConfig::SNAKE_SEGMENT_SPACING);
            runtime.aiSnakeList[i].segments[j].direction = direction;
            runtime.aiSnakeList[i].segments[j].radius = runtime.aiSnakeList[i].radius;
            runtime.aiSnakeList[i].segments[j].color = runtime.aiSnakeList[i].color;
        }

        runtime.aiSnakeList[i].recordedPositions.clear();
        for (int j = 0; j < 20; j++) {
            runtime.aiSnakeList[i].recordedPositions.push_back(
                runtime.aiSnakeList[i].position - direction * static_cast<float>(j) * (GameConfig::SNAKE_SEGMENT_SPACING / 4.0f));
        }
    }
}
