/**
 * @file PathSecurity.h
 * @brief 路径安全验证工具 - 防止路径遍历攻击
 * @version 1.0.0
 * @date 2026-04-02
 * 
 * 提供以下安全功能：
 * - 路径遍历检测 (../, ..\\, URL编码等)
 * - 敏感路径检测
 * - 缓冲区溢出防护
 * - 安全的文件路径拼接
 */

#pragma once

#ifndef PATH_SECURITY_H
#define PATH_SECURITY_H

#include <windows.h>
#include <tchar.h>
#include <string>
#include <vector>
#include <algorithm>

namespace Security {

// 最大安全路径长度
constexpr DWORD MAX_SAFE_PATH_LENGTH = 260;

// 危险路径模式
const std::vector<std::wstring> DANGEROUS_PATTERNS = {
    L"..",           // 父目录引用
    L"%2e%2e",       // URL编码的..
    L"0x2e0x2e",     // 十六进制编码的..
    L"~",            // 波浪号展开
    L"$",            // 环境变量
};

// 敏感系统路径
const std::vector<std::wstring> SENSITIVE_PATHS = {
    L"C:\\\\Windows\\\\",
    L"C:\\\\Program Files\\\\",
    L"C:\\\\ProgramData\\\\",
    L"C:\\\\System32\\\\",
    L"\\\\\\\\.\\\\",          // 设备路径
    L"\\\\?\\\\",              // 扩展UNC路径
};

/**
 * @class PathValidator
 * @brief 路径验证器类
 */
class PathValidator {
public:
    /**
     * @brief 验证路径是否包含路径遍历攻击模式
     * @param path 要验证的路径
     * @return true 如果路径安全
     */
    static bool ValidatePathTraversal(const std::wstring& path) {
        if (path.empty()) {
            return false;
        }

        // 检查路径长度
        if (path.length() > MAX_SAFE_PATH_LENGTH) {
            OutputDebugStringA("PathSecurity: Path exceeds maximum length\n");
            return false;
        }

        // 检查危险模式
        for (const auto& pattern : DANGEROUS_PATTERNS) {
            if (path.find(pattern) != std::wstring::npos) {
                OutputDebugStringA("PathSecurity: Path traversal pattern detected\n");
                return false;
            }
        }

        // 规范化路径并检查是否仍然安全
        wchar_t canonicalPath[MAX_PATH];
        if (GetFullPathNameW(path.c_str(), MAX_PATH, canonicalPath, nullptr) == 0) {
            return false;
        }

        std::wstring canonical(canonicalPath);
        for (const auto& pattern : DANGEROUS_PATTERNS) {
            if (canonical.find(pattern) != std::wstring::npos) {
                OutputDebugStringA("PathSecurity: Path traversal in canonical path\n");
                return false;
            }
        }

        return true;
    }

    /**
     * @brief 验证路径是否在允许的目录范围内
     * @param userPath 用户提供的文件路径
     * @param allowedBase 允许的基础目录路径
     * @return true 如果在允许范围内
     */
    static bool IsWithinAllowedDirectory(const std::wstring& userPath, 
                                         const std::wstring& allowedBase) {
        wchar_t userCanonical[MAX_PATH];
        wchar_t baseCanonical[MAX_PATH];

        if (GetFullPathNameW(userPath.c_str(), MAX_PATH, userCanonical, nullptr) == 0) {
            return false;
        }

        if (GetFullPathNameW(allowedBase.c_str(), MAX_PATH, baseCanonical, nullptr) == 0) {
            return false;
        }

        std::wstring userPathStr(userCanonical);
        std::wstring basePathStr(baseCanonical);

        // 确保以分隔符结尾，以进行前缀匹配
        if (basePathStr.back() != L'\\\\' && basePathStr.back() != L'/') {
            basePathStr += L'\\\\';
        }

        // 检查用户路径是否以基础路径开头
        if (userPathStr.length() < basePathStr.length()) {
            return false;
        }

        return _wcsnicmp(userPathStr.c_str(), basePathStr.c_str(), basePathStr.length()) == 0;
    }

    /**
     * @brief 检查路径是否为敏感系统路径
     * @param path 要检查的路径
     * @return true 如果是敏感路径
     */
    static bool IsSensitivePath(const std::wstring& path) {
        wchar_t canonicalPath[MAX_PATH];
        if (GetFullPathNameW(path.c_str(), MAX_PATH, canonicalPath, nullptr) == 0) {
            return true; // 无法解析，视为敏感
        }

        std::wstring canonical(canonicalPath);
        std::transform(canonical.begin(), canonical.end(), canonical.begin(), ::towlower);

        for (const auto& sensitive : SENSITIVE_PATHS) {
            std::wstring lowerSensitive = sensitive;
            std::transform(lowerSensitive.begin(), lowerSensitive.end(), 
                          lowerSensitive.begin(), ::towlower);
            if (canonical.find(lowerSensitive) != std::wstring::npos) {
                OutputDebugStringA("PathSecurity: Sensitive path access detected\n");
                return true;
            }
        }

        return false;
    }

    /**
     * @brief 安全的字符串拼接，防止缓冲区溢出
     * @param dest 目标缓冲区
     * @param destSize 目标缓冲区大小（以字符计）
     * @param src 源字符串
     * @return true 如果成功
     */
    static bool SafeStringCopy(wchar_t* dest, size_t destSize, const wchar_t* src) {
        if (!dest || !src || destSize == 0) {
            return false;
        }

        HRESULT hr = StringCchCopyW(dest, destSize, src);
        return SUCCEEDED(hr);
    }

