#include "ResourceManager.h"

#include "../UI/UI.h"
#include "../Utils/PathSecurity.h"
#include <tchar.h>
#include <limits.h>

namespace {

const LPCTSTR kDefaultBackgroundPath = _T(".\\Resource\\Greed-Snake-BG.png");

// 允许的资源文件扩展名
const std::vector<std::wstring> kAllowedImageExtensions = { L".png", L".jpg", L".jpeg", L".bmp" };
const std::vector<std::wstring> kAllowedAudioExtensions = { L".wav", L".mp3", L".ogg" };

void DrawMissingBackgroundFallback() {
    setfillcolor(RGB(20, 20, 20));
    solidrectangle(0, 0, getwidth(), getheight());

    settextstyle(24, 0, _T("Arial"));
    settextcolor(RGB(200, 200, 200));
    outtextxy(20, 20, _T("Background resource missing: Resource\\Greed-Snake-BG.png"));
}

/**
 * @brief 验证资源路径安全性
 * @param filePath 文件路径
 * @param allowedExtensions 允许的扩展名列表
 * @return true 如果路径安全
 */
bool ValidateResourcePath(LPCTSTR filePath, const std::vector<std::wstring>& allowedExtensions) {
    if (!filePath || filePath[0] == _T('\0')) {
        OutputDebugStringA("ResourceManager: Empty file path\n");
        return false;
    }

    std::wstring path(filePath);

    // 使用PathSecurity验证路径遍历
    if (!Security::PathValidator::ValidatePathTraversal(path)) {
        OutputDebugStringA("ResourceManager: Path traversal detected\n");
        return false;
    }

    // 验证扩展名
    if (!Security::PathValidator::ValidateFileExtension(path, allowedExtensions)) {
        OutputDebugStringA("ResourceManager: Invalid file extension\n");
        return false;
    }

    // 检查敏感路径
    if (Security::PathValidator::IsSensitivePath(path)) {
        OutputDebugStringA("ResourceManager: Sensitive path access denied\n");
        return false;
    }

    return true;
}

/**
 * @brief 验证图像尺寸是否合法
 * @param width 宽度
 * @param height 高度
 * @return true 如果尺寸合法
 */
bool ValidateImageDimensions(int width, int height) {
    const int MAX_IMAGE_DIMENSION = 8192; // 最大支持8K分辨率
    const int MIN_IMAGE_DIMENSION = 1;

    if (width < MIN_IMAGE_DIMENSION || height < MIN_IMAGE_DIMENSION) {
        return false;
    }
    if (width > MAX_IMAGE_DIMENSION || height > MAX_IMAGE_DIMENSION) {
        OutputDebugStringA("ResourceManager: Image dimensions too large\n");
        return false;
    }
    // 检查图像尺寸是否会导致整数溢出
    if (static_cast<long long>(width) * height > INT_MAX / 4) {
        OutputDebugStringA("ResourceManager: Image size would cause overflow\n");
        return false;
    }
    return true;
}

} // anonymous namespace

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
    
    try {
        const bool graphicsLoaded = LoadGraphicsResources();
        const bool audioLoaded = LoadAudioResources();
        const bool uiLoaded = LoadUIResources();

        std::lock_guard<std::mutex> lock(resourceMutex);
        resourcesLoaded = graphicsLoaded && audioLoaded && uiLoaded;
        return resourcesLoaded;
    } catch (const std::exception& e) {
        OutputDebugStringA("ResourceManager::LoadAllResources: Exception occurred\n");
        return false;
    }
}

void ResourceManager::UnloadAllResources() {
    CleanupUIResources();
    CleanupAudioResources();
    CleanupGraphicsResources();

    std::lock_guard<std::mutex> lock(resourceMutex);
    resourcesLoaded = false;
}

