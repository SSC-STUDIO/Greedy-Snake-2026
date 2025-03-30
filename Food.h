#pragma once
#include "Vector2.h"    
#include "GameConfig.h" 
#include "GameState.h" 
#include <graphics.h>

// 食物结构体
struct FoodItem {
    Vector2 position; // 食物位置
    int colorValue = HSLtoRGB(255, 255, 255);  // 默认白色
    float collisionRadius = GameConfig::INITIAL_SNAKE_SIZE;    // 默认碰撞半径
};

// 将重复的食物位置生成逻辑提取为函数
Vector2 GenerateRandomPosition();

void InitFood(FoodItem* foodList, int i, float speed);

void UpdateFoods(FoodItem* foodList, int foodCount);