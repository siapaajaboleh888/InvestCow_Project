# InvestCow: Smart Platform Crowdfunding Investasi Ternak Sapi

InvestCow adalah platform investasi ternak sapi berbasis mobile yang mengintegrasikan transparansi data fisik dengan sistem finansial menggunakan **Metodologi DevOps** dan **Real-Time Price Monitoring Engine**.

## 🚀 Implementasi DevOps (Academic Standards)
Proyek ini dibangun menggunakan siklus pengembangan modern (DevOps Lifecycle) sesuai dengan narasi pada Tugas Akhir:

1. **Phase 1: Planning** - Perancangan backlog fitur untuk mengatasi masalah transparansi harga pasar.
2. **Phase 2: Code & Build** - Frontend menggunakan Flutter, Backend menggunakan Node.js dengan arsitektur terelevasi.
3. **Phase 3: Continuous Integration (CI)** - Menggunakan GitHub Actions untuk automated build checks (Lihat `.github/workflows/`).
4. **Phase 4: Continuous Testing** - Implementasi Automated QA via `npm run devops-qa` pada backend untuk validasi algoritma harga.
5. **Phase 5: Monitoring** - Real-time Price Engine terintegrasi dengan Socket.io untuk pemantauan fluktuasi harga aset secara persisten.

## 🛠️ Tech Stack
- **Mobile:** Flutter (Dart)
- **Backend:** Node.js, Express, Socket.io
- **Security:** Helmet.js, JWT Stateless Auth, Bcrypt Hashing
- **Database:** MariaDB/MySQL (Asset-Backed Pricing Architecture)

## 🏗️ Cara Menjalankan (Development)

### Backend
1. Masuk ke folder `backend/`
2. Install dependencies: `npm install`
3. Jalankan Automated QA: `npm run devops-qa`
4. Jalankan Server: `npm run dev`

### Frontend (App)
1. Jalankan `flutter pub get`
2. Hubungkan device/emulator
3. Jalankan `flutter run`

---
*Proyek ini merupakan bagian dari penelitian Tugas Akhir mengenai Rancang Bangun Platform Fintech berbasis DevOps.*
