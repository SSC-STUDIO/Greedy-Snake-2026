#include "Snake.h"
#include "../Core/Collisions.h"
#include "../Utils/DrawHelpers.h"
#include <algorithm>
#include <limits>

namespace {

// 常量定义
constexpr float MAX_POSITION_VALUE = 10000.0f;
constexpr float MIN_POSITION_VALUE = -10000.0f;
constexpr float MAX_SPEED = 1000.0f;
constexpr size_t MAX_SEGMENTS = 10000;

/**
 * @brief 验证浮点值是否在有效范围内
 * @param value 输入值
 * @return true 如果值有效
 */
bool IsValidFloat(float value) {
    return !std::isnan(value) && !std::isinf(value) && 
           value >= MIN_POSITION_VALUE && value <= MAX_POSITION_VALUE;
}

/**
 * @brief 限制浮点值范围
 * @param value 输入值
 * @param min 最小值
 * @param max 最大值
 * @return 限制后的值
 */
float ClampFloat(float value, float min, float max) {
    if (std::isnan(value) || std::isinf(value)) return min;
    if (value < min) return min;
    if (value > max) return max;
    return value;
}

/**
 * @brief 验证Vector2是否有效
 * @param vec 向量
 * @return true 如果有效
 */
bool IsValidVector2(const Vector2& vec) {
    return IsValidFloat(vec.x) && IsValidFloat(vec.y);
}

/**
 * @brief 安全地调整vector大小
 * @param vec 向量
 * @param newSize 新大小
 * @return true 如果成功
 */
template<typename T>
bool SafeResize(std::vector<T>& vec, size_t newSize) {
    if (newSize > MAX_SEGMENTS) {
        OutputDebugStringA("SafeResize: Size limit exceeded\n");
        return false;
    }
    try {
        vec.resize(newSize);
        return true;
    } catch (const std::bad_alloc&) {
        OutputDebugStringA("SafeResize: Memory allocation failed\n");
        return false;
    }
}

} // anonymous namespace

Vector2 SnakeSegment::GetVelocity() const
{
    if (!IsValidVector2(direction)) {
        return Vector2(0, 0);
    }
    float speed = GameState::Instance().currentPlayerSpeed;
    if (!IsValidFloat(speed) || speed < 0 || speed > MAX_SPEED) {
        speed = GameConfig::PLAYER_NORMAL_SPEED;
    }
    return direction.GetNormalize() * speed;
}

bool SnakeSegment::CanRecordPosition() const {
    float interval = GameState::Instance().recordInterval;
    if (std::isnan(interval) || std::isinf(interval) || interval <= 0) {
        return false;
    }
    return timeSinceLastRecord >= interval;
}

void Snake::Update(float deltaTime)
{
    // 验证deltaTime
    if (std::isnan(deltaTime) || std::isinf(deltaTime) || deltaTime < 0 || deltaTime > 10.0f) {
        deltaTime = 1.0f / 60.0f;
    }

    if (!gridSnake) {
        currentTime += deltaTime;
        if (IsBeginRecord()) {
            RecordPos();
            currentTime = 0;
        }
        return;
    }
}

Vector2 Snake::GetVelocity() const
{
    if (!IsValidVector2(direction)) {
        return Vector2(0, 0);
    }
    float speed = GameState::Instance().currentPlayerSpeed;
    if (!IsValidFloat(speed) || speed < 0 || speed > MAX_SPEED) {
        speed = GameConfig::PLAYER_NORMAL_SPEED;
    }
    return direction.GetNormalize() * speed;
}

bool Snake::IsBeginRecord() const
{
    float interval = GameState::Instance().recordInterval;
    if (std::isnan(interval) || std::isinf(interval) || interval <= 0) {
        return false;
    }
    return currentTime >= interval;
}

void Snake::RecordPos()
{
    // 验证当前位置
    if (!IsValidVector2(position)) {
        OutputDebugStringA("Snake::RecordPos: Invalid position\n");
        return;
    }

    float distanceToLast = 0;
    if (!posRecords.empty()) {
        if (IsValidVector2(posRecords.back())) {
            distanceToLast = (position - posRecords.back()).GetLength();
        }
    }

    if (distanceToLast >= GameConfig::SNAKE_SEGMENT_SPACING) {
        // 限制队列大小以防止内存无限增长
        const size_t MAX_QUEUE_SIZE = 100;
        if (posRecords.size() >= MAX_QUEUE_SIZE) {
            posRecords.pop();
        }
        posRecords.push(position);
        while (posRecords.size() > 2) {
            posRecords.pop();
        }
    }
}

