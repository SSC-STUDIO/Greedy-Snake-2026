#include "Setting.h"
#include <algorithm>
#include <limits.h>

#pragma comment(lib, "winmm.lib")

namespace {

// 常量定义
constexpr float MIN_VOLUME = 0.0f;
constexpr float MAX_VOLUME = 1.0f;
constexpr int MIN_DIFFICULTY = 0;
constexpr int MAX_DIFFICULTY = 2;
constexpr int MIN_SPEED_INDEX = 0;
constexpr int MAX_SPEED_INDEX = 2;

/**
 * @brief 验证浮点值是否在有效范围内
 * @param value 输入值
 * @param min 最小值
 * @param max 最大值
 * @return 限制后的值
 */
float ClampFloat(float value, float min, float max) {
    if (std::isnan(value) || std::isinf(value)) {
        return min;
    }
    if (value < min) return min;
    if (value > max) return max;
    return value;
}

/**
 * @brief 验证整数值是否在有效范围内
 * @param value 输入值
 * @param min 最小值
 * @param max 最大值
 * @return 限制后的值
 */
int ClampIntValue(int value, int min, int max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
}

/**
 * @brief 验证滑块位置是否在有效范围内
 * @param x X坐标
 * @param sliderX 滑块起始X
 * @param sliderWidth 滑块宽度
 * @return 限制后的X坐标
 */
int ClampSliderPosition(int x, int sliderX, int sliderWidth) {
    if (x < sliderX) return sliderX;
    if (x > sliderX + sliderWidth) return sliderX + sliderWidth;
    return x;
}

/**
 * @brief 验证按钮索引是否有效
 * @param index 索引值
 * @param maxIndex 最大有效索引
 * @return true 如果有效
 */
bool IsValidButtonIndex(int index, int maxIndex) {
    return index >= 0 && index <= maxIndex;
}

int GetSnakeSpeedIndex(float speed) {
    // 验证输入速度
    if (std::isnan(speed) || std::isinf(speed) || speed < 0) {
        return 1; // 返回默认值
    }
    
    const float slowNormalBoundary = (GameConfig::PLAYER_SLOW_SPEED + GameConfig::PLAYER_NORMAL_SPEED) * 0.5f;
    const float normalFastBoundary = (GameConfig::PLAYER_NORMAL_SPEED + GameConfig::PLAYER_FAST_SPEED) * 0.5f;
    
    if (speed <= slowNormalBoundary) {
        return 0;
    }
    if (speed >= normalFastBoundary) {
        return 2;
    }
    return 1;
}

GameSettings CaptureCurrentSettings() {
    const auto& gameState = GameState::Instance();

    // 安全地捕获设置，使用验证后的值
    GameSettings settings;
    settings.volume = ClampFloat(GameConfig::DEFAULT_VOLUME, MIN_VOLUME, MAX_VOLUME);
    settings.difficulty = ClampIntValue(gameState.difficulty, MIN_DIFFICULTY, MAX_DIFFICULTY);
    settings.soundOn = GameConfig::SOUND_ON;
    settings.snakeSpeed = ClampIntValue(GetSnakeSpeedIndex(gameState.currentPlayerSpeed), MIN_SPEED_INDEX, MAX_SPEED_INDEX);
    settings.animationsOn = GameConfig::ANIMATIONS_ON;
    
    return settings;
}

} // anonymous namespace

// Set volume with validation
void SetVolume(float volume) {
    // 验证音量范围
    volume = ClampFloat(volume, MIN_VOLUME, MAX_VOLUME);
    
    // Convert float volume to DWORD value (0-0xFFFF)
    DWORD dwVolume = static_cast<DWORD>(volume * 0xFFFF);
    
    // Set left and right channel volumes to the same value
    DWORD stereoVolume = (dwVolume << 16) | dwVolume;
    
    // Set volume with error handling
    MMRESULT result = waveOutSetVolume(0, stereoVolume);
    if (result != MMSYSERR_NOERROR) {
        OutputDebugStringA("SetVolume: Failed to set volume\n");
    }
}

