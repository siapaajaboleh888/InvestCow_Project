# 🚀 PANDUAN DEPLOY INVESTCOW KE RENDER.COM

## Status Otomatis (Sudah Selesai oleh AI)
- ✅ `render.yaml` sudah dibuat
- ✅ `backend/Procfile` sudah dibuat
- ✅ `backend/src/db.js` diupdate (support SSL, cloud DB)
- ✅ Database diexport → `backend/InvestCow_Final_DB_Ready.sql`
- ✅ Semua kode sudah di-push ke GitHub

---

## LANGKAH 1: Setup Database Cloud (FreeSQLDatabase.com)

> ⏱️ Waktu: ~10 menit

1. Buka browser → https://www.freesqldatabase.com/
2. Klik **"Sign Up for Free"**
3. Isi form → Klik **"Create Free Database"**
4. Catat credentials yang diberikan:
   ```
   Host:     sql.freesqldatabase.com
   Database: [nama database kamu]
   Username: [username kamu]
   Password: [password kamu]
   Port:     3306
   ```
5. Buka link phpMyAdmin yang diberikan
6. Login dengan credentials di atas
7. Klik nama database kamu di sidebar kiri
8. Klik tab **"SQL"** di bagian atas
9. Buka file: `E:\SEMESTER 7\Flutter\investcow\backend\InvestCow_Final_DB_Ready.sql`
10. Copy seluruh isinya → Paste ke kotak SQL di phpMyAdmin
11. Klik **"Go"** / **"Execute"**
12. Tunggu hingga selesai → semua tabel akan terbuat

---

## LANGKAH 2: Deploy Backend ke Render

> ⏱️ Waktu: ~10 menit

1. Buka browser → https://render.com
2. Klik **"Get Started for Free"** → Daftar dengan GitHub
3. Setelah login, klik **"New +"** → **"Web Service"**
4. Klik **"Connect a Repository"**
5. Pilih repo **"InvestCow_Project"** → Klik **"Connect"**
6. Isi form seperti ini:

   | Field | Nilai |
   |---|---|
   | Name | `investcow-backend` |
   | Region | Singapore (paling dekat) |
   | Branch | `main` |
   | Root Directory | `backend` |
   | Runtime | `Node` |
   | Build Command | `npm install` |
   | Start Command | `npm start` |
   | Instance Type | **Free** |

7. Scroll ke bawah → **"Environment Variables"** → Klik **"Add Environment Variable"**
   Tambahkan satu per satu:

   | Key | Value |
   |---|---|
   | `NODE_ENV` | `production` |
   | `JWT_SECRET` | `InvestCow2026!xK9#mP2$qR7&vL4nW8@jT5sDfGhYuZaEbCiOp3` |
   | `DB_HOST` | `sql.freesqldatabase.com` |
   | `DB_PORT` | `3306` |
   | `DB_USER` | [username dari FreeSQLDatabase] |
   | `DB_PASSWORD` | [password dari FreeSQLDatabase] |
   | `DB_NAME` | [nama database dari FreeSQLDatabase] |
   | `DB_USE_SSL` | `false` |
   | `ALLOWED_ORIGINS` | `*` |

8. Klik **"Create Web Service"**
9. Tunggu build selesai (~3-5 menit)
10. Catat URL yang diberikan Render, contoh:
    ```
    https://investcow-backend.onrender.com
    ```

---

## LANGKAH 3: Setup NGROK_URL di Render

Setelah dapat URL Render:
1. Di dashboard Render → klik service kamu
2. Klik **"Environment"** di sidebar
3. Tambahkan/update variable:
   ```
   NGROK_URL = https://investcow-backend.onrender.com
   ```
4. Klik **"Save Changes"** → Render akan auto-redeploy

---

## LANGKAH 4: Test Backend di Internet

Buka browser → akses URL ini:
```
https://investcow-backend.onrender.com/health
```
Harus tampil JSON seperti:
```json
{"status": "ok", "uptime": 123, ...}
```

---

## LANGKAH 5: Setup UptimeRobot (Anti-Sleep)

> Render free tier tidur setelah 15 menit tidak ada request

1. Buka browser → https://uptimerobot.com
2. Daftar gratis → Login
3. Klik **"Add New Monitor"**
4. Isi:
   - Monitor Type: **HTTP(s)**
   - Friendly Name: **InvestCow Backend**
   - URL: `https://investcow-backend.onrender.com/health`
   - Monitoring Interval: **5 minutes**
5. Klik **"Create Monitor"**

Sekarang server tidak akan pernah tidur! ✅

---

## LANGKAH 6: Build APK Final (URL Permanen)

Setelah semua berjalan, jalankan `REBUILD_APK.bat` di folder InvestCow:
```
URL yang dimasukkan: https://investcow-backend.onrender.com
```

Atau jalankan perintah ini:
```bat
flutter build apk --release --dart-define=BASE_URL=https://investcow-backend.onrender.com
```

APK final ada di:
```
E:\SEMESTER 7\Flutter\investcow\build\app\outputs\flutter-apk\app-release.apk
```

---

## ✅ Setelah Selesai

- APK ini bisa disebarkan ke semua HP
- Tidak perlu rebuild lagi (URL sudah permanen)
- Tidak perlu laptop menyala
- Backend online 24/7 gratis!
