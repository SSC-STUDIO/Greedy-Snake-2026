#include "UI.h"
#include <tchar.h>
#include <conio.h>
#include <io.h>
#include <mmsystem.h>
#include <algorithm>
#include <cmath>
#include "../Core/ResourceManager.h"
#include "../Utils/Setting.h"
#include "../Utils/DrawHelpers.h"
#pragma comment(lib, "winmm.lib")

// Global button list
std::vector<Button> buttonList;

namespace {
int RectWidth(const RECT& rect) {
    return rect.right - rect.left;
}

int RectHeight(const RECT& rect) {
    return rect.bottom - rect.top;
}

RECT MakeRect(int left, int top, int right, int bottom) {
    RECT rect{ left, top, right, bottom };
    return rect;
}

int ScaleTextSize(int baseSize, float scale, int minSize, int maxSize) {
    return (std::clamp)(static_cast<int>(std::round(baseSize * scale)), minSize, maxSize);
}

struct StartMenuLayout {
    RECT heroRect{};
    RECT actionRect{};
    RECT lowerRect{};
    RECT quickRect{};
    RECT controlsRect{};
    RECT startButtonRect{};
    RECT iconButtons[3]{};
    float fontScale = 1.0f;
    int innerGap = 24;
};

StartMenuLayout BuildStartMenuLayout() {
    StartMenuLayout layout;
    layout.fontScale = (std::clamp)(
        static_cast<float>(GameConfig::WINDOW_WIDTH) / static_cast<float>(GameConfig::BASE_WINDOW_WIDTH) * 0.75f,
        1.0f,
        1.25f);

    const int marginX = (std::clamp)(GameConfig::WINDOW_WIDTH / 30, 24, 88);
    const int marginY = (std::clamp)(GameConfig::WINDOW_HEIGHT / 34, 20, 52);
    const int gap = (std::clamp)(GameConfig::WINDOW_WIDTH / 52, 18, 34);
    const int contentWidth = GameConfig::WINDOW_WIDTH - marginX * 2;
    const int contentBottom = GameConfig::WINDOW_HEIGHT - marginY;
    const int topHeight = (std::clamp)(static_cast<int>(GameConfig::WINDOW_HEIGHT * 0.43f), 300, 392);
    const int actionWidth = (std::clamp)(static_cast<int>(contentWidth * 0.31f), 250, 360);
    const int heroWidth = (std::max)(400, contentWidth - actionWidth - gap);
    const int actionLeft = marginX + heroWidth + gap;

    layout.heroRect = MakeRect(marginX, marginY, marginX + heroWidth, marginY + topHeight);
    layout.actionRect = MakeRect(actionLeft, marginY, GameConfig::WINDOW_WIDTH - marginX, marginY + topHeight);
    layout.lowerRect = MakeRect(marginX, layout.heroRect.bottom + gap, GameConfig::WINDOW_WIDTH - marginX, contentBottom);

    layout.innerGap = (std::clamp)(RectWidth(layout.lowerRect) / 34, 20, 30);
    const int lowerInnerPad = (std::clamp)(RectWidth(layout.lowerRect) / 36, 18, 30);
    const int lowerHeaderHeight = ScaleTextSize(72, layout.fontScale, 70, 92);
    const int quickWidth = (std::clamp)(
        static_cast<int>((RectWidth(layout.lowerRect) - lowerInnerPad * 2 - layout.innerGap) * 0.42f),
        286,
        430);

    layout.quickRect = MakeRect(
        layout.lowerRect.left + lowerInnerPad,
        layout.lowerRect.top + lowerHeaderHeight,
        layout.lowerRect.left + lowerInnerPad + quickWidth,
        layout.lowerRect.bottom - lowerInnerPad);
    layout.controlsRect = MakeRect(
        layout.quickRect.right + layout.innerGap,
        layout.quickRect.top,
        layout.lowerRect.right - lowerInnerPad,
        layout.quickRect.bottom);

    const int actionPad = (std::clamp)(RectWidth(layout.actionRect) / 9, 24, 36);
    const int startButtonHeight = ScaleTextSize(58, layout.fontScale, 56, 72);
    layout.startButtonRect = MakeRect(
        layout.actionRect.left + actionPad,
        layout.actionRect.top + static_cast<int>(RectHeight(layout.actionRect) * 0.53f),
        layout.actionRect.right - actionPad,
        layout.actionRect.top + static_cast<int>(RectHeight(layout.actionRect) * 0.53f) + startButtonHeight);

    const int iconSize = ScaleTextSize(56, layout.fontScale, 54, 74);
    const int iconGap = (std::clamp)(iconSize / 5, 12, 18);
    const int totalIconWidth = iconSize * 3 + iconGap * 2;
    const int iconStartX = layout.actionRect.left + (RectWidth(layout.actionRect) - totalIconWidth) / 2;
    const int iconTop = layout.actionRect.bottom - actionPad - iconSize;
    for (int i = 0; i < 3; ++i) {
        const int iconLeft = iconStartX + i * (iconSize + iconGap);
        layout.iconButtons[i] = MakeRect(iconLeft, iconTop, iconLeft + iconSize, iconTop + iconSize);
    }

    return layout;
}

struct LandingLayout {
    RECT panel{};
    RECT headerRect{};
    RECT promptRect{};
    int leftColumnX = 0;
    int rightColumnX = 0;
    float fontScale = 1.0f;
};

LandingLayout BuildLandingLayout() {
    LandingLayout layout;
    layout.fontScale = (std::clamp)(
        static_cast<float>(GameConfig::WINDOW_WIDTH) / static_cast<float>(GameConfig::BASE_WINDOW_WIDTH) * 0.72f,
        1.0f,
        1.22f);

    const int marginX = (std::clamp)(GameConfig::WINDOW_WIDTH / 16, 54, 124);
    const int marginY = (std::clamp)(GameConfig::WINDOW_HEIGHT / 10, 54, 110);
    layout.panel = MakeRect(
        marginX,
        marginY,
        GameConfig::WINDOW_WIDTH - marginX,
        GameConfig::WINDOW_HEIGHT - marginY);

    const int headerInset = (std::clamp)(RectWidth(layout.panel) / 28, 20, 28);
    const int headerHeight = (std::clamp)(static_cast<int>(RectHeight(layout.panel) * 0.15f), 94, 132);
    layout.headerRect = MakeRect(
        layout.panel.left + headerInset,
        layout.panel.top + headerInset,
        layout.panel.right - headerInset,
        layout.panel.top + headerInset + headerHeight);

    const int promptWidth = (std::clamp)(static_cast<int>(RectWidth(layout.panel) * 0.30f), 320, 420);
    const int promptHeight = ScaleTextSize(62, layout.fontScale, 60, 72);
    layout.promptRect = MakeRect(
        GameConfig::WINDOW_WIDTH / 2 - promptWidth / 2,
        layout.panel.bottom - ScaleTextSize(112, layout.fontScale, 98, 124),
        GameConfig::WINDOW_WIDTH / 2 + promptWidth / 2,
        layout.panel.bottom - ScaleTextSize(112, layout.fontScale, 98, 124) + promptHeight);

    layout.leftColumnX = layout.panel.left + ScaleTextSize(42, layout.fontScale, 38, 54);
    layout.rightColumnX = layout.panel.left + RectWidth(layout.panel) / 2 + ScaleTextSize(18, layout.fontScale, 10, 32);
    return layout;
}
}

