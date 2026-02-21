async function check(name, url) {
    try {
        const res = await fetch(url, { method: 'HEAD', timeout: 5000 });
        console.log(`${name}: Status ${res.status}`);
    } catch (e) {
        console.log(`${name}: Error ${e.message}`);
    }
}

const tests = [
    ['Lehrman Cows', 'https://streaming.ipcamlive.com/streams/5f8ef94646738/stream.m3u8'],
    ['Animaux TV', 'https://viamotionhsi.netplus.ch/live/eds/animaux/browser-HLS8/animaux.m3u8'],
    ['Farm Sanctuary 1', 'https://618991dc6b744.streamlock.net:443/fslive/farmcam1.stream/playlist.m3u8'],
    ['Farm Sanctuary 2', 'https://618991dc6b744.streamlock.net:443/fslive/farmcam2.stream/playlist.m3u8']
];

async function run() {
    for (const [name, url] of tests) {
        await check(name, url);
    }
}

run();
