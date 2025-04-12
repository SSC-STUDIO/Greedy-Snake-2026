#pragma once
#include "Vector2.h"
#include "GameConfig.h"
#include "GameState.h"
#include "Snake.h"
#include "Food.h"

// Initialize player snake
void InitializePlayerSnake();

// Initialize AI snakes
void InitializeAISnakes();

// Initialize game global variables
void InitGlobal();

// Initialize snake at specific position
void InitSnake(int i, const Vector2& pos, const Vector2& currentDir);

// Change global speed
void ChangeGlobalSpeed(float newSpeed);

// Update player snake
void UpdatePlayerSnake(float deltaTime);

// Update AI snakes
void UpdateAISnakes(float deltaTime);

// Update camera position
void UpdateCamera();

// Check collisions
void CheckCollisions();

// Get history position index
int GetHistoryIndexAtDistance(const std::deque<Vector2>& positions, float targetDistance); 