// Load button resources for the menu
void LoadButton()
{
    const StartMenuLayout layout = BuildStartMenuLayout();
    buttonList.resize(4); // Adjust button list size
    buttonList[StartGame].Initial(
        _T("Start Game"),
        Vector2(static_cast<float>(layout.startButtonRect.left), static_cast<float>(layout.startButtonRect.top)),
        Vector2(static_cast<float>(layout.startButtonRect.right), static_cast<float>(layout.startButtonRect.bottom)),
        RGB(49, 148, 211),
        _T(".\\Resource\\SoundEffects\\Button-Click.wav")); // Initialize start game button
    buttonList[Setting].Initial(
        _T("./Resource/Setting.png"),
        Vector2(static_cast<float>(layout.iconButtons[0].left), static_cast<float>(layout.iconButtons[0].top)),
        Vector2(static_cast<float>(RectWidth(layout.iconButtons[0])), static_cast<float>(RectHeight(layout.iconButtons[0]))),
        _T(".\\Resource\\SoundEffects\\Button-Click.wav"));
    buttonList[About].Initial(
        _T("./Resource/About.png"),
        Vector2(static_cast<float>(layout.iconButtons[1].left), static_cast<float>(layout.iconButtons[1].top)),
        Vector2(static_cast<float>(RectWidth(layout.iconButtons[1])), static_cast<float>(RectHeight(layout.iconButtons[1]))),
        _T(".\\Resource\\SoundEffects\\Button-Click.wav"));
    buttonList[Exit].Initial(
        _T("./Resource/Exit.png"),
        Vector2(static_cast<float>(layout.iconButtons[2].left), static_cast<float>(layout.iconButtons[2].top)),
        Vector2(static_cast<float>(RectWidth(layout.iconButtons[2])), static_cast<float>(RectHeight(layout.iconButtons[2]))),
        _T(".\\Resource\\SoundEffects\\Button-Click.wav"));
}

