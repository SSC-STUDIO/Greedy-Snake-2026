#include "Rendering.h"
#include "../Core/GameRuntime.h"
#include "../Core/SessionConfig.h"
#include "DrawHelpers.h"
#include <cmath>
#include <algorithm>
#include <tchar.h>
#include <vector>
#pragma warning(disable: 4996)

namespace {
int ClampColorChannel(int value) {
    return (std::max)(0, (std::min)(255, value));
}

void DrawRoundedPanel(int left, int top, int right, int bottom, int radius, COLORREF fillColor, COLORREF borderColor) {
    setfillcolor(fillColor);
    solidroundrect(left, top, right, bottom, radius, radius);
    setlinecolor(borderColor);
    roundrect(left, top, right, bottom, radius, radius);
}

int BrightenColor(int color, int amount) {
    return RGB(
        ClampColorChannel(GetRValue(color) + amount),
        ClampColorChannel(GetGValue(color) + amount),
        ClampColorChannel(GetBValue(color) + amount));
}

int CountLivingAISnakes(const std::vector<AISnake>& aiSnakes) {
    int aliveCount = 0;
    for (const auto& aiSnake : aiSnakes) {
        if (!aiSnake.isDead && aiSnake.radius > 0.0f) {
            ++aliveCount;
        }
    }
    return aliveCount;
}

bool IsSnakeVisible(const AISnake& aiSnake, const Camera& camera) {
    if (IsCircleInScreen(aiSnake.position - camera.position, aiSnake.radius + 8.0f)) {
        return true;
    }

    for (const auto& segment : aiSnake.segments) {
        if (segment.radius <= 0.0f) {
            continue;
        }
        if (IsCircleInScreen(segment.position - camera.position, segment.radius + 6.0f)) {
            return true;
        }
    }

    return false;
}

void DrawStatusChip(int left, int top, LPCTSTR label, COLORREF fillColor, COLORREF borderColor, COLORREF textColor) {
    settextstyle(17, 0, _T("Bahnschrift"));
    const int chipWidth = textwidth(label) + 24;
    DrawRoundedPanel(left, top, left + chipWidth, top + 30, 12, fillColor, borderColor);
    setbkmode(TRANSPARENT);
    settextcolor(textColor);
    outtextxy(left + 12, top + 5, label);
}

Vector2 ProjectWorldToMinimapPoint(const Vector2& worldPosition, int left, int top, int width, int height) {
    const float worldWidth = static_cast<float>(GameConfig::PLAY_AREA_RIGHT - GameConfig::PLAY_AREA_LEFT);
    const float worldHeight = static_cast<float>(GameConfig::PLAY_AREA_BOTTOM - GameConfig::PLAY_AREA_TOP);
    const float normalizedX = (worldPosition.x - static_cast<float>(GameConfig::PLAY_AREA_LEFT)) / worldWidth;
    const float normalizedY = (worldPosition.y - static_cast<float>(GameConfig::PLAY_AREA_TOP)) / worldHeight;

    return Vector2(
        static_cast<float>(left) + (std::clamp)(normalizedX, 0.0f, 1.0f) * static_cast<float>(width),
        static_cast<float>(top) + (std::clamp)(normalizedY, 0.0f, 1.0f) * static_cast<float>(height));
}

void DrawMinimapPanel(const GameRuntimeContext& runtime, const GameUISnapshot& snapshot) {
    const int panelLeft = GameConfig::WINDOW_WIDTH - 228;
    const int panelTop = 16;
    const int panelRight = GameConfig::WINDOW_WIDTH - 16;
    const int panelBottom = 224;
    const int mapLeft = panelLeft + 18;
    const int mapTop = panelTop + 48;
    const int mapWidth = 176;
    const int mapHeight = 122;

    DrawRoundedPanel(panelLeft, panelTop, panelRight, panelBottom, 22, RGB(14, 21, 33), RGB(72, 103, 145));

    setbkmode(TRANSPARENT);
    settextstyle(20, 0, _T("Bahnschrift"));
    settextcolor(RGB(238, 246, 255));
    outtextxy(panelLeft + 18, panelTop + 16, _T("Arena Radar"));

    DrawRoundedPanel(mapLeft, mapTop, mapLeft + mapWidth, mapTop + mapHeight, 14, RGB(10, 16, 26), RGB(58, 84, 120));

    setlinecolor(RGB(35, 54, 79));
    for (int i = 1; i < 4; ++i) {
        const int gridX = mapLeft + (mapWidth * i) / 4;
        const int gridY = mapTop + (mapHeight * i) / 4;
        line(gridX, mapTop + 8, gridX, mapTop + mapHeight - 8);
        line(mapLeft + 8, gridY, mapLeft + mapWidth - 8, gridY);
    }

    const Vector2 playerMapPoint = ProjectWorldToMinimapPoint(runtime.playerSnake.position, mapLeft, mapTop, mapWidth, mapHeight);
    const auto& camera = GameState::Instance().camera;
    const Vector2 viewTopLeft = ProjectWorldToMinimapPoint(camera.position, mapLeft, mapTop, mapWidth, mapHeight);
    const Vector2 viewBottomRight = ProjectWorldToMinimapPoint(
        camera.position + Vector2(static_cast<float>(GameConfig::WINDOW_WIDTH), static_cast<float>(GameConfig::WINDOW_HEIGHT)),
        mapLeft,
        mapTop,
        mapWidth,
        mapHeight);

    setlinecolor(snapshot.isInLava ? RGB(255, 120, 80) : RGB(102, 160, 214));
    rectangle(
        static_cast<int>(viewTopLeft.x),
        static_cast<int>(viewTopLeft.y),
        static_cast<int>(viewBottomRight.x),
        static_cast<int>(viewBottomRight.y));

    int drawnAiDots = 0;
    for (const auto& aiSnake : runtime.aiSnakeList) {
        if (aiSnake.isDead || aiSnake.radius <= 0.0f) {
            continue;
        }

        const Vector2 aiPoint = ProjectWorldToMinimapPoint(aiSnake.position, mapLeft, mapTop, mapWidth, mapHeight);
        setfillcolor(RGB(255, 188, 92));
        fillcircle(static_cast<int>(aiPoint.x), static_cast<int>(aiPoint.y), 2);

        ++drawnAiDots;
        if (drawnAiDots >= 40) {
            break;
        }
    }

    setfillcolor(RGB(87, 233, 167));
    setlinecolor(RGB(180, 255, 220));
    fillcircle(static_cast<int>(playerMapPoint.x), static_cast<int>(playerMapPoint.y), 4);

    settextstyle(16, 0, _T("Segoe UI"));
    settextcolor(RGB(173, 196, 225));
    TCHAR aliveText[64];
    _stprintf_s(aliveText, _T("AI Alive: %d"), CountLivingAISnakes(runtime.aiSnakeList));
    outtextxy(panelLeft + 18, panelBottom - 46, aliveText);

    TCHAR coordText[80];
    _stprintf_s(coordText, _T("Player: %.0f, %.0f"), runtime.playerSnake.position.x, runtime.playerSnake.position.y);
    outtextxy(panelLeft + 18, panelBottom - 22, coordText);
}

void DrawPlayerBoostTrail(const PlayerSnake& playerSnake, const Camera& camera) {
    auto& gameState = GameState::Instance();
    if (!gameState.isSpeedBoostActive) {
        return;
    }

    const Vector2 normalizedDirection = playerSnake.direction.LengthSquared() > 0.0f
        ? playerSnake.direction.Normalized()
        : Vector2(0.0f, 1.0f);
    const Vector2 headScreenPosition = playerSnake.position - camera.position;
    const float pulse = 0.5f + 0.5f * sinf(gameState.gameStartTime * 10.0f);

    const int trailCount = 4;
    for (int i = 0; i < trailCount; ++i) {
        const float ratio = static_cast<float>(i) / (std::max)(1, trailCount - 1);
        const float trailDistance = playerSnake.radius * (1.2f + ratio * 1.8f);
        const Vector2 trailPosition =
            headScreenPosition - normalizedDirection * trailDistance;
        const float trailRadius = playerSnake.radius * (0.55f - ratio * 0.18f);
        const int trailColor = i % 2 == 0 ? RGB(90, 220, 255) : RGB(220, 250, 255);

        if (!IsCircleInScreen(trailPosition, trailRadius + 8.0f)) {
            continue;
        }

        setfillcolor(trailColor);
        setlinecolor(trailColor);
        fillcircle(static_cast<int>(trailPosition.x), static_cast<int>(trailPosition.y), static_cast<int>(trailRadius));
    }

    const float auraRadius = playerSnake.radius * (1.7f + pulse * 0.25f);
    if (!IsCircleInScreen(headScreenPosition, auraRadius + 8.0f)) {
        return;
    }
    setlinecolor(RGB(170, 245, 255));
    setlinestyle(PS_SOLID, 2);
    circle(static_cast<int>(headScreenPosition.x), static_cast<int>(headScreenPosition.y), static_cast<int>(auraRadius));
    setlinestyle(PS_SOLID, 1);
}

void DrawMouseReticle(const PlayerSnake& playerSnake, const Camera& camera) {
    auto& gameState = GameState::Instance();
    if (!gameState.IsMouseControlEnabled()) {
        return;
    }

    const Vector2 mousePosition = gameState.GetGameplayMouseScreenPosition();
    if (!IsPointInsideGameplayViewport(mousePosition)) {
        return;
    }

    const Vector2 playerScreenPosition = playerSnake.position - camera.position;
    const float pulse = 0.5f + 0.5f * sinf(gameState.gameStartTime * 6.0f);
    const int reticleRadius = static_cast<int>(10.0f + pulse * 4.0f);

    setlinecolor(RGB(90, 220, 255));
    setlinestyle(PS_SOLID, 1);
    line(
        static_cast<int>(playerScreenPosition.x),
        static_cast<int>(playerScreenPosition.y),
        static_cast<int>(mousePosition.x),
        static_cast<int>(mousePosition.y));

    circle(static_cast<int>(mousePosition.x), static_cast<int>(mousePosition.y), reticleRadius);
    line(static_cast<int>(mousePosition.x) - reticleRadius - 4, static_cast<int>(mousePosition.y),
         static_cast<int>(mousePosition.x) - 4, static_cast<int>(mousePosition.y));
    line(static_cast<int>(mousePosition.x) + 4, static_cast<int>(mousePosition.y),
         static_cast<int>(mousePosition.x) + reticleRadius + 4, static_cast<int>(mousePosition.y));
    line(static_cast<int>(mousePosition.x), static_cast<int>(mousePosition.y) - reticleRadius - 4,
         static_cast<int>(mousePosition.x), static_cast<int>(mousePosition.y) - 4);
    line(static_cast<int>(mousePosition.x), static_cast<int>(mousePosition.y) + 4,
         static_cast<int>(mousePosition.x), static_cast<int>(mousePosition.y) + reticleRadius + 4);
}
}

