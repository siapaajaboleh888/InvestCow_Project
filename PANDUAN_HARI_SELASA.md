# 🐄 PANDUAN HARI SELASA — InvestCow untuk 40 User

---

## ⚠️ BACA INI SEBELUM MULAI!

> Kita sekarang menggunakan **Cloudflare Tunnel** (`.trycloudflare.com`) karena domain Ngrok diblokir oleh provider internet Indonesia.
> 
> URL Backend yang aktif saat ini = `https://mumbai-rotary-hose-dentists.trycloudflare.com`
> 
> ⚠️ **PENTING:** URL ini **BERUBAH** setiap kali Cloudflare Tunnel dimatikan dan dinyalakan ulang!
> Kalau URL berubah → APK lama tidak bisa konek → harus jalankan `REBUILD_APK.bat`

---

## 🚀 URUTAN MENJALANKAN (Hari Selasa)

### 1️⃣ Nyalakan MySQL dulu
Buka XAMPP / MySQL Workbench / Laragon → Start MySQL

Verifikasi: buka browser → `http://localhost:8081/health` — kalau belum muncul, lanjut ke langkah 2 dulu

---

### 2️⃣ Jalankan `START_INVESTCOW.bat`
Cukup klik ganda (double-click) file **`START_INVESTCOW.bat`** yang ada di folder project.
Script ini akan:
- Menjalankan Backend Node.js
- Menjalankan Cloudflare Tunnel
- Menampilkan URL publik yang didapatkan

**Catat URL yang muncul di layar!** (contoh: `https://xxxx.trycloudflare.com`)

---

### 3️⃣ Cek apakah URL berubah
Bandingkan URL yang baru didapat dengan URL saat kamu terakhir build APK.
- Jika **SAMA**: Langsung lanjut ke langkah 4.
- Jika **BEDA**: Kamu harus klik ganda file **`REBUILD_APK.bat`**, masukkan URL yang baru, dan tunggu sampai APK baru selesai dibuat.

---

### 4️⃣ Bagikan APK ke User Android
File APK ada di:
```
e:\SEMESTER 7\Flutter\investcow\build\app\outputs\flutter-apk\app-release.apk
```
Baca file **`CARA_DISTRIBUTE_APK.md`** untuk panduan lengkap cara membagikannya ke 40 orang.

---

### 5️⃣ Untuk User iOS (iPhone)
User iOS tidak bisa install APK. Solusinya:
- Buka browser Safari di iPhone
- Ketik URL Cloudflare yang aktif (contoh: `https://xxxx.trycloudflare.com`)
- Aplikasi Flutter Web (jika sudah disetup) atau halaman info akan terbuka. *Pastikan untuk memberitahu user iOS bahwa ini adalah batasan platform Apple.*

---

## ✅ CHECKLIST SEBELUM USER MASUK

- [ ] MySQL berjalan ✓
- [ ] Backend jalan dan tidak error
- [ ] Jendela Cloudflare Tunnel aktif dan menampilkan link `.trycloudflare.com`
- [ ] URL di APK sudah cocok dengan URL Cloudflare yang aktif
- [ ] Laptop dicolok charger
- [ ] Mode sleep dimatikan
- [ ] Koneksi internet stabil
- [ ] Test login dari HP sendiri dulu

---

## ❌ TROUBLESHOOTING

| Masalah | Solusi |
|---|---|
| User gagal daftar / "Failed host lookup" | URL Cloudflare berubah, atau HP user tidak ada koneksi internet. Pastikan kamu sudah rebuild APK dengan URL baru. |
| "Too many requests" | Rate limit kena → tunggu 15 menit. Kita sudah set limit ke 600 req/15 menit. |
| Koneksi terputus | Cek apakah laptop masuk sleep/hibernate |
| Layar hitam di aplikasi | Hapus cache aplikasi di HP user atau install ulang APK. |

---

## 🔑 Info Penting

```
Backend Port  : 8081
Database Port : 3307  
APK Path      : build\app\outputs\flutter-apk\app-release.apk
```
