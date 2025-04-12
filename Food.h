#pragma once
#include "Vector2.h"    
#include "GameConfig.h" 
#include "GameState.h" 
#include <graphics.h>

// Food structure
struct FoodItem {
    Vector2 position; // Food position
    int colorValue = HSLtoRGB(255, 255, 255);  // Default white
    float collisionRadius = GameConfig::INITIAL_SNAKE_SIZE;    // Default collision radius
};

// Extract repeated food position generation logic into a function
Vector2 GenerateRandomPosition();

void InitFood(FoodItem* foodList, int i, float speed);

void UpdateFoods(FoodItem* foodList, int foodCount);