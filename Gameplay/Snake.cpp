#include "Snake.h"
#include "../Core/Collisions.h"
#include "../Utils/DrawHelpers.h"

Vector2 SnakeSegment::GetVelocity() const
{
    return direction.GetNormalize() * GameState::Instance().currentPlayerSpeed;
}

bool SnakeSegment::CanRecordPosition() const {
    return timeSinceLastRecord >= GameState::Instance().recordInterval;
}

void Snake::Update(float deltaTime)
{
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
    Vector2 targetPos = lastBody.GetRecordTime();
    Vector2 direction = (targetPos - currentBody.position).GetNormalize();
    currentBody.position = targetPos - direction * GameConfig::SNAKE_SEGMENT_SPACING;
}

void Snake::MoveSnakeGrid(float deltaTime)
{
    moveTimer += deltaTime;
    if (moveTimer < moveInterval) {
        return;
    }
    moveTimer = 0.0f;

    if (currentDir != nextDir) {
        Direction opposite = (currentDir == UP) ? DOWN : (currentDir == DOWN) ? UP :
                            (currentDir == LEFT) ? RIGHT : LEFT;
        if (nextDir != opposite) {
            currentDir = nextDir;
        }
    }

    float step = GameConfig::SNAKE_SEGMENT_SPACING;
    switch (currentDir) {
        case UP: position.y -= step; break;
        case DOWN: position.y += step; break;
        case LEFT: position.x -= step; break;
        case RIGHT: position.x += step; break;
    }

    switch (currentDir) {
        case UP: direction = Vector2(0, -1); break;
        case DOWN: direction = Vector2(0, 1); break;
        case LEFT: direction = Vector2(-1, 0); break;
        case RIGHT: direction = Vector2(1, 0); break;
    }
}

void Snake::Draw(const Camera& camera) const
{
    Vector2 windowPos = position - camera.position;
    DrawCircleWithCamera(windowPos, radius, color);
}

