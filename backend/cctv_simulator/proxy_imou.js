const { spawn } = require('child_process');
const ffmpeg = require('@ffmpeg-installer/ffmpeg');

const ffmpegPath = ffmpeg.path;

// --- CONFIGURATION ---
const cameraIP = process.env.CCTV_IP || '192.168.1.10';
const safetyCode = process.env.CCTV_CODE || 'L2F40E55';
const rtspUrl = `rtsp://admin:${safetyCode}@${cameraIP}:554/cam/realmonitor?channel=1&subtype=0`;
const targetUrl = process.env.RTMP_TARGET || 'rtmp://localhost/live/imou';

console.log('--- 🐄 InvestCow CCTV Proxy (Production Grade) ---');
console.log('Source: ' + rtspUrl);
console.log('Target: ' + targetUrl);

function startStream() {
    console.log('\n[' + new Date().toLocaleTimeString() + '] 🛰️ Connecting to camera stream...');

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
        // Hanya tampilkan log jika ada error serius untuk menghemat CPU/RAM
        if (msg.includes('error') || msg.includes('Error')) {
            console.error('⚠️ Stream Warning: ' + msg.trim());
        }
    });

    proc.on('close', (code) => {
        console.log(`\n🔴 Stream disconnected (Code: ${code}). Restarting in 5 seconds...`);
        // AUTO-RESTART: Jantung dari sistem anti-mati
        setTimeout(startStream, 5000);
    });
}

// Jalankan sistem
startStream();
