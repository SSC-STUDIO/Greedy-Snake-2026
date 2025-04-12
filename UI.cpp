#include "UI.h"
#include "StartInterface.h"
#include <tchar.h>
#include <conio.h>

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
    outtextxy(50, 340, _T("- ESC to end game"));

    settextcolor(RGB(150, 150, 150));
    outtextxy(50, GameConfig::WINDOW_HEIGHT - 100, _T("Press any key to return to menu..."));

    FlushBatchDraw();
    _getch();  // Wait for any key
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