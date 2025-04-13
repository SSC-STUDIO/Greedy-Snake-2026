#include "Draw.h"
#include "Snake.h"
#include "Camera.h"
#include "GameConfig.h"
#include "GameState.h"
#include "../UI/UI.h"

void Draw::Initial() {
    Initialize();
}

void Draw::Update() {
    // 如果暂停菜单正在显示，不执行任何绘图操作
    if (GameState::isMenuShowing) {
        return;
    }

    BeginBatchDraw();

    // 清屏
    cleardevice();

    // 绘制背景
    DrawBackground();

    // 绘制UI
    DrawUI();

    // 绘制蛇
    DrawSnake();

    // 绘制蛇头
    DrawHead();

    // 绘制食物
    DrawFood();

    // 绘制岩浆块
    DrawLava();

    // 绘制墙壁
    DrawWalls();

    // 绘制碰撞闪烁效果
    DrawCollisionFlash();

    // 绘制无敌效果
    DrawInvulnerabilityEffect();

    // 如果游戏暂停但不是显示菜单，绘制暂停文本
    if (GameState::isPaused && !GameState::isMenuShowing) {
        DrawPausedText();
    }

    // 结束批量绘制
    FlushBatchDraw();
    EndBatchDraw();
}

// ... existing code ... 