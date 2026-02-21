async function checkStream(url) {
    try {
        const res = await fetch(url, { method: 'HEAD' });
        console.log(`Status for ${url}: ${res.status}`);
    } catch (e) {
        console.log(`Failed ${url}: ${e.message}`);
    }
}

const streams = [
    'https://streaming.ipcamlive.com/streams/5f8ef94646738/stream.m3u8',
    'https://streaming.ipcamlive.com/streams/5f8ef94646738/chunks.m3u8'
];

async function run() {
    for (const s of streams) {
        await checkStream(s);
    }
}

run();
