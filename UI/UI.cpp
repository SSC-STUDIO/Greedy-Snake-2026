#include "UI.h"
#include <tchar.h>
#include <conio.h>
#include <mmsystem.h>
#include "Setting.h"
#pragma comment(lib, "winmm.lib")

// Global button list
std::vector<Button> buttonList;

// Load button resources for the menu
void LoadButton()
{
    const int buttonWidth = 200; // Button width
    const int buttonHeight = 50; // Button height
    int buttonY = GameConfig::WINDOW_HEIGHT * 0.7 + 10; // Button Y coordinate
    buttonList.resize(4); // Adjust button list size
    buttonList[StartGame].Initial(_T("Start Game"), Vector2(getwidth() / 2 - buttonWidth / 2, buttonY), Vector2(getwidth() / 2 + buttonWidth / 2, buttonY + buttonHeight), RGB(50, 150, 50), _T(".\\Resource\\SoundEffects\\Button-Click.wav")); // Initialize start game button
    buttonList[Setting].Initial(_T("./Resource/Setting.png"), Vector2(120, 10), Vector2(GameConfig::MENU_ICON_SIZE, GameConfig::MENU_ICON_SIZE), _T(".\\Resource\\SoundEffects\\Button-Click.wav")); // Initialize settings button
    buttonList[About].Initial(_T("./Resource/About.png"), Vector2(170, 10), Vector2(GameConfig::MENU_ICON_SIZE, GameConfig::MENU_ICON_SIZE), _T(".\\Resource\\SoundEffects\\Button-Click.wav")); // Initialize about button
    buttonList[Exit].Initial(_T("./Resource/Exit.png"), Vector2(220, 10), Vector2(GameConfig::MENU_ICON_SIZE, GameConfig::MENU_ICON_SIZE), _T(".\\Resource\\SoundEffects\\Button-Click.wav")); // Initialize exit button
}

// Draw the main menu interface
void DrawMenu() {
    ExMessage m; // Message
    peekmessage(&m, EX_MOUSE);
    Vector2 mousePos = Vector2(m.x, m.y); // Mouse position

    // Draw title text
    settextstyle(48, 0, _T("Arial"));
    settextcolor(RGB(255, 255, 255));

    // Draw all buttons
    for (int i = 0; i < ButtonType::Num; ++i) {
        buttonList[i].DrawButton(mousePos); // Draw button
    }
}

// Display "About" information screen
void ShowAbout() {
    // Draw about dialog
    setfillcolor(RGB(30, 30, 30));
    solidrectangle(0, 0, GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT);

    settextstyle(32, 0, _T("Arial"));
    settextcolor(WHITE);
    outtextxy(50, 50, _T("About Greedy Snake"));

    settextstyle(20, 0, _T("Arial"));
    outtextxy(50, 120, _T("Version: 1.0"));
    outtextxy(50, 150, _T("Author: Chen Runsen"));
    outtextxy(50, 180, _T("Email: chenrunsen@gmail.com"));
    outtextxy(50, 210, _T("GitHub: github.com/chenrunsen/Greed-Snake-Remake"));
    outtextxy(50, 250, _T("Controls:"));
    outtextxy(50, 280, _T("- Arrow keys or mouse to control the snake"));
    outtextxy(50, 310, _T("- Hold left mouse button to accelerate"));
    outtextxy(50, 340, _T("- ESC to pause game"));

    // Add a Back button instead of waiting for any key
    int aboutButtonWidth = 150;
    int aboutButtonHeight = 50;
    int backButtonX = GameConfig::WINDOW_WIDTH / 2 - aboutButtonWidth / 2;
    int backButtonY = GameConfig::WINDOW_HEIGHT - 100;
    
    setfillcolor(RGB(80, 80, 150));
    solidroundrect(backButtonX, backButtonY, backButtonX + aboutButtonWidth, backButtonY + aboutButtonHeight, 10, 10);
    
    settextstyle(28, 0, _T("Arial"));
    settextcolor(WHITE);
    outtextxy(backButtonX + aboutButtonWidth / 2 - textwidth(_T("Back")) / 2, backButtonY + 10, _T("Back"));

    FlushBatchDraw();
    
    // Wait for button click instead of any key
    bool aboutOpen = true;
    while (aboutOpen) {
        ExMessage msg = getmessage(EX_MOUSE);
        if (msg.message == WM_LBUTTONDOWN) {
            if (msg.x >= backButtonX && msg.x <= backButtonX + aboutButtonWidth &&
                msg.y >= backButtonY && msg.y <= backButtonY + aboutButtonHeight) {
                aboutOpen = false;
            }
        }
    }
}

