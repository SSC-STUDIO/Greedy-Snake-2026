#include "Setting.h"
#include "../Core/ResourceManager.h"
#include "../Core/SessionConfig.h"
#include "../Gameplay/Food.h"
#include "../Gameplay/GameConfig.h"
#include "../UI/UI.h"
#include <algorithm>
#include <array>
#include <filesystem>
#include <fstream>
#include <string>
#include "../Utils/DrawHelpers.h"

#pragma comment(lib, "winmm.lib")

namespace {
GameSettings g_currentSettings = DefaultGameSettings();
bool g_settingsLoaded = false;
constexpr LPCTSTR kSettingsFileName = _T("Greed-Snake-2025.settings.ini");
using SettingsText = std::basic_string<TCHAR>;

struct SettingsLayout {
    RECT panel{};
    RECT volumeTrack{};
    RECT difficultyButtons[3]{};
    RECT soundButtons[2]{};
    RECT speedButtons[3]{};
    RECT animationButtons[2]{};
    RECT antiAliasingButtons[2]{};
    RECT displayButtons[2]{};
    RECT applyButton{};
    RECT cancelButton{};
};

RECT MakeRect(int left, int top, int right, int bottom) {
    RECT rect{ left, top, right, bottom };
    return rect;
}

bool Contains(const RECT& rect, int x, int y) {
    return x >= rect.left && x <= rect.right && y >= rect.top && y <= rect.bottom;
}

int RectWidth(const RECT& rect) {
    return rect.right - rect.left;
}

int RectHeight(const RECT& rect) {
    return rect.bottom - rect.top;
}

const TCHAR* GetSettingsFilePath() {
    static std::array<TCHAR, MAX_PATH> settingsPath{};
    static bool pathResolved = false;
    if (!pathResolved) {
        DWORD pathLength = GetModuleFileName(nullptr, settingsPath.data(), static_cast<DWORD>(settingsPath.size()));
        if (pathLength == 0 || pathLength >= settingsPath.size()) {
            _tcscpy_s(settingsPath.data(), settingsPath.size(), kSettingsFileName);
        } else {
            TCHAR* fileName = _tcsrchr(settingsPath.data(), _T('\\'));
            if (fileName == nullptr) {
                _tcscpy_s(settingsPath.data(), settingsPath.size(), kSettingsFileName);
            } else {
                *(fileName + 1) = _T('\0');
                _tcscat_s(settingsPath.data(), settingsPath.size(), kSettingsFileName);
            }
        }
        pathResolved = true;
    }

    return settingsPath.data();
}

int ClampChoice(int value, int minValue, int maxValue) {
    return (std::max)(minValue, (std::min)(maxValue, value));
}

float ClampUnitFloat(float value) {
    return (std::max)(0.0f, (std::min)(1.0f, value));
}

GameSettings SanitizeSettings(const GameSettings& settings) {
    GameSettings sanitized = settings;
    sanitized.volume = ClampUnitFloat(sanitized.volume);
    sanitized.difficulty = ClampChoice(sanitized.difficulty, 0, 2);
    sanitized.snakeSpeed = ClampChoice(sanitized.snakeSpeed, 0, 2);
    return sanitized;
}

SettingsText TrimSettingsText(const SettingsText& value) {
    size_t start = 0;
    while (start < value.size() && _istspace(value[start])) {
        ++start;
    }

    size_t end = value.size();
    while (end > start && _istspace(value[end - 1])) {
        --end;
    }

    return value.substr(start, end - start);
}

void ApplyStoredSetting(GameSettings& settings, const SettingsText& key, const SettingsText& value) {
    if (key == _T("volume")) {
        settings.volume = static_cast<float>(_tstof(value.c_str()));
        return;
    }
    if (key == _T("difficulty")) {
        settings.difficulty = _tstoi(value.c_str());
        return;
    }
    if (key == _T("soundOn")) {
        settings.soundOn = _tstoi(value.c_str()) != 0;
        return;
    }
    if (key == _T("snakeSpeed")) {
        settings.snakeSpeed = _tstoi(value.c_str());
        return;
    }
    if (key == _T("animationsOn")) {
        settings.animationsOn = _tstoi(value.c_str()) != 0;
        return;
    }
    if (key == _T("antiAliasingOn")) {
        settings.antiAliasingOn = _tstoi(value.c_str()) != 0;
        return;
    }
    if (key == _T("fullscreenOn")) {
        settings.fullscreenOn = _tstoi(value.c_str()) != 0;
    }
}

GameSettings LoadPersistedSettings() {
    GameSettings persistedSettings = DefaultGameSettings();
    std::basic_ifstream<TCHAR> input{ std::filesystem::path(GetSettingsFilePath()) };
    if (!input.is_open()) {
        return persistedSettings;
    }

    SettingsText line;
    while (std::getline(input, line)) {
        const size_t separator = line.find(_T('='));
        if (separator == SettingsText::npos) {
            continue;
        }

        const SettingsText key = TrimSettingsText(line.substr(0, separator));
        const SettingsText value = TrimSettingsText(line.substr(separator + 1));
        if (key.empty()) {
            continue;
        }

        ApplyStoredSetting(persistedSettings, key, value);
    }

    return persistedSettings;
}

void SavePersistedSettings(const GameSettings& settings) {
    const GameSettings sanitized = SanitizeSettings(settings);
    std::basic_ofstream<TCHAR> output{ std::filesystem::path(GetSettingsFilePath()), std::ios::trunc };
    if (!output.is_open()) {
        return;
    }

    TCHAR valueText[32];
    _stprintf_s(valueText, _T("%.3f"), sanitized.volume);
    output << _T("volume=") << valueText << _T('\n');

    _stprintf_s(valueText, _T("%d"), sanitized.difficulty);
    output << _T("difficulty=") << valueText << _T('\n');

    _stprintf_s(valueText, _T("%d"), sanitized.soundOn ? 1 : 0);
    output << _T("soundOn=") << valueText << _T('\n');

    _stprintf_s(valueText, _T("%d"), sanitized.snakeSpeed);
    output << _T("snakeSpeed=") << valueText << _T('\n');

    _stprintf_s(valueText, _T("%d"), sanitized.animationsOn ? 1 : 0);
    output << _T("animationsOn=") << valueText << _T('\n');

    _stprintf_s(valueText, _T("%d"), sanitized.antiAliasingOn ? 1 : 0);
    output << _T("antiAliasingOn=") << valueText << _T('\n');

    _stprintf_s(valueText, _T("%d"), sanitized.fullscreenOn ? 1 : 0);
    output << _T("fullscreenOn=") << valueText << _T('\n');
    output.flush();
}

void EnsureSettingsLoaded() {
    if (g_settingsLoaded) {
        return;
    }

    g_currentSettings = SanitizeSettings(LoadPersistedSettings());
    g_settingsLoaded = true;
}

SettingsLayout BuildSettingsLayout(int windowWidth, int windowHeight) {
    SettingsLayout layout;
    const int panelHorizontalMargin = windowWidth > 980 ? (windowWidth - 884) / 2 : 48;
    const int panelVerticalMargin = windowHeight > 860 ? (windowHeight - 792) / 2 : 20;
    layout.panel = MakeRect(
        panelHorizontalMargin,
        panelVerticalMargin,
        windowWidth - panelHorizontalMargin,
        windowHeight - panelVerticalMargin);

    const int controlLeft = layout.panel.left + 245;
    const int controlWidth = layout.panel.right - controlLeft - 36;
    const int buttonGap = 12;
    const int buttonHeight = 42;
    const int rowStart = layout.panel.top + 118;
    const int rowGap = 64;

    layout.volumeTrack = MakeRect(controlLeft, rowStart + 12, controlLeft + controlWidth, rowStart + 24);

    const int threeColWidth = (controlWidth - buttonGap * 2) / 3;
    const int twoColWidth = (controlWidth - buttonGap) / 2;

    auto fillThreeButtonRow = [&](RECT (&buttons)[3], int rowTop) {
        for (int i = 0; i < 3; ++i) {
            const int left = controlLeft + i * (threeColWidth + buttonGap);
            buttons[i] = MakeRect(left, rowTop, left + threeColWidth, rowTop + buttonHeight);
        }
    };

    auto fillTwoButtonRow = [&](RECT (&buttons)[2], int rowTop) {
        for (int i = 0; i < 2; ++i) {
            const int left = controlLeft + i * (twoColWidth + buttonGap);
            buttons[i] = MakeRect(left, rowTop, left + twoColWidth, rowTop + buttonHeight);
        }
    };

    fillThreeButtonRow(layout.difficultyButtons, rowStart + rowGap);
    fillTwoButtonRow(layout.soundButtons, rowStart + rowGap * 2);
    fillThreeButtonRow(layout.speedButtons, rowStart + rowGap * 3);
    fillTwoButtonRow(layout.animationButtons, rowStart + rowGap * 4);
    fillTwoButtonRow(layout.antiAliasingButtons, rowStart + rowGap * 5);
    fillTwoButtonRow(layout.displayButtons, rowStart + rowGap * 6);

    const int footerTop = layout.panel.bottom - 84;
    layout.applyButton = MakeRect(layout.panel.right - 292, footerTop, layout.panel.right - 152, footerTop + 48);
    layout.cancelButton = MakeRect(layout.panel.right - 140, footerTop, layout.panel.right - 20, footerTop + 48);
    return layout;
}

void DrawSoftBackdrop(int windowWidth, int windowHeight) {
    setfillcolor(RGB(11, 16, 26));
    solidrectangle(0, 0, windowWidth, windowHeight);

    setfillcolor(RGB(19, 31, 48));
    solidcircle(windowWidth - 90, 120, 180);
    setfillcolor(RGB(17, 46, 60));
    solidcircle(120, windowHeight - 40, 140);

    setlinecolor(RGB(36, 52, 77));
    for (int x = -windowWidth / 2; x < windowWidth * 2; x += 36) {
        line(x, 0, x + windowHeight / 2, windowHeight);
    }
}

void DrawPanel(const RECT& rect) {
    setfillcolor(RGB(17, 23, 36));
    solidroundrect(rect.left, rect.top, rect.right, rect.bottom, 24, 24);
    setlinecolor(RGB(64, 83, 116));
    roundrect(rect.left, rect.top, rect.right, rect.bottom, 24, 24);

    setfillcolor(RGB(25, 34, 50));
    solidroundrect(rect.left + 18, rect.top + 18, rect.right - 18, rect.top + 86, 18, 18);
}

void DrawSettingsTitle(const RECT& panel) {
    setbkmode(TRANSPARENT);
    settextcolor(RGB(240, 247, 255));
    settextstyle(34, 0, _T("Bahnschrift"));
    outtextxy(panel.left + 34, panel.top + 28, _T("Settings"));

    settextstyle(18, 0, _T("Segoe UI"));
    settextcolor(RGB(161, 188, 226));
    outtextxy(panel.left + 34, panel.top + 64, _T("Tune control feel, presentation and session rules."));
}

void DrawSectionText(int x, int y, const TCHAR* title, const TCHAR* subtitle) {
    setbkmode(TRANSPARENT);
    settextstyle(20, 0, _T("Bahnschrift"));
    settextcolor(RGB(241, 247, 255));
    outtextxy(x, y, title);

    settextstyle(15, 0, _T("Segoe UI"));
    settextcolor(RGB(148, 168, 196));
    outtextxy(x, y + 24, subtitle);
}

void DrawChoiceButton(const RECT& rect, const TCHAR* label, bool selected, bool hovered) {
    const COLORREF fill = selected
        ? RGB(41, 155, 196)
        : (hovered ? RGB(45, 57, 81) : RGB(30, 38, 56));
    const COLORREF border = selected ? RGB(128, 231, 255) : RGB(73, 89, 117);
    const COLORREF text = selected ? RGB(247, 252, 255) : RGB(194, 210, 230);

    setfillcolor(fill);
    solidroundrect(rect.left, rect.top, rect.right, rect.bottom, 12, 12);
    setlinecolor(border);
    roundrect(rect.left, rect.top, rect.right, rect.bottom, 12, 12);

    setbkmode(TRANSPARENT);
    settextstyle(18, 0, _T("Bahnschrift"));
    settextcolor(text);
    outtextxy(
        rect.left + (RectWidth(rect) - textwidth(label)) / 2,
        rect.top + (RectHeight(rect) - textheight(label)) / 2,
        label);
}

void DrawVolumeControl(const RECT& track, float volume, const Vector2& mousePosition) {
    const bool hovered = Contains(
        MakeRect(track.left - 12, track.top - 12, track.right + 12, track.bottom + 12),
        static_cast<int>(mousePosition.x),
        static_cast<int>(mousePosition.y));
    const int handleX = track.left + static_cast<int>(volume * RectWidth(track));
    const int handleY = track.top + RectHeight(track) / 2;

    setfillcolor(RGB(27, 34, 48));
    solidroundrect(track.left, track.top, track.right, track.bottom, 6, 6);

    setfillcolor(RGB(41, 155, 196));
    solidroundrect(track.left, track.top, handleX, track.bottom, 6, 6);

    setfillcolor(hovered ? RGB(234, 247, 255) : RGB(201, 236, 255));
    setlinecolor(RGB(115, 210, 255));
    solidcircle(handleX, handleY, hovered ? 12 : 10);
    circle(handleX, handleY, hovered ? 14 : 12);

    TCHAR volumeText[32];
    _stprintf_s(volumeText, _T("%d%%"), static_cast<int>(volume * 100.0f + 0.5f));
    settextstyle(18, 0, _T("Bahnschrift"));
    settextcolor(RGB(194, 220, 239));
    outtextxy(track.right - textwidth(volumeText), track.top - 32, volumeText);
}

void DrawFooterButton(const RECT& rect, const TCHAR* label, COLORREF fill, COLORREF border, const Vector2& mousePosition) {
    const bool hovered = Contains(rect, static_cast<int>(mousePosition.x), static_cast<int>(mousePosition.y));
    const COLORREF finalFill = hovered
        ? RGB(
            (std::min)(255, static_cast<int>(GetRValue(fill)) + 18),
            (std::min)(255, static_cast<int>(GetGValue(fill)) + 18),
            (std::min)(255, static_cast<int>(GetBValue(fill)) + 18))
        : fill;

    setfillcolor(finalFill);
    solidroundrect(rect.left, rect.top, rect.right, rect.bottom, 14, 14);
    setlinecolor(border);
    roundrect(rect.left, rect.top, rect.right, rect.bottom, 14, 14);

    settextstyle(20, 0, _T("Bahnschrift"));
    settextcolor(WHITE);
    outtextxy(
        rect.left + (RectWidth(rect) - textwidth(label)) / 2,
        rect.top + (RectHeight(rect) - textheight(label)) / 2,
        label);
}

void DrawSettingsScene(const SettingsLayout& layout, const GameSettings& settings, const Vector2& mousePosition) {
    DrawSoftBackdrop(GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT);
    DrawPanel(layout.panel);
    DrawSettingsTitle(layout.panel);

    const int leftColumn = layout.panel.left + 34;
    const int rowStart = layout.panel.top + 118;
    const int rowGap = 64;

    DrawSectionText(leftColumn, rowStart - 2, _T("Volume"), _T("Preview menu and gameplay audio immediately."));
    DrawVolumeControl(layout.volumeTrack, settings.volume, mousePosition);

    DrawSectionText(leftColumn, rowStart + rowGap - 2, _T("Difficulty"), _T("Adjust AI count, aggression and lava pressure."));
    const TCHAR* difficultyLabels[] = { _T("Easy"), _T("Normal"), _T("Hard") };
    for (int i = 0; i < 3; ++i) {
        DrawChoiceButton(layout.difficultyButtons[i], difficultyLabels[i], settings.difficulty == i,
            Contains(layout.difficultyButtons[i], static_cast<int>(mousePosition.x), static_cast<int>(mousePosition.y)));
    }

    DrawSectionText(leftColumn, rowStart + rowGap * 2 - 2, _T("Sound"), _T("Enable or mute all UI and gameplay effects."));
    const TCHAR* onOffLabels[] = { _T("Off"), _T("On") };
    for (int i = 0; i < 2; ++i) {
        const bool selected = (i == 0) ? !settings.soundOn : settings.soundOn;
        DrawChoiceButton(layout.soundButtons[i], onOffLabels[i], selected,
            Contains(layout.soundButtons[i], static_cast<int>(mousePosition.x), static_cast<int>(mousePosition.y)));
    }

    DrawSectionText(leftColumn, rowStart + rowGap * 3 - 2, _T("Snake Speed"), _T("Base movement speed before boost is applied."));
    const TCHAR* speedLabels[] = { _T("Slow"), _T("Normal"), _T("Fast") };
    for (int i = 0; i < 3; ++i) {
        DrawChoiceButton(layout.speedButtons[i], speedLabels[i], settings.snakeSpeed == i,
            Contains(layout.speedButtons[i], static_cast<int>(mousePosition.x), static_cast<int>(mousePosition.y)));
    }

    DrawSectionText(leftColumn, rowStart + rowGap * 4 - 2, _T("Animations"), _T("Toggle presentation-heavy scene effects."));
    for (int i = 0; i < 2; ++i) {
        const bool selected = (i == 0) ? !settings.animationsOn : settings.animationsOn;
        DrawChoiceButton(layout.animationButtons[i], onOffLabels[i], selected,
            Contains(layout.animationButtons[i], static_cast<int>(mousePosition.x), static_cast<int>(mousePosition.y)));
    }

    DrawSectionText(leftColumn, rowStart + rowGap * 5 - 2, _T("Anti-Aliasing"), _T("Use higher-quality image scaling for UI and splash assets."));
    for (int i = 0; i < 2; ++i) {
        const bool selected = (i == 0) ? !settings.antiAliasingOn : settings.antiAliasingOn;
        DrawChoiceButton(layout.antiAliasingButtons[i], onOffLabels[i], selected,
            Contains(layout.antiAliasingButtons[i], static_cast<int>(mousePosition.x), static_cast<int>(mousePosition.y)));
    }

    DrawSectionText(leftColumn, rowStart + rowGap * 6 - 2, _T("Display Mode"), _T("Fullscreen uses desktop resolution. Applies immediately and is saved."));
    const TCHAR* displayLabels[] = { _T("Windowed"), _T("Fullscreen") };
    for (int i = 0; i < 2; ++i) {
        const bool selected = (i == 0) ? !settings.fullscreenOn : settings.fullscreenOn;
        DrawChoiceButton(layout.displayButtons[i], displayLabels[i], selected,
            Contains(layout.displayButtons[i], static_cast<int>(mousePosition.x), static_cast<int>(mousePosition.y)));
    }

    DrawFooterButton(layout.applyButton, _T("Apply"), RGB(26, 126, 97), RGB(114, 224, 184), mousePosition);
    DrawFooterButton(layout.cancelButton, _T("Back"), RGB(95, 58, 74), RGB(218, 145, 167), mousePosition);
}

bool UpdateVolumeFromMouse(const RECT& track, int mouseX, GameSettings& settings) {
    const float newVolume = (std::max)(0.0f, (std::min)(1.0f, static_cast<float>(mouseX - track.left) / RectWidth(track)));
    settings.volume = newVolume;
    SetVolume(newVolume);
    return true;
}

GameSettings CaptureCurrentSettings() {
    EnsureSettingsLoaded();
    return g_currentSettings;
}

void RefreshDisplayMetrics(bool fullscreenOn) {
    GameConfig::FULLSCREEN_ON = fullscreenOn;
    if (fullscreenOn) {
        GameConfig::WINDOW_WIDTH = (std::max)(GameConfig::BASE_WINDOW_WIDTH, GetSystemMetrics(SM_CXSCREEN));
        GameConfig::WINDOW_HEIGHT = (std::max)(GameConfig::BASE_WINDOW_HEIGHT, GetSystemMetrics(SM_CYSCREEN));
    } else {
        GameConfig::WINDOW_WIDTH = GameConfig::BASE_WINDOW_WIDTH;
        GameConfig::WINDOW_HEIGHT = GameConfig::BASE_WINDOW_HEIGHT;
    }
    RefreshPlayAreaBounds();
}

void ApplyWindowMode(HWND hwnd) {
    if (!hwnd) {
        return;
    }

    if (GameConfig::FULLSCREEN_ON) {
        SetWindowLongPtr(hwnd, GWL_STYLE, WS_VISIBLE | WS_POPUP);
        SetWindowLongPtr(hwnd, GWL_EXSTYLE, WS_EX_APPWINDOW);
        SetWindowPos(
            hwnd,
            HWND_TOP,
            0,
            0,
            GameConfig::WINDOW_WIDTH,
            GameConfig::WINDOW_HEIGHT,
            SWP_FRAMECHANGED | SWP_SHOWWINDOW);
        ShowWindow(hwnd, SW_SHOWMAXIMIZED);
        return;
    }

    const LONG_PTR windowStyle = WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX;
    SetWindowLongPtr(hwnd, GWL_STYLE, windowStyle | WS_VISIBLE);
    SetWindowLongPtr(hwnd, GWL_EXSTYLE, WS_EX_APPWINDOW);

    RECT clientRect{ 0, 0, GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT };
    AdjustWindowRectEx(&clientRect, static_cast<DWORD>(windowStyle), FALSE, WS_EX_APPWINDOW);
    const int windowWidth = clientRect.right - clientRect.left;
    const int windowHeight = clientRect.bottom - clientRect.top;
    const int screenWidth = GetSystemMetrics(SM_CXSCREEN);
    const int screenHeight = GetSystemMetrics(SM_CYSCREEN);
    const int windowLeft = (std::max)(0, (screenWidth - windowWidth) / 2);
    const int windowTop = (std::max)(0, (screenHeight - windowHeight) / 2);

    SetWindowPos(
        hwnd,
        HWND_TOP,
        windowLeft,
        windowTop,
        windowWidth,
        windowHeight,
        SWP_FRAMECHANGED | SWP_SHOWWINDOW);
    ShowWindow(hwnd, SW_SHOWNORMAL);
}
}

