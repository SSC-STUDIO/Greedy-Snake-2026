#include "Snake.h"
#include "Collisions.h"

Vector2 SnakeSegment::GetVelocity() const
{
    return direction.GetNormalize() * GameState::Instance().currentPlayerSpeed; // Get velocity
}
bool SnakeSegment::CanRecordPosition() const {
    return timeSinceLastRecord >= GameState::Instance().recordInterval; // Check if position needs to be recorded
}

void Snake::Update(float deltaTime)
{
    currentTime += deltaTime;

    // Update logic
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
        // Record needed positions
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
    Vector2 targetPos = lastBody.GetRecordTime(); // Get target position
    Vector2 direction = (targetPos - currentBody.position).GetNormalize(); // Calculate direction

    // Calculate fixed position
    currentBody.position = targetPos - direction * GameConfig::SNAKE_SEGMENT_SPACING; // Update position
}

void Snake::Draw(const Camera& camera) const
{
    Vector2 windowPos = position - camera.position;
    DrawCircleWithCamera(windowPos, radius, color);
}

void PlayerSnake::Update(float deltaTime)
{
    Snake::Update(deltaTime);

    // Update body segments
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
    // Get the base color values for the snake body
    int baseR = (color >> 16) & 0xFF;
    int baseG = (color >> 8) & 0xFF; 
    int baseB = color & 0xFF;

    // Draw body segments with gradient effect
    for (size_t i = 0; i < segments.size(); i++) {
        const auto& segment = segments[i];
        Vector2 windowPos = segment.position - camera.position;
        
        // Create color gradient - color gradually changes from head to tail
        float ratio = static_cast<float>(i) / segments.size(); // Between 0 and 1
        int segR = baseR - static_cast<int>(ratio * baseR * 0.3f);
        int segG = baseG - static_cast<int>(ratio * baseG * 0.3f);
        int segB = baseB - static_cast<int>(ratio * baseB * 0.3f);
        int segColor = RGB(segR, segG, segB);
        
        // Snake body size variation, tail is slightly smaller, increases fluidity
        float sizeRatio = 1.0f - ratio * 0.3f;
        float segRadius = segment.radius * sizeRatio;
        
        // Draw snake body segment
        setfillcolor(segColor);
        setlinecolor(segColor);
        fillcircle(windowPos.x, windowPos.y, segRadius);
    }

    // Draw head
    Snake::Draw(camera);

    // Draw eyes
    Vector2 windowPos = position - camera.position;
    DrawSnakeEyes(windowPos, direction, radius);
}

void AISnake::Init()
{
    // Reset death state
    isDying = false;
    deathTimer = 0.0f;
    dyingSegmentIndex = -1;
    
    segments.resize(5);
    
    // Initialize segments and records
    for (auto& segment : segments) {
        segment.posRecords = std::queue<Vector2>();
    }
    
    // Clear history record queue
    while (!posRecords.empty()) {
        posRecords.pop();
    }
    
    // Use the same recording logic as player snake, rather than maintaining recordedPositions
    currentTime = 0;
}

void AISnake::Update(const std::vector<FoodItem>& foodItems, float deltaTime, const Vector2& playerHeadPos)
{
    // If dying, update death animation and return
    if (isDying) {
        UpdateDeathAnimation(deltaTime);
        return;
    }
    
    // AI behavior decision part - determine direction
    directionChangeTimer += deltaTime;
    
    // Check if direction needs to be changed
    if (directionChangeTimer >= GameConfig::AI_DIRECTION_CHANGE_TIME) {
        // Determine behavior based on aggression factor
        if (rand() % 100 < static_cast<int>(aggressionFactor * 100)) {
            // When aggression is high, tend to chase the player
            Vector2 toPlayer = playerHeadPos - position;
            float distToPlayer = toPlayer.GetLength();
            
            if (distToPlayer < GameConfig::AI_VIEW_RANGE * 2) {
                // Chase player when in view range
                direction = toPlayer.GetNormalize();
            } else {
                // Random movement
                float angle = (rand() % 360) * 3.14159f / 180.0f;
                direction = Vector2(cos(angle), sin(angle));
            }
        } else {
            // When aggression is low, tend to look for food
            float closestDist = GameConfig::AI_VIEW_RANGE;
            Vector2 closestFood = position;
            bool foodFound = false;
            
            // Find the nearest food
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
                // Random movement
                float angle = (rand() % 360) * 3.14159f / 180.0f;
                direction = Vector2(cos(angle), sin(angle));
            }
        }
        
        directionChangeTimer = 0.0f;
    }
    
    // Avoid boundaries
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
    
    // Modify speed calculation, set AI snake speed to 0.25x player speed
    Vector2 velocity = direction.GetNormalize() * GameState::Instance().currentPlayerSpeed * 0.25f;
    position = position + velocity * deltaTime;
    
    // Use base class Update to handle position recording
    Snake::Update(deltaTime);

    // Update body segments using the same logic as PlayerSnake
    for (size_t i = 0; i < segments.size(); i++) {
        if (i == 0) {
            UpdateBody(*this, segments[i]);
        }
        else {
            UpdateBody(segments[i - 1], segments[i]);
        }
        segments[i].Update(deltaTime);
    }
    
    // Check if AI snake eats food, if so, increase body length
    for (const auto& food : foodItems) {
        if (food.collisionRadius <= 0) continue;
        
        if (CheckCollisionWithPoint(food.position, food.collisionRadius)) {
            // If AI snake eats food, increase body length based on food size
            float growthAmount = food.collisionRadius / 10.0f;
            
            // Increase AI snake body length
            Snake newSegment;
            if (!segments.empty()) {
                newSegment = segments.back();  // Copy the last segment
            } else {
                newSegment = *this;  // If no segments, copy the head
            }
            
            // Set new segment position and direction
            if (!segments.empty()) {
                Vector2 lastSegPos = segments.back().position;
                Vector2 dir = segments.back().direction;
                newSegment.position = lastSegPos - dir * GameConfig::SNAKE_SEGMENT_SPACING;
            } else {
                Vector2 dir = direction;
                newSegment.position = position - dir * GameConfig::SNAKE_SEGMENT_SPACING;
            }
            
            // Add to body segments array
            segments.push_back(newSegment);
            
            // Limit maximum length when body length exceeds a certain value
            const int maxSegments = 20;
            if (segments.size() > maxSegments) {
                segments.resize(maxSegments);
            }
            
            break;  // Exit loop after finding one food
        }
    }
}

