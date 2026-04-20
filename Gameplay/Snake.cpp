#include "Snake.h"
#include "../Core/Collisions.h"
#include "../Core/SessionConfig.h"
#include "../Utils/DrawHelpers.h"
#include "../ModernCore/Random.h"
#include <io.h>
#include <tchar.h>

using GreedSnake::Random;

namespace {
LPCTSTR ResolveAISnakePopSound() {
    static const TCHAR* primary = _T(".\\Resource\\SoundEffects\\Pop.wav");
    static const TCHAR* fallback = _T(".\\Resource\\SoundEffects\\Impact.wav");
    return _taccess(primary, 0) == 0 ? primary : fallback;
}

void DrawInvulnerabilityUnderlay(
    const PlayerSnake& playerSnake,
    const Camera& camera,
    float invulnerabilityTime) {
    const float elapsedShieldTime = GameConfig::COLLISION_GRACE_PERIOD - invulnerabilityTime;
    const float pulsePhase = elapsedShieldTime * 7.0f;
    const float basePulse = 0.5f + 0.5f * sinf(pulsePhase);

    auto drawShieldFloor = [&](const Vector2& worldPosition, float baseRadius, int layerIndex) {
        const Vector2 screenPosition = worldPosition - camera.position;
        const float radiusScale = 1.15f + basePulse * 0.18f + layerIndex * 0.05f;
        const int floorOffset = 5 + layerIndex * 2;
        const float drawRadius = baseRadius * (radiusScale + 0.28f);

        if (!IsCircleInScreen(
                Vector2(screenPosition.x, screenPosition.y + static_cast<float>(floorOffset)),
                drawRadius)) {
            return;
        }

        setfillcolor(layerIndex == 0 ? RGB(20, 90, 110) : RGB(35, 125, 145));
        setlinecolor(layerIndex == 0 ? RGB(90, 235, 255) : RGB(160, 245, 255));
        fillcircle(
            static_cast<int>(screenPosition.x),
            static_cast<int>(screenPosition.y + floorOffset),
            static_cast<int>(baseRadius * radiusScale));

        setlinestyle(PS_SOLID, layerIndex == 0 ? 2 : 1);
        circle(
            static_cast<int>(screenPosition.x),
            static_cast<int>(screenPosition.y + floorOffset),
            static_cast<int>(drawRadius));
    };

    drawShieldFloor(playerSnake.position, playerSnake.radius * 1.2f, 0);
    drawShieldFloor(playerSnake.position, playerSnake.radius * 0.95f, 1);

    for (size_t i = 0; i < playerSnake.segments.size(); ++i) {
        const float ratio = static_cast<float>(i + 1) / (playerSnake.segments.size() + 1.0f);
        const float segmentRadius = playerSnake.segments[i].radius * (0.95f - ratio * 0.18f);
        drawShieldFloor(playerSnake.segments[i].position, segmentRadius, 1);
    }

    const Vector2 headScreenPosition = playerSnake.position - camera.position;
    const float orbitRadius = playerSnake.radius * (2.2f + basePulse * 0.15f);
    static constexpr int numSparkles = 10;
    for (int i = 0; i < numSparkles; ++i) {
        const float angle = (static_cast<float>(i) / numSparkles) * 6.28318f + pulsePhase * 0.35f;
        const float sparkleX = headScreenPosition.x + cosf(angle) * orbitRadius;
        const float sparkleY = headScreenPosition.y + sinf(angle) * orbitRadius + 5.0f;
        const float sparkleRadius = playerSnake.radius * (0.08f + basePulse * 0.03f);
        setfillcolor(RGB(220, 255, 255));
        fillcircle(
            static_cast<int>(sparkleX),
            static_cast<int>(sparkleY),
            static_cast<int>(sparkleRadius));
    }

    setlinestyle(PS_SOLID, 1);
}
}

