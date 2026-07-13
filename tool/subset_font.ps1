# Font subsetting script for NotoSansEthiopic (PowerShell)
# Requires pyftsubset from fonttools: pip install fonttools

$fontInput = "assets\fonts\NotoSansEthiopic-Regular.ttf"
$fontOutput = "assets\fonts\NotoSansEthiopic-Regular-subset.ttf"

Write-Host "Subsetting NotoSansEthiopic font..." -ForegroundColor Cyan

# Check if pyftsubset is available
$pyftsubset = Get-Command pyftsubset -ErrorAction SilentlyContinue
if (-not $pyftsubset) {
    Write-Host "❌ pyftsubset not found. Install fonttools:" -ForegroundColor Red
    Write-Host "   pip install fonttools" -ForegroundColor Yellow
    exit 1
}

# Subset to include only:
# - Amharic Unicode range: U+1200-U+137F
# - Latin (basic): U+0020-U+007F
# - Numbers: U+0030-U+0039
pyftsubset $fontInput `
  --output-file=$fontOutput `
  --unicodes="U+0020-007F,U+0030-0039,U+1200-137F" `
  --layout-features="*" `
  --flavor="woff2"

if ($LASTEXITCODE -eq 0) {
    $originalSize = (Get-Item $fontInput).Length / 1KB
    $subsetSize = (Get-Item $fontOutput).Length / 1KB
    $reduction = [math]::Round((1 - ($subsetSize / $originalSize)) * 100, 1)
    
    Write-Host "✅ Font subsetted successfully" -ForegroundColor Green
    Write-Host "   Original: $([math]::Round($originalSize, 2)) KB" -ForegroundColor Gray
    Write-Host "   Subset: $([math]::Round($subsetSize, 2)) KB" -ForegroundColor Gray
    Write-Host "   Reduction: $reduction%" -ForegroundColor Gray
    Write-Host ""
    Write-Host "⚠️  Remember to update pubspec.yaml to use the subset font" -ForegroundColor Yellow
} else {
    Write-Host "❌ Font subsetting failed" -ForegroundColor Red
    exit 1
}