// Draw the main menu interface
void DrawMenu(const Vector2& mousePos) {
    const float pulse = 0.5f + 0.5f * sinf(GetTickCount() * 0.0045f);
    const StartMenuLayout layout = BuildStartMenuLayout();
    const int heroLeft = layout.heroRect.left;
    const int heroTop = layout.heroRect.top;
    const int heroRight = layout.heroRect.right;
    const int heroBottom = layout.heroRect.bottom;
    const int actionLeft = layout.actionRect.left;
    const int actionTop = layout.actionRect.top;
    const int actionRight = layout.actionRect.right;
    const int actionBottom = layout.actionRect.bottom;
    const int lowerTop = layout.lowerRect.top;
    const int lowerBottom = layout.lowerRect.bottom;
    const int lowerLeft = layout.lowerRect.left;
    const int lowerRight = layout.lowerRect.right;
    const int displayTitleFont = ScaleTextSize(60, layout.fontScale, 50, 74);
    const int sectionLabelFont = ScaleTextSize(22, layout.fontScale, 22, 28);
    const int bodyFont = ScaleTextSize(18, layout.fontScale, 17, 22);
    const int smallFont = ScaleTextSize(16, layout.fontScale, 15, 20);
    const int cardPadding = ScaleTextSize(28, layout.fontScale, 24, 36);
    setbkmode(TRANSPARENT);

    setfillcolor(RGB(8, 14, 24));
    solidrectangle(0, 0, GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT);

    setfillcolor(RGB(14, 35, 52));
    solidcircle(
        layout.heroRect.left + ScaleTextSize(68, layout.fontScale, 56, 88),
        layout.heroRect.top + ScaleTextSize(62, layout.fontScale, 54, 80),
        ScaleTextSize(94, layout.fontScale, 90, 122) + static_cast<int>(12 * pulse));
    setfillcolor(RGB(18, 52, 63));
    solidcircle(
        actionRight + (std::min)(ScaleTextSize(44, layout.fontScale, 36, 58), (GameConfig::WINDOW_WIDTH - actionRight) / 2),
        lowerBottom - ScaleTextSize(54, layout.fontScale, 48, 74),
        ScaleTextSize(128, layout.fontScale, 112, 168) + static_cast<int>(8 * pulse));

    setfillcolor(RGB(17, 24, 38));
    solidroundrect(heroLeft, heroTop, heroRight, heroBottom, 28, 28);
    setfillcolor(RGB(16, 24, 38));
    solidroundrect(actionLeft, actionTop, actionRight, actionBottom, 28, 28);
    setfillcolor(RGB(17, 24, 38));
    solidroundrect(lowerLeft, lowerTop, lowerRight, lowerBottom, 28, 28);
    setlinecolor(RGB(83, 112, 157));
    roundrect(heroLeft, heroTop, heroRight, heroBottom, 28, 28);
    roundrect(actionLeft, actionTop, actionRight, actionBottom, 28, 28);
    roundrect(lowerLeft, lowerTop, lowerRight, lowerBottom, 28, 28);

    setfillcolor(RGB(27, 97, 136));
    solidroundrect(
        heroLeft + cardPadding,
        heroTop + cardPadding,
        heroLeft + cardPadding + ScaleTextSize(138, layout.fontScale, 132, 172),
        heroTop + cardPadding + ScaleTextSize(34, layout.fontScale, 34, 42),
        14,
        14);
    settextstyle(ScaleTextSize(18, layout.fontScale, 18, 22), 0, _T("Bahnschrift"));
    settextcolor(RGB(239, 246, 255));
    outtextxy(heroLeft + cardPadding + 18, heroTop + cardPadding + 5, _T("Arcade Survival"));

    settextstyle(displayTitleFont, 0, _T("Bahnschrift"));
    settextcolor(RGB(245, 249, 255));
    outtextxy(heroLeft + cardPadding, heroTop + ScaleTextSize(82, layout.fontScale, 78, 104), _T("GREED"));
    outtextxy(heroLeft + cardPadding, heroTop + ScaleTextSize(142, layout.fontScale, 136, 178), _T("SNAKE"));

    settextstyle(ScaleTextSize(20, layout.fontScale, 19, 24), 0, _T("Segoe UI"));
    settextcolor(RGB(167, 194, 225));
    outtextxy(heroLeft + cardPadding + 4, heroTop + ScaleTextSize(222, layout.fontScale, 210, 274), _T("A faster, cleaner chase through a large"));
    outtextxy(heroLeft + cardPadding + 4, heroTop + ScaleTextSize(250, layout.fontScale, 238, 306), _T("arena with AI pressure, boost timing"));
    outtextxy(heroLeft + cardPadding + 4, heroTop + ScaleTextSize(278, layout.fontScale, 266, 338), _T("and hybrid mouse + keyboard control."));

    setfillcolor(RGB(24, 38, 57));
    solidroundrect(
        heroLeft + cardPadding,
        heroBottom - ScaleTextSize(48, layout.fontScale, 42, 62),
        heroLeft + cardPadding + ScaleTextSize(170, layout.fontScale, 160, 210),
        heroBottom - ScaleTextSize(16, layout.fontScale, 12, 22),
        14,
        14);
    solidroundrect(
        heroLeft + cardPadding + ScaleTextSize(184, layout.fontScale, 176, 230),
        heroBottom - ScaleTextSize(48, layout.fontScale, 42, 62),
        heroLeft + cardPadding + ScaleTextSize(392, layout.fontScale, 376, 478),
        heroBottom - ScaleTextSize(16, layout.fontScale, 12, 22),
        14,
        14);
    settextstyle(smallFont, 0, _T("Segoe UI"));
    settextcolor(RGB(192, 212, 235));
    outtextxy(heroLeft + cardPadding + 18, heroBottom - ScaleTextSize(41, layout.fontScale, 36, 52), _T("Large scrolling map"));
    outtextxy(heroLeft + cardPadding + ScaleTextSize(202, layout.fontScale, 192, 254), heroBottom - ScaleTextSize(41, layout.fontScale, 36, 52), _T("Runtime visual tuning"));

    settextstyle(ScaleTextSize(18, layout.fontScale, 18, 22), 0, _T("Bahnschrift"));
    settextcolor(RGB(166, 193, 222));
    outtextxy(actionLeft + cardPadding, actionTop + cardPadding, _T("Main Menu"));
    settextstyle(ScaleTextSize(34, layout.fontScale, 32, 42), 0, _T("Bahnschrift"));
    settextcolor(RGB(242, 248, 255));
    outtextxy(actionLeft + cardPadding, actionTop + ScaleTextSize(70, layout.fontScale, 68, 92), _T("Start A Run"));
    settextstyle(bodyFont, 0, _T("Segoe UI"));
    settextcolor(RGB(170, 196, 226));
    outtextxy(actionLeft + cardPadding, actionTop + ScaleTextSize(116, layout.fontScale, 112, 148), _T("Jump in quickly or tune the"));
    outtextxy(actionLeft + cardPadding, actionTop + ScaleTextSize(144, layout.fontScale, 138, 180), _T("presentation from settings."));

    settextstyle(smallFont, 0, _T("Segoe UI"));
    settextcolor(RGB(162, 189, 220));
    outtextxy(actionLeft + cardPadding, layout.startButtonRect.bottom + ScaleTextSize(16, layout.fontScale, 14, 18), _T("Settings   About   Exit"));

    settextstyle(sectionLabelFont, 0, _T("Bahnschrift"));
    settextcolor(RGB(240, 246, 255));
    outtextxy(layout.quickRect.left + 6, lowerTop + ScaleTextSize(28, layout.fontScale, 24, 34), _T("Quick Start"));
    outtextxy(layout.controlsRect.left + 6, lowerTop + ScaleTextSize(28, layout.fontScale, 24, 34), _T("Controls"));

    setfillcolor(RGB(23, 33, 49));
    solidroundrect(layout.quickRect.left, layout.quickRect.top, layout.quickRect.right, layout.quickRect.bottom, 20, 20);
    solidroundrect(layout.controlsRect.left, layout.controlsRect.top, layout.controlsRect.right, layout.controlsRect.bottom, 20, 20);
    setlinecolor(RGB(69, 95, 133));
    roundrect(layout.quickRect.left, layout.quickRect.top, layout.quickRect.right, layout.quickRect.bottom, 20, 20);
    roundrect(layout.controlsRect.left, layout.controlsRect.top, layout.controlsRect.right, layout.controlsRect.bottom, 20, 20);

    settextstyle(bodyFont, 0, _T("Segoe UI"));
    settextcolor(RGB(184, 205, 228));
    outtextxy(layout.quickRect.left + 22, layout.quickRect.top + 30, _T("1. Start from the right-side action card."));
    outtextxy(layout.quickRect.left + 22, layout.quickRect.top + 64, _T("2. Use Settings to adjust audio, speed"));
    outtextxy(layout.quickRect.left + 22, layout.quickRect.top + 92, _T("   and anti-aliasing before a run."));
    outtextxy(layout.quickRect.left + 22, layout.quickRect.top + 138, _T("3. Restart after death or jump back to"));
    outtextxy(layout.quickRect.left + 22, layout.quickRect.top + 166, _T("   the menu without losing polish."));

    outtextxy(layout.controlsRect.left + 22, layout.controlsRect.top + 30, _T("Move mouse to steer"));
    outtextxy(layout.controlsRect.left + 22, layout.controlsRect.top + 64, _T("Arrow keys override mouse instantly"));
    outtextxy(layout.controlsRect.left + 22, layout.controlsRect.top + 98, _T("Hold left mouse to boost"));
    outtextxy(layout.controlsRect.left + 22, layout.controlsRect.top + 132, _T("ESC or P pauses the run"));
    outtextxy(layout.controlsRect.left + 22, layout.controlsRect.top + 166, _T("Right-side icons: settings, about, exit"));

    // Draw all buttons
    for (int i = 0; i < ButtonType::Num; ++i) {
        buttonList[i].DrawButton(mousePos); // Draw button
    }
}

