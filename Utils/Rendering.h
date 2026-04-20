/**
 * @file Rendering.h
 * @brief 渲染系统头文件
 */

#pragma once
#include "../ModernCore/Vector2.h"
#include "../Gameplay/GameConfig.h"
#include "../Core/GameState.h"
#include "../Core/Camera.h"
#include "../Gameplay/Food.h"
#include "../Gameplay/Snake.h"
#include <cstddef>

using Vector2 = GreedSnake::Vector2;

// 前向声明
class Snake;
class PlayerSnake;
class AISnake;
struct FoodItem;

// 渲染函数声明
void DrawGameArea(); // 绘制游戏主区域
void DrawFoods(const FoodItem* foodList, int foodCount); // 绘制食物
void DrawVisibleObjects(const FoodItem* foodList, int foodCount, 
                        const AISnake* aiSnakes, int aiSnakeCount,
                        const PlayerSnake& playerSnake); // 绘制所有可见游戏对象
void DrawCircleWithCamera(const Vector2& screenPos, float r, int c); // 绘制考虑相机位置的圆
void DebugDrawText(const std::wstring& text, int x, int y, int color); // 绘制调试文本
void DrawSnakeEyes(const Vector2& position, const Vector2& direction, float radius); // 绘制蛇眼
bool IsCircleInScreen(const Vector2& center, float r); // 检查圆是否在屏幕范围内
void DrawUI(); // 绘制用户界面元素
void DrawEnhancedFood(const Vector2& screenPos, float radius, int color, int index, int detailLevel); // 绘制增强视觉效果的食物
void DrawSnakeSegment(const Vector2& screenPos, float radius, int color, size_t segmentIndex); // 绘制蛇段
void DrawPauseMenu(); // 绘制暂停菜单
