const NodeMediaServer = require('node-media-server');
const ffmpegInstaller = require('@ffmpeg-installer/ffmpeg');

const config = {
    rtmp: {
        port: 1935,
        chunk_size: 60000,
        gop_cache: true,
        ping: 30,
        ping_timeout: 60
    },
    http: {
        port: 8000,
        allow_origin: '*',
        mediaroot: './media'
    },
    trans: {
        ffmpeg: ffmpegInstaller.path,
        tasks: [
            {
                app: 'live',
                hls: true,
                hls_flags: '[hls_time=1:hls_list_size=3:hls_flags=delete_segments]',
                dash: true,
                dash_flags: '[f=dash:window_size=3:extra_window_size=5]'
            }
        ]
    }
};

var nms = new NodeMediaServer(config)
nms.run();

console.log('--- InvestCow CCTV Simulator ---');
console.log('RTMP Server: rtmp://localhost/live/cow1');
console.log('HLS Stream:  http://localhost:8000/live/cow1/index.m3u8');
console.log('--------------------------------');
