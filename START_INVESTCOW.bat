@echo off
title 🐄 InvestCow Server - Jangan Ditutup!
color 0A

echo ================================================
echo   INVESTCOW SERVER - STARTUP SCRIPT
echo   Jangan tutup jendela ini selama demo berlangsung!
echo ================================================
echo.

:: ============================================================
:: LANGKAH 1: Cek MySQL
:: ============================================================
echo [1/4] Mengecek MySQL...
sc query MySQL80 > nul 2>&1
if %errorlevel% equ 0 (
    echo     ✅ MySQL80 berjalan
    goto mysql_ok
)
sc query MySQL > nul 2>&1
if %errorlevel% equ 0 (
    echo     ✅ MySQL berjalan
    goto mysql_ok
)
sc query mysql > nul 2>&1
if %errorlevel% equ 0 (
    echo     ✅ MySQL berjalan
    goto mysql_ok
)

echo     ⚠️  MySQL tidak terdeteksi otomatis.
echo     Pastikan MySQL sudah berjalan di port 3307.
echo     Buka MySQL Workbench atau XAMPP/WAMP dan nyalakan MySQL dulu!
echo.
pause

:mysql_ok
echo.

:: ============================================================
:: LANGKAH 2: Jalankan Backend Node.js
:: ============================================================
echo [2/4] Menjalankan Backend InvestCow (port 8081)...
start "🐄 InvestCow Backend (JANGAN TUTUP)" cmd /k "cd /d ""%~dp0backend"" && echo Backend InvestCow starting... && npm start"

echo     ✅ Backend sedang startup di jendela baru...
echo     Tunggu 5 detik...
timeout /t 5 /nobreak > nul
echo.

:: ============================================================
:: LANGKAH 3: Jalankan Cloudflare Tunnel
:: ============================================================
echo [3/4] Menjalankan Cloudflare Tunnel...
echo.

set "CF_EXE=C:\Program Files (x86)\cloudflared\cloudflared.exe"
if not exist "%CF_EXE%" (
    set "CF_EXE=C:\Program Files\cloudflared\cloudflared.exe"
)

if not exist "%CF_EXE%" (
    echo ❌ Cloudflared tidak ditemukan. Pastikan sudah diinstall.
    pause
    exit
)

:: Hapus file log lama jika ada
if exist "%TEMP%\cloudflared_investcow.log" del "%TEMP%\cloudflared_investcow.log"

:: Jalankan cloudflared di background dan simpan output ke log
start "🌐 Cloudflare Tunnel (JANGAN TUTUP)" cmd /k """%CF_EXE%"" tunnel --url http://localhost:8081 > ""%TEMP%\cloudflared_investcow.log"" 2>&1"

echo     ✅ Cloudflare tunnel aktif di jendela baru...
echo     Tunggu 10 detik untuk mendapatkan URL...
timeout /t 10 /nobreak > nul
echo.

:: Cari URL trycloudflare.com di file log
set "CF_URL="
for /f "tokens=*" %%a in ('findstr "trycloudflare.com" "%TEMP%\cloudflared_investcow.log"') do (
    set "LINE=%%a"
    for %%b in (%%a) do (
        echo %%b | findstr "trycloudflare.com" > nul
        if not errorlevel 1 set "CF_URL=%%b"
    )
)

echo.
:: ============================================================
:: LANGKAH 4: Tampilkan Info
:: ============================================================
echo [4/4] ✅ SEMUA SISTEM AKTIF!
echo.
echo ================================================
echo   🐄 InvestCow SIAP DIGUNAKAN!
echo ================================================
echo.
if "%CF_URL%"=="" (
    echo   ⚠️  Tidak dapat menemukan URL Cloudflare di log secara otomatis.
    echo   Silakan lihat jendela "Cloudflare Tunnel" untuk mencari URL yang berakhiran trycloudflare.com
) else (
    echo   🌐 URL Backend (untuk APK):
    echo      %CF_URL%
    echo.
    echo   ⚠️  PENTING: Jika URL di atas berbeda dengan saat kamu build APK,
    echo      jalankan REBUILD_APK.bat untuk membuat APK baru dengan URL ini!
)
echo.
echo   📱 Cara bagikan ke 40 user:
echo      Kirim file APK via WhatsApp/Drive (lihat CARA_DISTRIBUTE_APK.md)
echo      APK ada di: build\app\outputs\flutter-apk\app-release.apk
echo.
echo   ⚠️  JANGAN TUTUP:
echo      - Jendela "InvestCow Backend"
echo      - Jendela "Cloudflare Tunnel"
echo      - Laptop tetap menyala + colok charger
echo.
echo ================================================
echo.
pause
