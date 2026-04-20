#pragma once

#include "SessionConfig.h"
#include "../ModernCore/TimeUtils.h"

class GameSession {
public:
    explicit GameSession(const GameSettings& settings);

    GameSessionResult Run();

private:
    void Initialize();
    void InitializePlayerSnake();
    void InitializeFood();
    void UpdateFrame(float deltaTime);
    void RenderFrame();

    GameSettings settings_;
    GreedSnake::FrameRateCalculator frameRateCalculator_;
};
