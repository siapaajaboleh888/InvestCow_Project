const { spawn } = require('child_process');
const ffmpeg = require('@ffmpeg-installer/ffmpeg');

const ffmpegPath = ffmpeg.path;
const streamUrl = 'rtmp://localhost/live/cow1';

console.log('--- InvestCow CCTV Simulator Pushing Stream ---');
console.log('Using FFmpeg from: ' + ffmpegPath);
console.log('Target URL: ' + streamUrl);
console.log('\nStarting simulation... (Video: Test Pattern + Clock)');

const args = [
    '-re',
    '-f', 'lavfi', '-i', 'testsrc=size=1280x720:rate=30',
    '-f', 'lavfi', '-i', 'aevalsrc=0',
    '-vf', "drawtext=text='LIVE INVESTCOW %{localtime}':x=10:y=10:fontsize=36:fontcolor=white:box=1:boxcolor=black@0.5",
    '-c:v', 'libx264', '-preset', 'ultrafast', '-tune', 'zerolatency',
    '-c:a', 'aac',
    '-f', 'flv',
    streamUrl
];

const proc = spawn(ffmpegPath, args);

proc.stdout.on('data', (data) => {
    // Silence typical ffmpeg output to keep console clean
});

proc.stderr.on('data', (data) => {
    // FFmpeg logs to stderr by default
    const msg = data.toString();
    if (msg.includes('frame=')) {
        process.stdout.write('\r' + msg.split('\n')[0]);
    }
});

proc.on('close', (code) => {
    console.log(`\nFFmpeg process exited with code ${code}`);
});
