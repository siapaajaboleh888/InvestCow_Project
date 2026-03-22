@echo off
echo.
echo [INFO] Mengaktifkan ADB Reverse Port 8081...
echo ----------------------------------------------------

:: Gunakan loop sederhana dan hapus tanda petik ID
for /f "tokens=1" %%i in ('adb devices ^| findstr /v "List" ^| findstr "device"') do (
    echo [PROSES] Menghubungkan ke Perangkat ID: %%i
    adb -s %%i reverse tcp:8081 tcp:8081
)

echo.
echo [NOTE] Jika masih muncul error IP 192.168.1.10 di HP:
echo 1. HAPUS (Uninstall) aplikasi InvestCow di HP Android kamu.
echo 2. Jalankan perintah: flutter clean
echo 3. Jalankan kembali: flutter run
pause
