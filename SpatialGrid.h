#pragma once
#include "Vector2.h"
#include "GameConfig.h"
#include "GameState.h"
#include "Camera.h"
#include "Rendering.h"
#include "Food.h"
#include <queue>
#include <deque>
#include <vector>

class SpatialGrid {
private:
    struct Cell {
        std::vector<int> foodIndices;
        std::vector<int> aiSnakeIndices;
        bool hasPlayerSnake = false;
    };

    std::vector<Cell> grid;
    int gridWidth, gridHeight;
    float cellSize;

public:
    SpatialGrid(float worldWidth, float worldHeight, float cellSize)
        : cellSize(cellSize) {
        gridWidth = static_cast<int>(worldWidth / cellSize) + 1;
        gridHeight = static_cast<int>(worldHeight / cellSize) + 1;
        grid.resize(gridWidth * gridHeight);
    }

    void Clear() {
        for (auto& cell : grid) {
            cell.foodIndices.clear();
            cell.aiSnakeIndices.clear();
            cell.hasPlayerSnake = false;
        }
    }

    void AddFood(int foodIndex, const Vector2& position) {
        int cellX = static_cast<int>((position.x - GameConfig::PLAY_AREA_LEFT) / cellSize);
        int cellY = static_cast<int>((position.y - GameConfig::PLAY_AREA_TOP) / cellSize);

        if (IsValidCell(cellX, cellY)) {
            grid[cellY * gridWidth + cellX].foodIndices.push_back(foodIndex);
        }
    }

    void AddAISnake(int snakeIndex, const Vector2& position) {
        int cellX = static_cast<int>((position.x - GameConfig::PLAY_AREA_LEFT) / cellSize);
        int cellY = static_cast<int>((position.y - GameConfig::PLAY_AREA_TOP) / cellSize);

        if (IsValidCell(cellX, cellY)) {
            grid[cellY * gridWidth + cellX].aiSnakeIndices.push_back(snakeIndex);
        }
    }

    void AddPlayerSnake(const Vector2& position) {
        int cellX = static_cast<int>((position.x - GameConfig::PLAY_AREA_LEFT) / cellSize);
        int cellY = static_cast<int>((position.y - GameConfig::PLAY_AREA_TOP) / cellSize);

        if (IsValidCell(cellX, cellY)) {
            grid[cellY * gridWidth + cellX].hasPlayerSnake = true;
        }
    }

    std::vector<int> GetNearbyFoods(const Vector2& position, float radius) {
        std::vector<int> result;
        GetNearbyCellContents(position, radius, [&](const Cell& cell) {
            result.insert(result.end(), cell.foodIndices.begin(), cell.foodIndices.end());
            });
        return result;
    }

    std::vector<int> GetNearbyAISnakes(const Vector2& position, float radius) {
        std::vector<int> result;
        GetNearbyCellContents(position, radius, [&](const Cell& cell) {
            result.insert(result.end(), cell.aiSnakeIndices.begin(), cell.aiSnakeIndices.end());
            });
        return result;
    }

    bool IsPlayerSnakeNearby(const Vector2& position, float radius) {
        bool found = false;
        GetNearbyCellContents(position, radius, [&](const Cell& cell) {
            if (cell.hasPlayerSnake) found = true;
            });
        return found;
    }

private:
    bool IsValidCell(int x, int y) const {
        return x >= 0 && x < gridWidth && y >= 0 && y < gridHeight;
    }

    template <typename Func>
    void GetNearbyCellContents(const Vector2& position, float radius, Func callback) {
        int minCellX = static_cast<int>((position.x - radius - GameConfig::PLAY_AREA_LEFT) / cellSize);
        int maxCellX = static_cast<int>((position.x + radius - GameConfig::PLAY_AREA_LEFT) / cellSize);
        int minCellY = static_cast<int>((position.y - radius - GameConfig::PLAY_AREA_TOP) / cellSize);
        int maxCellY = static_cast<int>((position.y + radius - GameConfig::PLAY_AREA_TOP) / cellSize);

        minCellX = max(0, minCellX);
        maxCellX = min(gridWidth - 1, maxCellX);
        minCellY = max(0, minCellY);
        maxCellY = min(gridHeight - 1, maxCellY);

        for (int y = minCellY; y <= maxCellY; ++y) {
            for (int x = minCellX; x <= maxCellX; ++x) {
                callback(grid[y * gridWidth + x]);
            }
        }
    }
};