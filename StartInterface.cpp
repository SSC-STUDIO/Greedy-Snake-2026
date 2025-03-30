#include "StartInterface.h"


//std::vector<Button> buttonList; // 按钮列表

void LoadButton()
{
    const int buttonWidth = 200; // 按钮宽度
    const int buttonHeight = 50; // 按钮高度
    int buttonY = GameConfig::WINDOW_HEIGHT * 0.7 + 10; // 按钮Y坐标
    buttonList.resize(4); // 调整按钮列表大小
    buttonList[StartGame].Initial(_T("Start Game"), Vector2(getwidth() / 2 - buttonWidth / 2, buttonY), Vector2(getwidth() / 2 + buttonWidth / 2, buttonY + buttonHeight), RGB(50, 150, 50), _T("..\\Resource\\button_click.wav")); // 初始化开始游戏按钮
    buttonList[Setting].Initial(_T("./Resource/Setting.png"), Vector2(120, 10), Vector2(GameConfig::MENU_ICON_SIZE, GameConfig::MENU_ICON_SIZE), _T("..\\Resource\\button_click.wav")); // 初始化设置按钮
    buttonList[About].Initial(_T("./Resource/About.png"), Vector2(170, 10), Vector2(GameConfig::MENU_ICON_SIZE, GameConfig::MENU_ICON_SIZE), _T("..\\Resource\\button_click.wav")); // 初始化关于按钮
    buttonList[Exit].Initial(_T("./Resource/Exit.png"), Vector2(220, 10), Vector2(GameConfig::MENU_ICON_SIZE, GameConfig::MENU_ICON_SIZE), _T("..\\Resource\\button_click.wav")); // 初始化退出按钮
}

void DrawMenu() {
    ExMessage m; // 消息
    peekmessage(&m, EX_MOUSE);
    Vector2 mousePos = Vector2(m.x, m.y); // 鼠标位置

    for (int i = 0; i < ButtonType::Num; ++i) {
        buttonList[i].DrawButton(mousePos); // 绘制按钮
    }
}