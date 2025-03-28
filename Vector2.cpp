/*
    Name:       GreedSnakeOfMath.cpp
    Created:    2025/1/22 14:44:25
    Author:     PC-20230225XVVJ\Administrator
    
    Description: Implementation of Vector2 class and math utilities.
    Provides vector operations for game physics and movement.
*/

#include <iostream>
#include <cmath>
#include "Vector2.h"

// Vector normalization - makes vector length = 1
Vector2& Vector2::Normalize(float epsilon) const
{
    float length = GetLength();
    if (length < epsilon)
    {
        Vector2& mutableVector = const_cast<Vector2&>(*this);
        mutableVector.x = 0.0f;
        mutableVector.y = 0.0f;
        return mutableVector;
    }
    
    float inverseLength = 1.0f / length;
    Vector2& mutableVector = const_cast<Vector2&>(*this);
    mutableVector.x *= inverseLength;
    mutableVector.y *= inverseLength;
    return mutableVector;
}

// Get normalized copy of vector
Vector2 Vector2::GetNormalize(float epsilon) const
{
    float length = GetLength();
    if (length < epsilon)
    {
        return Vector2();
    }
    float inverseLength = 1.0f / length;
    return Vector2(x * inverseLength, y * inverseLength);
}

// Get vector length using hypot
float Vector2::GetLength() const
{
    return std::hypot(x, y);
}

// Get squared length (faster than GetLength for comparisons)
float Vector2::GetSquaredLength() const
{
    return x * x + y * y;
}

// Swap X and Y components
Vector2 Vector2::GetSwappedCoordinates() const
{
    return Vector2(y, x);
}

// Vector arithmetic operations
Vector2 Vector2::operator+(const Vector2& other) const
{
    return Vector2(x + other.x, y + other.y);
}

Vector2 Vector2::operator-(const Vector2& other) const
{
    return Vector2(x - other.x, y - other.y);
}

Vector2 Vector2::operator-() const
{
    return Vector2(-x, -y);
}

Vector2 Vector2::operator*(const float scale) const
{
    return Vector2(x * scale, y * scale);
}

Vector2 Vector2::operator/(const float scale) const
{
    return Vector2(x / scale, y / scale);
}

// Vector products
float Vector2::Dot(const Vector2& v1, const Vector2& v2)
{
    return v1.x * v2.x + v1.y * v2.y;
}

float Vector2::Cross(const Vector2& v1, const Vector2& v2)
{
    return v1.x * v2.y - v1.y * v2.x;
}

bool Vector2::operator==(const Vector2& other) const
{
    return (x == other.x) && (y == other.y);
}

bool Vector2::operator!=(const Vector2& other) const
{
    return!(*this == other);
}