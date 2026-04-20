#include "Food.h"
#include "../ModernCore/Random.h"
#include <atomic>

using GreedSnake::Random;

namespace {
int ClampInt(int value, int minValue, int maxValue) {
    if (value < minValue) return minValue;
    if (value > maxValue) return maxValue;
    return value;
}

int ComputeGridDimension(float minBound, float maxBound, int cellSize) {
    return static_cast<int>((maxBound - minBound) / cellSize) + 1;
}

FoodSpatialGrid g_foodGrids[2];
std::atomic<int> g_foodGridIndex{0};
}

void FoodSpatialGrid::Initialize(int cellSizeIn, float left, float top, float right, float bottom) {
    cellSize = cellSizeIn;
    origin = Vector2(left, top);

    const float width = right - left;
    const float height = bottom - top;

    columns = static_cast<int>(width / cellSize) + 1;
    rows = static_cast<int>(height / cellSize) + 1;

    cells.clear();
    cells.resize(columns * rows);
}

bool FoodSpatialGrid::MatchesConfiguration(int cellSizeIn, float left, float top, float right, float bottom) const {
    if (cellSize != cellSizeIn) {
        return false;
    }

    if (origin.x != left || origin.y != top) {
        return false;
    }

    return columns == ComputeGridDimension(left, right, cellSizeIn) &&
        rows == ComputeGridDimension(top, bottom, cellSizeIn);
}

void FoodSpatialGrid::Clear() {
    for (auto& cell : cells) {
        cell.clear();
    }
}

void FoodSpatialGrid::Build(const FoodItem* foodList, int foodCount) {
    if (!foodList || foodCount <= 0 || columns == 0 || rows == 0) {
        return;
    }

    Clear();

    for (int i = 0; i < foodCount; ++i) {
        if (foodList[i].collisionRadius <= 0) continue;

        const Vector2& pos = foodList[i].position;
        int cellX = static_cast<int>((pos.x - origin.x) / cellSize);
        int cellY = static_cast<int>((pos.y - origin.y) / cellSize);

        cellX = ClampInt(cellX, 0, columns - 1);
        cellY = ClampInt(cellY, 0, rows - 1);

        cells[cellY * columns + cellX].push_back(i);
    }
}

void FoodSpatialGrid::QueryRect(const Vector2& minPos, const Vector2& maxPos, std::vector<int>& outIndices) const {
    if (columns == 0 || rows == 0) {
        return;
    }

    outIndices.clear();

    int minCellX = static_cast<int>((minPos.x - origin.x) / cellSize);
    int minCellY = static_cast<int>((minPos.y - origin.y) / cellSize);
    int maxCellX = static_cast<int>((maxPos.x - origin.x) / cellSize);
    int maxCellY = static_cast<int>((maxPos.y - origin.y) / cellSize);

    minCellX = ClampInt(minCellX, 0, columns - 1);
    minCellY = ClampInt(minCellY, 0, rows - 1);
    maxCellX = ClampInt(maxCellX, 0, columns - 1);
    maxCellY = ClampInt(maxCellY, 0, rows - 1);

    for (int y = minCellY; y <= maxCellY; ++y) {
        for (int x = minCellX; x <= maxCellX; ++x) {
            const auto& cell = cells[y * columns + x];
            outIndices.insert(outIndices.end(), cell.begin(), cell.end());
        }
    }
}

void BuildFoodSpatialGrid(const FoodItem* foodList, int foodCount) {
    const int nextIndex = 1 - g_foodGridIndex.load(std::memory_order_relaxed);
    FoodSpatialGrid& grid = g_foodGrids[nextIndex];
    const float left = static_cast<float>(GameConfig::PLAY_AREA_LEFT);
    const float top = static_cast<float>(GameConfig::PLAY_AREA_TOP);
    const float right = static_cast<float>(GameConfig::PLAY_AREA_RIGHT);
    const float bottom = static_cast<float>(GameConfig::PLAY_AREA_BOTTOM);

    if (!grid.MatchesConfiguration(GameConfig::FOOD_GRID_CELL_SIZE, left, top, right, bottom)) {
        grid.Initialize(
            GameConfig::FOOD_GRID_CELL_SIZE,
            left,
            top,
            right,
            bottom);
    }

    grid.Build(foodList, foodCount);
    g_foodGridIndex.store(nextIndex, std::memory_order_release);
}

void ResetFoodSpatialGrid() {
    for (FoodSpatialGrid& grid : g_foodGrids) {
        grid = FoodSpatialGrid{};
    }
    g_foodGridIndex.store(0, std::memory_order_release);
}

const FoodSpatialGrid* GetFoodSpatialGrid() {
    const int index = g_foodGridIndex.load(std::memory_order_acquire);
    if (g_foodGrids[index].columns == 0 || g_foodGrids[index].rows == 0) {
        return nullptr;
    }
    return &g_foodGrids[index];
}

Vector2 GenerateRandomPosition() {
    float x = static_cast<float>(Random::Int(GameConfig::PLAY_AREA_LEFT, GameConfig::PLAY_AREA_RIGHT));
    float y = static_cast<float>(Random::Int(GameConfig::PLAY_AREA_TOP, GameConfig::PLAY_AREA_BOTTOM));
    return Vector2(x, y);
}

void InitFood(FoodItem* foodList, int i, float speed) {
    // Add parameter check
    if (!foodList || i < 0 || i >= GameConfig::MAX_FOOD_COUNT) {
        return; // Invalid parameters, return early
    }

    foodList[i].position = GenerateRandomPosition();
    foodList[i].colorValue = ColorGenerator::GenerateRandomColor();
    foodList[i].collisionRadius = Random::Float(2.0f, 7.0f);
}

void UpdateFoods(FoodItem* foodList, int foodCount) {
    for (int i = 0; i < foodCount; i++) {
        // Only respawn food when collision radius is 0, indicating the food was eaten
        if (foodList[i].collisionRadius <= 0) {
            if (Random::Float(0.0f, 1.0f) < GameState::Instance().foodSpawnRate) {
                InitFood(foodList, i, GameState::Instance().currentPlayerSpeed);
            }
        }
    }

    BuildFoodSpatialGrid(foodList, foodCount);
}
