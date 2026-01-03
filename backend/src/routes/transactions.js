const express = require('express');
const { pool } = require('../db');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

// List all transactions for the user
router.get('/all', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    const { limit = 50, offset = 0 } = req.query;

    const [rows] = await pool.query(
      `SELECT t.id, t.portfolio_id, t.type, t.symbol, t.quantity, t.price, t.occurred_at, t.note, t.created_at
       FROM transactions t
       JOIN portfolios p ON t.portfolio_id = p.id
       WHERE p.user_id = :uid
       ORDER BY t.occurred_at DESC, t.id DESC
       LIMIT :limit OFFSET :offset`,
      { uid: userId, limit: Number(limit), offset: Number(offset) }
    );
    return res.json(rows);
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: 'Server error' });
  }
});

// List transactions by portfolio (with optional pagination)
router.get('/', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    const { portfolio_id, limit = 50, offset = 0 } = req.query;
    if (!portfolio_id) return res.status(400).json({ message: 'Missing portfolio_id' });

    // Ensure portfolio belongs to user
    const [own] = await pool.query('SELECT id FROM portfolios WHERE id = :pid AND user_id = :uid', { pid: portfolio_id, uid: userId });
    if (!own.length) return res.status(404).json({ message: 'Portfolio not found' });

    const [rows] = await pool.query(
      `SELECT id, portfolio_id, type, symbol, quantity, price, occurred_at, note, created_at
       FROM transactions
       WHERE portfolio_id = :pid
       ORDER BY occurred_at DESC, id DESC
       LIMIT :limit OFFSET :offset`,
      { pid: Number(portfolio_id), limit: Number(limit), offset: Number(offset) }
    );
    return res.json(rows);
  } catch (e) {
    return res.status(500).json({ message: 'Server error' });
  }
});

// Get portfolio summary
router.get('/portfolio-summary', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    const [rows] = await pool.query(`
      SELECT t.symbol, 
             SUM(CASE WHEN t.type = 'buy' THEN t.quantity ELSE -t.quantity END) as total_quantity,
             SUM(CASE WHEN t.type = 'buy' THEN t.quantity * t.price ELSE -(t.quantity * t.price) END) as total_investment
      FROM transactions t
      JOIN portfolios p ON t.portfolio_id = p.id
      WHERE p.user_id = :uid
      GROUP BY t.symbol
    `, { uid: userId });

    // Filter out symbols with near-zero quantity (to handle precision issues)
    const summary = rows.filter(r => Math.abs(r.total_quantity) > 0.000001);

    return res.json(summary);
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: 'Server error' });
  }
});

// Create transaction
router.post('/', authMiddleware, async (req, res) => {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const userId = req.user.id;
    const { portfolio_id, type, symbol, quantity, price, occurred_at, note } = req.body || {};
    if (!portfolio_id || !type || !symbol || quantity == null || price == null || !occurred_at) {
      await connection.rollback();
      return res.status(400).json({ message: 'Missing fields' });
    }

    const validTypes = new Set(['buy', 'sell', 'deposit', 'withdraw']);
    if (!validTypes.has(String(type))) {
      await connection.rollback();
      return res.status(400).json({ message: 'Invalid type' });
    }

    // Ensure portfolio belongs to user
    const [own] = await connection.query('SELECT id FROM portfolios WHERE id = :pid AND user_id = :uid', { pid: portfolio_id, uid: userId });
    if (!own.length) {
      await connection.rollback();
      return res.status(404).json({ message: 'Portfolio not found' });
    }

    const totalCost = Number(quantity) * Number(price);

    // Balance check
    const [userRows] = await connection.query('SELECT balance FROM users WHERE id = :uid FOR UPDATE', { uid: userId });
    const userBalance = Number(userRows[0].balance);

    if (type === 'buy') {
      if (userBalance < totalCost) {
        await connection.rollback();
        return res.status(400).json({ message: 'Saldo tidak mencukupi. Silakan top up terlebih dahulu.' });
      }
      // Deduct balance
      await connection.query('UPDATE users SET balance = balance - :cost WHERE id = :uid', { cost: totalCost, uid: userId });
    } else if (type === 'sell') {
      // Check if user has enough quantity to sell
      const [holdings] = await connection.query(`
        SELECT SUM(CASE WHEN type = 'buy' THEN quantity ELSE -quantity END) as current_qty
        FROM transactions t
        JOIN portfolios p ON t.portfolio_id = p.id
        WHERE p.user_id = :uid AND t.symbol = :symbol
      `, { uid: userId, symbol });

      const currentQty = Number(holdings[0].current_qty || 0);
      if (currentQty < Number(quantity)) {
        await connection.rollback();
        return res.status(400).json({ message: 'Jumlah unit tidak mencukupi untuk dijual.' });
      }

      // Add balance
      await connection.query('UPDATE users SET balance = balance + :gain WHERE id = :uid', { gain: totalCost, uid: userId });
    }

    const [result] = await connection.query(
      `INSERT INTO transactions (portfolio_id, type, symbol, quantity, price, occurred_at, note)
       VALUES (:portfolio_id, :type, :symbol, :quantity, :price, :occurred_at, :note)`,
      { portfolio_id, type, symbol, quantity, price, occurred_at, note: note || null }
    );

    await connection.commit();
    return res.status(201).json({ id: result.insertId });
  } catch (e) {
    console.error(e);
    await connection.rollback();
    return res.status(500).json({ message: 'Server error' });
  } finally {
    connection.release();
  }
});

module.exports = router;
