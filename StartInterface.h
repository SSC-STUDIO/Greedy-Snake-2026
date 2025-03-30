#pragma once
#include "GameConfig.h"
#include "Button.h"
#include <graphics.h>

extern std::vector<Button> buttonList; // 按钮列表

// 菜单选项枚举
enum class MenuOption {
    START, // 开始
    SETTINGS, // 设置
    ABOUT, // 关于
    EXIT // 退出
};
void LoadButton();

void DrawMenu();
