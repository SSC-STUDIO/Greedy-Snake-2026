#include "Rendering.h"
#pragma warning(disable: 4996)	 // Disable security warnings for _tcscpy and _stprintf

void DrawGameArea() {
    // Draw background
    setbkcolor(RGB(30, 30, 30));
    cleardevice();

    // Get camera position
    Vector2 cameraPos = GameState::Instance().camera.position;

    // Calculate visible area
    float screenLeft = cameraPos.x;
    float screenRight = cameraPos.x + GameConfig::WINDOW_WIDTH;
    float screenTop = cameraPos.y;
    float screenBottom = cameraPos.y + GameConfig::WINDOW_HEIGHT;

    // Draw lava area outside game boundaries - dark red color
    // First check which boundaries are in view
    setfillcolor(RGB(80, 20, 20)); // Dark red

    // Check and draw top boundary lava area
    if (screenTop < GameConfig::PLAY_AREA_TOP) {
        solidrectangle(0, 0,
            GameConfig::WINDOW_WIDTH,
            GameConfig::PLAY_AREA_TOP - cameraPos.y);
    }

    // Check and draw bottom boundary lava area
    if (screenBottom > GameConfig::PLAY_AREA_BOTTOM) {
        solidrectangle(0,
            GameConfig::PLAY_AREA_BOTTOM - cameraPos.y,
            GameConfig::WINDOW_WIDTH,
            GameConfig::WINDOW_HEIGHT);
    }

    // Check and draw left boundary lava area
    if (screenLeft < GameConfig::PLAY_AREA_LEFT) {
        solidrectangle(0, 0,
            GameConfig::PLAY_AREA_LEFT - cameraPos.x,
            GameConfig::WINDOW_HEIGHT);
    }

    // Check and draw right boundary lava area
    if (screenRight > GameConfig::PLAY_AREA_RIGHT) {
        solidrectangle(GameConfig::PLAY_AREA_RIGHT - cameraPos.x,
            0,
            GameConfig::WINDOW_WIDTH,
            GameConfig::WINDOW_HEIGHT);
    }

    // Draw game boundary lines
    setlinecolor(RGB(150, 50, 50)); // Boundary line color
    Vector2 topLeft(GameConfig::PLAY_AREA_LEFT, GameConfig::PLAY_AREA_TOP);
    Vector2 bottomRight(GameConfig::PLAY_AREA_RIGHT, GameConfig::PLAY_AREA_BOTTOM);

    rectangle(topLeft.x - cameraPos.x, topLeft.y - cameraPos.y,
        bottomRight.x - cameraPos.x, bottomRight.y - cameraPos.y);
}

void DrawFoods(const FoodItem* foodList, int foodCount) {
    for (int i = 0; i < foodCount; ++i) {
        if (foodList[i].collisionRadius > 0) {
            Vector2 screenPos = foodList[i].position - GameState::Instance().camera.position;
            DrawCircleWithCamera(screenPos, foodList[i].collisionRadius, foodList[i].colorValue);
        }
    }
}

void DrawVisibleObjects(const FoodItem* foodList, int foodCount, 
                        const AISnake* aiSnakes, int aiSnakeCount,
                        const PlayerSnake& playerSnake) {
    // Calculate visible area
    Vector2 cameraPos = GameState::Instance().camera.position;
    float screenLeft = cameraPos.x;
    float screenRight = cameraPos.x + GameConfig::WINDOW_WIDTH;
    float screenTop = cameraPos.y;
    float screenBottom = cameraPos.y + GameConfig::WINDOW_HEIGHT;

    // Extend visible area to account for large objects that might be partially visible
    float margin = 100.0f;  // Large enough margin
    screenLeft -= margin;
    screenRight += margin;
    screenTop -= margin;
    screenBottom += margin;

    // Only draw food items in visible area
    for (int i = 0; i < foodCount; ++i) {
        const auto& food = foodList[i];
        if (food.position.x >= screenLeft && food.position.x <= screenRight &&
            food.position.y >= screenTop && food.position.y <= screenBottom) {
            Vector2 foodScreenPos = food.position - cameraPos;
            DrawCircleWithCamera(foodScreenPos, food.collisionRadius, food.colorValue);
        }
    }

    // Only draw AI snakes in visible area
    for (int i = 0; i < aiSnakeCount; ++i) {
        const auto& snake = aiSnakes[i];
        if (snake.position.x >= screenLeft && snake.position.x <= screenRight &&
            snake.position.y >= screenTop && snake.position.y <= screenBottom) {
            // Draw AI snake head
            Vector2 windowPos = snake.position - cameraPos;
            DrawCircleWithCamera(windowPos, snake.radius, snake.color);
            DrawSnakeEyes(windowPos, snake.direction, snake.radius);

            // Draw AI snake body - modify this part to not use range-based for loop
            for (size_t j = 0; j < snake.segments.size(); ++j) {
                const auto& segment = snake.segments[j];
                if (segment.position.x >= screenLeft && segment.position.x <= screenRight &&
                    segment.position.y >= screenTop && segment.position.y <= screenBottom) {
                    Vector2 segmentPos = segment.position - cameraPos;
                    DrawCircleWithCamera(segmentPos, segment.radius, segment.color);
                }
            }
        }
    }

    // Draw player snake head and body
    // Check if player head is in visible area
    if (playerSnake.position.x >= screenLeft && playerSnake.position.x <= screenRight &&
        playerSnake.position.y >= screenTop && playerSnake.position.y <= screenBottom) {
        // Draw head
        Vector2 headPos = playerSnake.position - cameraPos;
        DrawCircleWithCamera(headPos, playerSnake.radius, playerSnake.color);
        DrawSnakeEyes(headPos, playerSnake.direction, playerSnake.radius);
    }
    
    // Draw player snake body - similarly modified to not use range-based for loop
    for (size_t i = 0; i < playerSnake.segments.size(); ++i) {
        const auto& segment = playerSnake.segments[i];
        if (segment.position.x >= screenLeft && segment.position.x <= screenRight &&
            segment.position.y >= screenTop && segment.position.y <= screenBottom) {
            Vector2 segmentPos = segment.position - cameraPos;
            DrawCircleWithCamera(segmentPos, segment.radius, segment.color);
        }
    }
}

