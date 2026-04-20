#pragma once

#include "../Gameplay/Food.h"
#include "../Gameplay/GameConfig.h"
#include "../Gameplay/Snake.h"
#include <vector>

struct GameRuntimeContext {
    FoodItem foodList[GameConfig::MAX_FOOD_COUNT];
    std::vector<AISnake> aiSnakeList;
    PlayerSnake playerSnake;
};

extern GameRuntimeContext gGameRuntime;

inline GameRuntimeContext& GameRuntime() {
    return gGameRuntime;
}
