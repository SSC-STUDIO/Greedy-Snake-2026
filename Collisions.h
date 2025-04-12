#pragma once
#include "Vector2.h"
#include "Snake.h" 

// Forward declarations
class Snake;
class PlayerSnake;
class AISnake;
struct FoodItem;

class CollisionManager {
public:
    static bool CheckCircleCollision(const Vector2& pos1, float radius1, const Vector2& pos2, float radius2);
    
    // Basic function that only checks snake head collisions
    static bool CheckSnakeCollision(const Snake& snake1, const Snake& snake2);
    
    // Modified signature, added foodList parameter
    static void CheckCollisions(Snake* snake, AISnake* aiSnakes, int aiSnakeCount, 
                               FoodItem* foodList, int foodCount);
};
void DrawEatAISnakeEffect(const Vector2& position, int color, float radius);
void DrawAISnakeHitPlayerEffect(const Vector2& position, int color, float radius);