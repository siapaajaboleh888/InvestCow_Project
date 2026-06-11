# 📱 CARA DISTRIBUSI APK KE 40 USER

Berikut adalah beberapa cara termudah untuk mengirimkan file aplikasi InvestCow (`app-release.apk`) yang besarnya sekitar 87MB kepada 40 orang pengguna secara bersamaan.

Lokasi file APK di laptopmu:
`E:\SEMESTER 7\Flutter\investcow\build\app\outputs\flutter-apk\app-release.apk`

---

## Pilihan 1: Menggunakan Google Drive (Paling Direkomendasikan) 🌟
Ini adalah cara terbaik dan paling rapi untuk 40 orang.

1. Buka browser di laptop dan masuk ke **Google Drive** kamu (drive.google.com).
2. Klik tombol **New (Baru) -> File Upload (Upload File)**.
3. Cari file `app-release.apk` di folder `E:\SEMESTER 7\Flutter\investcow\build\app\outputs\flutter-apk\` lalu klik Open.
4. Tunggu sampai proses upload selesai (87MB).
5. Setelah selesai, klik kanan pada file yang sudah diupload di Google Drive, lalu pilih **Share (Bagikan)**.
6. Di bagian *General access (Akses umum)*, ubah dari *Restricted (Dibatasi)* menjadi **Anyone with the link (Siapa saja yang memiliki link)**.
7. Klik tombol **Copy link (Salin link)**.
8. Bagikan link tersebut ke grup WhatsApp kelas/teman-temanmu.
9. **Instruksi untuk temanmu:** Mereka tinggal klik link itu, pilih "Download", dan install di HP mereka.

---

## Pilihan 2: Menggunakan WhatsApp Web (Paling Praktis) 💬
Cara ini paling cepat jika semua user ada di satu grup WhatsApp, namun menguras kuota teman yang mendownload langsung dari WA.

1. Buka **WhatsApp Web** atau aplikasi WhatsApp di laptopmu.
2. Buka Grup chat yang berisi 40 user tersebut.
3. Klik tombol penjepit kertas (Attach) -> pilih **Document (Dokumen)**.
4. Cari dan pilih file `app-release.apk` di laptopmu.
5. Kirim.
6. **Instruksi untuk temanmu:** Mereka tinggal klik file APK tersebut di dalam chat WhatsApp, tunggu proses download selesai, lalu klik lagi untuk menginstall.

---

## Pilihan 3: Menggunakan Kabel USB (Flashdisk / Manual) 🔌
Hanya direkomendasikan jika tidak ada internet sama sekali, karena cukup memakan waktu untuk 40 orang.

1. Colokkan HP temanmu atau sebuah Flashdisk ke laptop.
2. Copy file `app-release.apk`.
3. Paste ke dalam folder Download di HP/Flashdisk tersebut.
4. Ulangi untuk semua HP.

---

## ⚠️ MASALAH YANG SERING MUNCUL SAAT INSTALL (TROUBLESHOOTING)

Saat teman-temanmu mencoba menginstall APK, mereka mungkin akan menemui beberapa hambatan keamanan dari Android. Berikut cara mengatasinya:

### 1. Pesan: "Instal aplikasi dari sumber tidak dikenal" (Unknown Sources)
Android secara bawaan melarang instalasi aplikasi di luar Play Store.
**Solusi untuk temanmu:**
- Saat muncul peringatan, klik **Settings / Pengaturan**.
- Aktifkan / geser tombol **"Allow from this source" (Izinkan dari sumber ini)** untuk browser atau WhatsApp (tergantung mereka download dari mana).
- Tekan tombol kembali (Back), lalu klik **Install**.

### 2. Peringatan Play Protect: "Unsafe App Blocked"
Karena aplikasi kita belum didaftarkan resmi ke Google Play Store, Google Play Protect mungkin memblokirnya.
**Solusi untuk temanmu:**
- Pada peringatan berwarna merah, klik tulisan **"More details" (Detail selengkapnya)** atau tanda panah ke bawah.
- Lalu klik tombol **"Install anyway" (Tetap install)**.

### 3. "App not installed" (Aplikasi tidak terinstal)
Biasanya karena memori HP penuh atau ada versi lama aplikasi yang bentrok.
**Solusi untuk temanmu:**
- Pastikan memori penyimpanan HP masih cukup (minimal kosong 300MB).
- Pastikan temanmu sudah **MENGHAPUS** aplikasi InvestCow versi lama (jika sebelumnya sudah pernah install).
- Pastikan versi OS Android temanmu minimal sesuai dengan requirement Flutter (biasanya Android 5.0 Lollipop ke atas).

---

## 🍏 CATATAN KHUSUS UNTUK PENGGUNA iOS (IPHONE / IPAD)

Aplikasi berformat `.apk` **TIDAK BISA** diinstall di perangkat Apple.
- Jika aplikasimu mendukung Flutter Web, bagikan URL Cloudflare Tunnel langsung ke teman yang menggunakan iPhone.
- Contoh: Beritahu mereka untuk membuka Safari dan mengetik `https://mumbai-rotary-hose-dentists.trycloudflare.com` (Ganti dengan URL yang aktif di hari H).
- Jika aplikasimu murni hanya Mobile (tanpa build Web), maka sayangnya pengguna iPhone tidak bisa mencoba aplikasi ini tanpa meminjam HP Android teman lain.
