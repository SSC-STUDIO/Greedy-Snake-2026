#include "ResourceManager.h"

#include "../UI/UI.h"
#include "../Gameplay/GameConfig.h"
#include <tchar.h>

namespace {
const LPCTSTR kDefaultBackgroundPath = _T(".\\Resource\\Greed-Snake-BG.png");

void ConfigureStretchQuality(HDC targetDC) {
    SetStretchBltMode(targetDC, GameConfig::ANTIALIASING_ON ? HALFTONE : COLORONCOLOR);
    if (GameConfig::ANTIALIASING_ON) {
        SetBrushOrgEx(targetDC, 0, 0, nullptr);
    }
}

void DrawMissingBackgroundFallback() {
    setfillcolor(RGB(20, 20, 20));
    solidrectangle(0, 0, getwidth(), getheight());

    settextstyle(24, 0, _T("Arial"));
    settextcolor(RGB(200, 200, 200));
    outtextxy(20, 20, _T("背景资源缺失：Resource\\Greed-Snake-BG.png"));
}
}

ResourceManager& ResourceManager::Instance() {
    static ResourceManager instance{};
    return instance;
}

ResourceManager::~ResourceManager() {
    UnloadAllResources();
}

bool ResourceManager::LoadAllResources() {
    {
        std::lock_guard<std::mutex> lock(resourceMutex);
        if (resourcesLoaded) {
            return true;
        }
    }
    const bool graphicsLoaded = LoadGraphicsResources();
    const bool audioLoaded = LoadAudioResources();
    const bool uiLoaded = LoadUIResources();

    std::lock_guard<std::mutex> lock(resourceMutex);
    resourcesLoaded = graphicsLoaded && audioLoaded && uiLoaded;
    return resourcesLoaded;
}

void ResourceManager::UnloadAllResources() {
    CleanupUIResources();
    CleanupAudioResources();
    CleanupGraphicsResources();

    std::lock_guard<std::mutex> lock(resourceMutex);
    resourcesLoaded = false;
}

bool ResourceManager::LoadBackgroundImage(LPCTSTR filePath) {
    std::lock_guard<std::mutex> lock(resourceMutex);

    if (filePath == NULL || filePath[0] == _T('\0')) {
        return false;
    }

    IMAGE loadedImage;
    loadimage(&loadedImage, filePath);
    if (loadedImage.getwidth() <= 0 || loadedImage.getheight() <= 0) {
        return false;
    }

    backgroundImage = loadedImage;
    scaledBackgroundImage = IMAGE();
    scaledWidth = 0;
    scaledHeight = 0;
    return true;
}

void ResourceManager::ScaleBackgroundImage(int width, int height) {
    std::lock_guard<std::mutex> lock(resourceMutex);

    if (width <= 0 || height <= 0) {
        return;
    }

    if (backgroundImage.getwidth() <= 0 || backgroundImage.getheight() <= 0) {
        return;
    }

    if (scaledBackgroundImage.getwidth() > 0 &&
        scaledBackgroundImage.getheight() > 0 &&
        scaledWidth == width &&
        scaledHeight == height &&
        scaledWithAntiAliasing == GameConfig::ANTIALIASING_ON) {
        return;
    }

    scaledBackgroundImage.Resize(width, height);
    ConfigureStretchQuality(GetImageHDC(&scaledBackgroundImage));
    StretchBlt(
        GetImageHDC(&scaledBackgroundImage),
        0,
        0,
        width,
        height,
        GetImageHDC(&backgroundImage),
        0,
        0,
        backgroundImage.getwidth(),
        backgroundImage.getheight(),
        SRCCOPY
    );
    scaledWidth = width;
    scaledHeight = height;
    scaledWithAntiAliasing = GameConfig::ANTIALIASING_ON;
}

void ResourceManager::DrawBackground() {
    std::lock_guard<std::mutex> lock(resourceMutex);

    if (scaledBackgroundImage.getwidth() > 0 && scaledBackgroundImage.getheight() > 0) {
        putimage(0, 0, &scaledBackgroundImage);
        return;
    }

    if (backgroundImage.getwidth() > 0 && backgroundImage.getheight() > 0) {
        putimage(0, 0, &backgroundImage);
        return;
    }

    DrawMissingBackgroundFallback();
}

void ResourceManager::InitializeAudio() {
}

void ResourceManager::CleanupAudio() {
    StopBackgroundMusic();
    ::CleanupAudioResources();
}

void ResourceManager::PlayBackgroundMusic() {
    ::PlayBackgroundMusic();
}

void ResourceManager::StopBackgroundMusic() {
    ::StopBackgroundMusic();
}

void ResourceManager::LoadButtons() {
    ::LoadButton();
}

bool ResourceManager::IsLoaded() const {
    std::lock_guard<std::mutex> lock(resourceMutex);
    return resourcesLoaded;
}

bool ResourceManager::LoadGraphicsResources() {
    return LoadBackgroundImage(kDefaultBackgroundPath);
}

bool ResourceManager::LoadAudioResources() {
    InitializeAudio();
    return true;
}

bool ResourceManager::LoadUIResources() {
    LoadButtons();
    return true;
}

void ResourceManager::CleanupGraphicsResources() {
    std::lock_guard<std::mutex> lock(resourceMutex);
    backgroundImage = IMAGE();
    scaledBackgroundImage = IMAGE();
    scaledWidth = 0;
    scaledHeight = 0;
    scaledWithAntiAliasing = false;
}

void ResourceManager::CleanupAudioResources() {
    CleanupAudio();
}

void ResourceManager::CleanupUIResources() {
}
