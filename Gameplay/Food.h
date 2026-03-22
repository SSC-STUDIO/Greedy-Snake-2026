#pragma once
#include "../Core/Vector2.h"    
#include "../Gameplay/GameConfig.h" 
#include "../Core/GameState.h" 
#include <graphics.h>
#include <vector>

// Food structure
struct FoodItem {
    Vector2 position; // Food position
    int colorValue = HSLtoRGB(255.0f, 255.0f, 255.0f);  // Default white
    float collisionRadius = GameConfig::INITIAL_SNAKE_SIZE;    // Default collision radius
};

// Spatial grid for faster food queries
struct FoodSpatialGrid {
    int cellSize = 200;
    int columns = 0;
    int rows = 0;
    Vector2 origin; // Play area top-left
    std::vector<std::vector<int>> cells;

    void Initialize(int cellSizeIn, float left, float top, float right, float bottom);
    void Clear();
    void Build(const FoodItem* foodList, int foodCount);
    void QueryRect(const Vector2& minPos, const Vector2& maxPos, std::vector<int>& outIndices) const;
};

// Extract repeated food position generation logic into a function
Vector2 GenerateRandomPosition();

void InitFood(FoodItem* foodList, int i, float speed);

void UpdateFoods(FoodItem* foodList, int foodCount);

// Build and access the shared food spatial grid.
void BuildFoodSpatialGrid(const FoodItem* foodList, int foodCount);
const FoodSpatialGrid* GetFoodSpatialGrid();
