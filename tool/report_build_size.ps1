# Build size reporting script for Windows
# Reports APK/AAB size and validates against 100MB target

Write-Host "📊 Flutter App Build Size Report" -ForegroundColor Cyan
Write-Host ""

# Check for AAB first (preferred for Play Store)
$aabPath = "build\app\outputs\bundle\release\app-release.aab"
$apkPath = "build\app\outputs\flutter-apk\app-release.apk"

$buildFile = $null
$buildType = ""

if (Test-Path $aabPath) {
    $buildFile = Get-Item $aabPath
    $buildType = "AAB"
} elseif (Test-Path $apkPath) {
    $buildFile = Get-Item $apkPath
    $buildType = "APK"
} else {
    Write-Host "❌ No build file found. Building release..." -ForegroundColor Red
    Write-Host "   Running: flutter build appbundle --release" -ForegroundColor Yellow
    flutter build appbundle --release
    
    if (Test-Path $aabPath) {
        $buildFile = Get-Item $aabPath
        $buildType = "AAB"
    } else {
        Write-Host "❌ Build failed or file not found" -ForegroundColor Red
        exit 1
    }
}

$sizeBytes = $buildFile.Length
$sizeMB = [math]::Round($sizeBytes / 1MB, 2)
$targetMB = 100

Write-Host "📦 Build File: $($buildFile.FullName)" -ForegroundColor White
Write-Host "📏 Size: $sizeMB MB ($sizeBytes bytes)" -ForegroundColor White
Write-Host "🎯 Target: < $targetMB MB" -ForegroundColor White
Write-Host ""

if ($sizeMB -gt $targetMB) {
    $excess = [math]::Round($sizeMB - $targetMB, 2)
    Write-Host "⚠️  WARNING: Build size exceeds target by $excess MB" -ForegroundColor Red
    Write-Host ""
    Write-Host "Recommendations:" -ForegroundColor Yellow
    Write-Host "  - Verify sheet music assets are removed from pubspec.yaml" -ForegroundColor Gray
    Write-Host "  - Check font subsetting is applied" -ForegroundColor Gray
    Write-Host "  - Ensure minifyEnabled and shrinkResources are enabled" -ForegroundColor Gray
    Write-Host "  - Run: flutter build appbundle --release --analyze-size" -ForegroundColor Gray
    exit 1
} else {
    Write-Host "✅ Build size is within target (< $targetMB MB)" -ForegroundColor Green
    $remaining = [math]::Round($targetMB - $sizeMB, 2)
    Write-Host "   $remaining MB remaining" -ForegroundColor Gray
}

Write-Host ""
Write-Host "💡 For detailed size analysis, run:" -ForegroundColor Cyan
Write-Host "   flutter build appbundle --release --analyze-size" -ForegroundColor White





