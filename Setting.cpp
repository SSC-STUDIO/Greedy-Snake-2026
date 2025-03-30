#include "Setting.h"
#include "GameState.h"
#include <mmsystem.h>
#include <tchar.h>
#include "Button.h"

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

// 设置对话框
void ShowSettings(int windowWidth, int windowHeight) {
    static GameSettings settings; // 设置

    // 填充整个窗口
    setfillcolor(RGB(30, 30, 30)); // 设置背景颜色
    solidrectangle(0, 0, windowWidth, windowHeight); // 绘制背景矩形

    // 绘制标题
    settextstyle(48, 0, _T("Arial")); // 设置文本样式
    settextcolor(RGB(255, 255, 255)); // 设置文本颜色
    const TCHAR* title = _T("Settings"); // 标题文本
    int titleWidth = textwidth(title); // 获取标题宽度
    outtextxy(windowWidth / 2 - titleWidth / 2, 50, title); // 绘制标题

    // 绘制设置面板
    setfillcolor(RGB(50, 50, 50)); // 设置面板颜色
    const int panelMargin = 50;  // 边距
    solidroundrect(panelMargin, 120,  // 调整位置
        windowWidth - panelMargin, windowHeight - panelMargin,
        20, 20); // 绘制面板

    settextstyle(32, 0, _T("Arial")); // 设置文本样式

    // 音量控制
    const int startY = 200; // 起始Y坐标
    const int lineHeight = 80; // 行高
    outtextxy(panelMargin + 50, startY, _T("Volume:")); // 绘制音量文本

    // 绘制音量滑块背景
    const int sliderWidth = windowWidth - panelMargin * 2 - 300; // 滑块宽度
    const int sliderHeight = 30; // 滑块高度
    const int sliderX = panelMargin + 200; // 滑块X坐标
    const int sliderY = startY; // 滑块Y坐标

    setfillcolor(RGB(70, 70, 70)); // 设置滑块背景颜色
    solidroundrect(sliderX, sliderY, sliderX + sliderWidth, sliderY + sliderHeight, 10, 10); // 绘制滑块背景

    // 绘制音量级别
    setfillcolor(RGB(100, 200, 100)); // 设置滑块填充颜色
    int filledWidth = static_cast<int>(settings.musicVolume * sliderWidth); // 计算填充宽度
    solidroundrect(sliderX, sliderY, sliderX + filledWidth, sliderY + sliderHeight, 10, 10); // 绘制填充滑块

    // 绘制音量百分比
    TCHAR volumeText[20]; // 音量文本
    _stprintf(volumeText, _T("%d%%"), static_cast<int>(settings.musicVolume * 100)); // 格式化音量文本
    outtextxy(sliderX + sliderWidth + 20, sliderY, volumeText); // 绘制音量文本

    // 难度选择
    outtextxy(panelMargin + 50, startY + lineHeight, _T("Difficulty:")); // 绘制难度文本
    const TCHAR* difficulties[] = { _T("Easy"), _T("Normal"), _T("Hard") }; // 难度选项
    for (int i = 0; i < 3; i++) {
        const int btnWidth = 120; // 按钮宽度
        const int btnX = panelMargin + 200 + i * (btnWidth + 20); // 按钮X坐标
        setfillcolor(settings.difficulty == i + 1 ? RGB(100, 200, 100) : RGB(70, 70, 70)); // 设置按钮颜色
        solidroundrect(btnX, startY + lineHeight,
            btnX + btnWidth, startY + lineHeight + 40,
            10, 10); // 绘制按钮
        // 中心对齐文本
        int textWidth = textwidth(difficulties[i]); // 获取文本宽度
        outtextxy(btnX + (btnWidth - textWidth) / 2,
            startY + lineHeight + 5,
            difficulties[i]); // 绘制难度文本
    }

    // 声音切换
    outtextxy(panelMargin + 50, startY + lineHeight * 2, _T("Sound:")); // 绘制声音文本
    setfillcolor(settings.enableSound ? RGB(100, 200, 100) : RGB(70, 70, 70)); // 设置声音按钮颜色
    solidroundrect(panelMargin + 200, startY + lineHeight * 2,
        panelMargin + 300, startY + lineHeight * 2 + 40,
        10, 10); // 绘制声音按钮
    const TCHAR* soundText = settings.enableSound ? _T("ON") : _T("OFF"); // 声音状态文本
    int textWidth = textwidth(soundText); // 获取文本宽度
    outtextxy(panelMargin + 200 + (100 - textWidth) / 2,
        startY + lineHeight * 2 + 5,
        soundText); // 绘制声音状态文本

    // 使用 Button 类创建按钮
    Button saveButton; // 保存按钮
    Button cancelButton; // 取消按钮
    const int btnWidth = 150; // 按钮宽度
    const int btnHeight = 50; // 按钮高度
    const int btnY = windowHeight - panelMargin - btnHeight - 50; // 按钮Y坐标

    saveButton.Initial(_T("Save"), Vector2(windowWidth / 2 - btnWidth - 20, btnY), Vector2(windowWidth / 2 - 20, btnY + btnHeight), RGB(100, 200, 100)); // 初始化保存按钮
    cancelButton.Initial(_T("Cancel"), Vector2(windowWidth / 2 + 20, btnY), Vector2(windowWidth / 2 + btnWidth + 20, btnY + btnHeight), RGB(200, 100, 100)); // 初始化取消按钮

    // 处理设置输入
    bool settingsOpen = true; // 设置窗口是否打开
    while (settingsOpen) {
        ExMessage m = getmessage(EX_MOUSE | EX_KEY); // 获取消息
        Vector2 mousePos = Vector2(m.x, m.y); // 鼠标位置

        // 绘制按钮
        saveButton.DrawButton(mousePos); // 绘制保存按钮
        cancelButton.DrawButton(mousePos); // 绘制取消按钮

        if (m.message == WM_LBUTTONDOWN) { // 左键按下
            // 处理音量滑块
            if (m.x >= sliderX && m.x <= sliderX + sliderWidth &&
                m.y >= sliderY && m.y <= sliderY + sliderHeight) {
                settings.musicVolume = static_cast<float>(m.x - sliderX) / sliderWidth; // 更新音量
                settings.musicVolume = (((0.0f) > ((((1.0f) < (settings.musicVolume)) ? (1.0f) : (settings.musicVolume)))) ? (0.0f) : ((((1.0f) < (settings.musicVolume)) ? (1.0f) : (settings.musicVolume)))); // 限制音量范围

                // 立即更新音量以反馈
                SetVolume(settings.musicVolume);

                // 重新绘制设置界面以更新滑块
                ShowSettings(windowWidth, windowHeight);
            }

            // 处理难度按钮
            for (int i = 0; i < 3; i++) {
                const int btnWidth = 120; // 按钮宽度
                const int btnX = panelMargin + 200 + i * (btnWidth + 20); // 按钮X坐标
                if (m.x >= btnX && m.x <= btnX + btnWidth &&
                    m.y >= startY + lineHeight && m.y <= startY + lineHeight + 40) {
                    settings.difficulty = i + 1; // 更新难度

                    // 更新游戏难度
                    GameState::Instance().SetDifficulty(static_cast<GameState::GameDifficulty>(i));

                    ShowSettings(windowWidth, windowHeight);  // 刷新设置界面
                    break;
                }
            }

            // 处理声音切换
            if (m.x >= panelMargin + 200 && m.x <= panelMargin + 300 &&
                m.y >= startY + lineHeight * 2 && m.y <= startY + lineHeight * 2 + 40) {
                settings.enableSound = !settings.enableSound; // 切换声音状态
                // 重新绘制设置界面以更新切换状态
                ShowSettings(windowWidth, windowHeight);
            }

            // 处理保存/取消
            if (saveButton.IsOnButton(mousePos)) {
                ApplySettings(settings); // 应用设置
                settingsOpen = false; // 关闭设置窗口
            }
            else if (cancelButton.IsOnButton(mousePos)) {
                settingsOpen = false; // 关闭设置窗口
            }
        }
        else if (m.message == WM_MOUSEMOVE && (m.wheel & MK_LBUTTON)) { // 鼠标移动并按下左键
            // 处理音量滑块拖动
            if (m.x >= sliderX && m.x <= sliderX + sliderWidth &&
                m.y >= sliderY && m.y <= sliderY + sliderHeight) {
                settings.musicVolume = static_cast<float>(m.x - sliderX) / sliderWidth; // 更新音量
                settings.musicVolume = (((0.0f) > ((((1.0f) < (settings.musicVolume)) ? (1.0f) : (settings.musicVolume)))) ? (0.0f) : ((((1.0f) < (settings.musicVolume)) ? (1.0f) : (settings.musicVolume)))); // 限制音量范围

                // 立即更新音量以反馈
                SetVolume(settings.musicVolume);

                // 重新绘制设置界面以更新滑块
                ShowSettings(windowWidth, windowHeight);
            }
        }
        else if (m.message == WM_KEYDOWN && m.vkcode == VK_ESCAPE) { // ESC键按下
            settingsOpen = false; // 关闭设置窗口
        }
    }
}