// Display "About" information screen
void ShowAbout() {
    setfillcolor(RGB(10, 15, 23));
    solidrectangle(0, 0, GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT);
    setfillcolor(RGB(18, 31, 49));
    solidcircle(GameConfig::WINDOW_WIDTH - 70, 90, 150);
    setfillcolor(RGB(20, 48, 59));
    solidcircle(90, GameConfig::WINDOW_HEIGHT - 10, 130);

    const int panelLeft = 68;
    const int panelTop = 54;
    const int panelRight = GameConfig::WINDOW_WIDTH - 68;
    const int panelBottom = GameConfig::WINDOW_HEIGHT - 70;
    setfillcolor(RGB(17, 24, 37));
    solidroundrect(panelLeft, panelTop, panelRight, panelBottom, 24, 24);
    setlinecolor(RGB(76, 102, 149));
    roundrect(panelLeft, panelTop, panelRight, panelBottom, 24, 24);

    setbkmode(TRANSPARENT);
    settextstyle(34, 0, _T("Bahnschrift"));
    settextcolor(RGB(243, 248, 255));
    outtextxy(panelLeft + 28, panelTop + 24, _T("About Greed Snake"));

    settextstyle(18, 0, _T("Segoe UI"));
    settextcolor(RGB(164, 188, 222));
    outtextxy(panelLeft + 28, panelTop + 68, _T("A compact arcade remake focused on smooth motion, AI pressure and readable feedback."));

    settextstyle(20, 0, _T("Bahnschrift"));
    settextcolor(RGB(236, 243, 255));
    outtextxy(panelLeft + 28, panelTop + 132, _T("Build"));
    outtextxy(panelLeft + 28, panelTop + 236, _T("Core Controls"));

    settextstyle(18, 0, _T("Segoe UI"));
    settextcolor(RGB(182, 200, 224));
    outtextxy(panelLeft + 28, panelTop + 166, _T("Version: 1.0"));
    outtextxy(panelLeft + 28, panelTop + 194, _T("Author: Chen Runsen"));

    outtextxy(panelLeft + 28, panelTop + 270, _T("Move mouse to steer"));
    outtextxy(panelLeft + 28, panelTop + 298, _T("Arrow keys override mouse control"));
    outtextxy(panelLeft + 28, panelTop + 326, _T("Hold left mouse button to boost"));
    outtextxy(panelLeft + 28, panelTop + 354, _T("ESC / P pauses the run"));

    setfillcolor(RGB(25, 34, 50));
    solidroundrect(panelLeft + 350, panelTop + 132, panelRight - 28, panelTop + 382, 18, 18);
    setlinecolor(RGB(68, 93, 130));
    roundrect(panelLeft + 350, panelTop + 132, panelRight - 28, panelTop + 382, 18, 18);

    settextstyle(20, 0, _T("Bahnschrift"));
    settextcolor(RGB(239, 246, 255));
    outtextxy(panelLeft + 378, panelTop + 156, _T("Highlights"));

    settextstyle(18, 0, _T("Segoe UI"));
    settextcolor(RGB(180, 199, 224));
    outtextxy(panelLeft + 378, panelTop + 196, _T("Large scrolling map"));
    outtextxy(panelLeft + 378, panelTop + 228, _T("Session-based settings"));
    outtextxy(panelLeft + 378, panelTop + 260, _T("Mouse + keyboard hybrid control"));
    outtextxy(panelLeft + 378, panelTop + 292, _T("AI snake swarms and food pressure"));
    outtextxy(panelLeft + 378, panelTop + 324, _T("Animated UI, boost and shield feedback"));

    int aboutButtonWidth = 150;
    int aboutButtonHeight = 50;
    int backButtonX = panelRight - aboutButtonWidth - 28;
    int backButtonY = panelBottom - aboutButtonHeight - 24;

    setfillcolor(RGB(41, 116, 174));
    solidroundrect(backButtonX, backButtonY, backButtonX + aboutButtonWidth, backButtonY + aboutButtonHeight, 12, 12);
    setlinecolor(RGB(144, 214, 255));
    roundrect(backButtonX, backButtonY, backButtonX + aboutButtonWidth, backButtonY + aboutButtonHeight, 12, 12);
    settextstyle(24, 0, _T("Bahnschrift"));
    settextcolor(WHITE);
    outtextxy(backButtonX + aboutButtonWidth / 2 - textwidth(_T("Back")) / 2, backButtonY + 10, _T("Back"));

    FlushBatchDraw();
    
    // Wait for button click instead of any key
    bool aboutOpen = true;
    while (aboutOpen) {
        ExMessage msg = getmessage(EX_MOUSE);
        if (msg.message == WM_LBUTTONDOWN) {
            if (msg.x >= backButtonX && msg.x <= backButtonX + aboutButtonWidth &&
                msg.y >= backButtonY && msg.y <= backButtonY + aboutButtonHeight) {
                aboutOpen = false;
            }
        }
    }
}

