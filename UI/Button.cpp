#include "Button.h"
#include "../ModernCore/Vector2.h"
#include "../Utils/DrawHelpers.h"
#include "../Gameplay/GameConfig.h"
#include <mmsystem.h>
#include <algorithm>
#pragma comment(lib, "winmm.lib")

namespace {
void ConfigureStretchQuality(HDC targetDC) {
    SetStretchBltMode(targetDC, GameConfig::ANTIALIASING_ON ? HALFTONE : COLORONCOLOR);
    if (GameConfig::ANTIALIASING_ON) {
        SetBrushOrgEx(targetDC, 0, 0, nullptr);
    }
}
}

Button::Button() {}

void Button::Initial(LPCTSTR imageFilePath, const Vector2& position, const Vector2& size, LPCTSTR soundFilePath)
{
    IMAGE TempIcon;
    loadimage(&TempIcon, imageFilePath);
    const int iconWidth = (std::max)(1, static_cast<int>(size.x) - 12);
    const int iconHeight = (std::max)(1, static_cast<int>(size.y) - 12);
    icon.Resize(iconWidth, iconHeight);
    ConfigureStretchQuality(GetImageHDC(&icon));
    StretchBlt(GetImageHDC(&icon), 0, 0, iconWidth, iconHeight,
        GetImageHDC(&TempIcon), 0, 0, TempIcon.getwidth(), TempIcon.getheight(), SRCCOPY);
    minPosition = position;
    maxPosition = position + size;
    drawMod = DrawMod::Image;
    this->soundFilePath = soundFilePath;
}

void Button::Initial(LPCTSTR buttonText, const Vector2& minPosition, const Vector2& maxPosition, const COLORREF& color, LPCTSTR soundFilePath)
{
    text = buttonText;
    this->minPosition = minPosition;
    this->maxPosition = maxPosition;
    this->color = color;
    drawMod = DrawMod::Rect;
    this->soundFilePath = soundFilePath;
}

bool Button::IsOnButton(const Vector2& mousePosition) const
{
    return mousePosition.x > minPosition.x &&
        mousePosition.y > minPosition.y &&
        mousePosition.x < maxPosition.x &&
        mousePosition.y < maxPosition.y;
}

void Button::PlayClickSound() const
{
    if (soundFilePath && GameConfig::SOUND_ON) {
        PlaySound(soundFilePath, NULL, SND_FILENAME | SND_ASYNC);
    }
}

void Button::DrawButton(const Vector2& mousePosition) const
{
    bool isHovered = IsOnButton(mousePosition);

    if (drawMod == DrawMod::Image)
    {
        const int left = static_cast<int>(minPosition.x);
        const int top = static_cast<int>(minPosition.y);
        const int right = static_cast<int>(maxPosition.x);
        const int bottom = static_cast<int>(maxPosition.y);
        const int iconX = static_cast<int>(minPosition.x) + (static_cast<int>(maxPosition.x - minPosition.x) - icon.getwidth()) / 2;
        const int iconY = static_cast<int>(minPosition.y) + (static_cast<int>(maxPosition.y - minPosition.y) - icon.getheight()) / 2;

        setfillcolor(isHovered ? RGB(27, 118, 176) : RGB(7, 15, 25));
        solidroundrect(left + 2, top + 4, right + 2, bottom + 4, 16, 16);
        setfillcolor(isHovered ? RGB(242, 248, 255) : RGB(225, 234, 246));
        solidroundrect(left, top, right, bottom, 16, 16);
        setlinecolor(isHovered ? RGB(120, 206, 255) : RGB(130, 150, 179));
        roundrect(left, top, right, bottom, 16, 16);
        putimage(iconX, iconY, &icon);
    }
    else
    {
        const int left = static_cast<int>(minPosition.x);
        const int top = static_cast<int>(minPosition.y);
        const int right = static_cast<int>(maxPosition.x);
        const int bottom = static_cast<int>(maxPosition.y);
        const COLORREF shadowColor = isHovered ? RGB(22, 76, 118) : RGB(6, 15, 27);
        const COLORREF buttonColor = isHovered ? RGB(66, 173, 234) : color;

        setfillcolor(shadowColor);
        solidroundrect(left + 3, top + 5, right + 3, bottom + 5, 16, 16);
        setfillcolor(buttonColor);
        solidroundrect(left, top, right, bottom, 16, 16);
        setlinecolor(isHovered ? RGB(194, 239, 255) : RGB(117, 194, 238));
        roundrect(left, top, right, bottom, 16, 16);
        setfillcolor(RGB(255, 255, 255));
        solidroundrect(left + 18, top + 10, left + 82, top + 18, 4, 4);

        settextstyle(24, 0, _T("Bahnschrift"));
        settextcolor(RGB(246, 250, 255));
        const int buttonWidth = static_cast<int>(maxPosition.x - minPosition.x);
        const int buttonHeight = static_cast<int>(maxPosition.y - minPosition.y);
        const int textX = static_cast<int>(minPosition.x) + (buttonWidth - textwidth(text)) / 2;
        const int textY = static_cast<int>(minPosition.y) + (buttonHeight - textheight(text)) / 2;
        outtextxy(textX, textY, text);
    }
}

Vector2 Button::GetSize() const
{
    return maxPosition - minPosition;
} 
