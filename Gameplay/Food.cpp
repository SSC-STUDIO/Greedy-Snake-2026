#include "Food.h"
#include <atomic>
#include <algorithm>

namespace {

/**
 * @brief 安全地限制整数值在指定范围内
 * @param value 输入值
 * @param minValue 最小允许值
 * @param maxValue 最大允许值
 * @return 限制后的值
 */
int ClampInt(int value, int minValue, int maxValue) {
    if (value < minValue) return minValue;
    if (value > maxValue) return maxValue;
    return value;
}

/**
 * @brief 验证浮点值是否在有效范围内
 * @param value 输入值
 * @param minValue 最小允许值
 * @param maxValue 最大允许值
 * @return true 如果在范围内
 */
bool ValidateFloatRange(float value, float minValue, float maxValue) {
    if (std::isnan(value) || std::isinf(value)) return false;
    return value >= minValue && value <= maxValue;
}

/**
 * @brief 验证网格坐标是否有效
 * @param x X坐标
 * @param y Y坐标
 * @param maxX 最大X值
 * @param maxY 最大Y值
 * @return true 如果坐标有效
 */
bool ValidateGridCoords(int x, int y, int maxX, int maxY) {
    return x >= 0 && x < maxX && y >= 0 && y < maxY;
}

// 双缓冲食物网格，用于线程安全
FoodSpatialGrid g_foodGrids[2];
std::atomic<int> g_foodGridIndex{0};

// 食物生成计数器，用于防止无限生成
int g_foodSpawnCounter = 0;
const int MAX_SPAWN_ATTEMPTS = 100;

} // anonymous namespace

void FoodSpatialGrid::Initialize(int cellSizeIn, float left, float top, float right, float bottom) {
    // 输入验证
    if (cellSizeIn <= 0) {
        OutputDebugStringA("FoodSpatialGrid::Initialize: Invalid cell size\n");
        return;
    }
    
    if (left >= right || top >= bottom) {
        OutputDebugStringA("FoodSpatialGrid::Initialize: Invalid bounds\n");
        return;
    }
    
    // 限制网格大小以防止内存溢出
    const float MAX_GRID_DIMENSION = 10000.0f;
    if (right - left > MAX_GRID_DIMENSION || bottom - top > MAX_GRID_DIMENSION) {
        OutputDebugStringA("FoodSpatialGrid::Initialize: Grid dimensions too large\n");
        return;
    }

    cellSize = cellSizeIn;
    origin = Vector2(left, top);

    const float width = right - left;
    const float height = bottom - top;

    // 使用safe calculation防止整数溢出
    columns = std::min(static_cast<int>(width / cellSize) + 1, 1000);
    rows = std::min(static_cast<int>(height / cellSize) + 1, 1000);

    try {
        cells.clear();
        cells.resize(static_cast<size_t>(columns) * rows);
    } catch (const std::bad_alloc& e) {
        OutputDebugStringA("FoodSpatialGrid::Initialize: Memory allocation failed\n");
        columns = 0;
        rows = 0;
        cells.clear();
    }
}

void FoodSpatialGrid::Clear() {
    for (auto& cell : cells) {
        cell.clear();
        // 释放内存到系统
        std::vector<int>().swap(cell);
    }
}

void FoodSpatialGrid::Build(const FoodItem* foodList, int foodCount) {
    // 参数验证
    if (!foodList || foodCount <= 0 || foodCount > GameConfig::MAX_FOOD_COUNT) {
        OutputDebugStringA("FoodSpatialGrid::Build: Invalid parameters\n");
        return;
    }
    
    if (columns <= 0 || rows <= 0) {
        OutputDebugStringA("FoodSpatialGrid::Build: Grid not initialized\n");
        return;
    }

    Clear();

    for (int i = 0; i < foodCount; ++i) {
        // 验证食物项有效性
        if (foodList[i].collisionRadius <= 0) continue;
        
        // 验证位置有效性
        const Vector2& pos = foodList[i].position;
        if (!ValidateFloatRange(pos.x, -10000.0f, 10000.0f) || 
            !ValidateFloatRange(pos.y, -10000.0f, 10000.0f)) {
            continue;
        }

        int cellX = static_cast<int>((pos.x - origin.x) / cellSize);
        int cellY = static_cast<int>((pos.y - origin.y) / cellSize);

        cellX = ClampInt(cellX, 0, columns - 1);
        cellY = ClampInt(cellY, 0, rows - 1);

        // 最终边界检查
        if (ValidateGridCoords(cellX, cellY, columns, rows)) {
            size_t index = static_cast<size_t>(cellY) * columns + cellX;
            if (index < cells.size()) {
                cells[index].push_back(i);
            }
        }
    }
}

