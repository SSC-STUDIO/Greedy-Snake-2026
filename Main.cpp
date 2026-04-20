#include <graphics.h>
#include <tchar.h>
#include "Gameplay/GameConfig.h"
#include "Core/GameSession.h"
#include "Core/ResourceManager.h"
#include "UI/UI.h"
#include "Utils/Setting.h"

namespace {

void DrawMenuBackground() {
    BeginBatchDraw();
    ResourceManager::Instance().DrawBackground();
    EndBatchDraw();
}

GameSessionResult RunSingleGameSession() {
    GameSession session(GetCurrentSettings());
    return session.Run();
}

void HandleMenuChoice(int menuChoice, bool& showMenu, bool& startGame, bool& quitProgram) {
    switch (menuChoice) {
        case StartGame:
            PlaySceneTransition(_T("Dive Into The Arena"), _T("Locking onto the active sector"), RGB(63, 177, 219), true);
            cleardevice();
            startGame = true;
            showMenu = false;
            break;
        case Setting:
            PlaySceneTransition(_T("Tune The Run"), _T("Adjusting visuals, controls and presentation"), RGB(102, 170, 210), true);
            ShowSettings(GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT);
            PlaySceneTransition(_T("Back To Menu"), _T("Returning to launch control"), RGB(92, 190, 214), false);
            DrawMenuBackground();
            break;
        case About:
            PlaySceneTransition(_T("About Greed Snake"), _T("Project overview and credits"), RGB(124, 179, 214), true);
            ShowAbout();
            PlaySceneTransition(_T("Back To Menu"), _T("Returning to launch control"), RGB(92, 190, 214), false);
            DrawMenuBackground();
            break;
        case Exit:
            quitProgram = true;
            showMenu = false;
            break;
        default:
            break;
    }
}

void RunMenuCycle(bool& quitProgram) {
    ResourceManager::Instance().PlayBackgroundMusic();
    DrawMenuBackground();

    bool showMenu = true;
    bool startGame = false;

    while (showMenu && !quitProgram) {
        const int menuChoice = ShowGameMenu();
        HandleMenuChoice(menuChoice, showMenu, startGame, quitProgram);
    }

    while (startGame && !quitProgram) {
        switch (RunSingleGameSession()) {
            case GameSessionResult::Restart:
                PlaySceneTransition(_T("Retry Run"), _T("Rebuilding the arena"), RGB(120, 215, 255), true);
                startGame = true;
                break;
            case GameSessionResult::ReturnToMenu:
                PlaySceneTransition(_T("Back To Base"), _T("Returning to launch control"), RGB(92, 190, 214), false);
                startGame = false;
                break;
            case GameSessionResult::ExitProgram:
                startGame = false;
                quitProgram = true;
                break;
        }
    }
}

}

int main() {
    const GameSettings initialSettings = GetCurrentSettings();
    InitializeDisplayConfig(initialSettings);
    initgraph(GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT);
    ApplyDisplayModeToCurrentWindow();

    ResourceManager& resourceManager = ResourceManager::Instance();
    resourceManager.LoadAllResources();
    resourceManager.ScaleBackgroundImage(GameConfig::WINDOW_WIDTH, GameConfig::WINDOW_HEIGHT);

    ApplySettings(initialSettings);
    ShowLandingScreen();

    bool quitProgram = false;
    while (!quitProgram) {
        RunMenuCycle(quitProgram);
    }

    resourceManager.CleanupAudio();
    closegraph();
    return 0;
}
