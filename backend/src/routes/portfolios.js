const express = require('express');
const { pool } = require('../db');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

// Get portfolios for current user
router.get('/', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    const [rows] = await pool.query(
      'SELECT id, name, created_at, updated_at FROM portfolios WHERE user_id = :user_id ORDER BY id DESC',
      { user_id: userId }
    );
    return res.json(rows);
  } catch (e) {
    return res.status(500).json({ message: 'Server error' });
  }
});

// Create portfolio
router.post('/', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    const { name } = req.body || {};
    if (!name) return res.status(400).json({ message: 'Missing name' });
    const [result] = await pool.query(
      'INSERT INTO portfolios (user_id, name) VALUES (:user_id, :name)',
      { user_id: userId, name }
    );
    return res.status(201).json({ id: result.insertId, name });
  } catch (e) {
    return res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
