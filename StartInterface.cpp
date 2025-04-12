#include "StartInterface.h"


std::vector<Button> buttonList; // Button list

void LoadButton()
{
    const int buttonWidth = 200; // Button width
    const int buttonHeight = 50; // Button height
    int buttonY = GameConfig::WINDOW_HEIGHT * 0.7 + 10; // Button Y coordinate
    buttonList.resize(4); // Adjust button list size
    buttonList[StartGame].Initial(_T("Start Game"), Vector2(getwidth() / 2 - buttonWidth / 2, buttonY), Vector2(getwidth() / 2 + buttonWidth / 2, buttonY + buttonHeight), RGB(50, 150, 50), _T("..\\Resource\\button_click.wav")); // Initialize start game button
    buttonList[Setting].Initial(_T("./Resource/Setting.png"), Vector2(120, 10), Vector2(GameConfig::MENU_ICON_SIZE, GameConfig::MENU_ICON_SIZE), _T("..\\Resource\\button_click.wav")); // Initialize settings button
    buttonList[About].Initial(_T("./Resource/About.png"), Vector2(170, 10), Vector2(GameConfig::MENU_ICON_SIZE, GameConfig::MENU_ICON_SIZE), _T("..\\Resource\\button_click.wav")); // Initialize about button
    buttonList[Exit].Initial(_T("./Resource/Exit.png"), Vector2(220, 10), Vector2(GameConfig::MENU_ICON_SIZE, GameConfig::MENU_ICON_SIZE), _T("..\\Resource\\button_click.wav")); // Initialize exit button
}

void DrawMenu() {
    ExMessage m; // Message
    peekmessage(&m, EX_MOUSE);
    Vector2 mousePos = Vector2(m.x, m.y); // Mouse position

    // Draw title text
    settextstyle(48, 0, _T("Arial"));
    settextcolor(RGB(255, 255, 255));
    /*const TCHAR* title = _T("Greedy Snake");
    int titleWidth = textwidth(title);
    outtextxy(GameConfig::WINDOW_WIDTH / 2 - titleWidth / 2, GameConfig::WINDOW_HEIGHT * 0.2, title);*/

    // Draw all buttons
    for (int i = 0; i < ButtonType::Num; ++i) {
        buttonList[i].DrawButton(mousePos); // Draw button
    }
}