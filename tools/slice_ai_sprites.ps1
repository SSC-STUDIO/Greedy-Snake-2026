# Slice AI-generated sprite sheets (magenta background) into game-ready transparent PNGs.
# Usage: powershell -File tools/slice_ai_sprites.ps1
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "Stop"
$Root = "c:\Users\Administrator\OneDrive\Documents\My-Program\Rustgrave"

function Read-Pixels([string]$path) {
	$src = [System.Drawing.Bitmap]::FromFile($path)
	$bmp = New-Object System.Drawing.Bitmap($src.Width, $src.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	$g = [System.Drawing.Graphics]::FromImage($bmp)
	$g.DrawImage($src, 0, 0, $src.Width, $src.Height)
	$g.Dispose(); $src.Dispose()
	$w = $bmp.Width; $h = $bmp.Height
	$rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
	$data = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	$bytes = New-Object byte[] ($data.Stride * $h)
	[System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $bytes, 0, $bytes.Length)
	$bmp.UnlockBits($data); $bmp.Dispose()
	return @{ Bytes = $bytes; Stride = $data.Stride; W = $w; H = $h }
}

function Test-Magenta([byte[]]$b, [int]$i) {
	$bl = $b[$i]; $gr = $b[$i + 1]; $r = $b[$i + 2]
	return ($r -gt 165 -and $bl -gt 165 -and $gr -lt 125 -and [Math]::Abs($r - $bl) -lt 90)
}

function Get-BgMap([hashtable]$px) {
	$bg = New-Object bool[] ($px.W * $px.H)
	for ($y = 0; $y -lt $px.H; $y++) {
		$row = $y * $px.Stride
		for ($x = 0; $x -lt $px.W; $x++) {
			if (Test-Magenta $px.Bytes ($row + $x * 4)) { $bg[$y * $px.W + $x] = $true }
		}
	}
	return $bg
}

function Get-Bands($proj, [int]$minGap) {
	# Merge true-runs separated by gaps smaller than minGap; return @(start,end) row/col bands.
	$runs = @(); $s = -1
	for ($i = 0; $i -lt $proj.Count; $i++) {
		if ($proj[$i] -and $s -lt 0) { $s = $i }
		elseif (-not $proj[$i] -and $s -ge 0) { $runs += , @($s, ($i - 1)); $s = -1 }
	}
	if ($s -ge 0) { $runs += , @($s, $proj.Count - 1) }
	if ($runs.Count -le 1) { return $runs }
	$merged = @(, $runs[0])
	for ($k = 1; $k -lt $runs.Count; $k++) {
		$last = $merged[$merged.Count - 1]
		if (($runs[$k][0] - $last[1] - 1) -lt $minGap) { $merged[$merged.Count - 1] = @($last[0], $runs[$k][1]) }
		else { $merged += , $runs[$k] }
	}
	return $merged
}

function Save-Frame([hashtable]$px, [bool[]]$bg, [int]$x0, [int]$y0, [int]$x1, [int]$y1, [string]$outPath, [int]$targetH) {
	$w = $x1 - $x0 + 1; $h = $y1 - $y0 + 1
	if ($w -le 8 -or $h -le 8) { return $false }
	$frame = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	$rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
	$fd = $frame.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::WriteOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	$fb = New-Object byte[] ($fd.Stride * $h)
	for ($y = 0; $y -lt $h; $y++) {
		$drow = $y * $fd.Stride
		$srow = ($y0 + $y) * $px.Stride
		for ($x = 0; $x -lt $w; $x++) {
			$di = $drow + $x * 4
			if ($bg[($y0 + $y) * $px.W + ($x0 + $x)]) { continue }  # already zero (transparent)
			$si = $srow + ($x0 + $x) * 4
			$fb[$di] = $px.Bytes[$si]; $fb[$di + 1] = $px.Bytes[$si + 1]; $fb[$di + 2] = $px.Bytes[$si + 2]; $fb[$di + 3] = 255
		}
	}
	[System.Runtime.InteropServices.Marshal]::Copy($fb, 0, $fd.Scan0, $fb.Length)
	$frame.UnlockBits($fd)
	# Scale to target height (keep aspect).
	$scale = $targetH / $h
	$nw = [int][Math]::Round($w * $scale); $nh = $targetH
	if ($nw -lt 1) { $nw = 1 }
	$out = New-Object System.Drawing.Bitmap($nw, $nh, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	$og = [System.Drawing.Graphics]::FromImage($out)
	$og.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
	$og.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
	$og.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
	$og.DrawImage($frame, 0, 0, $nw, $nh)
	$og.Dispose(); $frame.Dispose()
	$out.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
	$out.Dispose()
	return $true
}

# ---------- Player sheet: 2 rows (4 walk + 3 pose), auto band detection ----------
$sheetPath = Join-Path $Root "assets\external\ai\player_sheet_v2.jpg"
$px = Read-Pixels $sheetPath
$bg = Get-BgMap $px
$rowProj = New-Object bool[] $px.H
for ($y = 0; $y -lt $px.H; $y++) {
	$occ = $false
	for ($x = 0; $x -lt $px.W; $x++) { if (-not $bg[$y * $px.W + $x]) { $occ = $true; break } }
	$rowProj[$y] = $occ
}
$rowBands = Get-Bands $rowProj 8
Write-Host ("row bands: " + ($rowBands | ForEach-Object { "{0}-{1}" -f $_[0], $_[1] }) -join ", ")

$outDir = Join-Path $Root "assets\kenney_clean\player_ai"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$namesRow1 = @("walk_a", "walk_b", "walk_c", "walk_d", "walk_e", "walk_f")
$namesRow2 = @("pose_idle", "pose_jump", "pose_hurt", "pose_extra")

$frameIdx = 0
for ($rb = 0; $rb -lt $rowBands.Count; $rb++) {
	$y0 = $rowBands[$rb][0]; $y1 = $rowBands[$rb][1]
	$colProj = New-Object bool[] $px.W
	for ($x = 0; $x -lt $px.W; $x++) {
		$occ = $false
		for ($y = $y0; $y -le $y1; $y++) { if (-not $bg[$y * $px.W + $x]) { $occ = $true; break } }
		$colProj[$x] = $occ
	}
	$colBands = Get-Bands $colProj 8
	Write-Host ("row {0} col bands: {1}" -f $rb, (($colBands | ForEach-Object { "{0}-{1}" -f $_[0], $_[1] }) -join ", "))
	$names = if ($rb -eq 0) { $namesRow1 } else { $namesRow2 }
	for ($cb = 0; $cb -lt $colBands.Count; $cb++) {
		$x0 = $colBands[$cb][0]; $x1 = $colBands[$cb][1]
		# Tight content bbox inside the cell.
		$tx0 = $x1; $tx1 = $x0; $ty0 = $y1; $ty1 = $y0
		for ($y = $y0; $y -le $y1; $y++) {
			for ($x = $x0; $x -le $x1; $x++) {
				if (-not $bg[$y * $px.W + $x]) {
					if ($x -lt $tx0) { $tx0 = $x }; if ($x -gt $tx1) { $tx1 = $x }
					if ($y -lt $ty0) { $ty0 = $y }; if ($y -gt $ty1) { $ty1 = $y }
				}
			}
		}
		$name = if ($cb -lt $names.Count) { $names[$cb] } else { "extra_r{0}_c{1}" -f $rb, $cb }
		$outPath = Join-Path $outDir ("knight_{0}.png" -f $name)
		$ok = Save-Frame $px $bg $tx0 $ty0 $tx1 $ty1 $outPath 96
		Write-Host ("  frame {0}: cell {1}-{2} content {3},{4}-{5},{6} -> {7} ok={8}" -f $name, $x0, $x1, $tx0, $ty0, $tx1, $ty1, (Split-Path $outPath -Leaf), $ok)
		$frameIdx++
	}
}

# ---------- Enemies: single sprite each ----------
$enemies = @(
	@{ Src = "assets\external\ai\enemy_spitter.jpg"; Out = "assets\kenney_clean\enemies_ai\spitter.png"; H = 64 },
	@{ Src = "assets\external\ai\enemy_scrapper_v2.jpg"; Out = "assets\kenney_clean\enemies_ai\scrapper.png"; H = 56 }
)
foreach ($e in $enemies) {
	$px = Read-Pixels (Join-Path $Root $e.Src)
	$bg = Get-BgMap $px
	$tx0 = $px.W; $tx1 = 0; $ty0 = $px.H; $ty1 = 0
	for ($y = 0; $y -lt $px.H; $y++) {
		for ($x = 0; $x -lt $px.W; $x++) {
			if (-not $bg[$y * $px.W + $x]) {
				if ($x -lt $tx0) { $tx0 = $x }; if ($x -gt $tx1) { $tx1 = $x }
				if ($y -lt $ty0) { $ty0 = $y }; if ($y -gt $ty1) { $ty1 = $y }
			}
		}
	}
	$outDir2 = Split-Path (Join-Path $Root $e.Out) -Parent
	New-Item -ItemType Directory -Force -Path $outDir2 | Out-Null
	$ok = Save-Frame $px $bg $tx0 $ty0 $tx1 $ty1 (Join-Path $Root $e.Out) $e.H
	Write-Host ("enemy {0}: content {1},{2}-{3},{4} ok={5}" -f $e.Out, $tx0, $ty0, $tx1, $ty1, $ok)
}

# ---------- Title keyart: just copy as PNG (no keying) ----------
$titleSrc = Join-Path $Root "assets\external\ai\title_keyart_v2.jpg"
$titleOut = Join-Path $Root "assets\kenney_clean\backgrounds\title_keyart.png"
$timg = [System.Drawing.Bitmap]::FromFile($titleSrc)
$timg.Save($titleOut, [System.Drawing.Imaging.ImageFormat]::Png)
$timg.Dispose()
Write-Host "title keyart saved"
Write-Host "DONE"
