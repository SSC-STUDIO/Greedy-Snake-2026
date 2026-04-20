#pragma once

#include <graphics.h>
#include <mutex>

class ResourceManager {
private:
    IMAGE backgroundImage;
    IMAGE scaledBackgroundImage;
    bool resourcesLoaded = false;
    int scaledWidth = 0;
    int scaledHeight = 0;
    bool scaledWithAntiAliasing = false;
    mutable std::mutex resourceMutex;
    
public:
    static ResourceManager& Instance();
    ~ResourceManager();
    
    // Resource loading
    bool LoadAllResources();
    void UnloadAllResources();
    
    // Graphics resources
    bool LoadBackgroundImage(LPCTSTR filePath);
    void ScaleBackgroundImage(int width, int height);
    void DrawBackground();
    
    // Audio resources
    void InitializeAudio();
    void CleanupAudio();
    void PlayBackgroundMusic();
    void StopBackgroundMusic();
    
    // UI resources
    void LoadButtons();
    
    // Status
    bool IsLoaded() const;
    
private:
    bool LoadGraphicsResources();
    bool LoadAudioResources();
    bool LoadUIResources();
    
    void CleanupGraphicsResources();
    void CleanupAudioResources();
    void CleanupUIResources();
};