// Display game main menu
int ShowGameMenu() {
    // Load buttons (if needed)
    if (buttonList.empty()) {
        LoadButton();
    }

    flushmessage();

    // Set menu text style
    settextstyle(32, 0, _T("Arial"));
    settextcolor(RGB(255, 255, 255));
    setbkmode(TRANSPARENT);

    BeginBatchDraw();
    Vector2 mousePos(static_cast<float>(GameConfig::WINDOW_WIDTH / 2), static_cast<float>(GameConfig::WINDOW_HEIGHT / 2));
    while (true) {
        ExMessage m;
        while (peekmessage(&m, EX_MOUSE | EX_KEY)) {
            if (m.message == WM_MOUSEMOVE || m.message == WM_LBUTTONDOWN || m.message == WM_LBUTTONUP) {
                mousePos = Vector2(static_cast<float>(m.x), static_cast<float>(m.y));
            }

            if (m.message == WM_KEYDOWN) {
                if (m.vkcode == VK_RETURN || m.vkcode == VK_SPACE) {
                    buttonList[StartGame].PlayClickSound();
                    EndBatchDraw();
                    return StartGame;
                }

                if (m.vkcode == VK_ESCAPE) {
                    buttonList[Exit].PlayClickSound();
                    EndBatchDraw();
                    return Exit;
                }
            }

            if (m.message == WM_LBUTTONDOWN) {
                if (buttonList[StartGame].IsOnButton(mousePos)) {
                    buttonList[StartGame].PlayClickSound();
                    EndBatchDraw();
                    return StartGame;
                }
                if (buttonList[Setting].IsOnButton(mousePos)) {
                    buttonList[Setting].PlayClickSound();
                    EndBatchDraw();
                    return Setting;
                }
                if (buttonList[About].IsOnButton(mousePos)) {
                    buttonList[About].PlayClickSound();
                    EndBatchDraw();
                    return About;
                }
                if (buttonList[Exit].IsOnButton(mousePos)) {
                    buttonList[Exit].PlayClickSound();
                    EndBatchDraw();
                    return Exit;
                }
            }
        }

        ResourceManager::Instance().DrawBackground();
        DrawMenu(mousePos);
        FlushBatchDraw();
        Sleep(16);
    }

    return -1;  // No option selected
}

// ---------- Sound & Animation Functions ----------

void PlayBackgroundMusic() {
    if (!GameConfig::SOUND_ON) {
        StopBackgroundMusic();
        return;
    }

    TCHAR statusBuff[256] = {0};
    if (mciSendString(_T("status Greed-Snake mode"), statusBuff, 256, NULL) == 0) {
        if (_tcscmp(statusBuff, _T("playing")) != 0) {
            mciSendString(_T("play Greed-Snake repeat"), NULL, NULL, NULL);
        }
        SetVolume(GetCurrentSettings().volume);
        return;
    }

    if (_taccess(_T(".\\Resource\\SoundEffects\\Greed-Snake.mp3"), 0) != 0) {
        return;
    }

    mciSendString(_T("open .\\Resource\\SoundEffects\\Greed-Snake.mp3 alias Greed-Snake"), NULL, NULL, NULL);
    mciSendString(_T("play Greed-Snake repeat"), NULL, NULL, NULL);
    SetVolume(GetCurrentSettings().volume);
}

void StopBackgroundMusic() {
    // Check if music is playing before trying to stop it
    TCHAR statusBuff[256] = {0};
    if (mciSendString(_T("status Greed-Snake mode"), statusBuff, 256, NULL) == 0) {
        mciSendString(_T("stop Greed-Snake"), NULL, NULL, NULL); // Stop music
        mciSendString(_T("close Greed-Snake"), NULL, NULL, NULL); // Close music
    }
}