Vector2 Snake::GetRecordTime() const
{
    if (posRecords.empty()) {
        return position;
    }
    Vector2 record = posRecords.front();
    if (!IsValidVector2(record)) {
        return position;
    }
    return record;
}

void Snake::UpdateBody(const Snake& lastBody, Snake& currentBody)
{
    if (!IsValidVector2(lastBody.position) || !IsValidVector2(currentBody.position)) {
        OutputDebugStringA("Snake::UpdateBody: Invalid position\n");
        return;
    }

    Vector2 targetPos = lastBody.GetRecordTime();
    if (!IsValidVector2(targetPos)) {
        return;
    }

    Vector2 dir = (targetPos - currentBody.position);
    if (!IsValidVector2(dir)) {
        return;
    }

    Vector2 direction = dir.GetNormalize();
    if (!IsValidVector2(direction)) {
        return;
    }

    currentBody.position = targetPos - direction * GameConfig::SNAKE_SEGMENT_SPACING;
    
    // 验证新位置
    if (!IsValidVector2(currentBody.position)) {
        currentBody.position = targetPos;
    }
}

void Snake::MoveSnakeGrid(float deltaTime)
{
    // 验证deltaTime
    if (std::isnan(deltaTime) || std::isinf(deltaTime) || deltaTime < 0) {
        deltaTime = 1.0f / 60.0f;
    }

    // 验证移动间隔
    float interval = moveInterval;
    if (std::isnan(interval) || std::isinf(interval) || interval <= 0) {
        interval = 0.1f;
    }

    moveTimer += deltaTime;
    if (moveTimer < interval) {
        return;
    }
    moveTimer = 0.0f;

    // 验证并更新方向
    if (currentDir != nextDir) {
        Direction opposite = (currentDir == UP) ? DOWN : (currentDir == DOWN) ? UP :
                            (currentDir == LEFT) ? RIGHT : LEFT;
        if (nextDir != opposite && nextDir >= UP && nextDir <= RIGHT) {
            currentDir = nextDir;
        }
    }

    // 计算移动步长
    float step = GameConfig::SNAKE_SEGMENT_SPACING;
    if (std::isnan(step) || step <= 0) {
        step = 10.0f;
    }

    Vector2 oldPosition = position;

    // 移动蛇头
    switch (currentDir) {
        case UP: position.y -= step; break;
        case DOWN: position.y += step; break;
        case LEFT: position.x -= step; break;
        case RIGHT: position.x += step; break;
        default: break;
    }

    // 验证新位置
    if (!IsValidVector2(position)) {
        position = oldPosition;
        return;
    }

    // 更新方向向量
    switch (currentDir) {
        case UP: direction = Vector2(0, -1); break;
        case DOWN: direction = Vector2(0, 1); break;
        case LEFT: direction = Vector2(-1, 0); break;
        case RIGHT: direction = Vector2(1, 0); break;
        default: direction = Vector2(1, 0); break;
    }
}

void Snake::Draw(const Camera& camera) const
{
    if (!IsValidVector2(position)) {
        return;
    }
    Vector2 windowPos = position - camera.position;
    if (!IsValidVector2(windowPos)) {
        return;
    }
    DrawCircleWithCamera(windowPos, radius, color);
}

void PlayerSnake::Update(float deltaTime)
{
    if (isDead) return;

    // 验证deltaTime
    if (std::isnan(deltaTime) || std::isinf(deltaTime) || deltaTime < 0 || deltaTime > 10.0f) {
        deltaTime = 1.0f / 60.0f;
    }

    if (gridSnake) {
        Vector2 prevPos = position;
        MoveSnakeGrid(deltaTime);

        // 验证移动后的位置
        if (!IsValidVector2(position)) {
            position = prevPos;
            return;
        }

        for (size_t i = 0; i < segments.size(); i++) {
            if (!IsValidVector2(segments[i].position)) {
                continue;
            }
            Vector2 segPrevPos = segments[i].position;
            segments[i].position = prevPos;
            segments[i].direction = direction;
            prevPos = segPrevPos;
        }
    } else {
        Snake::Update(deltaTime);

        for (size_t i = 0; i < segments.size(); i++) {
            if (i == 0) {
                UpdateBody(*this, segments[i]);
            }
            else {
                UpdateBody(segments[i - 1], segments[i]);
            }
            segments[i].Update(deltaTime);
        }
    }
}

