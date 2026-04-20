#pragma once

#include <cmath>
#include <concepts>

namespace GreedSnake {

/**
 * @brief 二维向量结构体（现代化版本）
 * 
 * 使用 C++20 特性：constexpr, noexcept, spaceship 运算符
 */
struct Vector2 {
    float x = 0.0f;
    float y = 0.0f;
    
    // 构造函数
    constexpr Vector2() noexcept = default;
    constexpr Vector2(float xVal, float yVal) noexcept : x(xVal), y(yVal) {}
    
    // 算术运算符 - 全部 constexpr noexcept
    [[nodiscard]] constexpr Vector2 operator+(const Vector2& other) const noexcept {
        return Vector2{x + other.x, y + other.y};
    }
    
    [[nodiscard]] constexpr Vector2 operator-(const Vector2& other) const noexcept {
        return Vector2{x - other.x, y - other.y};
    }
    
    [[nodiscard]] constexpr Vector2 operator*(float scalar) const noexcept {
        return Vector2{x * scalar, y * scalar};
    }
    
    [[nodiscard]] constexpr Vector2 operator/(float scalar) const {
        return Vector2{x / scalar, y / scalar};
    }
    
    // 复合赋值运算符
    constexpr Vector2& operator+=(const Vector2& other) noexcept {
        x += other.x;
        y += other.y;
        return *this;
    }
    
    constexpr Vector2& operator-=(const Vector2& other) noexcept {
        x -= other.x;
        y -= other.y;
        return *this;
    }
    
    constexpr Vector2& operator*=(float scalar) noexcept {
        x *= scalar;
        y *= scalar;
        return *this;
    }
    
    constexpr Vector2& operator/=(float scalar) {
        x /= scalar;
        y /= scalar;
        return *this;
    }
    
    // 一元运算符
    [[nodiscard]] constexpr Vector2 operator-() const noexcept {
        return Vector2{-x, -y};
    }
    
    // 比较运算符
    [[nodiscard]] constexpr bool operator==(const Vector2& other) const noexcept {
        return x == other.x && y == other.y;
    }
    
    [[nodiscard]] constexpr bool operator!=(const Vector2& other) const noexcept {
        return !(*this == other);
    }
    
    // 实用方法 - 全部 constexpr 优化
    [[nodiscard]] constexpr float LengthSquared() const noexcept {
        return x * x + y * y;
    }
    
    [[nodiscard]] float Length() const noexcept {
        return std::sqrt(LengthSquared());
    }
    
    [[nodiscard]] Vector2 Normalized() const noexcept {
        const float len = Length();
        if (len > 0.0f) {
            return *this / len;
        }
        return Vector2{};
    }
    
    [[nodiscard]] constexpr float Dot(const Vector2& other) const noexcept {
        return x * other.x + y * other.y;
    }
    
    [[nodiscard]] constexpr float Cross(const Vector2& other) const noexcept {
        return x * other.y - y * other.x;
    }
    
    [[nodiscard]] float DistanceTo(const Vector2& other) const noexcept {
        return (*this - other).Length();
    }
    
    [[nodiscard]] constexpr float DistanceSquaredTo(const Vector2& other) const noexcept {
        return (*this - other).LengthSquared();
    }
    
    // 线性插值
    [[nodiscard]] constexpr Vector2 Lerp(const Vector2& target, float t) const noexcept {
        return *this + (target - *this) * t;
    }
    
    // 反射
    [[nodiscard]] Vector2 Reflect(const Vector2& normal) const noexcept {
        return *this - normal * (2.0f * Dot(normal));
    }
    
    // 判断是否为有效向量（非NaN）
    [[nodiscard]] bool IsValid() const noexcept {
        return !std::isnan(x) && !std::isnan(y);
    }
};

// 标量乘法（左乘）
[[nodiscard]] constexpr Vector2 operator*(float scalar, const Vector2& vec) noexcept {
    return vec * scalar;
}

} // namespace GreedSnake