namespace {

void ConfigureStretchQuality(HDC targetDC) {
    SetStretchBltMode(targetDC, GameConfig::ANTIALIASING_ON ? HALFTONE : COLORONCOLOR);
    if (GameConfig::ANTIALIASING_ON) {
        SetBrushOrgEx(targetDC, 0, 0, nullptr);
    }
}

float SmoothStep(float value) {
    const float clamped = (std::max)(0.0f, (std::min)(1.0f, value));
    return clamped * clamped * (3.0f - 2.0f * clamped);
}

void PlayUiCue(LPCTSTR soundPath) {
    if (!GameConfig::SOUND_ON || _taccess(soundPath, 0) != 0) {
        return;
    }

    PlaySound(soundPath, NULL, SND_FILENAME | SND_ASYNC);
}

void DrawLandingScene(float pulsePhase) {
    ResourceManager::Instance().DrawBackground();
    const LandingLayout layout = BuildLandingLayout();
    const int panelLeft = layout.panel.left;
    const int panelTop = layout.panel.top;
    const int panelRight = layout.panel.right;
    const int panelBottom = layout.panel.bottom;
    const int titleFont = ScaleTextSize(56, layout.fontScale, 50, 68);
    const int subheadFont = ScaleTextSize(22, layout.fontScale, 21, 26);
    const int sectionFont = ScaleTextSize(24, layout.fontScale, 24, 28);
    const int bodyFont = ScaleTextSize(18, layout.fontScale, 17, 21);
    const int promptFont = ScaleTextSize(24, layout.fontScale, 22, 28);
    const int promptSubFont = ScaleTextSize(17, layout.fontScale, 16, 20);

    setfillcolor(RGB(9, 14, 25));
    solidrectangle(0, 0, GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT);

    setfillcolor(RGB(16, 24, 39));
    solidroundrect(panelLeft, panelTop, panelRight, panelBottom, 26, 26);
    setlinecolor(RGB(76, 108, 156));
    roundrect(panelLeft, panelTop, panelRight, panelBottom, 26, 26);

    setfillcolor(RGB(25, 40, 58));
    solidroundrect(
        layout.headerRect.left,
        layout.headerRect.top,
        layout.headerRect.right,
        layout.headerRect.bottom,
        18,
        18);

    setbkmode(TRANSPARENT);
    settextstyle(titleFont, 0, _T("Bahnschrift"));
    settextcolor(RGB(244, 249, 255));
    outtextxy(panelLeft + ScaleTextSize(42, layout.fontScale, 40, 54), panelTop + ScaleTextSize(44, layout.fontScale, 40, 54), _T("GREED SNAKE"));

    settextstyle(subheadFont, 0, _T("Segoe UI"));
    settextcolor(RGB(168, 196, 228));
    outtextxy(panelLeft + ScaleTextSize(44, layout.fontScale, 42, 56), panelTop + ScaleTextSize(112, layout.fontScale, 106, 136), _T("Modern arcade chase across a large neon map."));

    settextstyle(sectionFont, 0, _T("Bahnschrift"));
    settextcolor(RGB(238, 246, 255));
    outtextxy(layout.leftColumnX, panelTop + ScaleTextSize(176, layout.fontScale, 166, 214), _T("Features"));
    outtextxy(layout.rightColumnX, panelTop + ScaleTextSize(176, layout.fontScale, 166, 214), _T("Controls"));

    settextstyle(bodyFont, 0, _T("Segoe UI"));
    settextcolor(RGB(183, 204, 229));
    outtextxy(layout.leftColumnX, panelTop + ScaleTextSize(214, layout.fontScale, 202, 256), _T("Adaptive visuals and cleaner UI"));
    outtextxy(layout.leftColumnX, panelTop + ScaleTextSize(246, layout.fontScale, 234, 292), _T("Large scrolling arena and AI swarms"));
    outtextxy(layout.leftColumnX, panelTop + ScaleTextSize(278, layout.fontScale, 266, 328), _T("Session tuning for speed, sound and presentation"));

    outtextxy(layout.rightColumnX, panelTop + ScaleTextSize(214, layout.fontScale, 202, 256), _T("Move mouse to steer"));
    outtextxy(layout.rightColumnX, panelTop + ScaleTextSize(246, layout.fontScale, 234, 292), _T("Arrow keys override mouse"));
    outtextxy(layout.rightColumnX, panelTop + ScaleTextSize(278, layout.fontScale, 266, 328), _T("Hold left mouse to boost"));
    outtextxy(layout.rightColumnX, panelTop + ScaleTextSize(310, layout.fontScale, 298, 364), _T("ESC / P pauses the run"));

    const int promptX = layout.promptRect.left;
    const int promptY = layout.promptRect.top;
    const int promptWidth = RectWidth(layout.promptRect);
    const int promptHeight = RectHeight(layout.promptRect);
    const int glowOffset = static_cast<int>(6.0f + 4.0f * pulsePhase);

    setfillcolor(RGB(31, 128, 173));
    solidroundrect(promptX - glowOffset, promptY - glowOffset / 2, promptX + promptWidth + glowOffset, promptY + promptHeight + glowOffset / 2, 20, 20);
    setfillcolor(RGB(20, 90, 126));
    solidroundrect(promptX, promptY, promptX + promptWidth, promptY + promptHeight, 20, 20);
    setlinecolor(RGB(167, 234, 255));
    roundrect(promptX, promptY, promptX + promptWidth, promptY + promptHeight, 20, 20);

    settextstyle(promptFont, 0, _T("Bahnschrift"));
    settextcolor(WHITE);
    outtextxy(promptX + (promptWidth - textwidth(_T("Click Or Press Any Key"))) / 2, promptY + (promptHeight - textheight(_T("Click Or Press Any Key"))) / 2, _T("Click Or Press Any Key"));

    settextstyle(promptSubFont, 0, _T("Segoe UI"));
    settextcolor(RGB(161, 188, 226));
    outtextxy(
        GameConfig::WINDOW_WIDTH / 2 - textwidth(_T("Open the main menu")) / 2,
        layout.promptRect.bottom + ScaleTextSize(10, layout.fontScale, 8, 14),
        _T("Open the main menu"));
}

void DrawSceneTransitionFrame(float progress, LPCTSTR title, LPCTSTR subtitle, COLORREF accentColor, bool entering) {
    const float eased = SmoothStep(progress);
    const float shutterPhase = entering ? (1.0f - eased) : eased;
    const int shutterWidth = static_cast<int>((GameConfig::WINDOW_WIDTH / 2.0f) * shutterPhase);
    const int shutterHeight = static_cast<int>((GameConfig::WINDOW_HEIGHT / 2.0f) * shutterPhase);
    const int panelWidth = 452;
    const int panelHeight = 172;
    const int panelLeft = GameConfig::WINDOW_WIDTH / 2 - panelWidth / 2;
    const int panelTop = GameConfig::WINDOW_HEIGHT / 2 - panelHeight / 2;
    const int progressWidth = static_cast<int>(320.0f * eased);

    setfillcolor(RGB(7, 11, 20));
    solidrectangle(0, 0, GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT);

    setfillcolor(accentColor);
    solidrectangle(0, 0, GameConfig::WINDOW_WIDTH, 8);
    solidrectangle(0, GameConfig::WINDOW_HEIGHT - 8, GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT);

    setfillcolor(RGB(13, 18, 28));
    solidrectangle(0, 0, shutterWidth, GameConfig::WINDOW_HEIGHT);
    solidrectangle(GameConfig::WINDOW_WIDTH - shutterWidth, 0, GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT);
    solidrectangle(0, 0, GameConfig::WINDOW_WIDTH, shutterHeight);
    solidrectangle(0, GameConfig::WINDOW_HEIGHT - shutterHeight, GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT);

    setfillcolor(RGB(14, 22, 34));
    solidroundrect(panelLeft, panelTop, panelLeft + panelWidth, panelTop + panelHeight, 28, 28);
    setlinecolor(RGB(111, 163, 210));
    roundrect(panelLeft, panelTop, panelLeft + panelWidth, panelTop + panelHeight, 28, 28);

    setfillcolor(accentColor);
    solidroundrect(panelLeft + 32, panelTop + 30, panelLeft + 176, panelTop + 58, 14, 14);
    setfillcolor(RGB(30, 81, 105));
    solidroundrect(panelLeft + 64, panelTop + 122, panelLeft + 384, panelTop + 136, 10, 10);
    setfillcolor(accentColor);
    solidroundrect(panelLeft + 64, panelTop + 122, panelLeft + 64 + progressWidth, panelTop + 136, 10, 10);

    setbkmode(TRANSPARENT);
    settextstyle(16, 0, _T("Segoe UI"));
    settextcolor(RGB(236, 245, 255));
    outtextxy(panelLeft + 46, panelTop + 34, entering ? _T("Scene Transition") : _T("Session Complete"));

    settextstyle(34, 0, _T("Bahnschrift"));
    settextcolor(RGB(240, 247, 255));
    outtextxy(GameConfig::WINDOW_WIDTH / 2 - textwidth(title) / 2, panelTop + 70, title);

    settextstyle(18, 0, _T("Segoe UI"));
    settextcolor(RGB(171, 199, 232));
    outtextxy(GameConfig::WINDOW_WIDTH / 2 - textwidth(subtitle) / 2, panelTop + 112, subtitle);
}

void DrawSessionIntroFrame(float progress, LPCTSTR title, LPCTSTR subtitle, COLORREF accentColor) {
    const float eased = SmoothStep(progress);
    const float pulse = 0.5f + 0.5f * sinf(progress * 6.2831853f);
    const int panelWidth = 484;
    const int panelHeight = 214;
    const int panelLeft = GameConfig::WINDOW_WIDTH / 2 - panelWidth / 2;
    const int panelTop = GameConfig::WINDOW_HEIGHT / 2 - panelHeight / 2;
    const int scanlineOffset = static_cast<int>((1.0f - eased) * 120.0f);

    setfillcolor(RGB(5, 9, 17));
    solidrectangle(0, 0, GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT);

    setfillcolor(RGB(11, 22, 33));
    solidrectangle(0, 124 - scanlineOffset, GameConfig::WINDOW_WIDTH, 132 - scanlineOffset);
    solidrectangle(0, GameConfig::WINDOW_HEIGHT - 132 + scanlineOffset, GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT - 124 + scanlineOffset);

    const int haloRadius = static_cast<int>(118.0f + 14.0f * pulse);
    setfillcolor(RGB(12, 38, 52));
    solidcircle(GameConfig::WINDOW_WIDTH / 2, GameConfig::WINDOW_HEIGHT / 2 - 12, haloRadius);

    setfillcolor(RGB(12, 19, 30));
    solidroundrect(panelLeft, panelTop, panelLeft + panelWidth, panelTop + panelHeight, 32, 32);
    setlinecolor(accentColor);
    roundrect(panelLeft, panelTop, panelLeft + panelWidth, panelTop + panelHeight, 32, 32);

    setfillcolor(accentColor);
    solidroundrect(panelLeft + 32, panelTop + 26, panelLeft + 198, panelTop + 54, 14, 14);
    solidroundrect(panelLeft + 46, panelTop + 162, panelLeft + 46 + static_cast<int>(392.0f * eased), panelTop + 176, 10, 10);

    setbkmode(TRANSPARENT);
    settextstyle(16, 0, _T("Segoe UI"));
    settextcolor(RGB(241, 248, 255));
    outtextxy(panelLeft + 46, panelTop + 30, _T("Run Initialized"));

    settextstyle(42, 0, _T("Bahnschrift"));
    settextcolor(RGB(245, 249, 255));
    outtextxy(GameConfig::WINDOW_WIDTH / 2 - textwidth(title) / 2, panelTop + 74, title);

    settextstyle(20, 0, _T("Segoe UI"));
    settextcolor(RGB(178, 205, 231));
    outtextxy(GameConfig::WINDOW_WIDTH / 2 - textwidth(subtitle) / 2, panelTop + 128, subtitle);

    const TCHAR* hint = _T("Mouse steers, arrows override, left mouse boosts");
    settextstyle(17, 0, _T("Segoe UI"));
    settextcolor(RGB(154, 183, 210));
    outtextxy(GameConfig::WINDOW_WIDTH / 2 - textwidth(hint) / 2, panelTop + 186, hint);
}

void StopStartAnimationAudio() {
    TCHAR statusBuff[256] = { 0 };
    if (mciSendString(_T("status Start-Animation mode"), statusBuff, 256, NULL) == 0) {
        mciSendString(_T("stop Start-Animation"), NULL, 0, NULL);
        mciSendString(_T("close Start-Animation"), NULL, 0, NULL);
    }
}

int FindLastAvailableStartAnimationFrame(const TCHAR* path, const TCHAR* ext) {
    for (int i = 0;; ++i) {
        TCHAR frameFileName[MAX_PATH];
        _stprintf_s(frameFileName, MAX_PATH, _T("%sframe_%d%s"), path, i, ext);
        if (_taccess(frameFileName, 0) != 0) {
            return i - 1;
        }
    }
}

}

