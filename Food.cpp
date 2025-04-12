#include "Food.h"

Vector2 GenerateRandomPosition() {
    float x = GameConfig::PLAY_AREA_LEFT +
        rand() % (GameConfig::PLAY_AREA_RIGHT - GameConfig::PLAY_AREA_LEFT);
    float y = GameConfig::PLAY_AREA_TOP +
        rand() % (GameConfig::PLAY_AREA_BOTTOM - GameConfig::PLAY_AREA_TOP);
    return Vector2(x, y);
}

void InitFood(FoodItem* foodList, int i, float speed) {
    // Add parameter check
    if (!foodList || i < 0 || i >= GameConfig::MAX_FOOD_COUNT) {
        return; // Invalid parameters, return early
    }
    
    foodList[i].position = GenerateRandomPosition();
    foodList[i].colorValue = ColorGenerator::GenerateRandomColor();
    foodList[i].collisionRadius = (rand() % 5000) / 1000.0f + 2;
}

void UpdateFoods(FoodItem* foodList, int foodCount) {
    for (int i = 0; i < foodCount; i++) {
        // Only respawn food when collision radius is 0, indicating the food was eaten
        if (foodList[i].collisionRadius <= 0) {
            if (rand() % 100 < (GameState::Instance().foodSpawnRate * 100)) {
                InitFood(foodList, i, GameState::Instance().currentPlayerSpeed);
            }
        }
    }
}