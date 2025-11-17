const express = require('express');
const { pool } = require('../db');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

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

// Create transaction
router.post('/', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    const { portfolio_id, type, symbol, quantity, price, occurred_at, note } = req.body || {};
    if (!portfolio_id || !type || !symbol || quantity == null || price == null || !occurred_at) {
      return res.status(400).json({ message: 'Missing fields' });
    }

    const validTypes = new Set(['buy', 'sell', 'deposit', 'withdraw']);
    if (!validTypes.has(String(type))) return res.status(400).json({ message: 'Invalid type' });

    // Ensure portfolio belongs to user
    const [own] = await pool.query('SELECT id FROM portfolios WHERE id = :pid AND user_id = :uid', { pid: portfolio_id, uid: userId });
    if (!own.length) return res.status(404).json({ message: 'Portfolio not found' });

    const [result] = await pool.query(
      `INSERT INTO transactions (portfolio_id, type, symbol, quantity, price, occurred_at, note)
       VALUES (:portfolio_id, :type, :symbol, :quantity, :price, :occurred_at, :note)`,
      { portfolio_id, type, symbol, quantity, price, occurred_at, note: note || null }
    );

    return res.status(201).json({ id: result.insertId });
  } catch (e) {
    return res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
