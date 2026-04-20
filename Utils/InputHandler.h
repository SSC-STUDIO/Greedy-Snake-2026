#pragma once
#include "../ModernCore/Vector2.h"
#include "../Gameplay/Snake.h"

using Vector2 = GreedSnake::Vector2;
#include <graphics.h>

// Handle keyboard and mouse input during gameplay
void PollGameplayInput();

// Handle mouse input in menu
void HandleMouseInput();

// Check if position is in safe area
bool IsInSafeArea(const Vector2& pos); 
