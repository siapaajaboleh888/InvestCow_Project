@echo off
title 🐄 Rebuild InvestCow APK
color 0B

echo ================================================
echo   REBUILD INVESTCOW APK
echo   Gunakan ini jika URL Cloudflare berubah!
echo ================================================
echo.

set /p NEW_URL="Masukkan URL Cloudflare yang baru (tanpa tanda kutip, pastikan diawali https://): "

if "%NEW_URL%"=="" (
    echo ❌ URL tidak boleh kosong!
    pause
    exit
)

echo.
echo Memperbarui konfigurasi backend di .env...
echo NGROK_URL=%NEW_URL% > "e:\SEMESTER 7\Flutter\investcow\backend\.env_tmp"
findstr /v "^NGROK_URL=" "e:\SEMESTER 7\Flutter\investcow\backend\.env" >> "e:\SEMESTER 7\Flutter\investcow\backend\.env_tmp"
move /y "e:\SEMESTER 7\Flutter\investcow\backend\.env_tmp" "e:\SEMESTER 7\Flutter\investcow\backend\.env" > nul

echo.
echo ⏳ Mulai melakukan build APK dengan URL: %NEW_URL%
echo Proses ini memakan waktu 5-15 menit tergantung kecepatan laptop.
echo JANGAN tutup jendela ini sebelum selesai!
echo.

cd /d "e:\SEMESTER 7\Flutter\investcow"
call flutter build apk --release --dart-define=BASE_URL=%NEW_URL%

if %errorlevel% equ 0 (
    echo.
    echo ================================================
    echo   ✅ BUILD APK BERHASIL!
    echo ================================================
    echo.
    echo   Lokasi APK Baru:
    echo   e:\SEMESTER 7\Flutter\investcow\build\app\outputs\flutter-apk\app-release.apk
    echo.
    echo   ⚠️ PENTING: Kamu HARUS mengirimkan APK BARU ini ke 40 user!
    echo   APK lama sudah tidak bisa digunakan.
    echo.
) else (
    echo.
    echo ❌ BUILD APK GAGAL!
    echo Periksa pesan error di atas. Pastikan Flutter sudah terinstall dengan benar.
)

pause
