#pragma once

#include <graphics.h>
#include <gdiplus.h>
#include <algorithm>
#include "../Gameplay/GameConfig.h"

#pragma comment(lib, "gdiplus.lib")

namespace DrawHelpersInternal {

template <typename T>
inline int ToInt(T value) {
    return static_cast<int>(value);
}

class GdiplusRuntime {
public:
    static bool EnsureReady() {
        static GdiplusRuntime instance;
        return instance.ready_;
    }

private:
    GdiplusRuntime() {
        Gdiplus::GdiplusStartupInput startupInput;
        ready_ = Gdiplus::GdiplusStartup(&token_, &startupInput, nullptr) == Gdiplus::Ok;
    }

    ~GdiplusRuntime() {
        if (ready_) {
            Gdiplus::GdiplusShutdown(token_);
        }
    }

    ULONG_PTR token_ = 0;
    bool ready_ = false;
};

inline bool UseAntialiasing() {
    return GameConfig::ANTIALIASING_ON && GdiplusRuntime::EnsureReady();
}

inline Gdiplus::Color ToGpColor(COLORREF color) {
    return Gdiplus::Color(255, GetRValue(color), GetGValue(color), GetBValue(color));
}

inline float GetPenThickness() {
    LINESTYLE lineStyle{};
    getlinestyle(&lineStyle);
    return (std::max)(1.0f, static_cast<float>(lineStyle.thickness));
}

inline void ConfigureGraphics(Gdiplus::Graphics& graphics) {
    graphics.SetSmoothingMode(Gdiplus::SmoothingModeAntiAlias);
    graphics.SetPixelOffsetMode(Gdiplus::PixelOffsetModeHighQuality);
    graphics.SetCompositingQuality(Gdiplus::CompositingQualityHighQuality);
    graphics.SetInterpolationMode(Gdiplus::InterpolationModeHighQualityBicubic);
}

inline void BuildRoundedRectPath(Gdiplus::GraphicsPath& path, float left, float top, float right, float bottom, float xRadius, float yRadius) {
    const float safeXRadius = (std::max)(0.0f, (std::min)((right - left) / 2.0f, xRadius));
    const float safeYRadius = (std::max)(0.0f, (std::min)((bottom - top) / 2.0f, yRadius));
    const float arcWidth = safeXRadius * 2.0f;
    const float arcHeight = safeYRadius * 2.0f;

    if (arcWidth <= 0.0f || arcHeight <= 0.0f) {
        path.AddRectangle(Gdiplus::RectF(left, top, right - left, bottom - top));
        path.CloseFigure();
        return;
    }

    path.AddArc(left, top, arcWidth, arcHeight, 180.0f, 90.0f);
    path.AddArc(right - arcWidth, top, arcWidth, arcHeight, 270.0f, 90.0f);
    path.AddArc(right - arcWidth, bottom - arcHeight, arcWidth, arcHeight, 0.0f, 90.0f);
    path.AddArc(left, bottom - arcHeight, arcWidth, arcHeight, 90.0f, 90.0f);
    path.CloseFigure();
}

inline void DrawEllipseStroke(int x, int y, int r) {
    if (!UseAntialiasing()) {
        ::circle(x, y, r);
        return;
    }

    Gdiplus::Graphics graphics(GetImageHDC());
    ConfigureGraphics(graphics);
    Gdiplus::Pen pen(ToGpColor(getlinecolor()), GetPenThickness());
    graphics.DrawEllipse(&pen, static_cast<Gdiplus::REAL>(x - r), static_cast<Gdiplus::REAL>(y - r), static_cast<Gdiplus::REAL>(r * 2), static_cast<Gdiplus::REAL>(r * 2));
}

inline void DrawEllipseFill(int x, int y, int r) {
    if (!UseAntialiasing()) {
        ::solidcircle(x, y, r);
        return;
    }

    Gdiplus::Graphics graphics(GetImageHDC());
    ConfigureGraphics(graphics);
    Gdiplus::SolidBrush brush(ToGpColor(getfillcolor()));
    graphics.FillEllipse(&brush, static_cast<Gdiplus::REAL>(x - r), static_cast<Gdiplus::REAL>(y - r), static_cast<Gdiplus::REAL>(r * 2), static_cast<Gdiplus::REAL>(r * 2));
}

inline void DrawLineStroke(int x1, int y1, int x2, int y2) {
    if (!UseAntialiasing()) {
        ::line(x1, y1, x2, y2);
        return;
    }

    Gdiplus::Graphics graphics(GetImageHDC());
    ConfigureGraphics(graphics);
    Gdiplus::Pen pen(ToGpColor(getlinecolor()), GetPenThickness());
    graphics.DrawLine(&pen, static_cast<Gdiplus::REAL>(x1), static_cast<Gdiplus::REAL>(y1), static_cast<Gdiplus::REAL>(x2), static_cast<Gdiplus::REAL>(y2));
}

inline void DrawRectangleStroke(int left, int top, int right, int bottom) {
    if (!UseAntialiasing()) {
        ::rectangle(left, top, right, bottom);
        return;
    }

    Gdiplus::Graphics graphics(GetImageHDC());
    ConfigureGraphics(graphics);
    Gdiplus::Pen pen(ToGpColor(getlinecolor()), GetPenThickness());
    graphics.DrawRectangle(&pen, static_cast<Gdiplus::REAL>(left), static_cast<Gdiplus::REAL>(top), static_cast<Gdiplus::REAL>(right - left), static_cast<Gdiplus::REAL>(bottom - top));
}

inline void DrawRectangleFill(int left, int top, int right, int bottom) {
    if (!UseAntialiasing()) {
        ::solidrectangle(left, top, right, bottom);
        return;
    }

    Gdiplus::Graphics graphics(GetImageHDC());
    ConfigureGraphics(graphics);
    Gdiplus::SolidBrush brush(ToGpColor(getfillcolor()));
    graphics.FillRectangle(&brush, static_cast<Gdiplus::REAL>(left), static_cast<Gdiplus::REAL>(top), static_cast<Gdiplus::REAL>(right - left), static_cast<Gdiplus::REAL>(bottom - top));
}

inline void DrawRoundedRectangleStroke(int left, int top, int right, int bottom, int ellipseWidth, int ellipseHeight) {
    if (!UseAntialiasing()) {
        ::roundrect(left, top, right, bottom, ellipseWidth, ellipseHeight);
        return;
    }

    Gdiplus::Graphics graphics(GetImageHDC());
    ConfigureGraphics(graphics);
    Gdiplus::GraphicsPath path(Gdiplus::FillModeAlternate);
    BuildRoundedRectPath(
        path,
        static_cast<float>(left),
        static_cast<float>(top),
        static_cast<float>(right),
        static_cast<float>(bottom),
        static_cast<float>(ellipseWidth) / 2.0f,
        static_cast<float>(ellipseHeight) / 2.0f);
    Gdiplus::Pen pen(ToGpColor(getlinecolor()), GetPenThickness());
    graphics.DrawPath(&pen, &path);
}

inline void DrawRoundedRectangleFill(int left, int top, int right, int bottom, int ellipseWidth, int ellipseHeight) {
    if (!UseAntialiasing()) {
        ::solidroundrect(left, top, right, bottom, ellipseWidth, ellipseHeight);
        return;
    }

    Gdiplus::Graphics graphics(GetImageHDC());
    ConfigureGraphics(graphics);
    Gdiplus::GraphicsPath path(Gdiplus::FillModeAlternate);
    BuildRoundedRectPath(
        path,
        static_cast<float>(left),
        static_cast<float>(top),
        static_cast<float>(right),
        static_cast<float>(bottom),
        static_cast<float>(ellipseWidth) / 2.0f,
        static_cast<float>(ellipseHeight) / 2.0f);
    Gdiplus::SolidBrush brush(ToGpColor(getfillcolor()));
    graphics.FillPath(&brush, &path);
}

inline void DrawTextAt(int x, int y, LPCTSTR text) {
    ::outtextxy(x, y, text);
}

template <typename TX, typename TY, typename TR>
inline void drawhelpers_circle(TX x, TY y, TR r) {
    DrawEllipseStroke(ToInt(x), ToInt(y), ToInt(r));
}

template <typename TX, typename TY, typename TR>
inline void drawhelpers_solidcircle(TX x, TY y, TR r) {
    DrawEllipseFill(ToInt(x), ToInt(y), ToInt(r));
}

template <typename TX, typename TY, typename TR>
inline void drawhelpers_fillcircle(TX x, TY y, TR r) {
    DrawEllipseFill(ToInt(x), ToInt(y), ToInt(r));
}

template <typename TX1, typename TY1, typename TX2, typename TY2>
inline void drawhelpers_line(TX1 x1, TY1 y1, TX2 x2, TY2 y2) {
    DrawLineStroke(ToInt(x1), ToInt(y1), ToInt(x2), ToInt(y2));
}

template <typename TL, typename TT, typename TR, typename TB>
inline void drawhelpers_rectangle(TL left, TT top, TR right, TB bottom) {
    DrawRectangleStroke(ToInt(left), ToInt(top), ToInt(right), ToInt(bottom));
}

template <typename TL, typename TT, typename TR, typename TB, typename TEW, typename TEH>
inline void drawhelpers_roundrect(TL left, TT top, TR right, TB bottom, TEW ellipseWidth, TEH ellipseHeight) {
    DrawRoundedRectangleStroke(ToInt(left), ToInt(top), ToInt(right), ToInt(bottom), ToInt(ellipseWidth), ToInt(ellipseHeight));
}

template <typename TL, typename TT, typename TR, typename TB>
inline void drawhelpers_solidrectangle(TL left, TT top, TR right, TB bottom) {
    DrawRectangleFill(ToInt(left), ToInt(top), ToInt(right), ToInt(bottom));
}

template <typename TL, typename TT, typename TR, typename TB, typename TEW, typename TEH>
inline void drawhelpers_solidroundrect(TL left, TT top, TR right, TB bottom, TEW ellipseWidth, TEH ellipseHeight) {
    DrawRoundedRectangleFill(ToInt(left), ToInt(top), ToInt(right), ToInt(bottom), ToInt(ellipseWidth), ToInt(ellipseHeight));
}

template <typename TX, typename TY>
inline void drawhelpers_outtextxy(TX x, TY y, LPCTSTR text) {
    DrawTextAt(ToInt(x), ToInt(y), text);
}

}

#define circle(...) DrawHelpersInternal::drawhelpers_circle(__VA_ARGS__)
#define solidcircle(...) DrawHelpersInternal::drawhelpers_solidcircle(__VA_ARGS__)
#define fillcircle(...) DrawHelpersInternal::drawhelpers_fillcircle(__VA_ARGS__)
#define line(...) DrawHelpersInternal::drawhelpers_line(__VA_ARGS__)
#define rectangle(...) DrawHelpersInternal::drawhelpers_rectangle(__VA_ARGS__)
#define roundrect(...) DrawHelpersInternal::drawhelpers_roundrect(__VA_ARGS__)
#define solidrectangle(...) DrawHelpersInternal::drawhelpers_solidrectangle(__VA_ARGS__)
#define solidroundrect(...) DrawHelpersInternal::drawhelpers_solidroundrect(__VA_ARGS__)
#define outtextxy(...) DrawHelpersInternal::drawhelpers_outtextxy(__VA_ARGS__)
