# Panduan Teknis & Strategi Sukses TA: InvestCow (Expert Level)

## 0. Master Prompt (Mega-Prompt untuk Konsultasi AI)
*Salin prompt di bawah ini ke AI (seperti Gemini atau ChatGPT) untuk menjadikannya ahli pendampingmu:*

> "Bertindaklah sebagai seorang Dosen Pembimbing Senior sekaligus Research Consultant yang sangat ahli dalam metodologi penelitian S1. Tugasmu adalah membantuku menyusun proposal Tugas Akhir (TA) yang brilian secara akademik namun tetap membumi.
>
> **Ikuti aturan ketat ini dalam setiap jawabanmu:**
>
> 1. **Gaya Bahasa Non-AI:** Hindari kata-kata klise AI seperti 'Tentu, ini adalah...', 'Penting untuk diingat...', atau kesimpulan yang terlalu formal dan repetitif. Gunakan bahasa Indonesia yang mengalir, natural, dan persuasif seperti seorang pakar yang sedang mengobrol dengan mahasiswanya.
> 2. **Level Pemahaman S1:** Meskipun kamu ahli, jelaskan konsep yang rumit (seperti algoritma, framework, atau metodologi) dengan bahasa yang sangat mudah dicerna. Gunakan analogi jika diperlukan agar logika penelitiannya mudah dipahami saat disidangkan.
> 3. **Anti-Plagiasi (Orisinalitas):** Jangan memberikan jawaban template. Olah setiap kalimat secara unik. Fokuslah pada keterkaitan (benang merah) antara masalah, tujuan, dan metode yang spesifik untuk judulku. Gunakan struktur kalimat yang variatif agar lolos cek Turnitin di bawah 20%.
> 4. **Berpikir Kritis:** Jangan hanya mengiyakan ideku. Jika ada logika penelitian yang bolong atau judul yang terlalu luas, berikan kritik membangun dan saran perbaikan yang konkret.
> 5. **Struktur Penulisan:** Pastikan setiap bagian (Latar Belakang, Rumusan Masalah, Metodologi) memiliki argumen yang kuat dan didukung oleh logika riset yang sistematis."

---

## 1. Judul Resmi & Filosofi Penamaan
**Judul:** "InvestCow: Rancang Bangun Smart Platform Crowdfunding Investasi Ternak Sapi Berbasis Mobile dengan Metodologi DevOps dan Real-Time Price Monitoring Engine"

**Rasional Pemilihan Istilah (Untuk Jawaban Sidang):**
1.  **Metodologi DevOps:** Dipilih sebagai pengganti istilah "Framework DevOps" karena DevOps secara fundamental adalah kombinasi filosofi, budaya, dan metodologi kerja, bukan sekadar library atau framework coding. Hal ini menunjukkan pemahaman mendalam kamu tentang SDLC (*Software Development Life Cycle*).
2.  **Tanpa Menyebut "Flutter":** Dalam penulisan ilmiah profesional, judul berfokus pada *solusi* dan *metode*, bukan tools spesifik. Flutter tetap menjadi teknologi utama yang dijelaskan secara mendalam di Bab 3 dan Bab 4 sebagai implementasi dari platform "Berbasis Mobile".
3.  **Smart Platform:** Menandakan adanya logika cerdas dalam sistem, dalam hal ini diwakili oleh *Real-Time Price Monitoring Engine* yang mensimulasikan pertumbuhan nilai aset secara logis.

---

## 1. Integritas Data & Transparansi (Algoritma Penentuan Harga)

**Pernyataan Masalah:** Bagaimana kita menjamin harga investasi itu "jujur" dan bukan sekadar angka acak?

**Solusi Expert:**
Aplikasi InvestCow menggunakan **Algoritma Asset-Backed Pricing**. Harga yang muncul di aplikasi bukan hasil *random walk* murni, melainkan kalkulasi dari aset fisik:
- **Pertumbuhan Fisik:** Sapi disimulasikan tumbuh secara real-time berdasarkan `daily_growth_rate`. Pertumbuhan ini dipengaruhi oleh `health_score` (Skor Kesehatan) yang diinput dari data lapangan.
- **Harga Pasar Komoditas:** Kita menggunakan variabel `price_per_kg` (Harga per Kg karkas) yang berfluktuasi mengikuti sentimen pasar global/nasional.
- **Rumus Utama:** `Harga_Aset = Berat_Sapi(kg) * Harga_Pasar(Rp/kg)`

**Manfaat untuk TA:** Kamu menunjukkan bahwa sistem kamu memiliki *Business Logic* yang kuat dan terintegrasi antara kondisi fisik aset dengan nilai finansialnya.

---

## 2. Keamanan Tingkat Tinggi (Security Architecture)

**Pernyataan Masalah:** Bagaimana mengamankan transaksi uang dan data investor?

**Solusi Expert:**
Aplikasi ini sudah mengadopsi standar industri perbankan modern:
- **Stateless Authentication (JWT):** Menggunakan *JSON Web Token* dengan masa berlaku yang diatur. Token disimpan dengan aman dan dikirim melalui header `Authorization: Bearer`.
- **Encryption & Hashing:** Password tidak pernah disimpan dalam bentuk teks biasa. Kita menggunakan **bcrypt** dengan *salt rounds* tingkat tinggi (12) untuk mencegah *brute force* dan *rainbow table attacks*.
- **Protection Headers (Helmet.js):** Backend menggunakan middleware `helmet` untuk mengamankan aplikasi Node.js dari celah keamanan HTTP umum seperti *Clickjacking, XSS, dan MIME sniffing*.
- **Role-Based Access Control (RBAC):** Memisahkan secara ketat hak akses antara 'User' (Investor) dan 'Admin' menggunakan middleware khusus di backend.

---

## 3. Analisis Skalabilitas (Scalability Analysis)

**Pernyataan Masalah:** Jika user naik menjadi 10.000+, apakah server akan meledak?

**Jawaban Teoretis (Untuk Sidang TA):**
Meskipun saat ini berjalan di satu server, arsitektur InvestCow dirancang untuk dapat dikembangkan ke skala besar (*Horizontal Scaling*):
1. **WebSocket Optimization (Socket.io):**
   - Di masa depan, kita bisa menggunakan **Redis Adapter**. Sehingga jika kita punya 10 server Node.js, pesan yang dikirim dari satu server akan disiarkan ke 10.000 user di server manapun melalui mekanisme *Pub/Sub Redis*.
2. **Database Performance:**
   - Tabel `product_prices` menggunakan Indexing pada `product_id` dan `timestamp`. Untuk 10.000 user, kita bisa menerapkan *Database Replication* (Satu Master untuk Write, beberapa Slave untuk Read).
3. **Load Balancing:**
   - Menggunakan Nginx sebagai *Reverse Proxy* dan *Load Balancer* untuk mendistribusikan trafik ke beberapa instance aplikasi.
4. **Caching Layer:**
   - Implementasi Redis untuk menyimpan harga terbaru (`last_price`) sehingga tidak perlu selalu melakukan query `SELECT` ke database MySQL yang berat setiap 15 detik.

---

### Kesimpulan untuk Penguji:
InvestCow bukan sekadar aplikasi "pajangan". Dengan integrasi **Physical-linked Pricing**, **JWT Security**, dan **Scalable Design**, proyek ini layak mendapatkan predikat **Sangat Baik** karena mempertimbangkan aspek realitas industri pengembangan perangkat lunak modern.