// Apply settings with validation
void ApplySettings(const GameSettings& settings) {
    // 创建设置的副本以便验证
    GameSettings validatedSettings;
    validatedSettings.volume = ClampFloat(settings.volume, MIN_VOLUME, MAX_VOLUME);
    validatedSettings.difficulty = ClampIntValue(settings.difficulty, MIN_DIFFICULTY, MAX_DIFFICULTY);
    validatedSettings.soundOn = settings.soundOn;
    validatedSettings.snakeSpeed = ClampIntValue(settings.snakeSpeed, MIN_SPEED_INDEX, MAX_SPEED_INDEX);
    validatedSettings.animationsOn = settings.animationsOn;

    // Apply volume
    SetVolume(validatedSettings.volume);
    
    // Set difficulty level
    GameState::Instance().difficulty = validatedSettings.difficulty;
    
    // Adjust AI snake count and aggression based on difficulty
    switch (validatedSettings.difficulty) {
    case 0: // Easy
        GameState::Instance().aiSnakeCount = GameConfig::Difficulty::Easy::AI_SNAKE_COUNT;
        GameState::Instance().aiAggression = GameConfig::Difficulty::Easy::AI_AGGRESSION;
        break;
    case 1: // Normal
        GameState::Instance().aiSnakeCount = GameConfig::Difficulty::Normal::AI_SNAKE_COUNT;
        GameState::Instance().aiAggression = GameConfig::Difficulty::Normal::AI_AGGRESSION;
        break;
    case 2: // Hard
        GameState::Instance().aiSnakeCount = GameConfig::Difficulty::Hard::AI_SNAKE_COUNT;
        GameState::Instance().aiAggression = GameConfig::Difficulty::Hard::AI_AGGRESSION;
        break;
    default:
        // 不应到达此处，但为安全起见使用默认值
        GameState::Instance().aiSnakeCount = GameConfig::Difficulty::Normal::AI_SNAKE_COUNT;
        GameState::Instance().aiAggression = GameConfig::Difficulty::Normal::AI_AGGRESSION;
        break;
    }
    
    // Apply sound toggle
    GameConfig::SOUND_ON = validatedSettings.soundOn;
    
    // Apply animations toggle
    GameConfig::ANIMATIONS_ON = validatedSettings.animationsOn;
    
    // Set snake speed with validation
    switch (validatedSettings.snakeSpeed) {
    case 0: // Slow
        GameState::Instance().currentPlayerSpeed = GameConfig::PLAYER_SLOW_SPEED;
        break;
    case 1: // Medium
        GameState::Instance().currentPlayerSpeed = GameConfig::PLAYER_NORMAL_SPEED;
        break;
    case 2: // Fast
        GameState::Instance().currentPlayerSpeed = GameConfig::PLAYER_FAST_SPEED;
        break;
    default:
        GameState::Instance().currentPlayerSpeed = GameConfig::PLAYER_NORMAL_SPEED;
        break;
    }
}