    /**
     * @brief 安全的格式化字符串，防止缓冲区溢出
     * @param dest 目标缓冲区
     * @param destSize 目标缓冲区大小（以字符计）
     * @param format 格式字符串
     * @param ... 可变参数
     * @return true 如果成功
     */
    static bool SafeFormat(wchar_t* dest, size_t destSize, const wchar_t* format, ...) {
        if (!dest || !format || destSize == 0) {
            return false;
        }

        va_list args;
        va_start(args, format);
        HRESULT hr = StringCchVPrintfW(dest, destSize, format, args);
        va_end(args);

        return SUCCEEDED(hr);
    }

    /**
     * @brief 清理文件名，移除危险字符
     * @param filename 原始文件名
     * @return 清理后的文件名
     */
    static std::wstring SanitizeFilename(const std::wstring& filename) {
        std::wstring sanitized = filename;

        // 移除危险字符
        const std::wstring dangerousChars = L"<>:\"/\\|?*\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f";
        for (wchar_t c : dangerousChars) {
            std::replace(sanitized.begin(), sanitized.end(), c, L'_');
        }

        // 移除前导和尾随的空格和点
        size_t start = sanitized.find_first_not_of(L" .");
        if (start == std::wstring::npos) {
            return L"unnamed";
        }
        size_t end = sanitized.find_last_not_of(L" .");
        sanitized = sanitized.substr(start, end - start + 1);

        // 限制长度
        const size_t MAX_FILENAME_LENGTH = 255;
        if (sanitized.length() > MAX_FILENAME_LENGTH) {
            size_t dotPos = sanitized.find_last_of(L'.');
            if (dotPos != std::wstring::npos && dotPos > 0) {
                std::wstring ext = sanitized.substr(dotPos);
                sanitized = sanitized.substr(0, MAX_FILENAME_LENGTH - ext.length()) + ext;
            } else {
                sanitized = sanitized.substr(0, MAX_FILENAME_LENGTH);
            }
        }

        return sanitized.empty() ? L"unnamed" : sanitized;
    }

    /**
     * @brief 验证文件扩展名
     * @param filepath 文件路径
     * @param allowedExtensions 允许的扩展名列表（小写，带点号）
     * @return true 如果扩展名有效
     */
    static bool ValidateFileExtension(const std::wstring& filepath,
                                       const std::vector<std::wstring& allowedExtensions) {
        size_t dotPos = filepath.find_last_of(L'.');
        if (dotPos == std::wstring::npos || dotPos == filepath.length() - 1) {
            return false;
        }

        std::wstring ext = filepath.substr(dotPos);
        std::transform(ext.begin(), ext.end(), ext.begin(), ::towlower);

        for (const auto& allowed : allowedExtensions) {
            std::wstring lowerAllowed = allowed;
            std::transform(lowerAllowed.begin(), lowerAllowed.end(), 
                          lowerAllowed.begin(), ::towlower);
            if (ext == lowerAllowed) {
                return true;
            }
        }

        return false;
    }
};

/**
 * @brief 安全的资源路径构建
 * @param baseDir 基础目录
 * @param subDir 子目录
 * @param filename 文件名
 * @param result 结果缓冲区
 * @param resultSize 结果缓冲区大小
 * @return true 如果成功构建安全路径
 */
inline bool BuildResourcePath(const wchar_t* baseDir, const wchar_t* subDir,
                               const wchar_t* filename, wchar_t* result,
                               size_t resultSize) {
    if (!baseDir || !filename || !result || resultSize == 0) {
        return false;
    }

    // 验证基础目录
    std::wstring basePath(baseDir);
    if (!PathValidator::ValidatePathTraversal(basePath)) {
        return false;
    }

    // 构建完整路径
    std::wstring fullPath = basePath;
    if (subDir) {
        std::wstring subPath(subDir);
        if (!PathValidator::ValidatePathTraversal(subPath)) {
            return false;
        }
        if (fullPath.back() != L'\\\\' && fullPath.back() != L'/') {
            fullPath += L'\\\\';
        }
        fullPath += subPath;
    }

    std::wstring filePath(filename);
    if (!PathValidator::ValidatePathTraversal(filePath)) {
        return false;
    }

    if (fullPath.back() != L'\\\\' && fullPath.back() != L'/') {
        fullPath += L'\\\\';
    }
    fullPath += filePath;

    // 验证最终路径
    if (!PathValidator::ValidatePathTraversal(fullPath)) {
        return false;
    }

    // 复制到结果缓冲区
    return PathValidator::SafeStringCopy(result, resultSize, fullPath.c_str());
}

/**
 * @brief 检查文件是否存在且可访问
 * @param filePath 文件路径
 * @return true 如果文件存在且可访问
 */
inline bool IsFileAccessible(const wchar_t* filePath) {
    if (!filePath) {
        return false;
    }

    DWORD attributes = GetFileAttributesW(filePath);
    if (attributes == INVALID_FILE_ATTRIBUTES) {
        return false;
    }

    // 检查是否为目录
    if (attributes & FILE_ATTRIBUTE_DIRECTORY) {
        return false;
    }

    // 尝试打开文件进行读取
    HANDLE hFile = CreateFileW(filePath, GENERIC_READ, FILE_SHARE_READ, nullptr,
                                OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (hFile == INVALID_HANDLE_VALUE) {
        return false;
    }

    CloseHandle(hFile);
    return true;
}

} // namespace Security

#endif // PATH_SECURITY_H