void DrawCircleWithCamera(const Vector2& screenPos, float r, int c) {
    if (!IsCircleInScreen(screenPos, r)) {
        return; // Not in screen, skip drawing
    }
    setlinecolor(c); // Set circle outline color
    setfillcolor(c); // Set circle fill color
    fillcircle(screenPos.x, screenPos.y, r); // Draw circle
}

void DebugDrawText(const std::wstring& text, int x, int y, int color) {
    settextcolor(color); // Set text color
    outtextxy(x, y, text.c_str()); // Draw text
}

void DrawSnakeEyes(const Vector2& position, const Vector2& direction, float radius) {
    // Unified eye style for all snakes
    float eyeRadius = radius * 0.3f;  // Eye size scale

    // Standardize direction calculations
    Vector2 normalizedDir = direction.GetNormalize();
    // Calculate perpendicular direction for eye distribution
    Vector2 perpDir(-normalizedDir.y, normalizedDir.x);

    // Calculate eye positions - smaller forward offset, fit inside head
    Vector2 eyeOffset = normalizedDir * (radius * 0.25f);  // Forward a bit
    Vector2 sideOffset = perpDir * (radius * 0.4f);  // Side by side

    // Calculate actual eye positions
    Vector2 leftEyePos = position + eyeOffset + sideOffset;
    Vector2 rightEyePos = position + eyeOffset - sideOffset;

    // Draw eye whites
    setfillcolor(WHITE);
    fillcircle(leftEyePos.x, leftEyePos.y, eyeRadius);
    fillcircle(rightEyePos.x, rightEyePos.y, eyeRadius);

    // Draw pupils, make them slightly larger for expression
    float pupilRadius = eyeRadius * 0.7f;  // Pupil scale
    setfillcolor(BLACK);

    // Offset pupils to give more expressive look
    // Increase offset by 1.5x to make eyes look more alive
    float pupilOffsetFactor = 1.5f;  // Offset factor to make eyes more expressive

    // Calculate pupil position without exceeding eye white
    float maxPupilOffset = eyeRadius - pupilRadius * 0.9f;  // Some margin to ensure visibility

    // Calculate scaled pupil offset
    Vector2 pupilOffset = normalizedDir * (maxPupilOffset * pupilOffsetFactor);

    // Ensure pupils don't exceed eye white bounds
    float pupilOffsetLength = pupilOffset.GetLength();
    if (pupilOffsetLength > maxPupilOffset) {
        pupilOffset = pupilOffset * (maxPupilOffset / pupilOffsetLength);
    }

    // Draw pupils in both eyes, with offset
    fillcircle(leftEyePos.x + pupilOffset.x, leftEyePos.y + pupilOffset.y, pupilRadius);
    fillcircle(rightEyePos.x + pupilOffset.x, rightEyePos.y + pupilOffset.y, pupilRadius);

    // Add eye highlights for depth
    setfillcolor(WHITE);
    float highlightRadius = pupilRadius * 0.3f;

    // Place highlights in opposite direction of gaze for better contrast
    Vector2 highlightOffset = normalizedDir * (-pupilRadius * 0.3f);

    fillcircle(leftEyePos.x + pupilOffset.x + highlightOffset.x,
        leftEyePos.y + pupilOffset.y + highlightOffset.y,
        highlightRadius);
    fillcircle(rightEyePos.x + pupilOffset.x + highlightOffset.x,
        rightEyePos.y + pupilOffset.y + highlightOffset.y,
        highlightRadius);
}

bool IsCircleInScreen(const Vector2& center, float r) {
    Vector2 minPoint = Vector2(center.x - r, center.y - r); // Min corner
    Vector2 maxPoint = Vector2(center.x + r, center.y + r); // Max corner

    return !(maxPoint.x < 0 || minPoint.x > GameConfig::WINDOW_WIDTH || maxPoint.y < 0 || minPoint.y > GameConfig::WINDOW_HEIGHT); // Check if visible on screen
}

void DrawUI() {
    auto& gameState = GameState::Instance();

    // Draw score
    settextstyle(24, 0, _T("Arial"));
    settextcolor(WHITE);
    TCHAR scoreText[50];
    _stprintf(scoreText, _T("Score: %d"), gameState.foodEatenCount);
    outtextxy(10, 10, scoreText);

    // Draw warning if in lava
    if (gameState.isInLava) {
        settextcolor(RGB(255, 0, 0));
        TCHAR warningText[50];
        float timeLeft = GameConfig::LAVA_WARNING_TIME - gameState.timeInLava;
        _stprintf(warningText, _T("WARNING! Return to play area! %.1f"), timeLeft);
        outtextxy(GameConfig::WINDOW_WIDTH / 2 - 150, 10, warningText);
    }
}
