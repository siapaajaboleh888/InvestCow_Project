async function check(name, url) {
    try {
        const res = await fetch(url, { method: 'HEAD', timeout: 5000 });
        console.log(`${name}: Status ${res.status}`);
    } catch (e) {
        console.log(`${name}: Error ${e.message}`);
    }
}

const tests = [
    ['KuhCam Direct', 'https://rtmp.kuhcam.de/live/kuhcam.m3u8'],
    ['Animaux HLS', 'https://viamotionhsi.netplus.ch/live/eds/animaux/browser-HLS8/animaux.m3u8']
];

async function run() {
    for (const [name, url] of tests) {
        await check(name, url);
    }
}

run();
