# rustgrave_test.ps1 — 可重复的视觉自测:启动游戏、逐屏截图、退出。
# 用法:  powershell -ExecutionPolicy Bypass -File rustgrave_test.ps1 [-GodotExe <path>] [-OutDir <dir>]
# 输出:  $OutDir\01_title.png / 02_level.png / 03_action.png,全部成功则退出码 0。

param(
    [string]$GodotExe = "C:\Program Files\Godot\Godot_v4.7.1-stable_win64.exe",
    [string]$OutDir = (Join-Path $PSScriptRoot "screenshots"),
    # -Extended: 03 之后继续按住 D 周期跳跃横穿全关，多截 04..08 五张图（巡查右半关卡）。
    [switch]$Extended,
    # -Ui: 巡查全部界面 —— 标题菜单 / 菜单选中态 / 操作说明 / 游戏内 HUD /
    #      暂停菜单 / 暂停里的操作说明 / 返回标题，最后再补一张“有存档”的标题
    #      （继续项可用）。为了让键盘导航可复现，该模式会先删除存档。
    [switch]$Ui
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
    [DllImport("user32.dll")]
    public static extern bool ClientToScreen(IntPtr hWnd, ref POINT lpPoint);

    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left, Top, Right, Bottom; }
    [StructLayout(LayoutKind.Sequential)]
    public struct POINT { public int X, Y; }
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

function Get-WindowBitmap([IntPtr]$hWnd) {
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
    $gfx.Dispose()
    return $bmp
}

function Save-WindowShot([IntPtr]$hWnd, [string]$Path) {
    $bmp = Get-WindowBitmap $hWnd
    $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host ("截图: {0} ({1:N0} KB)" -f $Path, ((Get-Item $Path).Length / 1KB))
}

