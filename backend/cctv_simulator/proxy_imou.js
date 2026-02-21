const { spawn } = require('child_process');
const ffmpeg = require('@ffmpeg-installer/ffmpeg');

const ffmpegPath = ffmpeg.path;

// --- SILAKAN CEK IP KAMERA ANDA DI APLIKASI IMOU LIFE ---
const cameraIP = '192.168.1.10'; // GANTI INI DENGAN IP DARI HP ANDA
const safetyCode = 'L2F40E55';
const rtspUrl = `rtsp://admin:${safetyCode}@${cameraIP}:554/cam/realmonitor?channel=1&subtype=0`;

const targetUrl = 'rtmp://localhost/live/imou';

console.log('--- InvestCow CCTV Proxy (Verbose Mode) ---');
console.log('Source URL: ' + rtspUrl);
console.log('Target URL: ' + targetUrl);
console.log('\n--- MENCARI SINYAL KAMERA (FFMPEG LOG) ---');

const args = [
    '-rtsp_transport', 'tcp',
    '-i', rtspUrl,
    '-c:v', 'copy',
    '-c:a', 'aac',
    '-f', 'flv',
    targetUrl
];

const proc = spawn(ffmpegPath, args);

proc.stderr.on('data', (data) => {
    const msg = data.toString();
    // Tampilkan semua log awal agar kita tahu errornya
    process.stdout.write(msg);
});

proc.on('close', (code) => {
    console.log(`\nFFmpeg process exited with code ${code}`);
});