void PlayerSnake::Draw(const Camera& camera) const
{
    if (isDead) return;

    if (!IsValidVector2(position)) {
        return;
    }

    int baseR = (color >> 16) & 0xFF;
    int baseG = (color >> 8) & 0xFF;
    int baseB = color & 0xFF;

    for (size_t i = 0; i < segments.size(); i++) {
        const auto& segment = segments[i];
        if (segment.radius <= 0) continue;
        if (!IsValidVector2(segment.position)) continue;

        Vector2 windowPos = segment.position - camera.position;
        if (!IsValidVector2(windowPos)) continue;

        float ratio = static_cast<float>(i) / segments.size();
        int segR = baseR - static_cast<int>(ratio * baseR * 0.3f);
        int segG = baseG - static_cast<int>(ratio * baseG * 0.3f);
        int segB = baseB - static_cast<int>(ratio * baseB * 0.3f);
        
        // 确保颜色分量在有效范围内
        segR = ClampInt(segR, 0, 255);
        segG = ClampInt(segG, 0, 255);
        segB = ClampInt(segB, 0, 255);
        
        int segColor = RGB(segR, segG, segB);

        float sizeRatio = 1.0f - ratio * 0.3f;
        float segRadius = segment.radius * sizeRatio;
        if (segRadius <= 0) continue;

        setfillcolor(segColor);
        setlinecolor(segColor);
        fillcircle(windowPos.x, windowPos.y, segRadius);
    }

    Snake::Draw(camera);
    Vector2 windowPos = position - camera.position;
    if (IsValidVector2(windowPos)) {
        DrawSnakeEyes(windowPos, direction, radius);
    }

    // Debug info
    auto& gs = GameState::Instance();
    float invTime = gs.GetRemainingInvulnerabilityTime();
    float gst = gs.gameStartTime;
    float dt = gs.deltaTime;
    
    // 验证debug值
    if (std::isnan(gst)) gst = 0;
    if (std::isnan(dt)) dt = 0;

    TCHAR dbgText[64];
    _stprintf_s(dbgText, _T("gst:%.2f dt:%.4f"), gst, dt);
    settextstyle(12, 0, _T("Arial"));
    setbkmode(TRANSPARENT);
    settextcolor(RGB(0, 255, 0));
    outtextxy(10, 30, dbgText);
    
    if (invTime > 0.0f) {
        float pulseRadius = radius * 1.5f + sinf(invTime * 5.0f) * radius * 0.3f;
        setfillcolor(RGB(255, 255, 255));
        setlinecolor(RGB(200, 200, 255));
        setlinestyle(PS_SOLID, 2);
        fillcircle(windowPos.x, windowPos.y, pulseRadius);
        setlinestyle(PS_SOLID, 1);

        settextstyle(16, 0, _T("Arial"));
        setbkmode(TRANSPARENT);
        settextcolor(WHITE);
        TCHAR timeText[32];
        _stprintf_s(timeText, _T("%.1f"), invTime);
        int textW = textwidth(timeText);
        int textH = textheight(timeText);
        outtextxy(windowPos.x - textW / 2, windowPos.y - textH / 2, timeText);
    }
}

void PlayerSnake::GrowSnake()
{
    // 限制最大段数以防止内存溢出
    if (segments.size() >= MAX_SEGMENTS) {
        OutputDebugStringA("PlayerSnake::GrowSnake: Maximum segments reached\n");
        return;
    }

    Snake newSegment;
    newSegment.position = position;
    newSegment.direction = direction;
    newSegment.radius = GameConfig::INITIAL_SNAKE_SIZE;
    if (newSegment.radius <= 0) {
        newSegment.radius = 5.0f;
    }
    newSegment.color = color;
    newSegment.currentDir = currentDir;
    newSegment.nextDir = nextDir;
    newSegment.gridSnake = true;

    if (!segments.empty()) {
        newSegment.position = segments.back().position;
    }

    // 验证新段位置
    if (!IsValidVector2(newSegment.position)) {
        newSegment.position = position;
    }

    try {
        segments.push_back(newSegment);
    } catch (const std::bad_alloc&) {
        OutputDebugStringA("PlayerSnake::GrowSnake: Memory allocation failed\n");
    }
}