void DrawGameArea() {
    setbkcolor(RGB(20, 20, 20));
    cleardevice();

    // 绘制背景网格（考虑相机偏移）
    auto& gameState = GameState::Instance();
    Vector2 camPos = gameState.camera.position;

    // Use larger grid cells for better performance (reduce draw calls)
    int cellSize = GameConfig::GRID_CELL_SIZE * 2;  // Double the cell size

    // 计算网格起始位置（相对于相机）
    int startX = -static_cast<int>(camPos.x) % cellSize;
    int startY = -static_cast<int>(camPos.y) % cellSize;
    if (startX > 0) startX -= cellSize;
    if (startY > 0) startY -= cellSize;

    // Only draw grid lines (not filled rectangles) for performance
    setlinecolor(RGB(40, 40, 40));
    setlinestyle(PS_SOLID, 1);

    // Draw vertical lines
    for (int x = startX; x <= GameConfig::WINDOW_WIDTH + cellSize; x += cellSize) {
        line(x, 0, x, GameConfig::WINDOW_HEIGHT);
    }

    // Draw horizontal lines
    for (int y = startY; y <= GameConfig::WINDOW_HEIGHT + cellSize; y += cellSize) {
        line(0, y, GameConfig::WINDOW_WIDTH, y);
    }

    const BoundaryWarningOverlay overlay = BuildBoundaryWarningOverlay(camPos);

    // 绘制当前视口中真正越过世界边界的警告区域
    setfillcolor(RGB(50, 30, 30));
    if (overlay.topDangerHeight > 0) {
        solidrectangle(0, 0, GameConfig::WINDOW_WIDTH, overlay.topDangerHeight);
    }
    if (overlay.bottomDangerHeight > 0) {
        solidrectangle(
            0,
            GameConfig::WINDOW_HEIGHT - overlay.bottomDangerHeight,
            GameConfig::WINDOW_WIDTH,
            GameConfig::WINDOW_HEIGHT);
    }
    if (overlay.leftDangerWidth > 0) {
        solidrectangle(0, 0, overlay.leftDangerWidth, GameConfig::WINDOW_HEIGHT);
    }
    if (overlay.rightDangerWidth > 0) {
        solidrectangle(
            GameConfig::WINDOW_WIDTH - overlay.rightDangerWidth,
            0,
            GameConfig::WINDOW_WIDTH,
            GameConfig::WINDOW_HEIGHT);
    }

    setlinecolor(RGB(150, 50, 50));
    setlinestyle(PS_SOLID, 3);
    if (overlay.topDangerHeight > 0 && overlay.topDangerHeight < GameConfig::WINDOW_HEIGHT) {
        line(0, overlay.topDangerHeight, GameConfig::WINDOW_WIDTH, overlay.topDangerHeight);
    }
    if (overlay.bottomDangerHeight > 0 && overlay.bottomDangerHeight < GameConfig::WINDOW_HEIGHT) {
        const int bottomBoundaryY = GameConfig::WINDOW_HEIGHT - overlay.bottomDangerHeight;
        line(0, bottomBoundaryY, GameConfig::WINDOW_WIDTH, bottomBoundaryY);
    }
    if (overlay.leftDangerWidth > 0 && overlay.leftDangerWidth < GameConfig::WINDOW_WIDTH) {
        line(overlay.leftDangerWidth, 0, overlay.leftDangerWidth, GameConfig::WINDOW_HEIGHT);
    }
    if (overlay.rightDangerWidth > 0 && overlay.rightDangerWidth < GameConfig::WINDOW_WIDTH) {
        const int rightBoundaryX = GameConfig::WINDOW_WIDTH - overlay.rightDangerWidth;
        line(rightBoundaryX, 0, rightBoundaryX, GameConfig::WINDOW_HEIGHT);
    }
    setlinestyle(PS_SOLID, 1);
}

