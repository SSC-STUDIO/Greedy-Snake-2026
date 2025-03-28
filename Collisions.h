// 碰撞检测系统
#include "Vector2.h"
#include <vector>

class CollisionManager {
public:
    static bool CheckCircleCollision(const Vector2& pos1, float radius1, const Vector2& pos2, float radius2) {
        float distance = (pos1 - pos2).GetLength();
        return distance < (radius1 + radius2);
    }

    static bool CheckSnakeCollision(const Vector2& snakeHeadPos, float snakeHeadRadius, const std::vector<AISnake>& aiSnakes) {
        // 遍历所有AI蛇
        for (const auto& aiSnake : aiSnakes) {
            // 检查与AI蛇头的碰撞
            if (CheckCircleCollision(snakeHeadPos, snakeHeadRadius, aiSnake.position, aiSnake.radius)) {
                return true;
            }

            // 检查与AI蛇身体段的碰撞
            for (const auto& segment : aiSnake.segments) {
                if (CheckCircleCollision(snakeHeadPos, snakeHeadRadius, segment.position, segment.radius)) {
                    return true;
                }
            }
        }
        return false;
    }
};