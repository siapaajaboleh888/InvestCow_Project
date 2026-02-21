# CCTV Live Streaming Architecture (InvestCow)

Sistem ini dirancang untuk monitoring sapi secara real-time dengan latency rendah menggunakan stack Flutter dan Node.js.

## 1. Arsitektur
- **Ingestion**: Kamera (atau Simulator) mengirim stream RTMP ke server.
- **Server**: `node-media-server` menerima RTMP dan melakukan transmuxing ke **HLS** secara real-time.
- **Optimization**: Setting `hls_time=1` (1 detik per segmen) digunakan untuk mencapai latency < 5 detik.
- **Frontend**: Flutter menggunakan `video_player` + `chewie` untuk memutar stream HLS.

## 2. Cara Menjalankan (Simulation Mode)

### Step 1: Backend Server
1. Masuk ke folder `backend/cctv_simulator`.
2. Jalankan `npm install` (jika belum).
3. Jalankan `node server.js`.
   - Server HLS akan tersedia di: `http://localhost:8000/live/cow1/index.m3u8`

### Step 2: Stream Simulator (FFmpeg)
1. Install FFmpeg di komputer Anda.
2. Edit file `simulate.bat`, pastikan `FFMPEG_PATH` mengarah ke file `ffmpeg.exe` Anda.
3. Jalankan `simulate.bat`.
   - Ini akan mengirim video "Test Card" dengan **JAM REAL-TIME** ke server.

### Step 3: Flutter Integration
Gunakan widget `CctvLivePlayer` yang sudah dibuat:

```dart
CctvLivePlayer(
  title: "Kandang Sapi A1",
  streamUrl: "http://localhost:8000/live/cow1/index.m3u8",
)
```

## 3. Cara Verifikasi "Live"
Pada video streaming, Anda akan melihat teks **"LIVE INVESTCOW HH:MM:SS"**. 
- Jika jam tersebut berjalan dan selisihnya dengan jam Windows Anda hanya ~2-4 detik, maka syarat latency terpenuhi.
- Jika stream berhenti, widget akan menampilkan mode "Retry".

## 4. Trade-offs & Alternatives
- **HLS**: Paling stabil, namun latency bawaan biasanya 10s+. Kita optimasi ke < 5s dengan segmentasi agresif.
- **WebRTC**: Bisa < 1s, namun implementasinya jauh lebih kompleks (membutuhkan signaling server).
- **WebSocket-FLV**: Support oleh `node-media-server`, latency sangat rendah (~1-2s), namun butuh decoder khusus di Flutter (seperti `flutter_vlc_player`).
