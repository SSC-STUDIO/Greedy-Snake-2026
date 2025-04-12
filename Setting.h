#pragma once
#include "GameConfig.h"
#include "GameState.h"
#include <tchar.h>
#include <windows.h>
#pragma comment(lib, "winmm.lib") 
#pragma warning(disable: 4996)	 // Disable security warnings for _tcscpy and _stprintf functions

// Game settings structure
struct GameSettings {
    float volume;         // Volume (0.0-1.0)
    int difficulty;       // Difficulty (0-Easy, 1-Normal, 2-Hard)
    bool soundOn;         // Sound toggle
    int snakeSpeed;       // Snake speed (0-Slow, 1-Normal, 2-Fast)
};

// Set volume (0.0-1.0)
void SetVolume(float volume);

// Apply settings
void ApplySettings(const GameSettings& settings);

// Display settings interface
void ShowSettings(int windowWidth, int windowHeight);