bool PlayerSnake::CheckCollisionWith(const Snake& other) const {
    if (!IsValidVector2(position) || !IsValidVector2(other.position)) {
        return false;
    }

    if (Snake::CheckCollisionWith(other))
        return true;

    for (const auto& segment : segments) {
        if (!IsValidVector2(segment.position)) continue;
        if (CollisionManager::CheckCircleCollision(
                other.position, other.radius,
                segment.position, segment.radius)) {
            return true;
        }
    }

    return false;
}

void AISnake::Initialize()
{
    isDying = false;
    deathTimer = 0.0f;
    dyingSegmentIndex = -1;
    isDead = false;

    // 使用安全的大小调整
    if (!SafeResize(segments, 4)) {
        OutputDebugStringA("AISnake::Initialize: Failed to resize segments\n");
        return;
    }

    currentDir = RIGHT;
    nextDir = RIGHT;
    gridSnake = true;
    moveInterval = 0.2f;

    for (auto& segment : segments) {
        // 安全地清空队列
        while (!segment.posRecords.empty()) {
            segment.posRecords.pop();
        }
        segment.gridSnake = true;
    }

    while (!posRecords.empty()) {
        posRecords.pop();
    }

    currentTime = 0;
    moveTimer = 0.0f;
}

void AISnake::Update(const FoodItem* foodItems, int foodCount, const FoodSpatialGrid* grid,
                     float deltaTime, const Vector2& playerHeadPos)
{
    // 参数验证
    if (!foodItems || foodCount < 0 || foodCount > GameConfig::MAX_FOOD_COUNT) {
        return;
    }

    // 验证deltaTime
    if (std::isnan(deltaTime) || std::isinf(deltaTime) || deltaTime < 0 || deltaTime > 10.0f) {
        deltaTime = 1.0f / 60.0f;
    }

    // 验证玩家位置
    if (!IsValidVector2(playerHeadPos)) {
        return;
    }

    if (isDying) {
        UpdateDeathAnimation(deltaTime);
        return;
    }

    if (isDead) return;

    if (!gridSnake) {
        directionChangeTimer += deltaTime;

        if (directionChangeTimer >= GameConfig::AI_DIRECTION_CHANGE_TIME) {
            directionChangeTimer = 0.0f;

            int gridX = static_cast<int>(position.x / GameConfig::GRID_CELL_SIZE);
            int gridY = static_cast<int>(position.y / GameConfig::GRID_CELL_SIZE);
            
            // 限制网格坐标
            gridX = ClampInt(gridX, 0, GameConfig::WINDOW_WIDTH / GameConfig::GRID_CELL_SIZE);
            gridY = ClampInt(gridY, 0, GameConfig::WINDOW_HEIGHT / GameConfig::GRID_CELL_SIZE);

            bool canUp = (currentDir != DOWN) && (gridY > 0);
            bool canDown = (currentDir != UP) && (gridY < GameConfig::WINDOW_HEIGHT / GameConfig::GRID_CELL_SIZE - 1);
            bool canLeft = (currentDir != RIGHT) && (gridX > 0);
            bool canRight = (currentDir != LEFT) && (gridX < GameConfig::WINDOW_WIDTH / GameConfig::GRID_CELL_SIZE - 1);

            Direction newDir = currentDir;
            switch (currentDir) {
                case UP: newDir = (canRight && rand() % 3 == 0) ? RIGHT : (canLeft && rand() % 3 == 0) ? LEFT : UP; break;
                case DOWN: newDir = (canRight && rand() % 3 == 0) ? RIGHT : (canLeft && rand() % 3 == 0) ? LEFT : DOWN; break;
                case LEFT: newDir = (canUp && rand() % 3 == 0) ? UP : (canDown && rand() % 3 == 0) ? DOWN : LEFT; break;
                case RIGHT: newDir = (canUp && rand() % 3 == 0) ? UP : (canDown && rand() % 3 == 0) ? DOWN : RIGHT; break;
                default: break;
            }
            nextDir = newDir;
        }

        MoveSnakeGrid(deltaTime);

        for (size_t i = 0; i < segments.size(); i++) {
            if (i == 0) {
                UpdateBody(*this, segments[i]);
            }
            else {
                UpdateBody(segments[i - 1], segments[i]);
            }
            segments[i].Update(deltaTime);
        }

        CheckWallCollision();
        return;
    }

    directionChangeTimer += deltaTime;

    if (directionChangeTimer >= GameConfig::AI_DIRECTION_CHANGE_TIME * 0.5f) {
        directionChangeTimer = 0.0f;

        int gridX = static_cast<int>(position.x / GameConfig::GRID_CELL_SIZE);
        int gridY = static_cast<int>(position.y / GameConfig::GRID_CELL_SIZE);
        
        // 限制网格坐标
        gridX = ClampInt(gridX, 0, GameConfig::WINDOW_WIDTH / GameConfig::GRID_CELL_SIZE);
        gridY = ClampInt(gridY, 0, GameConfig::WINDOW_HEIGHT / GameConfig::GRID_CELL_SIZE);

        bool canUp = (currentDir != DOWN) && (gridY > 0);
        bool canDown = (currentDir != UP) && (gridY < GameConfig::WINDOW_HEIGHT / GameConfig::GRID_CELL_SIZE - 1);
        bool canLeft = (currentDir != RIGHT) && (gridX > 0);
        bool canRight = (currentDir != LEFT) && (gridX < GameConfig::WINDOW_WIDTH / GameConfig::GRID_CELL_SIZE - 1);

        Direction newDir = currentDir;
        float randVal = static_cast<float>(rand() % 100) / 100.0f;
        
        // 限制侵略性因子范围
        float aggression = ClampFloat(aggressionFactor, 0.0f, 1.0f);

        if (randVal < aggression * 0.5f) {
            Vector2 toPlayer = playerHeadPos - position;
            if (IsValidVector2(toPlayer)) {
                if (abs(toPlayer.x) > abs(toPlayer.y)) {
                    if (toPlayer.x > 0 && canRight) newDir = RIGHT;
                    else if (toPlayer.x < 0 && canLeft) newDir = LEFT;
                } else {
                    if (toPlayer.y > 0 && canDown) newDir = DOWN;
                    else if (toPlayer.y < 0 && canUp) newDir = UP;
                }
            }
        } else {
            switch (currentDir) {
                case UP:
                    if (canRight && rand() % 4 == 0) newDir = RIGHT;
                    else if (canLeft && rand() % 4 == 0) newDir = LEFT;
                    else if (!canUp) newDir = (rand() % 2 == 0) ? (canRight ? RIGHT : LEFT) : (canLeft ? LEFT : RIGHT);
                    break;
                case DOWN:
                    if (canRight && rand() % 4 == 0) newDir = RIGHT;
                    else if (canLeft && rand() % 4 == 0) newDir = LEFT;
                    else if (!canDown) newDir = (rand() % 2 == 0) ? (canRight ? RIGHT : LEFT) : (canLeft ? LEFT : RIGHT);
                    break;
                case LEFT:
                    if (canUp && rand() % 4 == 0) newDir = UP;
                    else if (canDown && rand() % 4 == 0) newDir = DOWN;
                    else if (!canLeft) newDir = (rand() % 2 == 0) ? (canUp ? UP : DOWN) : (canDown ? DOWN : UP);
                    break;
                case RIGHT:
                    if (canUp && rand() % 4 == 0) newDir = UP;
                    else if (canDown && rand() % 4 == 0) newDir = DOWN;
                    else if (!canRight) newDir = (rand() % 2 == 0) ? (canUp ? UP : DOWN) : (canDown ? DOWN : UP);
                    break;
                default: break;
            }
        }

        nextDir = newDir;
    }

    MoveSnakeGrid(deltaTime);

    for (size_t i = 0; i < segments.size(); i++) {
        segments[i].currentTime += deltaTime;
    }

    CheckWallCollision();
}