void PlayerSnake::Update(float deltaTime)
{
    if (isDead) return;

    if (gridSnake) {
        Vector2 prevPos = position;
        MoveSnakeGrid(deltaTime);

        for (size_t i = 0; i < segments.size(); i++) {
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

    int baseR = (color >> 16) & 0xFF;
    int baseG = (color >> 8) & 0xFF;
    int baseB = color & 0xFF;

    for (size_t i = 0; i < segments.size(); i++) {
        const auto& segment = segments[i];
        Vector2 windowPos = segment.position - camera.position;

        float ratio = static_cast<float>(i) / segments.size();
        int segR = baseR - static_cast<int>(ratio * baseR * 0.3f);
        int segG = baseG - static_cast<int>(ratio * baseG * 0.3f);
        int segB = baseB - static_cast<int>(ratio * baseB * 0.3f);
        int segColor = RGB(segR, segG, segB);

        float sizeRatio = 1.0f - ratio * 0.3f;
        float segRadius = segment.radius * sizeRatio;

        setfillcolor(segColor);
        setlinecolor(segColor);
        fillcircle(windowPos.x, windowPos.y, segRadius);
    }

    Snake::Draw(camera);
    Vector2 windowPos = position - camera.position;
    DrawSnakeEyes(windowPos, direction, radius);

    auto& gs = GameState::Instance();
    float invTime = gs.GetRemainingInvulnerabilityTime();
    float gst = gs.gameStartTime;
    float dt = gs.deltaTime;
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
    Snake newSegment;
    newSegment.position = position;
    newSegment.direction = direction;
    newSegment.radius = GameConfig::INITIAL_SNAKE_SIZE;
    newSegment.color = color;
    newSegment.currentDir = currentDir;
    newSegment.nextDir = nextDir;
    newSegment.gridSnake = true;

    if (!segments.empty()) {
        newSegment.position = segments.back().position;
    }

    segments.push_back(newSegment);
}

bool PlayerSnake::CheckCollisionWith(const Snake& other) const {
    if (Snake::CheckCollisionWith(other))
        return true;

    for (const auto& segment : segments) {
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

    segments.resize(4);
    currentDir = RIGHT;
    nextDir = RIGHT;
    gridSnake = true;
    moveInterval = 0.2f;

    for (auto& segment : segments) {
        segment.posRecords = std::queue<Vector2>();
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

        bool canUp = (currentDir != DOWN) && (gridY > 0);
        bool canDown = (currentDir != UP) && (gridY < GameConfig::WINDOW_HEIGHT / GameConfig::GRID_CELL_SIZE - 1);
        bool canLeft = (currentDir != RIGHT) && (gridX > 0);
        bool canRight = (currentDir != LEFT) && (gridX < GameConfig::WINDOW_WIDTH / GameConfig::GRID_CELL_SIZE - 1);

        Direction newDir = currentDir;
        float randVal = static_cast<float>(rand() % 100) / 100.0f;

        if (randVal < aggressionFactor * 0.5f) {
            Vector2 toPlayer = playerHeadPos - position;
            if (abs(toPlayer.x) > abs(toPlayer.y)) {
                if (toPlayer.x > 0 && canRight) newDir = RIGHT;
                else if (toPlayer.x < 0 && canLeft) newDir = LEFT;
            } else {
                if (toPlayer.y > 0 && canDown) newDir = DOWN;
                else if (toPlayer.y < 0 && canUp) newDir = UP;
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
    if (position.x < GameConfig::GRID_CELL_SIZE / 2) {
        position.x = GameConfig::GRID_CELL_SIZE / 2;
        if (currentDir == LEFT) {
            nextDir = (rand() % 2 == 0) ? UP : DOWN;
        }
    }
    if (position.x > GameConfig::WINDOW_WIDTH - GameConfig::GRID_CELL_SIZE / 2) {
        position.x = GameConfig::WINDOW_WIDTH - GameConfig::GRID_CELL_SIZE / 2;
        if (currentDir == RIGHT) {
            nextDir = (rand() % 2 == 0) ? UP : DOWN;
        }
    }
    if (position.y < GameConfig::GRID_CELL_SIZE / 2) {
        position.y = GameConfig::GRID_CELL_SIZE / 2;
        if (currentDir == UP) {
            nextDir = (rand() % 2 == 0) ? LEFT : RIGHT;
        }
    }
    if (position.y > GameConfig::WINDOW_HEIGHT - GameConfig::GRID_CELL_SIZE / 2) {
        position.y = GameConfig::WINDOW_HEIGHT - GameConfig::GRID_CELL_SIZE / 2;
        if (currentDir == DOWN) {
            nextDir = (rand() % 2 == 0) ? LEFT : RIGHT;
        }
    }
}

void AISnake::UpdateDeathAnimation(float deltaTime) {
    deathTimer += deltaTime;

    int targetSegmentIndex = static_cast<int>(deathTimer / segmentFadeTime) - 1;

    if (targetSegmentIndex > dyingSegmentIndex) {
        dyingSegmentIndex = targetSegmentIndex;

        if (dyingSegmentIndex == -1) {
            radius = 0;
        }
        else if (dyingSegmentIndex >= 0 && dyingSegmentIndex < segments.size()) {
            if (GameConfig::SOUND_ON) {
                PlaySound(_T(".\\Resource\\SoundEffects\\Pop.wav"), NULL, SND_FILENAME | SND_ASYNC);
            }
            segments[dyingSegmentIndex].radius = 0;
        }
        else if (dyingSegmentIndex >= segments.size()) {
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

    int baseR = (color >> 16) & 0xFF;
    int baseG = (color >> 8) & 0xFF;
    int baseB = color & 0xFF;

    for (size_t i = 0; i < segments.size(); i++) {
        const auto& segment = segments[i];
        if (segment.radius <= 0) continue;

        Vector2 windowPos = segment.position - camera.position;

        float ratio = static_cast<float>(i) / segments.size();
        int segR = baseR - static_cast<int>(ratio * baseR * 0.3f);
        int segG = baseG - static_cast<int>(ratio * baseG * 0.3f);
        int segB = baseB - static_cast<int>(ratio * baseB * 0.3f);
        int segColor = RGB(segR, segG, segB);

        setfillcolor(segColor);
        setlinecolor(segColor);
        fillcircle(windowPos.x, windowPos.y, segment.radius);
    }

    Snake::Draw(camera);
    Vector2 windowPos = position - camera.position;
    DrawSnakeEyes(windowPos, direction, radius);
}

bool AISnake::CheckCollisionWith(const Snake& other) const {
    if (Snake::CheckCollisionWith(other))
        return true;

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
    return CollisionManager::CheckCircleCollision(
        position, radius, other.position, other.radius);
}

bool Snake::CheckCollisionWithPoint(const Vector2& point, float pointRadius) const {
    return CollisionManager::CheckCircleCollision(
        position, radius, point, pointRadius);
}