# 客户区左上角在窗口截图里的偏移(边框 + 标题栏),把视口坐标换算成截图坐标。
function Get-ClientOrigin([IntPtr]$hWnd) {
    $rect = New-Object Win32+RECT
    [Win32]::GetWindowRect($hWnd, [ref]$rect) | Out-Null
    $pt = New-Object Win32+POINT
    [Win32]::ClientToScreen($hWnd, [ref]$pt) | Out-Null
    return @{ X = $pt.X - $rect.Left; Y = $pt.Y - $rect.Top }
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
# 方向键是扩展键:不带 KEYEVENTF_EXTENDEDKEY 的话扫描码会撞到小键盘,
# Godot 收到的就不是 ui_up / ui_down 了。
function Send-ArrowKey([byte]$Vk, [int]$HoldMs = 60) {
    $scan = [byte]([Win32]::MapVirtualKey($Vk, 0))
    [Win32]::keybd_event($Vk, $scan, 0x09, [UIntPtr]::Zero)   # SCANCODE | EXTENDEDKEY
    Start-Sleep -Milliseconds $HoldMs
    [Win32]::keybd_event($Vk, $scan, 0x0B, [UIntPtr]::Zero)   # + KEYUP
}

# --- 标题菜单导航:按到位为止 ---
# 注入的第一个按键偶尔会被丢掉(窗口刚拿到焦点),在标题屏上这会让回车打在
# “点燃余烬”上、直接进关卡,后面几张截图全废。所以这里按一下就回读一次画面:
# 选中行的内腔是锈色(R 明显大于 B),未选中是暗紫(B 大于 R),据此确认再继续。
# 几何常量必须与 scripts/ui/title_screen.gd + menu_item.gd 保持一致。
$script:MenuTop = 254
$script:MenuRowPitch = 62   # 行高 52 + VBoxContainer separation 10
$script:MenuProbeX = 820    # 行内右侧空白处,躲开居中文字与左侧光标

function Test-TitleRowSelected([IntPtr]$hWnd, [int]$Index) {
    $origin = Get-ClientOrigin $hWnd
    $bmp = Get-WindowBitmap $hWnd
    try {
        $x = $origin.X + $script:MenuProbeX
        $y = $origin.Y + $script:MenuTop + $Index * $script:MenuRowPitch + 26
        if ($x -ge $bmp.Width -or $y -ge $bmp.Height) { return $false }
        $c = $bmp.GetPixel($x, $y)
        return ($c.R - $c.B) -gt 20
    } finally { $bmp.Dispose() }
}

function Move-TitleSelection([IntPtr]$hWnd, [int]$Index, [int]$Tries = 4) {
    foreach ($i in 1..$Tries) {
        if (Test-TitleRowSelected $hWnd $Index) { return }
        Send-ArrowKey 0x28   # VK_DOWN
        Start-Sleep -Milliseconds 450
    }
    if (-not (Test-TitleRowSelected $hWnd $Index)) {
        throw "标题菜单导航失败:$Tries 次向下仍未选中第 $Index 项"
    }
}

# 存档落在 Godot 的 user:// 目录里；界面巡查要靠它决定“继续旅程”是否灰显。
function Get-SavePath {
    return Join-Path $env:APPDATA 'Godot\app_userdata\Rustgrave\rustgrave_save.cfg'
}
function Remove-Save {
    $p = Get-SavePath
    if (Test-Path $p) { Remove-Item $p -Force; Write-Host "已删除存档: $p" }
}
# has_save() 只看文件是否存在,所以占位内容足够点亮“继续旅程”给截图看。
function Write-StubSave {
    $p = Get-SavePath
    New-Item -ItemType Directory -Path (Split-Path $p) -Force | Out-Null
    Set-Content -Path $p -Value "[meta]`nversion=1`nscene=`"res://scenes/levels/Level01_Static.tscn`"`n" -Encoding UTF8
    Write-Host "已写入占位存档: $p"
}

# --- Step 0: 准备 ---
if (-not (Test-Path $GodotExe)) { Write-Host "找不到 Godot: $GodotExe"; exit 1 }
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
$projectDir = $PSScriptRoot

# 启动一局并拿到已置前台、已归位的游戏窗口;失败直接退出码 1。
function Start-Game {
    Write-Host "=== 启动游戏 ==="
    $p = Start-Process -FilePath $GodotExe -ArgumentList '--path', "`"$projectDir`"" -PassThru
    $h = [IntPtr]::Zero
    foreach ($i in 1..40) {
        Start-Sleep -Milliseconds 500
        $h = Find-GameWindow -OwnerPid $p.Id
        if ($h -ne [IntPtr]::Zero) { break }
        if ($p.HasExited) { Write-Host "游戏进程提前退出,exit=$($p.ExitCode)"; exit 1 }
    }
    if ($h -eq [IntPtr]::Zero) { Write-Host "20 秒内未找到 Rustgrave 窗口"; exit 1 }
    Write-Host ("找到窗口 HWND=0x{0:X8}" -f $h.ToInt64())
    [Win32]::ShowWindow($h, 9) | Out-Null
    Start-Sleep -Milliseconds 300
    # 挪到屏幕左上,避免窗口超出屏幕导致截图被裁。
    $rect = New-Object Win32+RECT
    [Win32]::GetWindowRect($h, [ref]$rect) | Out-Null
    [Win32]::MoveWindow($h, 10, 10, $rect.Right - $rect.Left, $rect.Bottom - $rect.Top, $true) | Out-Null
    [Win32]::SetForegroundWindow($h) | Out-Null
    Start-Sleep -Milliseconds 2000   # 等标题屏余烬/keyart 稳定
    return @{ Proc = $p; Hwnd = $h }
}

if ($Ui) { Remove-Save }

$game = Start-Game
$proc = $game.Proc
$hwnd = $game.Hwnd

try {
    # --- Step 3: 标题屏截图 ---
    Save-WindowShot $hwnd (Join-Path $OutDir '01_title.png')

    # --- Step 3b (可选): 菜单导航 + 操作说明 ---
    # 无存档时“继续旅程”灰显,向下一次会跳过它落在“操作说明”上 —— 因此
    # -Ui 一开始就删档,导航步数才是确定的。
    if ($Ui) {
        Assert-Foreground $hwnd | Out-Null
        Move-TitleSelection $hwnd 2   # 灰显的“继续旅程”会被跳过,落在“操作说明”
        Save-WindowShot $hwnd (Join-Path $OutDir '01b_menu_controls.png')
        Send-Key 0x0D        # Enter -> 打开操作说明
        Start-Sleep -Milliseconds 900
        Save-WindowShot $hwnd (Join-Path $OutDir '01c_controls.png')
        Send-Key 0x1B        # Esc -> 关面板
        Start-Sleep -Milliseconds 500
        Move-TitleSelection $hwnd 0   # 回到“点燃余烬”(向下绕一圈即可)
    }

    # --- Step 4: 按 Enter 开新游戏,等淡出 + 关卡加载 ---
    Assert-Foreground $hwnd | Out-Null
    Send-Key 0x0D    # VK_RETURN
    Start-Sleep -Milliseconds 3500
    Save-WindowShot $hwnd (Join-Path $OutDir '02_level.png')
    # 苏醒过场可跳过：Enter 快进，避免后续走位被锁。
    Send-Key 0x0D
    Start-Sleep -Milliseconds 400
    Send-Key 0x0D
    Start-Sleep -Milliseconds 600

    # --- Step 5: 向右移动 + 挥砍,截动作画面 ---
    Assert-Foreground $hwnd | Out-Null
    Press-Key 0x44                                       # D 按下
    Start-Sleep -Milliseconds 900
    Release-Key 0x44                                     # D 抬起
    Send-Key 0x4A    # J 挥砍
    Start-Sleep -Milliseconds 180                        # 命中判定帧内
    Save-WindowShot $hwnd (Join-Path $OutDir '03_action.png')

    # --- Step 5b (可选): 暂停菜单 -> 操作说明 -> 返回标题 ---
    if ($Ui) {
        Assert-Foreground $hwnd | Out-Null
        Send-Key 0x1B        # Esc -> 暂停
        Start-Sleep -Milliseconds 800
        Save-WindowShot $hwnd (Join-Path $OutDir '03b_pause.png')
        Send-ArrowKey 0x28   # 操作说明
        Start-Sleep -Milliseconds 600
        Send-Key 0x0D
        Start-Sleep -Milliseconds 900
        Save-WindowShot $hwnd (Join-Path $OutDir '03c_pause_controls.png')
        Send-Key 0x1B        # 关面板,回到暂停菜单
        Start-Sleep -Milliseconds 600
        Send-ArrowKey 0x28   # 返回标题
        Start-Sleep -Milliseconds 600
        Send-Key 0x0D
        Start-Sleep -Milliseconds 2000
        Save-WindowShot $hwnd (Join-Path $OutDir '03d_title_return.png')

        if (-not $proc.HasExited) { $proc.Kill() }
        Start-Sleep -Milliseconds 800
        # 再开一局,这次带存档,专门看“继续旅程”亮起来的样子。
        Write-StubSave
        $game2 = Start-Game
        Save-WindowShot $game2.Hwnd (Join-Path $OutDir '01d_title_continue.png')
        if (-not $game2.Proc.HasExited) { $game2.Proc.Kill() }
        Remove-Save
        Write-Host "=== 界面巡查完成,8 张截图已保存到 $OutDir ==="
        exit 0
    }

    # --- Step 6 (可选): 横穿全关,分段截图巡查右半关卡 ---
    # 跳跃模式: 先原地满高双跳(不顶墙,不浪费二段跳),到最高点才按 D 平移。
    # 注意 jump-cut: 松开 Space 会砍跳跃高度(重力x2.15),所以每跳按住 200ms
    # 保住满高,双跳合计 ~70px,足以从 48px 深的毒坑底爬出来。
    if ($Extended) {
        Assert-Foreground $hwnd | Out-Null
        Send-Key 0x0D
        Start-Sleep -Milliseconds 300
        foreach ($leg in 4..8) {
            foreach ($hop in 1..3) {
                Send-Key 0x20 200                        # Space (地面跳,满高)
                Start-Sleep -Milliseconds 30
                Send-Key 0x20 200                        # Space (二段跳,满高)
                Press-Key 0x44                           # 近最高点,空中前移
                Start-Sleep -Milliseconds 620
                Release-Key 0x44
                Start-Sleep -Milliseconds 340            # 落地稳定
            }
            Save-WindowShot $hwnd (Join-Path $OutDir ('{0:D2}_walk.png' -f $leg))
        }
        Write-Host "=== 自测完成,8 张截图已保存到 $OutDir ==="
        exit 0
    }

    Write-Host "=== 自测完成,3 张截图已保存到 $OutDir ==="
    exit 0
}
finally {
    if (-not $proc.HasExited) { $proc.Kill() }
}
