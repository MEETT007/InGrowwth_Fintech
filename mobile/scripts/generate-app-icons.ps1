param()

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$mobileRoot = Split-Path $PSScriptRoot -Parent
$sourcePath = Join-Path $mobileRoot 'assets/branding/homeease-ai-icon-blue-glass-transparent-v3.png'
$source = [System.Drawing.Image]::FromFile($sourcePath)

function Save-Icon([string]$Path, [int]$Size, [double]$Fill, [bool]$Transparent) {
    $bitmap = [System.Drawing.Bitmap]::new($Size, $Size)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        if ($Transparent) { $graphics.Clear([System.Drawing.Color]::Transparent) }
        else { $graphics.Clear([System.Drawing.Color]::White) }
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $width = [int][Math]::Round($Size * $Fill)
        $height = [int][Math]::Round($width * $source.Height / $source.Width)
        $graphics.DrawImage($source, [int](($Size - $width) / 2), [int](($Size - $height) / 2), $width, $height)
        [System.IO.Directory]::CreateDirectory((Split-Path $Path -Parent)) | Out-Null
        $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally { $graphics.Dispose(); $bitmap.Dispose() }
}

try {
    $res = Join-Path $mobileRoot 'android/app/src/main/res'
    $densities = @{ mdpi = 1; hdpi = 1.5; xhdpi = 2; xxhdpi = 3; xxxhdpi = 4 }
    foreach ($entry in $densities.GetEnumerator()) {
        Save-Icon (Join-Path $res "mipmap-$($entry.Key)/ic_launcher.png") ([int](48 * $entry.Value)) 0.84 $false
        # Adaptive foreground has a larger canvas, leaving room for launcher masks and motion.
        Save-Icon (Join-Path $res "mipmap-$($entry.Key)/ic_launcher_foreground.png") ([int](108 * $entry.Value)) 0.60 $true
    }
    $ios = Join-Path $mobileRoot 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    $contents = Get-Content (Join-Path $ios 'Contents.json') -Raw | ConvertFrom-Json
    foreach ($entry in $contents.images) {
        $points = [double](($entry.size -split 'x')[0])
        $scale = [double]($entry.scale.TrimEnd('x'))
        Save-Icon (Join-Path $ios $entry.filename) ([int]($points * $scale)) 0.84 $false
    }
}
finally { $source.Dispose() }
Write-Output 'Generated Android legacy/adaptive and iOS launcher icons.'
