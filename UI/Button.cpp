#include "Button.h"
#include "..\Core\Vector2.h"
#include "..\Utils\DrawHelpers.h"
#include <mmsystem.h>
#pragma comment(lib, "winmm.lib")

Button::Button() {}

void Button::Initial(LPCTSTR imageFilePath, const Vector2& position, const Vector2& size, LPCTSTR soundFilePath)
{
    IMAGE TempIcon;
    loadimage(&TempIcon, imageFilePath);
    icon.Resize(static_cast<int>(size.x), static_cast<int>(size.y));
    StretchBlt(GetImageHDC(&icon), 0, 0, static_cast<int>(size.x), static_cast<int>(size.y),
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
        putimage(static_cast<int>(minPosition.x), static_cast<int>(minPosition.y), &icon);
    }
    else
    {
        // Draw button shadow
        setfillcolor(RGB(0, 0, 0)); // Shadow color
        solidroundrect(minPosition.x + 5.0f, minPosition.y + 5.0f, maxPosition.x + 5.0f, maxPosition.y + 5.0f, 10.0f, 10.0f);

        // Adjust color if hovered
        COLORREF buttonColor = isHovered ? RGB(GetRValue(color) * 0.8, GetGValue(color) * 0.8, GetBValue(color) * 0.8) : color;

        // Draw button text
        setfillcolor(buttonColor);
        solidroundrect(minPosition.x, minPosition.y, maxPosition.x, maxPosition.y, 10.0f, 10.0f);

        settextstyle(24, 0, _T("Arial"));
        settextcolor(WHITE);
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
