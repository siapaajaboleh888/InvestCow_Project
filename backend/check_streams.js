async function checkStream(url) {
    try {
        const res = await fetch(url, { method: 'HEAD' });
        console.log(`Status for ${url}: ${res.status}`);
    } catch (e) {
        console.log(`Failed ${url}: ${e.message}`);
    }
}

const streams = [
    'https://viamotionhsi.netplus.ch/live/eds/animaux/browser-HLS8/animaux.m3u8',
    'https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8',
    'https://bitdash-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-911d-4720-911b-df8f44354b59.m3u8',
    'http://sample.vodobox.net/skate_phantom_flex_4k/skate_phantom_flex_4k.m3u8'
];

async function run() {
    for (const s of streams) {
        await checkStream(s);
    }
}

run();
