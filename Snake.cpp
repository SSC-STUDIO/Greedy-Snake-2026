#include "Snake.h"
#include "Collisions.h"

Vector2 SnakeSegment::GetVelocity() const
{
    return direction.GetNormalize() * GameState::Instance().currentPlayerSpeed; // 获取速度
}
bool SnakeSegment::CanRecordPosition() const {
    return timeSinceLastRecord >= GameState::Instance().recordInterval; // 是否需要记录位置
}

void Snake::Update(float deltaTime)
{
    currentTime += deltaTime;

    // 更新逻辑
    if (IsBeginRecord()) {
        RecordPos();
        currentTime = 0;
    }
}

Vector2 Snake::GetVelocity() const
{
    return direction.GetNormalize() * GameState::Instance().currentPlayerSpeed;
}

bool Snake::IsBeginRecord() const
{
    return currentTime >= GameState::Instance().recordInterval;
}

void Snake::RecordPos()
{
    float distanceToLast = 0;
    if (!posRecords.empty()) {
        distanceToLast = (position - posRecords.back()).GetLength();
    }

    if (distanceToLast >= GameConfig::SNAKE_SEGMENT_SPACING) {
        posRecords.push(position);
        // 需要记录的记录
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
    return posRecords.front();
}

void Snake::UpdateBody(const Snake& lastBody, Snake& currentBody)
{
    Vector2 targetPos = lastBody.GetRecordTime(); // 获取目标位置
    Vector2 direction = (targetPos - currentBody.position).GetNormalize(); // 计算方向

    // 计算固定位置
    currentBody.position = targetPos - direction * GameConfig::SNAKE_SEGMENT_SPACING; // 更新位置
}

void Snake::Draw(const Camera& camera) const
{
    Vector2 windowPos = position - camera.position;
    DrawCircleWithCamera(windowPos, radius, color);
}

void PlayerSnake::Update(float deltaTime)
{
    Snake::Update(deltaTime);

    // 更新身体
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

void PlayerSnake::Draw(const Camera& camera) const
{
    // 绘制身体
    for (const auto& segment : segments) {
        segment.Draw(camera);
    }

    // 绘制头部
    Snake::Draw(camera);

    // 绘制眼睛
    Vector2 windowPos = position - camera.position;
    DrawSnakeEyes(windowPos, direction, radius);
}

void AISnake::Init()
{
    segments.resize(5);
    
    // 初始化段和记录
    for (auto& segment : segments) {
        segment.posRecords = std::queue<Vector2>();
    }
    
    // 清空历史记录队列
    while (!posRecords.empty()) {
        posRecords.pop();
    }
    
    // 使用与玩家蛇相同的记录逻辑，而不是维护recordedPositions
    currentTime = 0;
}

void AISnake::Update(const std::vector<FoodItem>& foodItems, float deltaTime, const Vector2& playerHeadPos)
{
    // AI行为决策部分 - 确定方向
    directionChangeTimer += deltaTime;
    
    // 检查是否需要改变方向
    if (directionChangeTimer >= GameConfig::AI_DIRECTION_CHANGE_TIME) {
        // 根据攻击性确定行为
        if (rand() % 100 < static_cast<int>(aggressionFactor * 100)) {
            // 高攻击性时偏向追逐玩家
            Vector2 toPlayer = playerHeadPos - position;
            float distToPlayer = toPlayer.GetLength();
            
            if (distToPlayer < GameConfig::AI_VIEW_RANGE * 2) {
                // 玩家在视野范围内时追逐
                direction = toPlayer.GetNormalize();
            } else {
                // 随机移动
                float angle = (rand() % 360) * 3.14159f / 180.0f;
                direction = Vector2(cos(angle), sin(angle));
            }
        } else {
            // 低攻击性时偏向寻找食物
            float closestDist = GameConfig::AI_VIEW_RANGE;
            Vector2 closestFood = position;
            bool foodFound = false;
            
            // 找最近的食物
            for (const auto& food : foodItems) {
                if (food.collisionRadius <= 0) continue;
                
                float dist = (food.position - position).GetLength();
                if (dist < closestDist) {
                    closestDist = dist;
                    closestFood = food.position;
                    foodFound = true;
                }
            }
            
            if (foodFound) {
                direction = (closestFood - position).GetNormalize();
            } else {
                // 随机移动
                float angle = (rand() % 360) * 3.14159f / 180.0f;
                direction = Vector2(cos(angle), sin(angle));
            }
        }
        
        directionChangeTimer = 0.0f;
    }
    
    // 避开边界
    const float borderAvoidDistance = 200.0f;
    Vector2 borderAvoidDir(0, 0);
    int borderCount = 0;
    
    if (position.x - GameConfig::PLAY_AREA_LEFT < borderAvoidDistance) {
        borderAvoidDir.x += 1.0f;
        borderCount++;
    }
    
    if (GameConfig::PLAY_AREA_RIGHT - position.x < borderAvoidDistance) {
        borderAvoidDir.x -= 1.0f;
        borderCount++;
    }
    
    if (position.y - GameConfig::PLAY_AREA_TOP < borderAvoidDistance) {
        borderAvoidDir.y += 1.0f;
        borderCount++;
    }
    
    if (GameConfig::PLAY_AREA_BOTTOM - position.y < borderAvoidDistance) {
        borderAvoidDir.y -= 1.0f;
        borderCount++;
    }
    
    if (borderCount > 0) {
        borderAvoidDir = borderAvoidDir.GetNormalize();
        direction = (direction + borderAvoidDir * 3.0f).GetNormalize();
    }
    
    // 使用与Snake::Update相同的逻辑更新时间和记录位置
    Snake::Update(deltaTime);
    
    // 添加这一行来更新蛇的身体段
    UpdateSegments();
}

void AISnake::UpdateSegments() {
    // 更新所有身体段
    for (size_t i = 0; i < segments.size(); i++) {
        if (i == 0) {
            // 第一段跟随头部
            Vector2 targetPos = position - direction * GameConfig::SNAKE_SEGMENT_SPACING;
            Vector2 moveDir = (targetPos - segments[i].position).GetNormalize();
            segments[i].position = segments[i].position + moveDir * speedMultiplier * GameState::Instance().currentPlayerSpeed * GameState::Instance().deltaTime;
            segments[i].direction = moveDir;
        } else {
            // 其他段跟随前一段
            Vector2 targetPos = segments[i-1].position - segments[i-1].direction * GameConfig::SNAKE_SEGMENT_SPACING;
            Vector2 moveDir = (targetPos - segments[i].position).GetNormalize();
            segments[i].position = segments[i].position + moveDir * speedMultiplier * GameState::Instance().currentPlayerSpeed * GameState::Instance().deltaTime;
            segments[i].direction = moveDir;
        }
    }
}

bool PlayerSnake::CheckCollisionWith(const Snake& other) const {
    // 首先检查头部碰撞
    if (Snake::CheckCollisionWith(other))
        return true;
        
    // 然后检查身体段
    for (const auto& segment : segments) {
        if (CollisionManager::CheckCircleCollision(
                other.position, other.radius,
                segment.position, segment.radius)) {
            return true;
        }
    }
    
    return false;
}

bool AISnake::CheckCollisionWith(const Snake& other) const {
    // 首先检查头部碰撞
    if (Snake::CheckCollisionWith(other))
        return true;
        
    // 然后检查身体段
    for (const auto& segment : segments) {
        if (CollisionManager::CheckCircleCollision(
                other.position, other.radius,
                segment.position, segment.radius)) {
            return true;
        }
    }
    
    return false;
}

bool Snake::CheckCollisionWith(const Snake& other) const {
    // 基类只检查头部碰撞
    return CollisionManager::CheckCircleCollision(
        position, radius, other.position, other.radius);
}

bool Snake::CheckCollisionWithPoint(const Vector2& point, float pointRadius) const {
    return CollisionManager::CheckCircleCollision(
        position, radius, point, pointRadius);
}


