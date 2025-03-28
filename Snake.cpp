#include "Snake.h"

Vector2 SnakeSegment::GetVelocity() const
{
    return direction.GetNormalize() * GameState::Instance().currentPlayerSpeed; // 获取速度
}
bool SnakeSegment::CanRecordPosition() const {
    return timeSinceLastRecord >= GameState::Instance().recordInterval; // 是否可以记录位置
}

void Snake::Update(float deltaTime)
{
    currentTime += deltaTime;

    // 基础更新逻辑
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
        // 保留必要的记录
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

    // 计算保持固定距离的新位置
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

    // 更新蛇段
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
    // 绘制身体段
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
    segments.resize(5);  // 初始化5个段
    for (auto& segment : segments) {
        segment.posRecords = std::queue<Vector2>();  // 初始化位置记录队列
    }
}

void AISnake::Update(const std::vector<FoodItem>& foodItems, float deltaTime, const Vector2& playerHeadPos)
{
    directionChangeTimer += deltaTime; // 更新方向改变计时器

    // 定期改变方向或在发现食物时改变方向
    if (directionChangeTimer >= GameConfig::AI_DIRECTION_CHANGE_TIME) {
        // 根据攻击性因子决定行为
        if (rand() % 100 < (aggressionFactor * 100)) {
            // 更具攻击性的行为：追逐玩家
            direction = (playerHeadPos - position).GetNormalize(); // 计算方向
        }
        else {
            // 随机移动
            float angle = (rand() % 360) * 3.14159f / 180.0f; // 随机角度
            direction = Vector2(cos(angle), sin(angle)); // 计算方向
        }
        directionChangeTimer = 0.0f; // 重置计时器
    }

    // 根据攻击性寻找附近的食物
    if (rand() % 100 >= (aggressionFactor * 70)) {  // 较低攻击性的AI更倾向于寻找食物
        float closestDist = GameConfig::AI_VIEW_RANGE; // 最近距离
        Vector2 closestFood; // 最近食物位置
        bool foodFound = false; // 是否找到食物

        for (const auto& food : foodItems) {
            float dist = (food.position - position).GetLength(); // 计算距离
            if (dist < closestDist) {
                closestDist = dist; // 更新最近距离
                closestFood = food.position; // 更新最近食物位置
                foodFound = true; // 找到食物
            }
        }

        // 如果找到最近食物，朝其移动
        if (foodFound) {
            direction = (closestFood - position).GetNormalize(); // 计算方向
            directionChangeTimer = 0.0f; // 重置计时器
        }
    }

    // 新增：避免撞到其他AI蛇（简单避障）
    // 这里只是一个简单示例，更复杂的避障算法可以进一步改进
    const float avoidanceDistance = radius * 3.0f;
    Vector2 avoidanceVector(0, 0);
    int nearbySnakeCount = 0;

    // 这部分需要外部传入其他AI蛇的信息，或者在AISnake类内部实现
    // 暂时简化为只对玩家蛇做出反应
    float distToPlayer = (playerHeadPos - position).GetLength();
    if (distToPlayer < avoidanceDistance) {
        Vector2 avoidDir = (position - playerHeadPos).GetNormalize();
        avoidanceVector = avoidanceVector + avoidDir;
        nearbySnakeCount++;
    }

    // 如果有需要避开的蛇，调整方向
    if (nearbySnakeCount > 0) {
        avoidanceVector = avoidanceVector * (1.0f / nearbySnakeCount);
        // 混合当前方向和避障方向
        direction = (direction + avoidanceVector * 2.0f).GetNormalize();
    }
}

void AISnake::UpdateSegments()
{
    // 记录头部位置
    RecordPos();

    // 更新段以跟随前面的段
    for (size_t i = 0; i < segments.size(); i++) {
        if (i == 0) {
            // 第一个段跟随头部
            UpdateBody(*this, segments[i]);
        }
        else {
            // 其他段跟随前面的段
            UpdateBody(segments[i - 1], segments[i]);
        }

        // 记录下一个段的位置
        segments[i].RecordPos();
    }
}


