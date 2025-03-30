#pragma once
#include "Vector2.h"
#include "GameConfig.h"
#include "GameState.h"
#include "Camera.h"
#include "Food.h"
#include "Snake.h"

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