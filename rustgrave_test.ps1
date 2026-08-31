# rustgrave_test.ps1 — 可重复的视觉自测:启动游戏、逐屏截图、退出。
# 用法:  powershell -ExecutionPolicy Bypass -File rustgrave_test.ps1 [-GodotExe <path>] [-OutDir <dir>]
# 输出:  $OutDir\01_title.png / 02_level.png / 03_action.png,全部成功则退出码 0。

param(
    [string]$GodotExe = "C:\Program Files\Godot\Godot_v4.7.1-stable_win64.exe",
    [string]$OutDir = (Join-Path $PSScriptRoot "screenshots")
)

$ErrorActionPreference = 'Stop'

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;

public class Win32 {
    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc enumProc, IntPtr lParam);
    [DllImport("user32.dll")]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    [DllImport("user32.dll")]
    public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
    [DllImport("user32.dll")]
    public static extern uint MapVirtualKey(uint uCode, uint uMapType);
    [DllImport("user32.dll")]
    public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")]
    public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdcBlt, uint nFlags);
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, IntPtr lpdwProcessId);
    [DllImport("user32.dll")]
    public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentThreadId();
    [DllImport("user32.dll")]
    public static extern bool BringWindowToTop(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern bool SetProcessDPIAware();

    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left, Top, Right, Bottom; }
}
'@

Add-Type -AssemblyName System.Drawing

# DPI 感知:否则 GetWindowRect 返回缩放后的逻辑坐标,PrintWindow 按物理像素渲染,截图被裁。
[Win32]::SetProcessDPIAware() | Out-Null

function Find-GameWindow([int]$OwnerPid) {
    $found = [IntPtr]::Zero
    $cb = [Win32+EnumWindowsProc]{
        param($hWnd, $lParam)
        if (-not [Win32]::IsWindowVisible($hWnd)) { return $true }
        $winPid = [uint32]0
        [Win32]::GetWindowThreadProcessId($hWnd, [ref]$winPid) | Out-Null
        if ($winPid -ne $OwnerPid) { return $true }
        $sb = New-Object System.Text.StringBuilder 512
        [Win32]::GetWindowText($hWnd, $sb, 512) | Out-Null
        if ($sb.ToString() -like '*Rustgrave*') {
            $script:foundHwnd = $hWnd
            return $false
        }
        return $true
    }
    $script:foundHwnd = [IntPtr]::Zero
    [Win32]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
    return $script:foundHwnd
}

function Save-WindowShot([IntPtr]$hWnd, [string]$Path) {
    $rect = New-Object Win32+RECT
    [Win32]::GetWindowRect($hWnd, [ref]$rect) | Out-Null
    $w = $rect.Right - $rect.Left
    $h = $rect.Bottom - $rect.Top
    if ($w -le 0 -or $h -le 0) { throw "窗口尺寸异常: ${w}x${h}" }
    $bmp = New-Object System.Drawing.Bitmap $w, $h
    $gfx = [System.Drawing.Graphics]::FromImage($bmp)
    # PrintWindow + PW_RENDERFULLCONTENT(2):即使被其他窗口遮挡也能抓到游戏画面。
    $hdc = $gfx.GetHdc()
    $ok = [Win32]::PrintWindow($hWnd, $hdc, 2)
    $gfx.ReleaseHdc($hdc)
    if (-not $ok) {   # 回退:老式屏幕区域拷贝
        $gfx.CopyFromScreen($rect.Left, $rect.Top, 0, 0, $bmp.Size)
    }
    $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $gfx.Dispose(); $bmp.Dispose()
    Write-Host ("截图: {0} ({1:N0} KB)" -f $Path, ((Get-Item $Path).Length / 1KB))
}

# 确保游戏窗口在前台再注入按键,避免把按键打进别的窗口。
# Windows 会拒绝后台进程的 SetForegroundWindow;用 Alt 键脉冲 + AttachThreadInput 解锁。
function Assert-Foreground([IntPtr]$hWnd) {
    foreach ($i in 1..10) {
        if ([Win32]::GetForegroundWindow() -eq $hWnd) { return $true }
        # 技巧 1:先发一个 Alt 按键脉冲,解除前台锁定限制。
        [Win32]::keybd_event(0x12, 0, 0, [UIntPtr]::Zero)      # VK_MENU down
        [Win32]::keybd_event(0x12, 0, 0x02, [UIntPtr]::Zero)   # VK_MENU up
        [Win32]::SetForegroundWindow($hWnd) | Out-Null
        Start-Sleep -Milliseconds 150
        if ([Win32]::GetForegroundWindow() -eq $hWnd) { return $true }
        # 技巧 2:把本线程输入队列挂到当前前台窗口线程再抢前台。
        $fg = [Win32]::GetForegroundWindow()
        if ($fg -ne [IntPtr]::Zero) {
            $fgThread = [Win32]::GetWindowThreadProcessId($fg, [IntPtr]::Zero)
            $myThread = [Win32]::GetCurrentThreadId()
            [Win32]::AttachThreadInput($myThread, $fgThread, $true) | Out-Null
            [Win32]::BringWindowToTop($hWnd) | Out-Null
            [Win32]::SetForegroundWindow($hWnd) | Out-Null
            [Win32]::AttachThreadInput($myThread, $fgThread, $false) | Out-Null
        }
        Start-Sleep -Milliseconds 200
    }
    throw "无法把游戏窗口置于前台,中止按键注入"
}

