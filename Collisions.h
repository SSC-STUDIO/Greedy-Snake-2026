#pragma once
#include "Vector2.h"
#include "Snake.h" 

// 前向声明
class Snake;
class PlayerSnake;
class AISnake;
struct FoodItem;

class CollisionManager {
public:
    static bool CheckCircleCollision(const Vector2& pos1, float radius1, const Vector2& pos2, float radius2);
    
    // 只检查蛇头碰撞的基本函数
    static bool CheckSnakeCollision(const Snake& snake1, const Snake& snake2);
    
    // 修改签名，添加foodList参数
    static void CheckCollisions(Snake* snake, AISnake* aiSnakes, int aiSnakeCount, 
                               FoodItem* foodList, int foodCount);
};