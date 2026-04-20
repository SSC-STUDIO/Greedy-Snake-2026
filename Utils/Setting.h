#pragma once
#include "../Core/AppSettings.h"
#include <windows.h>
#include <mmsystem.h>
#include <tchar.h>
#include "../ModernCore/Vector2.h"
#pragma comment(lib, "winmm.lib")
#pragma warning(disable: 4996)

using Vector2 = GreedSnake::Vector2;	 // Disable security warnings for _tcscpy and _stprintf functions

// Set volume (0.0-1.0)
void SetVolume(float volume);

// Apply settings
void ApplySettings(const GameSettings& settings);
void InitializeDisplayConfig(const GameSettings& settings);
void ApplyDisplayModeToCurrentWindow();

// Read the persistent application settings used for the next session.
GameSettings GetCurrentSettings();

// Display settings interface
void ShowSettings(int windowWidth, int windowHeight);