# Godot 按物理扫描码匹配输入动作,必须用 KEYEVENTF_SCANCODE 注入。
function Press-Key([byte]$Vk) {
    $scan = [byte]([Win32]::MapVirtualKey($Vk, 0))
    [Win32]::keybd_event($Vk, $scan, 0x08, [UIntPtr]::Zero)          # SCANCODE down
}
function Release-Key([byte]$Vk) {
    $scan = [byte]([Win32]::MapVirtualKey($Vk, 0))
    [Win32]::keybd_event($Vk, $scan, 0x0A, [UIntPtr]::Zero)  # SCANCODE | KEYUP
}
function Send-Key([byte]$Vk, [int]$HoldMs = 60) {
    Press-Key $Vk
    Start-Sleep -Milliseconds $HoldMs
    Release-Key $Vk
}

# --- Step 0: 准备 ---
if (-not (Test-Path $GodotExe)) { Write-Host "找不到 Godot: $GodotExe"; exit 1 }
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
$projectDir = $PSScriptRoot

# --- Step 1: 启动游戏 ---
Write-Host "=== 启动游戏 ==="
$proc = Start-Process -FilePath $GodotExe -ArgumentList '--path', "`"$projectDir`"" -PassThru

try {
    # --- Step 2: 等待窗口出现 ---
    $hwnd = [IntPtr]::Zero
    foreach ($i in 1..40) {
        Start-Sleep -Milliseconds 500
        $hwnd = Find-GameWindow -OwnerPid $proc.Id
        if ($hwnd -ne [IntPtr]::Zero) { break }
        if ($proc.HasExited) { Write-Host "游戏进程提前退出,exit=$($proc.ExitCode)"; exit 1 }
    }
    if ($hwnd -eq [IntPtr]::Zero) { Write-Host "20 秒内未找到 Rustgrave 窗口"; exit 1 }
    Write-Host ("找到窗口 HWND=0x{0:X8}" -f $hwnd.ToInt64())

    [Win32]::ShowWindow($hwnd, 9) | Out-Null
    Start-Sleep -Milliseconds 300
    # 挪到屏幕左上,避免窗口超出屏幕导致截图被裁。
    $rect = New-Object Win32+RECT
    [Win32]::GetWindowRect($hwnd, [ref]$rect) | Out-Null
    [Win32]::MoveWindow($hwnd, 10, 10, $rect.Right - $rect.Left, $rect.Bottom - $rect.Top, $true) | Out-Null
    [Win32]::SetForegroundWindow($hwnd) | Out-Null
    Start-Sleep -Milliseconds 2000   # 等标题屏余烬/keyart 稳定

    # --- Step 3: 标题屏截图 ---
    Save-WindowShot $hwnd (Join-Path $OutDir '01_title.png')

    # --- Step 4: 按 Enter 开新游戏,等淡出 + 关卡加载 ---
    Assert-Foreground $hwnd | Out-Null
    Send-Key 0x0D    # VK_RETURN
    Start-Sleep -Milliseconds 2500
    Save-WindowShot $hwnd (Join-Path $OutDir '02_level.png')

    # --- Step 5: 向右移动 + 挥砍,截动作画面 ---
    Assert-Foreground $hwnd | Out-Null
    Press-Key 0x44                                       # D 按下
    Start-Sleep -Milliseconds 900
    Release-Key 0x44                                     # D 抬起
    Send-Key 0x4A    # J 挥砍
    Start-Sleep -Milliseconds 180                        # 命中判定帧内
    Save-WindowShot $hwnd (Join-Path $OutDir '03_action.png')

    Write-Host "=== 自测完成,3 张截图已保存到 $OutDir ==="
    exit 0
}
finally {
    if (-not $proc.HasExited) { $proc.Kill() }
}