void FoodSpatialGrid::QueryRect(const Vector2& minPos, const Vector2& maxPos, std::vector<int>& outIndices) const {
    outIndices.clear();
    
    if (columns <= 0 || rows <= 0) {
        return;
    }

    // 验证输入坐标
    if (!ValidateFloatRange(minPos.x, -10000.0f, 10000.0f) ||
        !ValidateFloatRange(minPos.y, -10000.0f, 10000.0f) ||
        !ValidateFloatRange(maxPos.x, -10000.0f, 10000.0f) ||
        !ValidateFloatRange(maxPos.y, -10000.0f, 10000.0f)) {
        OutputDebugStringA("FoodSpatialGrid::QueryRect: Invalid coordinates\n");
        return;
    }

    int minCellX = static_cast<int>((minPos.x - origin.x) / cellSize);
    int minCellY = static_cast<int>((minPos.y - origin.y) / cellSize);
    int maxCellX = static_cast<int>((maxPos.x - origin.x) / cellSize);
    int maxCellY = static_cast<int>((maxPos.y - origin.y) / cellSize);

    minCellX = ClampInt(minCellX, 0, columns - 1);
    minCellY = ClampInt(minCellY, 0, rows - 1);
    maxCellX = ClampInt(maxCellX, 0, columns - 1);
    maxCellY = ClampInt(maxCellY, 0, rows - 1);

    // 预分配空间以优化性能
    size_t estimatedSize = 0;
    for (int y = minCellY; y <= maxCellY; ++y) {
        for (int x = minCellX; x <= maxCellX; ++x) {
            size_t index = static_cast<size_t>(y) * columns + x;
            if (index < cells.size()) {
                estimatedSize += cells[index].size();
            }
        }
    }
    outIndices.reserve(std::min(estimatedSize, static_cast<size_t>(GameConfig::MAX_FOOD_COUNT)));

    for (int y = minCellY; y <= maxCellY; ++y) {
        for (int x = minCellX; x <= maxCellX; ++x) {
            size_t index = static_cast<size_t>(y) * columns + x;
            if (index < cells.size()) {
                const auto& cell = cells[index];
                outIndices.insert(outIndices.end(), cell.begin(), cell.end());
            }
        }
    }
}

void BuildFoodSpatialGrid(const FoodItem* foodList, int foodCount) {
    // 参数验证
    if (!foodList || foodCount <= 0 || foodCount > GameConfig::MAX_FOOD_COUNT) {
        OutputDebugStringA("BuildFoodSpatialGrid: Invalid parameters\n");
        return;
    }

    const int nextIndex = 1 - g_foodGridIndex.load(std::memory_order_relaxed);
    FoodSpatialGrid& grid = g_foodGrids[nextIndex];

    if (grid.columns == 0 || grid.rows == 0) {
        grid.Initialize(
            GameConfig::FOOD_GRID_CELL_SIZE,
            static_cast<float>(GameConfig::PLAY_AREA_LEFT),
            static_cast<float>(GameConfig::PLAY_AREA_TOP),
            static_cast<float>(GameConfig::PLAY_AREA_RIGHT),
            static_cast<float>(GameConfig::PLAY_AREA_BOTTOM));
    }

    grid.Build(foodList, foodCount);
    g_foodGridIndex.store(nextIndex, std::memory_order_release);
}

