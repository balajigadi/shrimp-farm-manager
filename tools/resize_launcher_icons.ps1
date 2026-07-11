param(
  [string]$src = "C:\Users\Admin\.cursor\projects\c-Projects-android-develop-prawn-farm-app\assets\c__Users_Admin_AppData_Roaming_Cursor_User_workspaceStorage_57b8f395da3b6272418d27bbf685d74d_images_PawnFarmlogo-e94dfff2-429c-488d-902c-03fd8a1ef2a8.png"
)

Add-Type -AssemblyName System.Drawing

$map = @(
  @{ dir = "mipmap-mdpi"; size = 48 },
  @{ dir = "mipmap-hdpi"; size = 72 },
  @{ dir = "mipmap-xhdpi"; size = 96 },
  @{ dir = "mipmap-xxhdpi"; size = 144 },
  @{ dir = "mipmap-xxxhdpi"; size = 192 }
)

$projectRoot = "C:\Projects\android\develop\prawn_farm_app"

$img = [System.Drawing.Image]::FromFile($src)
foreach ($m in $map) {
  $dir = $m.dir
  $size = [int]$m.size
  $target = Join-Path $projectRoot "android\app\src\main\res\$dir\ic_launcher.png"

  $bmp = New-Object System.Drawing.Bitmap $size, $size
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
  $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $g.Clear([System.Drawing.Color]::Transparent)

  $rect = New-Object System.Drawing.Rectangle(0, 0, $size, $size)
  $g.DrawImage($img, $rect)

  $bmp.Save($target, [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose()
  $bmp.Dispose()

  Write-Host ("Wrote {0} {1}x{1}" -f $target, $size)
}
$img.Dispose()

