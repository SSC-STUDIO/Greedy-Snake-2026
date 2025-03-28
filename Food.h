#pragma once
#include "Vector2.h"    
#include "GameConfig.h" // 包含游戏配置   
#include "GameState.h" // 包含游戏状态
#include <easyx.h>

// 更新结构体名称
struct FoodItem {
    Vector2 position; // 食物位置
    float moveSpeed = GameState::Instance().currentPlayerSpeed; // 食物移动速度
    int colorValue = HSLtoRGB(255, 255, 255);  // 默认白色
    float collisionRadius = GameConfig::INITIAL_SNAKE_SIZE;    // 默认碰撞半径
};