const FoodSpatialGrid* GetFoodSpatialGrid() {
    const int index = g_foodGridIndex.load(std::memory_order_acquire);
    if (index < 0 || index >= 2) {
        return nullptr;
    }
    if (g_foodGrids[index].columns == 0 || g_foodGrids[index].rows == 0) {
        return nullptr;
    }
    return &g_foodGrids[index];
}

Vector2 GenerateRandomPosition() {
    // 计算安全范围
    int rangeX = GameConfig::PLAY_AREA_RIGHT - GameConfig::PLAY_AREA_LEFT;
    int rangeY = GameConfig::PLAY_AREA_BOTTOM - GameConfig::PLAY_AREA_TOP;
    
    // 验证范围有效性
    if (rangeX <= 0 || rangeY <= 0) {
        OutputDebugStringA("GenerateRandomPosition: Invalid play area\n");
        return Vector2(0.0f, 0.0f);
    }

    // 使用更安全的随机数生成
    float x = static_cast<float>(GameConfig::PLAY_AREA_LEFT) +
        static_cast<float>(rand() % rangeX);
    float y = static_cast<float>(GameConfig::PLAY_AREA_TOP) +
        static_cast<float>(rand() % rangeY);
    
    return Vector2(x, y);
}

void InitFood(FoodItem* foodList, int i, float speed) {
    // 参数检查
    if (!foodList || i < 0 || i >= GameConfig::MAX_FOOD_COUNT) {
        OutputDebugStringA("InitFood: Invalid parameters\n");
        return;
    }
    
    // 防止无限生成
    g_foodSpawnCounter++;
    if (g_foodSpawnCounter > MAX_SPAWN_ATTEMPTS) {
        OutputDebugStringA("InitFood: Too many spawn attempts\n");
        g_foodSpawnCounter = 0;
        return;
    }
    
    // 验证速度参数
    if (!ValidateFloatRange(speed, 0.0f, 1000.0f)) {
        speed = GameConfig::PLAYER_NORMAL_SPEED;
    }
    
    // 生成位置
    Vector2 pos = GenerateRandomPosition();
    
    // 验证生成的位置
    if (!ValidateFloatRange(pos.x, -10000.0f, 10000.0f) || 
        !ValidateFloatRange(pos.y, -10000.0f, 10000.0f)) {
        OutputDebugStringA("InitFood: Invalid position generated\n");
        return;
    }
    
    foodList[i].position = pos;
    foodList[i].colorValue = ColorGenerator::GenerateRandomColor();
    
    // 安全地计算碰撞半径
    const float MIN_RADIUS = 2.0f;
    const float MAX_RADIUS = 7.0f;
    float radius = (rand() % 5000) / 1000.0f + MIN_RADIUS;
    foodList[i].collisionRadius = ClampInt(static_cast<int>(radius), static_cast<int>(MIN_RADIUS), static_cast<int>(MAX_RADIUS));
}

void UpdateFoods(FoodItem* foodList, int foodCount) {
    // 参数验证
    if (!foodList || foodCount <= 0 || foodCount > GameConfig::MAX_FOOD_COUNT) {
        OutputDebugStringA("UpdateFoods: Invalid parameters\n");
        return;
    }
    
    // 重置生成计数器
    g_foodSpawnCounter = 0;

    for (int i = 0; i < foodCount; i++) {
        // 只重新生成被吃掉的食物（碰撞半径为0）
        if (foodList[i].collisionRadius <= 0) {
            // 安全地计算生成概率
            float spawnRate = GameState::Instance().foodSpawnRate;
            if (!ValidateFloatRange(spawnRate, 0.0f, 1.0f)) {
                spawnRate = 0.5f; // 使用默认值
            }
            
            if (rand() % 100 < static_cast<int>(spawnRate * 100)) {
                float speed = GameState::Instance().currentPlayerSpeed;
                if (!ValidateFloatRange(speed, 0.0f, 1000.0f)) {
                    speed = GameConfig::PLAYER_NORMAL_SPEED;
                }
                InitFood(foodList, i, speed);
            }
        }
    }

    BuildFoodSpatialGrid(foodList, foodCount);
}
