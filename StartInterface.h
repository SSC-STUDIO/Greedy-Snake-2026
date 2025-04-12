#pragma once
#include "GameConfig.h"
#include "Button.h"
#include <graphics.h>

extern std::vector<Button> buttonList; // Button list

// Menu option enumeration
enum class MenuOption {
    START, // Start
    SETTINGS, // Settings
    ABOUT, // About
    EXIT // Exit
};
void LoadButton();

void DrawMenu();
