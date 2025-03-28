/*
    Name:       GreedSnakeOfMath.h
    Created:    2025/1/22 14:44:25
    Author:     PC-20230225XVVJ\Administrator
    
    Description: Header file defining Vector2 class and math utilities.
    Core math functionality for the snake game.
*/

#ifndef GreedSnakeOfMath_H
#define GreedSnakeOfMath_H

#include <iostream>
#include <cmath>


struct Vector2
{
    float x;
    float y;

    Vector2() : x(0), y(0) {}

    Vector2(float xPos, float yPos) : x(xPos), y(yPos) {}

  
    Vector2& Normalize(float epsilon = 0.0000001f) const;
   
    Vector2 GetNormalize(float epsilon = 0.0000001f) const;
   
    float GetLength() const;

    float GetSquaredLength() const;

    Vector2 GetSwappedCoordinates() const;

    
    Vector2 operator+(const Vector2& rhs) const;
    Vector2 operator-(const Vector2& rhs) const;
    Vector2 operator-() const;
    Vector2 operator*(const float scalar) const;
    Vector2 operator/(const float scalar) const;

   
    static float Dot(const Vector2& lhs, const Vector2& rhs);

    static float Cross(const Vector2& lhs, const Vector2& rhs);


    bool operator==(const Vector2& rhs) const;
  
    bool operator!=(const Vector2& rhs) const;
};


#endif // GreedSnakeOfMath_H