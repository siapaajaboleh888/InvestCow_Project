const express = require('express');
const path = require('path');
const fs = require('fs');
const multer = require('multer');
const { pool } = require('../db');
const { authMiddleware, adminOnly } = require('../middleware/auth');

const router = express.Router();

// ensure uploads directory exists
const uploadDir = path.join(__dirname, '..', '..', 'uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname || '');
    const base = path
      .basename(file.originalname || 'image', ext)
      .replace(/[^a-zA-Z0-9_-]/g, '');
    const name = `${base || 'image'}-${Date.now()}${ext}`;
    cb(null, name);
  },
});

const upload = multer({ storage });

// Public: list products for users
router.get('/products-public', async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT id, name, ticker_code, description, price, prev_price, target_price, quota, image_url, cctv_url, market_sentiment FROM products ORDER BY id DESC',
    );
    return res.json(rows);
  } catch (e) {
    console.error('public get products error', e);
    return res.status(500).json({ message: 'Server error' });
  }
});

// Upload image
router.post(
  '/upload-image',
  authMiddleware,
  adminOnly,
  upload.single('image'),
  (req, res) => {
    if (!req.file) {
      return res.status(400).json({ message: 'No file uploaded' });
    }
    const url = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;
    return res.json({ url });
  },
);


// Get all products
router.get('/products', authMiddleware, adminOnly, async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT id, name, ticker_code, description, price, prev_price, target_price, quota, image_url, cctv_url, market_sentiment FROM products ORDER BY id DESC',
    );
    return res.json(rows);
  } catch (e) {
    console.error('get products error', e);
    return res.status(500).json({ message: 'Server error' });
  }
});

// Create product
router.post('/products', authMiddleware, adminOnly, async (req, res) => {
  try {
    const { name, ticker_code, description, price, target_price, quota, image_url, cctv_url, market_sentiment, investor_share_ratio } = req.body || {};
    if (!name || price == null) {
      return res.status(400).json({ message: 'Missing name or price' });
    }
    const [result] = await pool.query(
      'INSERT INTO products (name, ticker_code, description, price, prev_price, target_price, quota, image_url, cctv_url, market_sentiment, investor_share_ratio) VALUES (:name, :ticker_code, :description, :price, :price, :target_price, :quota, :image_url, :cctv_url, :market_sentiment, :investor_share_ratio)',
      {
        name,
        ticker_code: ticker_code || 'COW',
        description: description || null,
        price,
        target_price: target_price || null,
        quota: quota ?? 0,
        image_url: image_url || null,
        cctv_url: cctv_url || null,
        market_sentiment: market_sentiment || null,
        investor_share_ratio: investor_share_ratio || 0.7000,
      },
    );
    const id = result.insertId;
    const [rows] = await pool.query(
      'SELECT id, name, ticker_code, description, price, prev_price, target_price, quota, image_url, cctv_url, market_sentiment, current_weight, daily_growth_rate, price_per_kg, health_score FROM products WHERE id = :id',
      { id },
    );

    const newProduct = rows[0];
    if (req.io) {
      req.io.emit('product-updated', newProduct);
    }

    return res.status(201).json(newProduct);
  } catch (e) {
    console.error('create product error', e);
    return res.status(500).json({ message: 'Server error' });
  }
});

// Update product
router.put('/products/:id', authMiddleware, adminOnly, async (req, res) => {
  try {
    const id = req.params.id;
    // Get old data to preserve or move
    const [oldRows] = await pool.query('SELECT * FROM products WHERE id = :id', { id });
    const oldProduct = oldRows.length > 0 ? oldRows[0] : null;

    if (!oldProduct) {
      return res.status(404).json({ message: 'Product not found' });
    }

    const { 
      name, 
      ticker_code, 
      description, 
      price, 
      target_price, 
      quota, 
      image_url, 
      cctv_url, 
      market_sentiment, 
      investor_share_ratio 
    } = req.body || {};

    const finalPrice = price !== undefined ? price : oldProduct.price;
    const oldPrice = oldProduct.price;

    const [result] = await pool.query(
      'UPDATE products SET name = :name, ticker_code = :ticker_code, description = :description, price = :price, prev_price = :prev_price, target_price = :target_price, quota = :quota, image_url = :image_url, cctv_url = :cctv_url, market_sentiment = :market_sentiment, investor_share_ratio = :investor_share_ratio WHERE id = :id',
      {
        id,
        name: name || oldProduct.name,
        ticker_code: ticker_code || oldProduct.ticker_code,
        description: description !== undefined ? description : oldProduct.description,
        price: finalPrice,
        prev_price: oldPrice, 
        target_price: target_price !== undefined ? target_price : oldProduct.target_price,
        quota: quota !== undefined ? quota : oldProduct.quota,
        image_url: image_url !== undefined ? image_url : oldProduct.image_url,
        cctv_url: cctv_url !== undefined ? cctv_url : oldProduct.cctv_url,
        market_sentiment: market_sentiment !== undefined ? market_sentiment : oldProduct.market_sentiment,
        investor_share_ratio: investor_share_ratio !== undefined ? investor_share_ratio : oldProduct.investor_share_ratio,
      },
    );


    if (!result.affectedRows) {
      return res.status(404).json({ message: 'Not found' });
    }

    // Record price history
    await pool.query(
      'INSERT INTO product_prices (product_id, price_open, price_high, price_low, price_close, volume) VALUES (:id, :open, :high, :low, :close, :volume)',
      {
        id,
        open: oldPrice,
        high: Math.max(parseFloat(oldPrice), parseFloat(finalPrice)),
        low: Math.min(parseFloat(oldPrice), parseFloat(finalPrice)),
        close: finalPrice,
        volume: Math.floor(Math.random() * 100), // simulated volume
      },
    );

    const [rows] = await pool.query(
      'SELECT id, name, ticker_code, description, price, prev_price, target_price, quota, image_url, cctv_url, market_sentiment, investor_share_ratio, current_weight, daily_growth_rate, price_per_kg, health_score FROM products WHERE id = :id',
      { id },
    );

    const updatedProduct = rows[0];
    // Emit real-time update via socket.io
    if (req.io) {
      req.io.emit('product-updated', updatedProduct);
      
      req.io.emit('price-update', {
        productId: id,
        newPrice: finalPrice,
        marketSentiment: market_sentiment || null,
        timestamp: new Date().toISOString(),
        candle: {
          open: oldPrice,
          high: Math.max(parseFloat(oldPrice), parseFloat(finalPrice)),
          low: Math.min(parseFloat(oldPrice), parseFloat(finalPrice)),
          close: finalPrice,
          timestamp: new Date().toISOString(),
        },
      });
    }

    return res.json(updatedProduct);
  } catch (e) {
    console.error('update product error', e);
    return res.status(500).json({ message: 'Server error' });
  }
});