// Display game main menu
int ShowGameMenu() {
    // Load buttons (if needed)
    if (buttonList.empty()) {
        LoadButton();
    }

    // Set menu text style
    settextstyle(32, 0, _T("Arial"));
    settextcolor(RGB(255, 255, 255));
    setbkmode(TRANSPARENT);

    // Display main menu
    DrawMenu();

    // Wait for user to select menu item
    ExMessage m;
    while (true) {
        m = getmessage(EX_MOUSE);
        Vector2 mousePos(m.x, m.y);
        
        if (m.message == WM_LBUTTONDOWN) {
            if (buttonList[StartGame].IsOnButton(mousePos)) {
                return StartGame;
            }
            else if (buttonList[Setting].IsOnButton(mousePos)) {
                return Setting;
            }
            else if (buttonList[About].IsOnButton(mousePos)) {
                return About;
            }
            else if (buttonList[Exit].IsOnButton(mousePos)) {
                return Exit;
            }
        }
        
        // Refresh menu drawing
        DrawMenu();
        Sleep(10);
    }

    return -1;  // No option selected
}

// ---------- Sound & Animation Functions ----------

void PlayBackgroundMusic() {
    // Check if music is already playing
    TCHAR statusBuff[256] = {0};
    if (mciSendString(_T("status Greed-Snake mode"), statusBuff, 256, NULL) == 0) {
        // If already open, close it first
        mciSendString(_T("close Greed-Snake"), NULL, 0, NULL);
    }
    
    // Open and play music
    mciSendString(_T("open .\\Resource\\SoundEffects\\Greed-Snake.mp3 alias Greed-Snake"), NULL, NULL, NULL); // Open music file
    mciSendString(_T("play Greed-Snake repeat"), NULL, NULL, NULL); // Play music
    SetVolume(GameConfig::DEFAULT_VOLUME);  // Set initial volume
}

void StopBackgroundMusic() {
    // Check if music is playing before trying to stop it
    TCHAR statusBuff[256] = {0};
    if (mciSendString(_T("status Greed-Snake mode"), statusBuff, 256, NULL) == 0) {
        mciSendString(_T("stop Greed-Snake"), NULL, NULL, NULL); // Stop music
        mciSendString(_T("close Greed-Snake"), NULL, NULL, NULL); // Close music
    }
}

void PlayStartAnimation() {
    // Define frame file path and file extension
    const TCHAR* path = _T(".\\Resource\\Greed-Snake-Start-Animation-Frames\\"); // Frame file path
    const TCHAR* ext = _T(".bmp"); // File extension

    // Check if animation audio is already playing and close it if needed
    TCHAR statusBuff[256] = {0};
    if (mciSendString(_T("status Start-Animation mode"), statusBuff, 256, NULL) == 0) {
        mciSendString(_T("close Start-Animation"), NULL, 0, NULL);
    }

    // Always play the sound even if animations are off
    mciSendString(_T("open .\\Resource\\SoundEffects\\Greed-Snake-Start-Animation.MP3 alias Start-Animation"), NULL, NULL, NULL); // Open animation music
    mciSendString(_T("play Start-Animation"), NULL, NULL, NULL); // Play animation music
    
    if (!GameConfig::ANIMATIONS_ON) {
        // If animations are disabled, just wait a moment and return
        Sleep(1000);
        return;
    }
    
    Sleep(6000); // Wait 6 seconds

    // Declare IMAGE structure variable
    IMAGE FImg;    

    // Use loop to load and display each frame
    for (int i = 0; i <= GameConfig::NUM_FRAMES; i++) {
        TCHAR frameFileName[MAX_PATH];  // Ensure buffer is large enough to store full path
        _stprintf_s(frameFileName, MAX_PATH, _T("%sframe_%d%s"), path, i, ext); // Format frame filename

        // Load image and draw it
        loadimage(&FImg, frameFileName);
        IMAGE scaledG;
        scaledG.Resize(GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT);
        StretchBlt(GetImageHDC(&scaledG), 0, 0, GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT,
            GetImageHDC(&FImg), 0, 0, FImg.getwidth(), FImg.getheight(), SRCCOPY);
        putimage(0, 0, &scaledG);
        
        // Sleep without holding the mutex
        Sleep(GameConfig::FRAME_DELAY);
    }
}

// Add a new function to properly clean up audio resources when closing the game
void CleanupAudioResources() {
    // Close all audio devices and resources
    mciSendString(_T("close all"), NULL, 0, NULL);
} 