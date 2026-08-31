# slice_ai_sprites.ps1 — AI 标题画转 PNG。
# 历史注记：本脚本曾负责从 AI 生成图切玩家/敌人角色帧；角色美术已全面换成
# 像素帧动画（assets/characters/，见 docs/character_art_plan.md），相关切图
# 段落与源图（player_sheet*/enemy_*）已删除。现仅保留标题画 keyart 的转换。
# 用法:  powershell -ExecutionPolicy Bypass -File tools\slice_ai_sprites.ps1

param(
	[string]$Root = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

# ---------- Title keyart: just copy as PNG (no keying) ----------
$titleSrc = Join-Path $Root "assets\external\ai\title_keyart_v2.jpg"
$titleOut = Join-Path $Root "assets\kenney_clean\backgrounds\title_keyart.png"
$timg = [System.Drawing.Bitmap]::FromFile($titleSrc)
$timg.Save($titleOut, [System.Drawing.Imaging.ImageFormat]::Png)
$timg.Dispose()
Write-Host "title keyart saved"
Write-Host "DONE"
