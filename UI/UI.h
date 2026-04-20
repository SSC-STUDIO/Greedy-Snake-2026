#pragma once
#include "../Gameplay/GameConfig.h"
#include "Button.h"
#include <graphics.h>
#include <windows.h>

// Button list
extern std::vector<Button> buttonList;

// Menu option enumeration
enum class MenuOption {
    START,
    SETTINGS,
    ABOUT,
    EXIT
};

// Load button resources for the menu
void LoadButton();

// Draw the main menu interface
void DrawMenu(const Vector2& mousePosition);

// Display "About" information screen
void ShowAbout();

// Display game main menu, returns user's menu selection
int ShowGameMenu();
void ShowLandingScreen();
void PlaySceneTransition(LPCTSTR title, LPCTSTR subtitle, COLORREF accentColor, bool entering);
void PlaySceneTransition(LPCTSTR title, COLORREF accentColor, bool entering);
void PlaySessionIntroSequence(LPCTSTR title, LPCTSTR subtitle, COLORREF accentColor);

// Sound & Animation Functions
// Play background music
void PlayBackgroundMusic();

// Stop background music
void StopBackgroundMusic();

// Play start animation music and animation
void PlayStartAnimation();

// Cleanup audio resources before exiting
void CleanupAudioResources();