// Get price history for chart
router.get('/products/:id/history', async (req, res) => {
  try {
    const id = req.params.id;
    const [rows] = await pool.query(
      'SELECT * FROM product_prices WHERE product_id = :id ORDER BY timestamp DESC LIMIT 50',
      { id },
    );
    // Transform to OHLC format expected by most charts
    const history = rows.map((r) => ({
      date: new Date(r.timestamp),
      open: parseFloat(r.price_open),
      high: parseFloat(r.price_high),
      low: parseFloat(r.price_low),
      close: parseFloat(r.price_close),
      volume: parseFloat(r.volume),
    }));
    return res.json(history);
  } catch (e) {
    console.error('get history error', e);
    return res.status(500).json({ message: 'Server error' });
  }
});


// Delete product
router.delete('/products/:id', authMiddleware, adminOnly, async (req, res) => {
  try {
    const id = req.params.id;
    const [result] = await pool.query('DELETE FROM products WHERE id = :id', { id });
    if (!result.affectedRows) {
      return res.status(404).json({ message: 'Not found' });
    }
    return res.status(204).send();
  } catch (e) {
    console.error('delete product error', e);
    return res.status(500).json({ message: 'Server error' });
  }
});

// Admin: list users
router.get('/users', authMiddleware, adminOnly, async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT id, email, role, created_at FROM users ORDER BY id DESC',
    );
    return res.json(rows);
  } catch (e) {
    console.error('admin get users error', e);
    return res.status(500).json({ message: 'Server error' });
  }
});

// Admin: delete user
router.delete('/users/:id', authMiddleware, adminOnly, async (req, res) => {
  try {
    const id = req.params.id;

    // Optional: jangan izinkan admin menghapus dirinya sendiri dengan endpoint ini
    if (req.user && String(req.user.id) === String(id)) {
      return res.status(400).json({ message: 'Tidak dapat menghapus akun sendiri' });
    }

    const [result] = await pool.query('DELETE FROM users WHERE id = :id', { id });
    if (!result.affectedRows) {
      return res.status(404).json({ message: 'User tidak ditemukan' });
    }
    return res.status(204).send();
  } catch (e) {
    console.error('admin delete user error', e);
    return res.status(500).json({ message: 'Server error' });
  }
});

// Admin: list health requests
router.get('/health-requests', authMiddleware, adminOnly, async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT hr.*, u.display_name as user_name, u.email as user_email 
      FROM health_requests hr
      JOIN users u ON hr.user_id = u.id
      ORDER BY hr.created_at DESC
    `);
    return res.json(rows);
  } catch (e) {
    console.error('admin get health requests error', e);
    return res.status(500).json({ message: 'Server error' });
  }
});

// Admin: update health request status
router.patch('/health-requests/:id', authMiddleware, adminOnly, async (req, res) => {
  try {
    const { id } = req.params;
    const { status, admin_note, handover_date } = req.body || {};

    // Format date for MySQL DATETIME (convert T to space and remove Z/milliseconds)
    const formattedDate = handover_date ? handover_date.replace('T', ' ').substring(0, 19) : null;

    const [result] = await pool.query(
      'UPDATE health_requests SET status = :status, admin_note = :admin_note, handover_date = :handover_date WHERE id = :id',
      { status, admin_note, handover_date: formattedDate, id }
    );

    if (!result.affectedRows) {
      return res.status(404).json({ message: 'Request not found' });
    }

    return res.json({ message: 'Request updated successfully' });
  } catch (e) {
    console.error('admin update health request error', e);
    return res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
