
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Drawing;
using System.Drawing.Imaging;

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
    public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")]
    public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
    
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left, Top, Right, Bottom; }
}
'@ -ReferencedAssemblies 'System.Drawing'

$ErrorActionPreference = 'Continue'
New-Item -ItemType Directory -Path "c:\Users\Administrator\OneDrive\Documents\My-Program\Rustgrave\screenshots" -Force | Out-Null

Write-Host "=== Step 1: 查找 Rustgrave 窗口 ==="
$found = $null
$windows = New-Object System.Collections.Generic.List[Tuple[IntPtr,string]]

[Win32]::EnumWindows([Win32+EnumWindowsProc]{
    param($hWnd, $lParam)
    if ([Win32]::IsWindowVisible($hWnd)) {
        $sb = New-Object System.Text.StringBuilder 512
        [Win32]::GetWindowText($hWnd, $sb, 512) | Out-Null
        $title = $sb.ToString()
        if ($title.Length -gt 0) {
            $windows.Add([Tuple]::Create($hWnd, $title))
            if ($title -like '*Rustgrave*' -or $title -like '*rustgrave*' -or $title -like '*Godot*') {
                $script:found = $hWnd
                Write-Host "MATCH! HWND=$($hWnd.ToString('X8')) Title='$title'"
            }
        }
    }
    return $true
}, [IntPtr]::Zero) | Out-Null

Write-Host "
最近窗口 (最后30个):"
$windows | Select-Object -Last 30 | ForEach-Object {
    Write-Host ("  [{0}] '{1}'" -f $_.Item1.ToString('X8'), $_.Item2)
}

# 如果没找到，检查进程
if ($null -eq $script:found) {
    Write-Host "
*** 标题搜索失败，按进程查找... ***"
    Get-Process | Where-Object { $_.Name -match 'godot|Rustgrave|Godot' -and $_.MainWindowHandle -ne [IntPtr]::Zero } | ForEach-Object {
        Write-Host ("  PROC: {0} PID={1} Handle={2} Title='{3}'" -f $_.Name, $_.Id, $_.MainWindowHandle.ToString('X8'), $_.MainWindowTitle)
        if (-not $script:found) { $script:found = $_.MainWindowHandle }
    }
}

if ($null -eq $script:found) {
    Write-Host "
*** ERROR: 找不到 Rustgrave 窗口！请确认游戏已运行。 ***"
    exit 1
}

# === Step 2: 激活并截图 ===
Write-Host "
=== Step 2: 激活窗口并截图标题画面 ==="
[Win32]::ShowWindow($script:found, 9) | Out-Null
Start-Sleep -ms 200
[Win32]::SetForegroundWindow($script:found) | Out-Null
Start-Sleep -ms 600

$rect = New-Object Win32+RECT
[Win32]::GetWindowRect($script:found, [ref]$rect) | Out-Null
$W = $rect.Right - $rect.Left
$H = $rect.Bottom - $rect.Top
Write-Host ("窗口: ({0},{1}) - ({2},{3}) Size={4}x{5}" -f $rect.Left,$rect.Top,$rect.Right,$rect.Bottom,$W,$H)

$bmp = New-Object System.Drawing.Bitmap $W, $H
$gfx = [System.Drawing.Graphics]::FromImage($bmp)
$gfx.CopyFromScreen($rect.Left, $rect.Top, 0, 0, $bmp.Size)
$bmp.Save("$screenshot1Path", [System.Drawing.Imaging.ImageFormat]::Png)
$gfx.Dispose(); $bmp.Dispose()
Write-Host ("标题截图已保存: $screenshot1Path ({0:N0} KB)" -f ((Get-Item "$screenshot1Path").Length/1KB))

# 返回找到的窗口信息用于后续步骤
Write-Host "WINDOW_HWND=$($script:found.ToString('X8'))"