// Settings dialog with improved input validation
void ShowSettings(int windowWidth, int windowHeight) {
    // 验证窗口尺寸
    if (windowWidth <= 0 || windowHeight <= 0 || 
        windowWidth > 10000 || windowHeight > 10000) {
        OutputDebugStringA("ShowSettings: Invalid window dimensions\n");
        return;
    }

    // Create game settings object and initialize with current settings
    GameSettings currentSettings = CaptureCurrentSettings();
    const GameSettings originalSettings = currentSettings;
    
    // Create settings interface
    setfillcolor(RGB(30, 30, 30));
    solidrectangle(0, 0, windowWidth, windowHeight);
    
    settextstyle(36, 0, _T("Arial"));
    settextcolor(RGB(255, 255, 255));
    
    // 安全计算文本位置
    int titleWidth = textwidth(_T("Settings"));
    if (titleWidth > 0 && titleWidth < windowWidth) {
        outtextxy(windowWidth / 2 - titleWidth / 2, 30, _T("Settings"));
    }
    
    settextstyle(24, 0, _T("Arial"));
    
    // Volume slider with bounds checking
    int sliderX = 150;
    int sliderY = 120;
    int sliderWidth = windowWidth - 300;
    int sliderHeight = 10;
    
    // 验证滑块尺寸
    if (sliderWidth <= 0 || sliderWidth > windowWidth) {
        sliderWidth = 300;
    }
    
    outtextxy(sliderX, sliderY - 40, _T("Volume"));

    // Draw volume slider background
    setfillcolor(RGB(100, 100, 100));
    solidroundrect(sliderX, sliderY, sliderX + sliderWidth, sliderY + sliderHeight, 5, 5);
    
    // Draw volume slider current position
    int handleX = sliderX + static_cast<int>(ClampFloat(currentSettings.volume, MIN_VOLUME, MAX_VOLUME) * sliderWidth);
    int handleRadius = 15;
    
    setfillcolor(RGB(0, 150, 255));
    solidcircle(handleX, sliderY + sliderHeight / 2, handleRadius);

    // Difficulty selection
    int difficultyY = sliderY + 100;
    outtextxy(sliderX, difficultyY - 40, _T("Difficulty"));
    
    const TCHAR* difficultyLabels[] = { _T("Easy"), _T("Normal"), _T("Hard") };
    int buttonWidth = sliderWidth / 3;
    int buttonHeight = 40;
    
    // 验证按钮尺寸
    if (buttonWidth <= 0) buttonWidth = 100;
    if (buttonHeight <= 0) buttonHeight = 40;
    
    for (int i = 0; i < 3; i++) {
        // Calculate button position
        int btnX = sliderX + i * buttonWidth;
        
        // Set color (selected button is highlighted)
        if (i == currentSettings.difficulty) {
            setfillcolor(RGB(0, 150, 255));
        } else {
            setfillcolor(RGB(80, 80, 80));
        }
        
        // Draw button
        solidroundrect(btnX, difficultyY, btnX + buttonWidth - 10, difficultyY + buttonHeight, 5, 5);
        
        // Draw text
        int textW = textwidth(difficultyLabels[i]);
        if (textW > 0 && textW < buttonWidth) {
            outtextxy(btnX + (buttonWidth - 10) / 2 - textW / 2, difficultyY + 8, difficultyLabels[i]);
        }
    }
    
    // Sound toggle
    int soundY = difficultyY + 100;
    outtextxy(sliderX, soundY - 40, _T("Sound"));
    
    const TCHAR* soundLabels[] = { _T("Off"), _T("On") };
    int soundBtnWidth = sliderWidth / 2;
    
    for (int i = 0; i < 2; i++) {
        int btnX = sliderX + i * soundBtnWidth;
        
        if ((i == 0 && !currentSettings.soundOn) || (i == 1 && currentSettings.soundOn)) {
            setfillcolor(RGB(0, 150, 255));
        } else {
            setfillcolor(RGB(80, 80, 80));
        }
        
        solidroundrect(btnX, soundY, btnX + soundBtnWidth - 10, soundY + buttonHeight, 5, 5);
        
        int textW = textwidth(soundLabels[i]);
        if (textW > 0 && textW < soundBtnWidth) {
            outtextxy(btnX + (soundBtnWidth - 10) / 2 - textW / 2, soundY + 8, soundLabels[i]);
        }
    }
    
    // Snake speed selection
    int speedY = soundY + 100;
    outtextxy(sliderX, speedY - 40, _T("Snake Speed"));
    
    const TCHAR* speedLabels[] = { _T("Slow"), _T("Normal"), _T("Fast") };
    
    for (int i = 0; i < 3; i++) {
        int btnX = sliderX + i * buttonWidth;
        
        if (i == currentSettings.snakeSpeed) {
            setfillcolor(RGB(0, 150, 255));
        } else {
            setfillcolor(RGB(80, 80, 80));
        }
        
        solidroundrect(btnX, speedY, btnX + buttonWidth - 10, speedY + buttonHeight, 5, 5);
        
        int textW = textwidth(speedLabels[i]);
        if (textW > 0 && textW < buttonWidth) {
            outtextxy(btnX + (buttonWidth - 10) / 2 - textW / 2, speedY + 8, speedLabels[i]);
        }
    }
    
    // Animation toggle
    int animationY = speedY + 100;
    outtextxy(sliderX, animationY - 40, _T("Animations"));
    
    const TCHAR* animationLabels[] = { _T("Off"), _T("On") };
    
    for (int i = 0; i < 2; i++) {
        int btnX = sliderX + i * soundBtnWidth;
        
        if ((i == 0 && !currentSettings.animationsOn) || (i == 1 && currentSettings.animationsOn)) {
            setfillcolor(RGB(0, 150, 255));
        } else {
            setfillcolor(RGB(80, 80, 80));
        }
        
        solidroundrect(btnX, animationY, btnX + soundBtnWidth - 10, animationY + buttonHeight, 5, 5);
        
        int textW = textwidth(animationLabels[i]);
        if (textW > 0 && textW < soundBtnWidth) {
            outtextxy(btnX + (soundBtnWidth - 10) / 2 - textW / 2, animationY + 8, animationLabels[i]);
        }
    }
    
    // Return button area with bounds checking
    int returnY = windowHeight - 100;
    int settingButtonWidth = 150;
    int settingButtonHeight = 50;
    
    // 验证按钮不会超出窗口
    if (returnY < animationY + buttonHeight + 20) {
        returnY = animationY + buttonHeight + 20;
    }
    
    int applyX = windowWidth / 2 - settingButtonWidth - 20;
    int cancelX = windowWidth / 2 + 20;
    
    // Apply button
    setfillcolor(RGB(0, 150, 80));
    solidroundrect(applyX, returnY, applyX + settingButtonWidth, returnY + settingButtonHeight, 10, 10);

    settextstyle(28, 0, _T("Arial"));
    int applyTextW = textwidth(_T("Apply"));
    if (applyTextW > 0 && applyTextW < settingButtonWidth) {
        outtextxy(applyX + settingButtonWidth / 2 - applyTextW / 2, returnY + 10, _T("Apply"));
    }

    // Cancel button
    setfillcolor(RGB(150, 50, 50));
    solidroundrect(cancelX, returnY, cancelX + settingButtonWidth, returnY + settingButtonHeight, 10, 10);

    int cancelTextW = textwidth(_T("Cancel"));
    if (cancelTextW > 0 && cancelTextW < settingButtonWidth) {
        outtextxy(cancelX + settingButtonWidth / 2 - cancelTextW / 2, returnY + 10, _T("Cancel"));
    }
    
    FlushBatchDraw();
    
    // Handle user input with validation
    bool settingsOpen = true;
    while (settingsOpen) {
        ExMessage msg = getmessage(EX_MOUSE);
        if (msg.message == WM_LBUTTONDOWN) {
            // 验证鼠标坐标
            if (msg.x < 0 || msg.x > windowWidth || msg.y < 0 || msg.y > windowHeight) {
                continue;
            }
            
            // Check if on volume slider
            if (msg.y >= sliderY - handleRadius && msg.y <= sliderY + sliderHeight + handleRadius &&
                msg.x >= sliderX - handleRadius && msg.x <= sliderX + sliderWidth + handleRadius) {
                // Update volume with validation
                float newVolume = static_cast<float>(msg.x - sliderX) / sliderWidth;
                newVolume = ClampFloat(newVolume, MIN_VOLUME, MAX_VOLUME);
                currentSettings.volume = newVolume;
                
                // Apply volume in real-time
                SetVolume(newVolume);
                
                // Clear the volume area first
                setfillcolor(RGB(30, 30, 30));
                solidrectangle(sliderX-handleRadius, sliderY-handleRadius, sliderX+sliderWidth+handleRadius, sliderY+sliderHeight+handleRadius);
                
                // Redraw volume slider
                setfillcolor(RGB(100, 100, 100));
                solidroundrect(sliderX, sliderY, sliderX + sliderWidth, sliderY + sliderHeight, 5, 5);
                
                int newHandleX = sliderX + static_cast<int>(currentSettings.volume * sliderWidth);
                setfillcolor(RGB(0, 150, 255));
                solidcircle(newHandleX, sliderY + sliderHeight / 2, handleRadius);
                
                FlushBatchDraw();
            }
            // Check difficulty buttons
            else if (msg.y >= difficultyY && msg.y <= difficultyY + buttonHeight) {
                for (int i = 0; i < 3; i++) {
                    int btnX = sliderX + i * buttonWidth;
                    if (msg.x >= btnX && msg.x <= btnX + buttonWidth - 10) {
                        if (IsValidButtonIndex(i, 2)) {
                            currentSettings.difficulty = i;
                            
                            // Redraw difficulty buttons
                            for (int j = 0; j < 3; j++) {
                                int btnX2 = sliderX + j * buttonWidth;
                                if (j == currentSettings.difficulty) {
                                    setfillcolor(RGB(0, 150, 255));
                                } else {
                                    setfillcolor(RGB(80, 80, 80));
                                }
                                solidroundrect(btnX2, difficultyY, btnX2 + buttonWidth - 10, difficultyY + buttonHeight, 5, 5);
                                
                                int textW = textwidth(difficultyLabels[j]);
                                if (textW > 0 && textW < buttonWidth) {
                                    outtextxy(btnX2 + (buttonWidth - 10) / 2 - textW / 2, difficultyY + 8, difficultyLabels[j]);
                                }
                            }
                            
                            FlushBatchDraw();
                        }
                        break;
                    }
                }
            }
            // Check sound toggle buttons
            else if (msg.y >= soundY && msg.y <= soundY + buttonHeight) {
                for (int i = 0; i < 2; i++) {
                    int btnX = sliderX + i * soundBtnWidth;
                    if (msg.x >= btnX && msg.x <= btnX + soundBtnWidth - 10) {
                        currentSettings.soundOn = (i == 1);
                        
                        // Redraw sound buttons
                        for (int j = 0; j < 2; j++) {
                            int btnX2 = sliderX + j * soundBtnWidth;
                            if ((j == 0 && !currentSettings.soundOn) || (j == 1 && currentSettings.soundOn)) {
                                setfillcolor(RGB(0, 150, 255));
                            } else {
                                setfillcolor(RGB(80, 80, 80));
                            }
                            
                            solidroundrect(btnX2, soundY, btnX2 + soundBtnWidth - 10, soundY + buttonHeight, 5, 5);
                            
                            int textW = textwidth(soundLabels[j]);
                            if (textW > 0 && textW < soundBtnWidth) {
                                outtextxy(btnX2 + (soundBtnWidth - 10) / 2 - textW / 2, soundY + 8, soundLabels[j]);
                            }
                        }
                        
                        FlushBatchDraw();
                        break;
                    }
                }
            }
            // Check speed buttons
            else if (msg.y >= speedY && msg.y <= speedY + buttonHeight) {
                for (int i = 0; i < 3; i++) {
                    int btnX = sliderX + i * buttonWidth;
                    if (msg.x >= btnX && msg.x <= btnX + buttonWidth - 10) {
                        if (IsValidButtonIndex(i, 2)) {
                            currentSettings.snakeSpeed = i;
                            
                            // Redraw speed buttons
                            for (int j = 0; j < 3; j++) {
                                int btnX2 = sliderX + j * buttonWidth;
                                if (j == currentSettings.snakeSpeed) {
                                    setfillcolor(RGB(0, 150, 255));
                                } else {
                                    setfillcolor(RGB(80, 80, 80));
                                }
                                solidroundrect(btnX2, speedY, btnX2 + buttonWidth - 10, speedY + buttonHeight, 5, 5);
                                
                                int textW = textwidth(speedLabels[j]);
                                if (textW > 0 && textW < buttonWidth) {
                                    outtextxy(btnX2 + (buttonWidth - 10) / 2 - textW / 2, speedY + 8, speedLabels[j]);
                                }
                            }
                            
                            FlushBatchDraw();
                        }
                        break;
                    }
                }
            }
            // Check animation toggle buttons
            else if (msg.y >= animationY && msg.y <= animationY + buttonHeight) {
                for (int i = 0; i < 2; i++) {
                    int btnX = sliderX + i * soundBtnWidth;
                    if (msg.x >= btnX && msg.x <= btnX + soundBtnWidth - 10) {
                        currentSettings.animationsOn = (i == 1);
                        
                        // Redraw animation buttons
                        for (int j = 0; j < 2; j++) {
                            int btnX2 = sliderX + j * soundBtnWidth;
                            if ((j == 0 && !currentSettings.animationsOn) || (j == 1 && currentSettings.animationsOn)) {
                                setfillcolor(RGB(0, 150, 255));
                            } else {
                                setfillcolor(RGB(80, 80, 80));
                            }
                            
                            solidroundrect(btnX2, animationY, btnX2 + soundBtnWidth - 10, animationY + buttonHeight, 5, 5);
                            
                            int textW = textwidth(animationLabels[j]);
                            if (textW > 0 && textW < soundBtnWidth) {
                                outtextxy(btnX2 + (soundBtnWidth - 10) / 2 - textW / 2, animationY + 8, animationLabels[j]);
                            }
                        }
                        
                        FlushBatchDraw();
                        break;
                    }
                }
            }
            // Check apply button
            else if (msg.x >= applyX && msg.x <= applyX + settingButtonWidth &&
                     msg.y >= returnY && msg.y <= returnY + settingButtonHeight) {
                // Apply settings with validation
                ApplySettings(currentSettings);
                settingsOpen = false;
            }
            // Check cancel button
            else if (msg.x >= cancelX && msg.x <= cancelX + settingButtonWidth &&
                     msg.y >= returnY && msg.y <= returnY + settingButtonHeight) {
                ApplySettings(originalSettings);
                settingsOpen = false;
            }
        }
    }
}