void SetVolume(float volume) {
    volume = max(0.0f, min(1.0f, volume));
    DWORD dwVolume = static_cast<DWORD>(volume * 0xFFFF);
    DWORD stereoVolume = (dwVolume << 16) | dwVolume;
    waveOutSetVolume(0, stereoVolume);
}

void ApplySettings(const GameSettings& settings) {
    EnsureSettingsLoaded();

    const GameSettings sanitizedSettings = SanitizeSettings(settings);
    const bool wasSoundOn = g_currentSettings.soundOn;
    const bool displayModeChanged = g_currentSettings.fullscreenOn != sanitizedSettings.fullscreenOn;
    g_currentSettings = sanitizedSettings;
    SavePersistedSettings(g_currentSettings);

    if (displayModeChanged) {
        RefreshDisplayMetrics(g_currentSettings.fullscreenOn);
        ResetFoodSpatialGrid();
        ApplyWindowMode(GetHWnd());
    }

    SetVolume(g_currentSettings.volume);
    GameConfig::SOUND_ON = g_currentSettings.soundOn;
    GameConfig::ANIMATIONS_ON = g_currentSettings.animationsOn;
    GameConfig::ANTIALIASING_ON = g_currentSettings.antiAliasingOn;

    if (!g_currentSettings.soundOn) {
        ResourceManager::Instance().StopBackgroundMusic();
    } else if (!wasSoundOn) {
        ResourceManager::Instance().PlayBackgroundMusic();
    }

    if (ResourceManager::Instance().IsLoaded()) {
        ResourceManager::Instance().ScaleBackgroundImage(GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT);
    }
    LoadButton();
}