void AISnake::CheckWallCollision()
{
    float halfCell = GameConfig::GRID_CELL_SIZE / 2.0f;
    float maxX = GameConfig::WINDOW_WIDTH - halfCell;
    float maxY = GameConfig::WINDOW_HEIGHT - halfCell;
    
    // 验证边界值
    if (halfCell <= 0 || maxX <= 0 || maxY <= 0) {
        return;
    }

    if (position.x < halfCell) {
        position.x = halfCell;
        if (currentDir == LEFT) {
            nextDir = (rand() % 2 == 0) ? UP : DOWN;
        }
    }
    if (position.x > maxX) {
        position.x = maxX;
        if (currentDir == RIGHT) {
            nextDir = (rand() % 2 == 0) ? UP : DOWN;
        }
    }
    if (position.y < halfCell) {
        position.y = halfCell;
        if (currentDir == UP) {
            nextDir = (rand() % 2 == 0) ? LEFT : RIGHT;
        }
    }
    if (position.y > maxY) {
        position.y = maxY;
        if (currentDir == DOWN) {
            nextDir = (rand() % 2 == 0) ? LEFT : RIGHT;
        }
    }
}

void AISnake::UpdateDeathAnimation(float deltaTime) {
    // 验证deltaTime
    if (std::isnan(deltaTime) || std::isinf(deltaTime) || deltaTime < 0) {
        deltaTime = 1.0f / 60.0f;
    }

    deathTimer += deltaTime;

    int targetSegmentIndex = static_cast<int>(deathTimer / segmentFadeTime) - 1;

    if (targetSegmentIndex > dyingSegmentIndex) {
        dyingSegmentIndex = targetSegmentIndex;

        if (dyingSegmentIndex == -1) {
            radius = 0;
        }
        else if (dyingSegmentIndex >= 0 && dyingSegmentIndex < static_cast<int>(segments.size())) {
            if (GameConfig::SOUND_ON) {
                PlaySound(_T(".\\Resource\\SoundEffects\\Pop.wav"), NULL, SND_FILENAME | SND_ASYNC);
            }
            segments[dyingSegmentIndex].radius = 0;
        }
        else if (dyingSegmentIndex >= static_cast<int>(segments.size())) {
            for (auto& segment : segments) {
                segment.radius = 0;
            }
            isDying = false;
            isDead = true;
        }
    }
}

