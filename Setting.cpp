#include "Setting.h"
#include "GameState.h"
#include <mmsystem.h>
#include <tchar.h>

// 设置音量
void SetVolume(float volume) {
    // 确保音量在0-1范围内
    volume = max(0.0f, min(1.0f, volume));
    
    // 将0-1的音量值转换为0-0xFFFF范围
    DWORD volumeValue = static_cast<DWORD>(volume * 0xFFFF);
    
    // 设置左右声道的音量
    DWORD volumeSetting = (volumeValue << 16) | volumeValue;
    
    // 使用Windows多媒体API设置音量
    waveOutSetVolume(0, volumeSetting);
}

// 应用设置
void ApplySettings(const GameSettings& settings) {
    // 应用音量设置
    SetVolume(settings.musicVolume);
    
    // 应用难度设置
    switch (settings.difficulty) {
        case 1: // Easy
            GameState::Instance().SetDifficulty(GameState::GameDifficulty::Easy);
            break;
        case 2: // Normal
            GameState::Instance().SetDifficulty(GameState::GameDifficulty::Normal);
            break;
        case 3: // Hard
            GameState::Instance().SetDifficulty(GameState::GameDifficulty::Hard);
            break;
    }
    
    // 应用声音开关设置
    if (!settings.enableSound) {
        SetVolume(0.0f);
    }
    
    // 应用蛇速度设置
    GameState::Instance().currentPlayerSpeed = settings.snakeSpeed;
}