void DrawFoods(const FoodItem* foodList, int foodCount) {
    const FoodSpatialGrid* foodGrid = GetFoodSpatialGrid();
    Vector2 camPos = GameState::Instance().camera.position;

    // Use spatial grid to only draw visible foods
    if (foodGrid) {
        std::vector<int> visibleFoods;
        Vector2 minPos(camPos.x - 50, camPos.y - 50);
        Vector2 maxPos(camPos.x + GameConfig::WINDOW_WIDTH + 50, camPos.y + GameConfig::WINDOW_HEIGHT + 50);
        foodGrid->QueryRect(minPos, maxPos, visibleFoods);
        const int detailLevel = visibleFoods.size() > 260 ? 0 : (visibleFoods.size() > 140 ? 1 : 2);

        for (int idx : visibleFoods) {
            if (idx < 0 || idx >= foodCount) continue;
            if (foodList[idx].collisionRadius <= 0) continue;

            Vector2 screenPos = foodList[idx].position - camPos;
            DrawEnhancedFood(screenPos, foodList[idx].collisionRadius, foodList[idx].colorValue, idx, detailLevel);
        }
        return;
    }

    // Fallback: iterate all foods if grid not available
    for (int i = 0; i < foodCount; i++) {
        if (foodList[i].collisionRadius <= 0) continue;

        // 转换为相对于相机的屏幕坐标
        Vector2 screenPos = foodList[i].position - camPos;

        // Skip foods outside visible area
        if (screenPos.x < -50 || screenPos.x > GameConfig::WINDOW_WIDTH + 50 ||
            screenPos.y < -50 || screenPos.y > GameConfig::WINDOW_HEIGHT + 50) {
            continue;
        }

        DrawEnhancedFood(screenPos, foodList[i].collisionRadius, foodList[i].colorValue, i, 1);
    }
}

