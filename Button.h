#pragma once
#include "Snake.h"
#include <graphics.h>

enum class DrawMod
{
	Image,
	Rect
};

class Button
{
public:
	Button();

	void Initial(LPCTSTR imageFilePath, const Vector2& position, const Vector2& size, LPCTSTR soundFilePath = nullptr);
	void Initial(LPCTSTR buttonText, const Vector2& minPosition, const Vector2& maxPosition, const COLORREF& color, LPCTSTR soundFilePath = nullptr);
	bool IsOnButton(const Vector2& mousePosition) const;
	void DrawButton(const Vector2& mousePosition) const;
	Vector2 GetSize() const;

private:
	Vector2 minPosition;
	Vector2 maxPosition;
	COLORREF color;
	IMAGE icon;
	LPCTSTR text;
	DrawMod drawMod;
	LPCTSTR soundFilePath;
};