# Build sorununu çözmek için script
Write-Host "1. İlgili işlemleri durduruyorum..." -ForegroundColor Yellow

# Tüm Flutter, Dart, Java, Gradle işlemlerini durdur
Get-Process | Where-Object {
    $_.ProcessName -match "java|dart|flutter|gradle"
} | Stop-Process -Force -ErrorAction SilentlyContinue

Start-Sleep -Seconds 3

Write-Host "2. Gradle daemon'ı durduruyorum..." -ForegroundColor Yellow
if (Test-Path "android\gradlew.bat") {
    Push-Location android
    & .\gradlew.bat --stop 2>&1 | Out-Null
    Pop-Location
    Start-Sleep -Seconds 2
}

Write-Host "3. Build klasörlerini temizliyorum..." -ForegroundColor Yellow

# Build klasörünü silmeyi dene
$buildPath = "build"
if (Test-Path $buildPath) {
    try {
        # Önce içeriği sil
        Get-ChildItem -Path $buildPath -Recurse -Force | Remove-Item -Force -Recurse -ErrorAction Stop
        Remove-Item -Path $buildPath -Force -Recurse -ErrorAction Stop
        Write-Host "Build klasörü temizlendi." -ForegroundColor Green
    } catch {
        Write-Host "UYARI: Build klasörü silinemedi: $_" -ForegroundColor Red
        Write-Host "Lütfen şu adımları deneyin:" -ForegroundColor Yellow
        Write-Host "  - Task Manager'dan tüm Java, Dart, Flutter işlemlerini sonlandırın" -ForegroundColor Cyan
        Write-Host "  - Proje klasörünü File Explorer'da kapatın" -ForegroundColor Cyan
        Write-Host "  - Bilgisayarı yeniden başlatın" -ForegroundColor Cyan
        Write-Host "  - VEYA projeyi OneDrive dışı bir klasöre taşıyın (örn: C:\Projects\)" -ForegroundColor Cyan
    }
}

Write-Host "4. Flutter paketlerini güncelliyorum..." -ForegroundColor Yellow
flutter pub get

Write-Host "`nTemizlik tamamlandı! Şimdi 'flutter run' komutunu çalıştırabilirsiniz." -ForegroundColor Green