void DrawVisibleObjects(const FoodItem* foodList, int foodCount,
                        const AISnake* aiSnakes, int aiSnakeCount,
                        const PlayerSnake& playerSnake) {
    DrawFoods(foodList, foodCount);

    for (int i = 0; i < aiSnakeCount; i++) {
        if (aiSnakes[i].radius <= 0 || aiSnakes[i].isDead) continue;
        if (!IsSnakeVisible(aiSnakes[i], GameState::Instance().camera)) continue;
        aiSnakes[i].Draw(GameState::Instance().camera);
    }

    DrawPlayerBoostTrail(playerSnake, GameState::Instance().camera);
    playerSnake.Draw(GameState::Instance().camera);
    DrawMouseReticle(playerSnake, GameState::Instance().camera);
}

void DrawCircleWithCamera(const Vector2& screenPos, float r, int c) {
    setfillcolor(c);
    setlinecolor(c);
    fillcircle(static_cast<int>(screenPos.x), static_cast<int>(screenPos.y), static_cast<int>(r));
}

void DebugDrawText(const std::wstring& text, int x, int y, int color) {
    settextstyle(16, 0, _T("Arial"));
    settextcolor(color);
    outtextxy(x, y, text.c_str());
}

void DrawSnakeEyes(const Vector2& position, const Vector2& direction, float radius) {
    Vector2 eyeOffset = direction * radius * 0.4f;
    Vector2 perpOffset(direction.y, -direction.x);

    Vector2 eye1 = position + eyeOffset + perpOffset * radius * 0.4f;
    Vector2 eye2 = position + eyeOffset - perpOffset * radius * 0.4f;

    setfillcolor(RGB(255, 255, 255));
    fillcircle(static_cast<int>(eye1.x), static_cast<int>(eye1.y), static_cast<int>(radius * 0.2f));
    fillcircle(static_cast<int>(eye2.x), static_cast<int>(eye2.y), static_cast<int>(radius * 0.2f));

    setfillcolor(RGB(0, 0, 0));
    fillcircle(static_cast<int>(eye1.x + direction.x * radius * 0.1f),
               static_cast<int>(eye1.y + direction.y * radius * 0.1f),
               static_cast<int>(radius * 0.1f));
    fillcircle(static_cast<int>(eye2.x + direction.x * radius * 0.1f),
               static_cast<int>(eye2.y + direction.y * radius * 0.1f),
               static_cast<int>(radius * 0.1f));
}

