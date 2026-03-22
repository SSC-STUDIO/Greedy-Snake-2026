#include "Rendering.h"
#include "../Core/GameRuntime.h"
#include "DrawHelpers.h"
#include <cmath>
#pragma warning(disable: 4996)

void DrawGameArea() {
    GameRuntime().animationTimer += 0.05f;

    setbkcolor(RGB(20, 20, 20));
    cleardevice();

    setfillcolor(RGB(40, 40, 40));
    int cellSize = GameConfig::GRID_CELL_SIZE;
    int cols = GameConfig::WINDOW_WIDTH / cellSize;
    int rows = GameConfig::WINDOW_HEIGHT / cellSize;

    for (int i = 0; i <= cols; i++) {
        for (int j = 0; j <= rows; j++) {
            int x = i * cellSize;
            int y = j * cellSize;
            rectangle(x, y, x + cellSize, y + cellSize);
        }
    }

    setfillcolor(RGB(50, 30, 30));
    int borderWidth = 10;
    solidrectangle(0, 0, GameConfig::WINDOW_WIDTH, borderWidth);
    solidrectangle(0, GameConfig::WINDOW_HEIGHT - borderWidth, GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT);
    solidrectangle(0, 0, borderWidth, GameConfig::WINDOW_HEIGHT);
    solidrectangle(GameConfig::WINDOW_WIDTH - borderWidth, 0, GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT);

    setlinecolor(RGB(150, 50, 50));
    setlinestyle(PS_SOLID, 3);
    rectangle(borderWidth, borderWidth,
              GameConfig::WINDOW_WIDTH - borderWidth,
              GameConfig::WINDOW_HEIGHT - borderWidth);
    setlinestyle(PS_SOLID, 1);
}

void DrawFoods(const FoodItem* foodList, int foodCount) {
    const FoodSpatialGrid* foodGrid = GetFoodSpatialGrid();

    for (int i = 0; i < foodCount; i++) {
        if (foodList[i].collisionRadius <= 0) continue;

        int x = static_cast<int>(foodList[i].position.x);
        int y = static_cast<int>(foodList[i].position.y);
        int radius = static_cast<int>(foodList[i].collisionRadius);

        setfillcolor(foodList[i].colorValue);
        setlinecolor(foodList[i].colorValue);
        fillcircle(x, y, radius);
    }
}

void DrawVisibleObjects(const FoodItem* foodList, int foodCount,
                        const AISnake* aiSnakes, int aiSnakeCount,
                        const PlayerSnake& playerSnake) {
    DrawFoods(foodList, foodCount);

    for (int i = 0; i < aiSnakeCount; i++) {
        if (aiSnakes[i].radius <= 0 || aiSnakes[i].isDead) continue;
        aiSnakes[i].Draw(GameState::Instance().camera);
    }

    playerSnake.Draw(GameState::Instance().camera);
}

void DrawCircleWithCamera(const Vector2& screenPos, float r, int c) {
    setfillcolor(c);
    setlinecolor(c);
    fillcircle(static_cast<int>(screenPos.x), static_cast<int>(screenPos.y), static_cast<int>(r));
}

void DebugDrawText(const std::wstring& text, int x, int y, int color) {
    settextstyle(16, 0, _T("Arial"));
    settextcolor(color);
    outtextxy(x, y, text.c_str());
}

void DrawSnakeEyes(const Vector2& position, const Vector2& direction, float radius) {
    Vector2 eyeOffset = direction * radius * 0.4f;
    Vector2 perpOffset(direction.y, -direction.x);

    Vector2 eye1 = position + eyeOffset + perpOffset * radius * 0.4f;
    Vector2 eye2 = position + eyeOffset - perpOffset * radius * 0.4f;

    setfillcolor(RGB(255, 255, 255));
    fillcircle(static_cast<int>(eye1.x), static_cast<int>(eye1.y), static_cast<int>(radius * 0.2f));
    fillcircle(static_cast<int>(eye2.x), static_cast<int>(eye2.y), static_cast<int>(radius * 0.2f));

    setfillcolor(RGB(0, 0, 0));
    fillcircle(static_cast<int>(eye1.x + direction.x * radius * 0.1f),
               static_cast<int>(eye1.y + direction.y * radius * 0.1f),
               static_cast<int>(radius * 0.1f));
    fillcircle(static_cast<int>(eye2.x + direction.x * radius * 0.1f),
               static_cast<int>(eye2.y + direction.y * radius * 0.1f),
               static_cast<int>(radius * 0.1f));
}

bool IsCircleInScreen(const Vector2& center, float r) {
    return true;
}

void DrawUI() {
}

void DrawEnhancedFood(const Vector2& screenPos, float radius, int color, int index) {
    DrawCircleWithCamera(screenPos, radius, color);
}

void DrawSnakeSegment(const Vector2& screenPos, float radius, int color, size_t segmentIndex) {
    DrawCircleWithCamera(screenPos, radius, color);
}

void DrawPauseMenu() {
}