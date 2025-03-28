#include "Button.h"
#include "Vector2.h"
#include <mmsystem.h>
#pragma comment(lib, "winmm.lib")

Button::Button() {}

void Button::Initial(LPCTSTR imageFilePath, const Vector2& position, const Vector2& size, LPCTSTR soundFilePath)
{
    IMAGE TempIcon;
    loadimage(&TempIcon, imageFilePath);
    icon.Resize(size.x, size.y);
    StretchBlt(GetImageHDC(&icon), 0, 0, size.x, size.y,
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
    bool isOn = mousePosition.x > minPosition.x &&
        mousePosition.y > minPosition.y &&
        mousePosition.x < maxPosition.x &&
        mousePosition.y < maxPosition.y;
    if (isOn && soundFilePath) {
        PlaySound(soundFilePath, NULL, SND_FILENAME | SND_ASYNC);
    }
    return isOn;
}

void Button::DrawButton(const Vector2& mousePosition) const
{
    bool isHovered = IsOnButton(mousePosition);

    if (drawMod == DrawMod::Image)
    {
        putimage(minPosition.x, minPosition.y, &icon);
    }
    else
    {
        // Draw button shadow
        setfillcolor(RGB(0, 0, 0)); // Shadow color
        solidroundrect(minPosition.x + 5, minPosition.y + 5, maxPosition.x + 5, maxPosition.y + 5, 10, 10);

        // Adjust color if hovered
        COLORREF buttonColor = isHovered ? RGB(GetRValue(color) * 0.8, GetGValue(color) * 0.8, GetBValue(color) * 0.8) : color;

        // Draw button text
        setfillcolor(buttonColor);
        solidroundrect(minPosition.x, minPosition.y, maxPosition.x, maxPosition.y, 10, 10);

        settextstyle(24, 0, _T("Arial"));
        settextcolor(WHITE);
        outtextxy(minPosition.x + textwidth(text) / 2, minPosition.y + textheight(text) / 2, text);
    }
}

Vector2 Button::GetSize() const
{
    return maxPosition - minPosition;
} 