bool IsCircleInScreen(const Vector2& center, float r) {
    const float margin = (std::max)(8.0f, r + 16.0f);
    return center.x + margin >= 0.0f &&
        center.x - margin <= static_cast<float>(GameConfig::WINDOW_WIDTH) &&
        center.y + margin >= 0.0f &&
        center.y - margin <= static_cast<float>(GameConfig::WINDOW_HEIGHT);
}

void DrawUI() {
    const GameUISnapshot snapshot = GameState::Instance().GetUISnapshot();
    const auto& runtime = GameRuntime();
    auto& gameState = GameState::Instance();
    const int scorePanelLeft = 16;
    const int scorePanelTop = 16;
    const int scorePanelRight = 250;
    const int scorePanelBottom = 148;
    const int statusPanelLeft = 16;
    const int statusPanelTop = 164;
    const int statusPanelRight = 362;
    const int statusPanelBottom = 244;

    DrawRoundedPanel(scorePanelLeft, scorePanelTop, scorePanelRight, scorePanelBottom, 22, RGB(14, 21, 33), RGB(72, 103, 145));
    DrawRoundedPanel(statusPanelLeft, statusPanelTop, statusPanelRight, statusPanelBottom, 22, RGB(14, 21, 33), RGB(72, 103, 145));

    setbkmode(TRANSPARENT);
    settextstyle(18, 0, _T("Bahnschrift"));
    settextcolor(RGB(174, 198, 228));
    outtextxy(scorePanelLeft + 18, scorePanelTop + 14, _T("Run Status"));

    settextstyle(40, 0, _T("Bahnschrift"));
    settextcolor(RGB(245, 248, 255));
    TCHAR scoreValue[32];
    _stprintf_s(scoreValue, _T("%d"), snapshot.score);
    outtextxy(scorePanelLeft + 18, scorePanelTop + 42, scoreValue);

    settextstyle(16, 0, _T("Segoe UI"));
    settextcolor(RGB(183, 204, 229));
    outtextxy(scorePanelLeft + 20, scorePanelTop + 94, _T("Player"));
    outtextxy(scorePanelLeft + 128, scorePanelTop + 94, _T("AI Alive"));

    TCHAR playerText[64];
    _stprintf_s(playerText, _T("(%.0f, %.0f)"), runtime.playerSnake.position.x, runtime.playerSnake.position.y);
    outtextxy(scorePanelLeft + 20, scorePanelTop + 118, playerText);
    TCHAR aiAliveText[32];
    _stprintf_s(aiAliveText, _T("%d"), CountLivingAISnakes(runtime.aiSnakeList));
    outtextxy(scorePanelLeft + 128, scorePanelTop + 118, aiAliveText);

    settextstyle(18, 0, _T("Bahnschrift"));
    settextcolor(RGB(174, 198, 228));
    outtextxy(statusPanelLeft + 18, statusPanelTop + 14, _T("Live Systems"));

    int chipX = statusPanelLeft + 18;
    int chipY = statusPanelTop + 42;
    DrawStatusChip(chipX, chipY,
        gameState.IsMouseControlEnabled() ? _T("Control: Mouse") : _T("Control: Keyboard"),
        gameState.IsMouseControlEnabled() ? RGB(19, 65, 89) : RGB(34, 43, 57),
        gameState.IsMouseControlEnabled() ? RGB(89, 205, 255) : RGB(98, 117, 143),
        gameState.IsMouseControlEnabled() ? RGB(194, 243, 255) : RGB(190, 204, 224));

    chipX += 148;
    DrawStatusChip(chipX, chipY,
        gameState.isSpeedBoostActive ? _T("Boost: x2") : _T("Boost: ready"),
        gameState.isSpeedBoostActive ? RGB(79, 56, 19) : RGB(34, 43, 57),
        gameState.isSpeedBoostActive ? RGB(255, 209, 109) : RGB(98, 117, 143),
        gameState.isSpeedBoostActive ? RGB(255, 238, 194) : RGB(190, 204, 224));

    chipX = statusPanelLeft + 18;
    chipY += 38;
    if (snapshot.isInvulnerable) {
        TCHAR shieldText[64];
        _stprintf_s(shieldText, _T("Shield: %.1fs"), snapshot.remainingInvulnerabilityTime);
        DrawStatusChip(chipX, chipY, shieldText, RGB(16, 67, 77), RGB(98, 235, 255), RGB(205, 248, 255));
        chipX += textwidth(shieldText) + 42;
    }

    if (snapshot.isInLava) {
        TCHAR lavaText[64];
        _stprintf_s(lavaText, _T("Lava: %.1fs"), snapshot.remainingLavaWarningTime);
        DrawStatusChip(chipX, chipY, lavaText, RGB(84, 35, 26), RGB(255, 144, 103), RGB(255, 229, 215));
    }

    DrawMinimapPanel(runtime, snapshot);
}

