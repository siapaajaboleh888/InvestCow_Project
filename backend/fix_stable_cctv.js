const { pool } = require('./src/db');

async function fixCctvLinks() {
  console.log('🚀 Updating CCTV links with high-stability YouTube Embed streams...');
  
  // Stable 2026 YouTube Live/High-Permission Cattle-related IDs
  const stableStreams = [
    { ticker: 'MADURA', id: 'inDzgZjCxmQ' },   // Global Cattle Stream
    { ticker: 'LIMO', id: 'f0W7v8X-y68' },     // Farm Environment
    { ticker: 'PO-01', id: 'f0W7v8X-y68' },    // Alternate Farm
    { ticker: 'ANGUS-P', id: 'Wih8A0JmB3I' },  // High quality cattle feed
    { ticker: 'BRAH-P', id: 'XJ6o3t0mH_M' }    // Stable feedlot
  ];

  try {
    for (const stream of stableStreams) {
      const cctvUrl = `youtube://${stream.id}`;
      const [result] = await pool.query(
        'UPDATE products SET cctv_url = :url WHERE ticker_code = :ticker',
        { url: cctvUrl, ticker: stream.ticker }
      );
      console.log(`✅ ${stream.ticker} updated to: ${cctvUrl} (${result.affectedRows} row Affected)`);
    }
    console.log('\n✨ Database Update Complete! Please REFRESH your app.');
    process.exit(0);
  } catch (e) {
    console.error('❌ Error updating database:', e);
    process.exit(1);
  }
}

fixCctvLinks();
