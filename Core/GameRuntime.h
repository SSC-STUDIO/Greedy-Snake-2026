#pragma once

#include "../Gameplay/Food.h"
#include "../Gameplay/GameConfig.h"
#include "../Gameplay/Snake.h"
#include <vector>

struct GameRuntimeContext {
    float animationTimer = 0.0f;
    FoodItem foodList[GameConfig::MAX_FOOD_COUNT];
    std::vector<AISnake> aiSnakeList;
    Snake snake[1];
};

extern GameRuntimeContext gGameRuntime;

inline GameRuntimeContext& GameRuntime() {
    return gGameRuntime;
}