void Snake::Update(float deltaTime)
{
    currentTime += deltaTime;

    if (IsBeginRecord()) {
        RecordPos();
        currentTime = 0;
    }
}

Vector2 Snake::GetVelocity() const
{
    return direction.Normalized() * GameState::Instance().currentPlayerSpeed;
}

bool Snake::IsBeginRecord() const
{
    return currentTime >= GameState::Instance().recordInterval;
}

void Snake::RecordPos()
{
    float distanceToLast = 0;
    if (!posRecords.empty()) {
        distanceToLast = (position - posRecords.back()).Length();
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
    const float idealSpacing = GameConfig::SNAKE_SEGMENT_SPACING;
    Vector2 fallbackDirection = lastBody.direction;
    if (fallbackDirection.LengthSquared() <= 0.0001f) {
        fallbackDirection = currentBody.direction;
    }

    currentBody.direction = ResolveFollowDirection(
        lastBody.position,
        currentBody.position,
        fallbackDirection);
    currentBody.position = ResolveUniformFollowPosition(
        lastBody.position,
        currentBody.position,
        currentBody.direction,
        idealSpacing);
}

void Snake::MoveSnakeGrid(float deltaTime)
{
    moveTimer += deltaTime;
    if (moveTimer < moveInterval) {
        return;
    }
    moveTimer = 0.0f;

    if (currentDir != nextDir) {
        Direction opposite = GreedSnake::GetOppositeDirection(currentDir);
        if (nextDir != opposite) {
            currentDir = nextDir;
        }
    }

    float step = GameConfig::SNAKE_SEGMENT_SPACING;
    switch (currentDir) {
        case Direction::Up: position.y -= step; break;
        case Direction::Down: position.y += step; break;
        case Direction::Left: position.x -= step; break;
        case Direction::Right: position.x += step; break;
    }

    switch (currentDir) {
        case Direction::Up: direction = Vector2(0, -1); break;
        case Direction::Down: direction = Vector2(0, 1); break;
        case Direction::Left: direction = Vector2(-1, 0); break;
        case Direction::Right: direction = Vector2(1, 0); break;
    }
}

void Snake::Draw(const Camera& camera) const
{
    Vector2 windowPos = position - camera.position;
    setfillcolor(color);
    setlinecolor(color);
    fillcircle(static_cast<int>(windowPos.x), static_cast<int>(windowPos.y), static_cast<int>(radius));
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

    Vector2 windowPos = position - camera.position;
    int baseR = (color >> 16) & 0xFF;
    int baseG = (color >> 8) & 0xFF;
    int baseB = color & 0xFF;
    auto& gs = GameState::Instance();
    float invTime = gs.GetRemainingInvulnerabilityTime();

    if (invTime > 0.0f) {
        DrawInvulnerabilityUnderlay(*this, camera, invTime);
    }

    for (size_t i = 0; i < segments.size(); i++) {
        const auto& segment = segments[i];
        Vector2 segWindowPos = segment.position - camera.position;

        float ratio = static_cast<float>(i + 1) / (segments.size() + 1);
        int segR = baseR - static_cast<int>(ratio * baseR * 0.3f);
        int segG = baseG - static_cast<int>(ratio * baseG * 0.3f);
        int segB = baseB - static_cast<int>(ratio * baseB * 0.3f);
        int segColor = RGB(segR, segG, segB);

        float sizeRatio = 1.0f - ratio * 0.3f;
        float segRadius = segment.radius * sizeRatio;

        if (!IsCircleInScreen(segWindowPos, segRadius + 4.0f)) {
            continue;
        }

        setfillcolor(segColor);
        setlinecolor(segColor);
        fillcircle(segWindowPos.x, segWindowPos.y, segRadius);
    }

    if (IsCircleInScreen(windowPos, radius + 8.0f)) {
        setfillcolor(color);
        setlinecolor(color);
        fillcircle(windowPos.x, windowPos.y, radius);
        DrawSnakeEyes(windowPos, direction, radius);
    }

    if (invTime > 0.0f && IsCircleInScreen(windowPos, radius + 24.0f)) {
        const float elapsedShieldTime = GameConfig::COLLISION_GRACE_PERIOD - invTime;
        const float pulsePhase = elapsedShieldTime * 7.0f;
        const float rimRadius = radius * (1.18f + 0.08f * sinf(pulsePhase));
        setlinecolor(RGB(170, 250, 255));
        setlinestyle(PS_SOLID, 2);
        circle(static_cast<int>(windowPos.x), static_cast<int>(windowPos.y), static_cast<int>(rimRadius));
        setlinestyle(PS_SOLID, 1);

        settextstyle(18, 0, _T("Arial"));
        setbkmode(TRANSPARENT);
        settextcolor(RGB(200, 255, 255));
        TCHAR timeText[32];
        _stprintf_s(timeText, _T("%.1f"), invTime);
        int textW = textwidth(timeText);
        outtextxy(
            static_cast<int>(windowPos.x - textW / 2),
            static_cast<int>(windowPos.y + radius + 18),
            timeText);
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

    segments.resize(5);
    currentDir = Direction::Right;
    nextDir = Direction::Right;
    gridSnake = false;  // Use smooth continuous movement instead of jerky grid movement
    moveInterval = 0.05f;  // Faster update for smoother movement

    for (auto& segment : segments) {
        segment.posRecords = std::queue<Vector2>();
        segment.gridSnake = false;  // Smooth movement for segments too
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

    // Use smooth continuous movement for all AI snakes
    directionChangeTimer += deltaTime;

    // Update direction periodically for smooth behavior
    if (directionChangeTimer >= GameConfig::AI_DIRECTION_CHANGE_TIME * 0.3f) {
        directionChangeTimer = 0.0f;

        // Calculate target direction
        Vector2 targetDir = direction;

        // Aggressive: move toward player based on aggression factor
        float randVal = Random::Float(0.0f, 1.0f);
        if (randVal < aggressionFactor * 0.5f) {
            Vector2 toPlayer = playerHeadPos - position;
            if (toPlayer.Length() > 100.0f) {  // Only chase if far from player
                targetDir = toPlayer.Normalized();
            }
        } else {
            // Random wandering
            if (Random::Bool(0.25f)) {
                float angle = Random::Float(-60.0f, 60.0f) * 3.14159f / 180.0f;
                float cosA = cos(angle);
                float sinA = sin(angle);
                targetDir = Vector2(
                    direction.x * cosA - direction.y * sinA,
                    direction.x * sinA + direction.y * cosA
                );
            }
        }

        // Smooth turn toward target direction
        float turnSpeed = 0.15f;
        direction = (direction + targetDir * turnSpeed).Normalized();
    }

    // Continuous smooth movement using velocity
    float speed = ResolveAISpeed(GameState::Instance().originalSpeed, speedMultiplier);
    Vector2 velocity = direction * speed;
    position = position + velocity * deltaTime;

    // Record position for body segments
    Snake::Update(deltaTime);

    // Update body segments smoothly
    for (size_t i = 0; i < segments.size(); i++) {
        if (i == 0) {
            UpdateBody(*this, segments[i]);
        }
        else {
            UpdateBody(segments[i - 1], segments[i]);
        }
        segments[i].Update(deltaTime);
    }

    // Keep segments color and radius consistent
    for (auto& segment : segments) {
        segment.color = color;
        segment.radius = radius;
    }

    // Smooth wall avoidance - gradually turn away from walls
    const float wallWarningDist = 300.0f;
    Vector2 avoidanceDir(0, 0);
    bool needAvoidance = false;

    if (position.x < GameConfig::PLAY_AREA_LEFT + wallWarningDist) {
        avoidanceDir.x = 1.0f;
        needAvoidance = true;
    }
    if (position.x > GameConfig::PLAY_AREA_RIGHT - wallWarningDist) {
        avoidanceDir.x = -1.0f;
        needAvoidance = true;
    }
    if (position.y < GameConfig::PLAY_AREA_TOP + wallWarningDist) {
        avoidanceDir.y = 1.0f;
        needAvoidance = true;
    }
    if (position.y > GameConfig::PLAY_AREA_BOTTOM - wallWarningDist) {
        avoidanceDir.y = -1.0f;
        needAvoidance = true;
    }

    if (needAvoidance && avoidanceDir.Length() > 0.0f) {
        // Smooth turn away from wall
        avoidanceDir = avoidanceDir.Normalized();
        direction = (direction + avoidanceDir * 0.4f).Normalized();
    }

}

void AISnake::CheckWallCollision()
{
    // Use PLAY_AREA bounds instead of WINDOW bounds for large map support
    const float halfGrid = GameConfig::GRID_CELL_SIZE / 2.0f;
    if (position.x < GameConfig::PLAY_AREA_LEFT + halfGrid) {
        position.x = GameConfig::PLAY_AREA_LEFT + halfGrid;
        if (currentDir == Direction::Left) {
            nextDir = Random::Bool(0.5f) ? Direction::Up : Direction::Down;
        }
    }
    if (position.x > GameConfig::PLAY_AREA_RIGHT - halfGrid) {
        position.x = GameConfig::PLAY_AREA_RIGHT - halfGrid;
        if (currentDir == Direction::Right) {
            nextDir = Random::Bool(0.5f) ? Direction::Up : Direction::Down;
        }
    }
    if (position.y < GameConfig::PLAY_AREA_TOP + halfGrid) {
        position.y = GameConfig::PLAY_AREA_TOP + halfGrid;
        if (currentDir == Direction::Up) {
            nextDir = Random::Bool(0.5f) ? Direction::Left : Direction::Right;
        }
    }
    if (position.y > GameConfig::PLAY_AREA_BOTTOM - halfGrid) {
        position.y = GameConfig::PLAY_AREA_BOTTOM - halfGrid;
        if (currentDir == Direction::Down) {
            nextDir = Random::Bool(0.5f) ? Direction::Left : Direction::Right;
        }
    }
}

void AISnake::UpdateDeathAnimation(float deltaTime) {
    // SECURITY FIX: Check for valid segmentFadeTime to prevent division by zero
    if (segmentFadeTime <= 0.0f) {
        segmentFadeTime = 0.1f; // Set a safe default
    }
    
    deathTimer += deltaTime;

    int targetSegmentIndex = static_cast<int>(deathTimer / segmentFadeTime) - 1;

    if (targetSegmentIndex > dyingSegmentIndex) {
        dyingSegmentIndex = targetSegmentIndex;

        if (dyingSegmentIndex == -1) {
            radius = 0;
        }
        else if (dyingSegmentIndex >= 0 && dyingSegmentIndex < segments.size()) {
            if (GameConfig::SOUND_ON) {
                PlaySound(ResolveAISnakePopSound(), NULL, SND_FILENAME | SND_ASYNC);
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
        if (!IsCircleInScreen(windowPos, segment.radius + 4.0f)) {
            continue;
        }

        float ratio = static_cast<float>(i) / segments.size();
        int segR = baseR - static_cast<int>(ratio * baseR * 0.3f);
        int segG = baseG - static_cast<int>(ratio * baseG * 0.3f);
        int segB = baseB - static_cast<int>(ratio * baseB * 0.3f);
        int segColor = RGB(segR, segG, segB);

        setfillcolor(segColor);
        setlinecolor(segColor);
        fillcircle(windowPos.x, windowPos.y, segment.radius);
    }

    Vector2 windowPos = position - camera.position;
    if (IsCircleInScreen(windowPos, radius + 8.0f)) {
        Snake::Draw(camera);
        DrawSnakeEyes(windowPos, direction, radius);
    }
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
