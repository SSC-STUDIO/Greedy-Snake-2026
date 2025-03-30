#pragma once
#include "GameConfig.h"
#include "GameState.h"
#include <tchar.h>
#include <windows.h>
#pragma comment(lib, "winmm.lib") 
#pragma warning(disable: 4996)	 // 禁用关于 _tcscpy 和 _stprintf 的安全警告

// 设置结构
struct GameSettings {
    float musicVolume = GameConfig::DEFAULT_VOLUME; // 音乐音量
    bool enableSound = true; // 启用声音
    int difficulty = 1;  // 1: 简单, 2: 普通, 3: 困难
    float snakeSpeed = GameConfig::DEFAULT_PLAYER_SPEED; // 蛇速度
};

void SetVolume(float volume);
void ApplySettings(const GameSettings& settings);
void ShowSettings(int windowWidth, int windowHeight);