void ShowLandingScreen() {
    flushmessage();
    BeginBatchDraw();

    bool waiting = true;
    while (waiting) {
        ExMessage message;
        while (peekmessage(&message, EX_MOUSE | EX_KEY)) {
            if (message.message == WM_LBUTTONDOWN || message.message == WM_KEYDOWN) {
                waiting = false;
                break;
            }
        }

        const float pulsePhase = 0.5f + 0.5f * sinf(GetTickCount() * 0.005f);
        DrawLandingScene(pulsePhase);
        FlushBatchDraw();
        Sleep(16);
    }

    EndBatchDraw();
    flushmessage();
}

void PlaySceneTransition(LPCTSTR title, LPCTSTR subtitle, COLORREF accentColor, bool entering) {
    flushmessage();
    PlayUiCue(_T(".\\Resource\\SoundEffects\\Impact.wav"));
    BeginBatchDraw();
    const int frameCount = GameConfig::ANIMATIONS_ON ? 18 : 1;
    for (int frameIndex = 0; frameIndex < frameCount; ++frameIndex) {
        const float progress = frameCount == 1
            ? 1.0f
            : static_cast<float>(frameIndex + 1) / static_cast<float>(frameCount);
        DrawSceneTransitionFrame(progress, title, subtitle, accentColor, entering);
        FlushBatchDraw();
        Sleep(GameConfig::ANIMATIONS_ON ? 12 : 1);
    }
    EndBatchDraw();
    flushmessage();
}