void DrawEnhancedFood(const Vector2& screenPos, float radius, int color, int index, int detailLevel) {
    const float time = GameState::Instance().gameStartTime;
    const float pulse = 0.5f + 0.5f * sinf(time * 4.5f + index * 0.37f);
    const int glowColor = BrightenColor(color, 70);

    if (detailLevel >= 1 && GameConfig::ANIMATIONS_ON) {
        setlinecolor(glowColor);
        setlinestyle(PS_SOLID, 1);
        circle(
            static_cast<int>(screenPos.x),
            static_cast<int>(screenPos.y),
            static_cast<int>(radius * (1.4f + pulse * 0.25f)));
    }

    DrawCircleWithCamera(screenPos, radius, color);

    setfillcolor(BrightenColor(color, 110));
    fillcircle(
        static_cast<int>(screenPos.x - radius * 0.35f),
        static_cast<int>(screenPos.y - radius * 0.35f),
        static_cast<int>((std::max)(1.0f, radius * 0.35f)));

    if (detailLevel >= 2 && GameConfig::ANIMATIONS_ON && (index % 3 == 0)) {
        const float sparkleAngle = time * 3.0f + static_cast<float>(index);
        const Vector2 sparklePosition(
            screenPos.x + cosf(sparkleAngle) * radius * 1.4f,
            screenPos.y + sinf(sparkleAngle) * radius * 1.4f);
        setfillcolor(WHITE);
        fillcircle(
            static_cast<int>(sparklePosition.x),
            static_cast<int>(sparklePosition.y),
            static_cast<int>((std::max)(1.0f, radius * 0.2f)));
    }
}

