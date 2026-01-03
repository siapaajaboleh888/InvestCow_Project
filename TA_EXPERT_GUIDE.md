# Panduan Teknis Luar Biasa: InvestCow (Expert Level)

Dokumen ini disusun untuk memperkuat narasi Tugas Akhir (TA) kamu dari sisi teknis profesional. Gunakan poin-point ini dalam naskah TA atau saat presentasi di depan penguji.

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