// Implement AI snake death animation update
void AISnake::UpdateDeathAnimation(float deltaTime) {
    // Update death timer
    deathTimer += deltaTime;
    
    // Calculate which segment should currently disappear
    int targetSegmentIndex = static_cast<int>(deathTimer / segmentFadeTime) - 1;
    
    // If segment index has changed, handle segment disappearance logic
    if (targetSegmentIndex > dyingSegmentIndex) {
        dyingSegmentIndex = targetSegmentIndex;
        
        // If head disappears, generate food
        if (dyingSegmentIndex == -1) {
            // Food generation logic is handled in collision detection
            radius = 0;  // Head disappears
        }
        // If body segment disappears
        else if (dyingSegmentIndex >= 0 && dyingSegmentIndex < segments.size()) {
            // Play effect sound when body segment disappears
            if (GameConfig::SOUND_ON) {
                PlaySound(_T(".\\Resource\\SoundEffects\\Pop.wav"), NULL, SND_FILENAME | SND_ASYNC);
            }
            
            // Set corresponding segment radius to 0 to indicate disappearance
            segments[dyingSegmentIndex].radius = 0;
        }
        // If all segments have disappeared
        else if (dyingSegmentIndex >= segments.size()) {
            // Completely destroy AI snake
            for (auto& segment : segments) {
                segment.radius = 0;
            }
            isDying = false;  // Death process ends
        }
    }
}

// Start AI snake death process
void AISnake::StartDying(int foodValue) {
    isDying = true;
    deathTimer = 0.0f;
    dyingSegmentIndex = -1;  // Start disappearing from the head
    foodValueOnDeath = foodValue;  // Record food value provided at death
}

void AISnake::Draw(const Camera& camera) const
{
    // Get the base color values for the snake body
    int baseR = (color >> 16) & 0xFF;
    int baseG = (color >> 8) & 0xFF; 
    int baseB = color & 0xFF;

    // Draw body segments with gradient effect
    for (size_t i = 0; i < segments.size(); i++) {
        const auto& segment = segments[i];
        Vector2 windowPos = segment.position - camera.position;
        
        // Create color gradient - color gradually changes from head to tail
        float ratio = static_cast<float>(i) / segments.size(); // Between 0 and 1
        int segR = baseR - static_cast<int>(ratio * baseR * 0.3f);
        int segG = baseG - static_cast<int>(ratio * baseG * 0.3f);
        int segB = baseB - static_cast<int>(ratio * baseB * 0.3f);
        int segColor = RGB(segR, segG, segB);
        
        // Draw snake body segment
        setfillcolor(segColor);
        setlinecolor(segColor);
        fillcircle(windowPos.x, windowPos.y, segment.radius);
    }

    // Draw head
    Snake::Draw(camera);

    // Draw eyes
    Vector2 windowPos = position - camera.position;
    DrawSnakeEyes(windowPos, direction, radius);
}

bool PlayerSnake::CheckCollisionWith(const Snake& other) const {
    // First check head collision
    if (Snake::CheckCollisionWith(other))
        return true;
        
    // Then check body segments
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
    // First check head collision
    if (Snake::CheckCollisionWith(other))
        return true;
        
    // Then check body segments
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
    // Base class only checks head collision
    return CollisionManager::CheckCircleCollision(
        position, radius, other.position, other.radius);
}

bool Snake::CheckCollisionWithPoint(const Vector2& point, float pointRadius) const {
    return CollisionManager::CheckCircleCollision(
        position, radius, point, pointRadius);
}


