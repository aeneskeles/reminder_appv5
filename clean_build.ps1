# Build temizleme scripti
Write-Host "Flutter ve Gradle işlemlerini durduruyorum..." -ForegroundColor Yellow

# Flutter işlemlerini durdur
Get-Process | Where-Object {$_.ProcessName -like "*dart*" -or $_.ProcessName -like "*flutter*"} | Stop-Process -Force -ErrorAction SilentlyContinue

Start-Sleep -Seconds 2

Write-Host "Build klasörlerini temizliyorum..." -ForegroundColor Yellow

# Build klasörlerini sil
$folders = @("build", ".dart_tool")
foreach ($folder in $folders) {
    if (Test-Path $folder) {
        Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
        if (Test-Path $folder) {
            Write-Host "UYARI: $folder klasörü silinemedi. Lütfen manuel olarak silin veya kullanan programları kapatın." -ForegroundColor Red
        } else {
            Write-Host "$folder temizlendi." -ForegroundColor Green
        }
    }
}

Write-Host "Temizlik tamamlandı!" -ForegroundColor Green
Write-Host "Şimdi 'flutter pub get' ve ardından 'flutter run' komutunu çalıştırabilirsiniz." -ForegroundColor Cyan

