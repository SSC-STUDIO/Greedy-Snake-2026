#pragma once
#include "../Core/Vector2.h"
#include "../Core/GameConfig.h"
#include "../Gameplay/GameState.h"
#include "../Core/Camera.h"
#include "../Gameplay/Food.h"
#include "../Gameplay/Snake.h"

class Snake;
class PlayerSnake;
class AISnake;
struct FoodItem;

void DrawGameArea();
void DrawFoods(const FoodItem* foodList, int foodCount);
void DrawVisibleObjects(const FoodItem* foodList, int foodCount, 
                        const AISnake* aiSnakes, int aiSnakeCount,
                        const PlayerSnake& playerSnake);
void DrawCircleWithCamera(const Vector2& screenPos, float r, int c);
void DebugDrawText(const std::wstring& text, int x, int y, int color);
void DrawSnakeEyes(const Vector2& position, const Vector2& direction, float radius);
bool IsCircleInScreen(const Vector2& center, float r);
void DrawUI();
void DrawEnhancedFood(const Vector2& screenPos, float radius, int color, int index);

// 新增函数声明
void DrawSnakeSegment(const Vector2& screenPos, float radius, int color, int segmentIndex);
void DrawPauseMenu();