void PlaySceneTransition(LPCTSTR title, COLORREF accentColor, bool entering) {
    PlaySceneTransition(
        title,
        entering ? _T("Preparing next scene") : _T("Returning to control deck"),
        accentColor,
        entering);
}

void PlaySessionIntroSequence(LPCTSTR title, LPCTSTR subtitle, COLORREF accentColor) {
    flushmessage();
    PlayUiCue(_T(".\\Resource\\SoundEffects\\Impact.wav"));

    BeginBatchDraw();
    const int frameCount = GameConfig::ANIMATIONS_ON ? 22 : 1;
    for (int frameIndex = 0; frameIndex < frameCount; ++frameIndex) {
        const float progress = frameCount == 1
            ? 1.0f
            : static_cast<float>(frameIndex + 1) / static_cast<float>(frameCount);
        DrawSessionIntroFrame(progress, title, subtitle, accentColor);
        FlushBatchDraw();
        Sleep(GameConfig::ANIMATIONS_ON ? 14 : 1);
    }
    EndBatchDraw();

    flushmessage();
}

void PlayStartAnimation() {
    // Define frame file path and file extension
    const TCHAR* path = _T(".\\Resource\\Greed-Snake-Start-Animation-Frames\\"); // Frame file path
    const TCHAR* ext = _T(".bmp"); // File extension

    // Check if animation audio is already playing and close it if needed
    TCHAR statusBuff[256] = {0};
    if (mciSendString(_T("status Start-Animation mode"), statusBuff, 256, NULL) == 0) {
        mciSendString(_T("close Start-Animation"), NULL, 0, NULL);
    }

    // Always play the sound even if animations are off
    mciSendString(_T("open .\\Resource\\SoundEffects\\Greed-Snake-Start-Animation.MP3 alias Start-Animation"), NULL, NULL, NULL); // Open animation music
    mciSendString(_T("play Start-Animation"), NULL, NULL, NULL); // Play animation music
    
    if (!GameConfig::ANIMATIONS_ON) {
        // If animations are disabled, just wait a moment and return
        Sleep(1000);
        StopStartAnimationAudio();
        return;
    }

    const int lastFrameIndex = FindLastAvailableStartAnimationFrame(path, ext);
    if (lastFrameIndex < 0) {
        StopStartAnimationAudio();
        return;
    }
    const int frameStep = lastFrameIndex > 240 ? 2 : 1;
    
    // 先绘制背景，避免黑屏
    setfillcolor(RGB(20, 20, 20));
    solidrectangle(0, 0, GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT);
    settextstyle(32, 0, _T("Arial"));
    settextcolor(WHITE);
    outtextxy(GameConfig::WINDOW_WIDTH/2 - 100, GameConfig::WINDOW_HEIGHT/2 - 16, _T("Loading..."));
    FlushBatchDraw();

    Sleep(1000); // 缩短等待时间

    // Declare IMAGE structure variable
    IMAGE FImg;
    IMAGE scaledFrame;
    scaledFrame.Resize(GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT);

    BeginBatchDraw();

    // Use loop to load and display each frame
    for (int i = 0; i <= lastFrameIndex; i += frameStep) {
        TCHAR frameFileName[MAX_PATH];  // Ensure buffer is large enough to store full path
        _stprintf_s(frameFileName, MAX_PATH, _T("%sframe_%d%s"), path, i, ext); // Format frame filename

        if (_taccess(frameFileName, 0) != 0) {
            break;
        }

        // Load image and draw it
        loadimage(&FImg, frameFileName);
        ConfigureStretchQuality(GetImageHDC(&scaledFrame));
        StretchBlt(GetImageHDC(&scaledFrame), 0, 0, GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT,
            GetImageHDC(&FImg), 0, 0, FImg.getwidth(), FImg.getheight(), SRCCOPY);
        putimage(0, 0, &scaledFrame);
        FlushBatchDraw();
        
        // Sleep without holding the mutex
        Sleep((std::max)(8, GameConfig::FRAME_DELAY - frameStep * 6));
    }

    EndBatchDraw();
    StopStartAnimationAudio();
    flushmessage();
}

// Add a new function to properly clean up audio resources when closing the game
void CleanupAudioResources() {
    // Close all audio devices and resources
    mciSendString(_T("close all"), NULL, 0, NULL);
} 
