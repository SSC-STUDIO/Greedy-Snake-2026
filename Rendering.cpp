#include "Rendering.h"
#pragma warning(disable: 4996)	 // 禁用关于 _tcscpy 和 _stprintf 的安全警告

void DrawGameArea() {
    // ���Ʊ���
    setbkcolor(RGB(30, 30, 30));
    cleardevice();

    // ��ȡ�����λ��
    Vector2 cameraPos = GameState::Instance().camera.position;

    // ����ɼ�����
    float screenLeft = cameraPos.x;
    float screenRight = cameraPos.x + GameConfig::WINDOW_WIDTH;
    float screenTop = cameraPos.y;
    float screenBottom = cameraPos.y + GameConfig::WINDOW_HEIGHT;

    // �����ҽ�������Ϸ�߽��������- ����ɫ����
    // ���ȼ����Щ�߽�����Ұ��
    setfillcolor(RGB(80, 20, 20)); // ����ɫ

    // ��鲢�����ϱ߽����ҽ�����
    if (screenTop < GameConfig::PLAY_AREA_TOP) {
        solidrectangle(0, 0,
            GameConfig::WINDOW_WIDTH,
            GameConfig::PLAY_AREA_TOP - cameraPos.y);
    }

    // ��鲢�����±߽����ҽ�����
    if (screenBottom > GameConfig::PLAY_AREA_BOTTOM) {
        solidrectangle(0,
            GameConfig::PLAY_AREA_BOTTOM - cameraPos.y,
            GameConfig::WINDOW_WIDTH,
            GameConfig::WINDOW_HEIGHT);
    }

    // ��鲢������߽����ҽ�����
    if (screenLeft < GameConfig::PLAY_AREA_LEFT) {
        solidrectangle(0, 0,
            GameConfig::PLAY_AREA_LEFT - cameraPos.x,
            GameConfig::WINDOW_HEIGHT);
    }

    // ��鲢�����ұ߽����ҽ�����
    if (screenRight > GameConfig::PLAY_AREA_RIGHT) {
        solidrectangle(GameConfig::PLAY_AREA_RIGHT - cameraPos.x,
            0,
            GameConfig::WINDOW_WIDTH,
            GameConfig::WINDOW_HEIGHT);
    }

    // ������Ϸ�߽���
    setlinecolor(RGB(150, 50, 50)); // �߽�����ɫ
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
    // 计算可见区域
    Vector2 cameraPos = GameState::Instance().camera.position;
    float screenLeft = cameraPos.x;
    float screenRight = cameraPos.x + GameConfig::WINDOW_WIDTH;
    float screenTop = cameraPos.y;
    float screenBottom = cameraPos.y + GameConfig::WINDOW_HEIGHT;

    // 扩展可见区域，考虑到大型对象可能部分可见
    float margin = 100.0f;  // 足够大的边距
    screenLeft -= margin;
    screenRight += margin;
    screenTop -= margin;
    screenBottom += margin;

    // 只绘制可见区域内的食物
    for (int i = 0; i < foodCount; ++i) {
        const auto& food = foodList[i];
        if (food.position.x >= screenLeft && food.position.x <= screenRight &&
            food.position.y >= screenTop && food.position.y <= screenBottom) {
            Vector2 foodScreenPos = food.position - cameraPos;
            DrawCircleWithCamera(foodScreenPos, food.collisionRadius, food.colorValue);
        }
    }

    // 只绘制可见区域内的AI蛇
    for (int i = 0; i < aiSnakeCount; ++i) {
        const auto& snake = aiSnakes[i];
        if (snake.position.x >= screenLeft && snake.position.x <= screenRight &&
            snake.position.y >= screenTop && snake.position.y <= screenBottom) {
            // 绘制AI蛇头
            Vector2 windowPos = snake.position - cameraPos;
            DrawCircleWithCamera(windowPos, snake.radius, snake.color);
            DrawSnakeEyes(windowPos, snake.direction, snake.radius);

            // 绘制AI蛇身 - 修改这部分，不使用基于范围的for循环
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

    // 绘制玩家蛇头和身体
    // 检查玩家头部是否在可见区域
    if (playerSnake.position.x >= screenLeft && playerSnake.position.x <= screenRight &&
        playerSnake.position.y >= screenTop && playerSnake.position.y <= screenBottom) {
        // 绘制头部
        Vector2 headPos = playerSnake.position - cameraPos;
        DrawCircleWithCamera(headPos, playerSnake.radius, playerSnake.color);
        DrawSnakeEyes(headPos, playerSnake.direction, playerSnake.radius);
    }
    
    // 绘制玩家蛇身体 - 同样修改为不使用基于范围的for循环
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
        return; // ���������Ļ�ڣ�����
    }
    setlinecolor(c); // ����������ɫ
    setfillcolor(c); // ���������ɫ
    fillcircle(screenPos.x, screenPos.y, r); // ����Բ
}

void DebugDrawText(const std::wstring& text, int x, int y, int color) {
    settextcolor(color); // �����ı���ɫ
    outtextxy(x, y, text.c_str()); // �����ı�
}
void DrawSnakeEyes(const Vector2& position, const Vector2& direction, float radius) {
    // ͳһ�����ߵ��۾���ʽ
    float eyeRadius = radius * 0.3f;  // �۾���С����

    // �淶����������
    Vector2 normalizedDir = direction.GetNormalize();
    // ���㴹ֱ�ڷ�������������������۷ֲ���
    Vector2 perpDir(-normalizedDir.y, normalizedDir.x);

    // �����۾�λ�ã�ʹ������� - ��Сǰ�ƣ�������ͷ����
    Vector2 eyeOffset = normalizedDir * (radius * 0.25f);  // ������һ��
    Vector2 sideOffset = perpDir * (radius * 0.4f);  // �������Ҽ��

    // ����������λ��
    Vector2 leftEyePos = position + eyeOffset + sideOffset;
    Vector2 rightEyePos = position + eyeOffset - sideOffset;

    // �����۰�
    setfillcolor(WHITE);
    fillcircle(leftEyePos.x, leftEyePos.y, eyeRadius);
    fillcircle(rightEyePos.x, rightEyePos.y, eyeRadius);

    // ����ͫ�ױ�������ͫ�׸��������
    float pupilRadius = eyeRadius * 0.7f;  // ����ͫ�ױ���
    setfillcolor(BLACK);

    // ͫ��λ�ô��ƫ�ƣ��Եø��ӿ���
    // ������Ӱ��Ŵ�1.5����������ת����������
    float pupilOffsetFactor = 1.5f;  // ����ƫ��ϵ����ʹ������������

    // ����ͫ��λ�ò�Ҫ�����۰�
    float maxPupilOffset = eyeRadius - pupilRadius * 0.9f;  // ��һ��߾࣬ȷ������ȫ����

    // ������ŵ�ͫ��ƫ��
    Vector2 pupilOffset = normalizedDir * (maxPupilOffset * pupilOffsetFactor);

    // ȷ��ͫ�ײ��ᳬ���۰׷�Χ
    float pupilOffsetLength = pupilOffset.GetLength();
    if (pupilOffsetLength > maxPupilOffset) {
        pupilOffset = pupilOffset * (maxPupilOffset / pupilOffsetLength);
    }

    // ���������۵�ͫ�ף�λ�ô��ƫ��
    fillcircle(leftEyePos.x + pupilOffset.x, leftEyePos.y + pupilOffset.y, pupilRadius);
    fillcircle(rightEyePos.x + pupilOffset.x, rightEyePos.y + pupilOffset.y, pupilRadius);

    // ����ͫ�׸߹⣬����������
    setfillcolor(WHITE);
    float highlightRadius = pupilRadius * 0.3f;

    // ��ͫ�������ӷ���߹⣬λ���������߷����෴
    Vector2 highlightOffset = normalizedDir * (-pupilRadius * 0.3f);

    fillcircle(leftEyePos.x + pupilOffset.x + highlightOffset.x,
        leftEyePos.y + pupilOffset.y + highlightOffset.y,
        highlightRadius);
    fillcircle(rightEyePos.x + pupilOffset.x + highlightOffset.x,
        rightEyePos.y + pupilOffset.y + highlightOffset.y,
        highlightRadius);
}

bool IsCircleInScreen(const Vector2& center, float r) {
    Vector2 minPoint = Vector2(center.x - r, center.y - r); // ������С��
    Vector2 maxPoint = Vector2(center.x + r, center.y + r); // ��������

    return !(maxPoint.x < 0 || minPoint.x > GameConfig::WINDOW_WIDTH || maxPoint.y < 0 || minPoint.y > GameConfig::WINDOW_HEIGHT); // ����Ƿ�����Ļ��
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