bool ResourceManager::LoadBackgroundImage(LPCTSTR filePath) {
    // 输入验证
    if (!filePath || filePath[0] == _T('\0')) {
        OutputDebugStringA("ResourceManager::LoadBackgroundImage: Invalid file path\n");
        return false;
    }

    // 路径安全验证
    if (!ValidateResourcePath(filePath, kAllowedImageExtensions)) {
        return false;
    }

    // 验证文件存在且可访问
    if (!Security::IsFileAccessible(filePath)) {
        OutputDebugStringA("ResourceManager::LoadBackgroundImage: File not accessible\n");
        return false;
    }

    std::lock_guard<std::mutex> lock(resourceMutex);

    // 限制图像加载尝试次数，防止资源耗尽攻击
    static int loadAttempts = 0;
    if (loadAttempts > 100) {
        OutputDebugStringA("ResourceManager::LoadBackgroundImage: Too many load attempts\n");
        return false;
    }
    loadAttempts++;

    IMAGE loadedImage;
    try {
        loadimage(&loadedImage, filePath);
    } catch (...) {
        OutputDebugStringA("ResourceManager::LoadBackgroundImage: Exception during image load\n");
        return false;
    }
    
    // 验证加载的图像
    if (!ValidateImageDimensions(loadedImage.getwidth(), loadedImage.getheight())) {
        OutputDebugStringA("ResourceManager::LoadBackgroundImage: Invalid image dimensions\n");
        return false;
    }

    backgroundImage = loadedImage;
    scaledBackgroundImage = IMAGE();
    scaledWidth = 0;
    scaledHeight = 0;
    
    // 重置加载计数器
    loadAttempts = 0;
    
    return true;
}

void ResourceManager::ScaleBackgroundImage(int width, int height) {
    // 输入验证
    if (width <= 0 || height <= 0) {
        OutputDebugStringA("ResourceManager::ScaleBackgroundImage: Invalid dimensions\n");
        return;
    }

    // 验证缩放尺寸
    if (!ValidateImageDimensions(width, height)) {
        OutputDebugStringA("ResourceManager::ScaleBackgroundImage: Dimensions too large\n");
        return;
    }

    std::lock_guard<std::mutex> lock(resourceMutex);

    if (backgroundImage.getwidth() <= 0 || backgroundImage.getheight() <= 0) {
        return;
    }

    if (scaledBackgroundImage.getwidth() > 0 &&
        scaledBackgroundImage.getheight() > 0 &&
        scaledWidth == width &&
        scaledHeight == height) {
        return;
    }

    try {
        scaledBackgroundImage.Resize(width, height);
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
    } catch (...) {
        OutputDebugStringA("ResourceManager::ScaleBackgroundImage: Exception during scaling\n");
        scaledBackgroundImage = IMAGE();
        scaledWidth = 0;
        scaledHeight = 0;
    }
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
    // 音频初始化前进行资源限制检查
    static bool audioInitialized = false;
    if (audioInitialized) {
        return; // 防止重复初始化
    }
    audioInitialized = true;
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
    
    // 安全地释放图像资源
    backgroundImage = IMAGE();
    scaledBackgroundImage = IMAGE();
    scaledWidth = 0;
    scaledHeight = 0;
}

void ResourceManager::CleanupAudioResources() {
    CleanupAudio();
}

void ResourceManager::CleanupUIResources() {
    // UI资源清理
}

/**
 * @brief 安全地加载外部资源文件
 * @param filePath 文件路径
 * @param resourceType 资源类型（"image", "audio"）
 * @return true 如果加载成功
 */
bool ResourceManager::LoadExternalResource(LPCTSTR filePath, LPCTSTR resourceType) {
    if (!filePath || !resourceType) {
        return false;
    }

    std::wstring type(resourceType);
    std::vector<std::wstring> allowedExts;
    
    if (type == L"image") {
        allowedExts = kAllowedImageExtensions;
    } else if (type == L"audio") {
        allowedExts = kAllowedAudioExtensions;
    } else {
        OutputDebugStringA("ResourceManager::LoadExternalResource: Unknown resource type\n");
        return false;
    }

    // 验证路径安全
    if (!ValidateResourcePath(filePath, allowedExts)) {
        return false;
    }

    // 验证文件存在
    if (!Security::IsFileAccessible(filePath)) {
        OutputDebugStringA("ResourceManager::LoadExternalResource: File not accessible\n");
        return false;
    }

    // 这里可以添加实际的资源加载逻辑
    return true;
}
