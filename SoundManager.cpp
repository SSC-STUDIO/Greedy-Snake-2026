#include "SoundManager.h"
#include "GameConfig.h"
#include "Setting.h"
#include <tchar.h>
#include <mmsystem.h>
#include <graphics.h>
#pragma comment(lib, "winmm.lib")

void PlayBackgroundMusic() {
    mciSendString(_T("open ..\\Resource\\Greed-Snake-Start-Animation.mp3 alias Greed-Snake"), NULL, NULL, NULL); // Open music file
    mciSendString(_T("play Greed-Snake repeat"), NULL, NULL, NULL); // Play music
    SetVolume(GameConfig::DEFAULT_VOLUME);  // Set initial volume
}

void StopBackgroundMusic() {
    mciSendString(_T("stop Greed-Snake"), NULL, NULL, NULL); // Stop music
}

void PlayStartAnimation() {
    // Define frame file path and file extension
    const TCHAR* path = _T(".\\Resource\\Greed-Snake-Start-Animation-Frames\\"); // Frame file path
    const TCHAR* ext = _T(".bmp"); // File extension

    mciSendString(_T("open .\\Resource\\Greed-Snake-Start-Animation.mp3 alias Start-Animation"), NULL, NULL, NULL); // Open animation music
    mciSendString(_T("play Start-Animation"), NULL, NULL, NULL); // Play animation music
    Sleep(6000); // Wait 6 seconds

    // Declare IMAGE structure variable
    IMAGE FImg;    

    // Use loop to load and display each frame
    for (int i = 0; i <= GameConfig::NUM_FRAMES; i++) {
        TCHAR frameFileName[MAX_PATH];  // Ensure buffer is large enough to store full path
        _stprintf_s(frameFileName, MAX_PATH, _T("%sframe_%d%s"), path, i, ext); // Format frame filename

        // Load image
        loadimage(&FImg, frameFileName); // Load image

        IMAGE scaledG; // Scaled image
        scaledG.Resize(GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT); // Resize image to fit window
        StretchBlt(GetImageHDC(&scaledG), 0, 0, GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT,
            GetImageHDC(&FImg), 0, 0, FImg.getwidth(), FImg.getheight(), SRCCOPY); // Draw image
        // Draw image at (0,0) position in window
        putimage(0, 0, &scaledG);

        // Wait for specified delay time
        Sleep(GameConfig::FRAME_DELAY); // Wait for frame delay
    }
} 