void AISnake::StartDying(int foodValue) {
    isDying = true;
    deathTimer = 0.0f;
    dyingSegmentIndex = -1;
    foodValueOnDeath = foodValue;
}

void AISnake::Draw(const Camera& camera) const
{
    if (isDead) return;

    if (!IsValidVector2(position)) {
        return;
    }

    int baseR = (color >> 16) & 0xFF;
    int baseG = (color >> 8) & 0xFF;
    int baseB = color & 0xFF;

    for (size_t i = 0; i < segments.size(); i++) {
        const auto& segment = segments[i];
        if (segment.radius <= 0) continue;
        if (!IsValidVector2(segment.position)) continue;

        Vector2 windowPos = segment.position - camera.position;
        if (!IsValidVector2(windowPos)) continue;

        float ratio = static_cast<float>(i) / segments.size();
        int segR = baseR - static_cast<int>(ratio * baseR * 0.3f);
        int segG = baseG - static_cast<int>(ratio * baseG * 0.3f);
        int segB = baseB - static_cast<int>(ratio * baseB * 0.3f);
        
        // 确保颜色分量在有效范围内
        segR = ClampInt(segR, 0, 255);
        segG = ClampInt(segG, 0, 255);
        segB = ClampInt(segB, 0, 255);
        
        int segColor = RGB(segR, segG, segB);

        setfillcolor(segColor);
        setlinecolor(segColor);
        fillcircle(windowPos.x, windowPos.y, segment.radius);
    }

    Snake::Draw(camera);
    Vector2 windowPos = position - camera.position;
    if (IsValidVector2(windowPos)) {
        DrawSnakeEyes(windowPos, direction, radius);
    }
}

bool AISnake::CheckCollisionWith(const Snake& other) const {
    if (!IsValidVector2(position) || !IsValidVector2(other.position)) {
        return false;
    }

    if (Snake::CheckCollisionWith(other))
        return true;

    for (const auto& segment : segments) {
        if (!IsValidVector2(segment.position)) continue;
        if (CollisionManager::CheckCircleCollision(
                other.position, other.radius,
                segment.position, segment.radius)) {
            return true;
        }
    }

    return false;
}

bool Snake::CheckCollisionWith(const Snake& other) const {
    if (!IsValidVector2(position) || !IsValidVector2(other.position)) {
        return false;
    }
    return CollisionManager::CheckCircleCollision(
        position, radius, other.position, other.radius);
}

bool Snake::CheckCollisionWithPoint(const Vector2& point, float pointRadius) const {
    if (!IsValidVector2(position) || !IsValidVector2(point)) {
        return false;
    }
    if (radius <= 0 || pointRadius < 0) {
        return false;
    }
    return CollisionManager::CheckCircleCollision(
        position, radius, point, pointRadius);
}