void InitializeDisplayConfig(const GameSettings& settings) {
    RefreshDisplayMetrics(settings.fullscreenOn);
}

void ApplyDisplayModeToCurrentWindow() {
    ApplyWindowMode(GetHWnd());
}

GameSettings GetCurrentSettings() {
    EnsureSettingsLoaded();
    return g_currentSettings;
}

void ShowSettings(int windowWidth, int windowHeight) {
    GameSettings currentSettings = CaptureCurrentSettings();
    const GameSettings originalSettings = currentSettings;
    const SettingsLayout layout = BuildSettingsLayout(windowWidth, windowHeight);
    Vector2 mousePosition(static_cast<float>(windowWidth / 2), static_cast<float>(windowHeight / 2));
    bool settingsOpen = true;
    bool draggingVolume = false;

    BeginBatchDraw();
    DrawSettingsScene(layout, currentSettings, mousePosition);
    FlushBatchDraw();

    while (settingsOpen) {
        ExMessage msg = getmessage(EX_MOUSE | EX_KEY);
        mousePosition = Vector2(static_cast<float>(msg.x), static_cast<float>(msg.y));

        if (msg.message == WM_MOUSEMOVE && draggingVolume) {
            UpdateVolumeFromMouse(layout.volumeTrack, msg.x, currentSettings);
        } else if (msg.message == WM_LBUTTONUP) {
            draggingVolume = false;
        } else if (msg.message == WM_KEYDOWN && msg.vkcode == VK_ESCAPE) {
            ApplySettings(originalSettings);
            settingsOpen = false;
        } else if (msg.message == WM_LBUTTONDOWN) {
            if (Contains(MakeRect(layout.volumeTrack.left - 12, layout.volumeTrack.top - 12,
                    layout.volumeTrack.right + 12, layout.volumeTrack.bottom + 12), msg.x, msg.y)) {
                draggingVolume = true;
                UpdateVolumeFromMouse(layout.volumeTrack, msg.x, currentSettings);
            } else {
                for (int i = 0; i < 3; ++i) {
                    if (Contains(layout.difficultyButtons[i], msg.x, msg.y)) {
                        currentSettings.difficulty = i;
                    }
                    if (Contains(layout.speedButtons[i], msg.x, msg.y)) {
                        currentSettings.snakeSpeed = i;
                    }
                }

                for (int i = 0; i < 2; ++i) {
                    if (Contains(layout.soundButtons[i], msg.x, msg.y)) {
                        currentSettings.soundOn = (i == 1);
                    }
                    if (Contains(layout.animationButtons[i], msg.x, msg.y)) {
                        currentSettings.animationsOn = (i == 1);
                    }
                    if (Contains(layout.antiAliasingButtons[i], msg.x, msg.y)) {
                        currentSettings.antiAliasingOn = (i == 1);
                    }
                    if (Contains(layout.displayButtons[i], msg.x, msg.y)) {
                        currentSettings.fullscreenOn = (i == 1);
                    }
                }

                if (Contains(layout.applyButton, msg.x, msg.y)) {
                    ApplySettings(currentSettings);
                    settingsOpen = false;
                } else if (Contains(layout.cancelButton, msg.x, msg.y)) {
                    ApplySettings(originalSettings);
                    settingsOpen = false;
                }
            }
        }

        if (settingsOpen) {
            DrawSettingsScene(layout, currentSettings, mousePosition);
            FlushBatchDraw();
        }
    }

    EndBatchDraw();
}
