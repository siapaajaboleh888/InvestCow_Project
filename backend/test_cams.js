async function check(url) {
    try {
        const res = await fetch(url, { method: 'HEAD' });
        console.log(`${url} Status: ${res.status}`);
    } catch (e) {
        console.log(`${url} Error: ${e.message}`);
    }
}

// Common patterns for public animal/cow cams
const urls = [
    'https://streaming.ipcamlive.com/streams/5f8ef94646738/stream.m3u8',
    'https://viamotionhsi.netplus.ch/live/eds/animaux/browser-HLS8/animaux.m3u8',
    'https://618991dc6b744.streamlock.net:443/fslive/farmcam2.stream/playlist.m3u8', // Farm Sanctuary
    'https://618991dc6b744.streamlock.net:443/fslive/farmcam1.stream/playlist.m3u8'
];

urls.forEach(check);