void DrawSnakeSegment(const Vector2& screenPos, float radius, int color, size_t segmentIndex) {
    DrawCircleWithCamera(screenPos, radius, color);
}

void DrawPauseMenu() {
    const int boxWidth = 520;
    const int boxHeight = 292;
    const int boxX = (GameConfig::WINDOW_WIDTH - boxWidth) / 2;
    const int boxY = (GameConfig::WINDOW_HEIGHT - boxHeight) / 2;
    const int boxRight = boxX + boxWidth;
    const int boxBottom = boxY + boxHeight;
    const GameUISnapshot snapshot = GameState::Instance().GetUISnapshot();

    setfillcolor(RGB(7, 11, 19));
    solidrectangle(0, 0, GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT);
    setfillcolor(RGB(18, 51, 70));
    solidcircle(boxX + 56, boxY + 54, 52);
    setfillcolor(RGB(19, 29, 44));
    solidcircle(boxRight - 54, boxBottom - 46, 68);
    DrawRoundedPanel(boxX, boxY, boxRight, boxBottom, 28, RGB(16, 24, 37), RGB(82, 113, 158));
    DrawRoundedPanel(boxX + 24, boxY + 22, boxRight - 24, boxY + 96, 20, RGB(24, 41, 59), RGB(65, 98, 135));

    setbkmode(TRANSPARENT);
    settextstyle(18, 0, _T("Bahnschrift"));
    settextcolor(RGB(170, 197, 227));
    outtextxy(boxX + 40, boxY + 34, _T("Session Control"));

    settextstyle(42, 0, _T("Bahnschrift"));
    settextcolor(RGB(242, 248, 255));
    outtextxy(boxX + 38, boxY + 50, _T("PAUSED"));

    settextstyle(19, 0, _T("Segoe UI"));
    settextcolor(RGB(183, 202, 225));
    outtextxy(boxX + 38, boxY + 124, _T("ESC / P / S"));
    outtextxy(boxX + 180, boxY + 124, _T("Resume the run"));
    outtextxy(boxX + 38, boxY + 160, _T("M"));
    outtextxy(boxX + 180, boxY + 160, _T("Return to main menu"));
    outtextxy(boxX + 38, boxY + 196, _T("Q"));
    outtextxy(boxX + 180, boxY + 196, _T("Exit the game"));

    DrawRoundedPanel(boxRight - 168, boxY + 120, boxRight - 32, boxY + 214, 18, RGB(23, 33, 49), RGB(68, 97, 137));
    settextstyle(18, 0, _T("Bahnschrift"));
    settextcolor(RGB(173, 196, 225));
    outtextxy(boxRight - 148, boxY + 138, _T("Current Run"));
    settextstyle(16, 0, _T("Segoe UI"));
    settextcolor(RGB(234, 242, 255));
    TCHAR scoreText[48];
    _stprintf_s(scoreText, _T("Score: %d"), snapshot.score);
    outtextxy(boxRight - 148, boxY + 170, scoreText);
    outtextxy(boxRight - 148, boxY + 194, snapshot.isInLava ? _T("Status: danger") : _T("Status: stable"));

    settextstyle(17, 0, _T("Segoe UI"));
    settextcolor(RGB(157, 182, 214));
    outtextxy(boxX + 38, boxBottom - 38, _T("Mouse steer and boost state are preserved cleanly when you resume."));
}
