const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { pool } = require('../db');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

router.post('/register', async (req, res) => {
  try {
    const { email, password, display_name, locale } = req.body || {};
    if (!email || !password || !display_name) return res.status(400).json({ message: 'Missing fields' });
    const [rows] = await pool.query('SELECT id FROM users WHERE email = :email', { email });
    if (rows.length) return res.status(409).json({ message: 'Email already exists' });
    const password_hash = await bcrypt.hash(password, 12);
    const [result] = await pool.query(
      'INSERT INTO users (email, password_hash, display_name, locale) VALUES (:email, :password_hash, :display_name, :locale)',
      { email, password_hash, display_name, locale: locale || null }
    );
    const userId = result.insertId;
    const token = jwt.sign({}, process.env.JWT_SECRET, { subject: String(userId), expiresIn: '7d' });
    return res.status(201).json({ id: userId, email, display_name, token });
  } catch (e) {
    // Duplicate email error code in MySQL
    if (e && e.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ message: 'Email already exists' });
    }
    console.error('register error:', e);
    return res.status(500).json({ message: 'Server error' });
  }
});

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body || {};
    if (!email || !password) return res.status(400).json({ message: 'Missing fields' });
    const [rows] = await pool.query(
      'SELECT id, password_hash, display_name, role, profile_picture FROM users WHERE email = :email',
      { email }
    );
    if (!rows.length) return res.status(401).json({ message: 'Invalid credentials' });
    const user = rows[0];
    const ok = await bcrypt.compare(password, user.password_hash);
    if (!ok) return res.status(401).json({ message: 'Invalid credentials' });
    const token = jwt.sign({}, process.env.JWT_SECRET, { subject: String(user.id), expiresIn: '7d' });
    return res.json({
      id: user.id,
      email,
      display_name: user.display_name,
      role: user.role || 'user',
      balance: user.balance || 0,
      profile_picture: user.profile_picture,
      token
    });
  } catch (e) {
    console.error('login error:', e);
    return res.status(500).json({ message: 'Server error' });
  }
});

// Get profile
router.get('/me', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    const [rows] = await pool.query('SELECT id, email, display_name, role, balance, profile_picture FROM users WHERE id = :id', { id: userId });
    if (!rows.length) return res.status(404).json({ message: 'User not found' });
    return res.json(rows[0]);
  } catch (e) {
    return res.status(500).json({ message: 'Server error' });
  }
});

// Top-up balance
router.post('/topup', authMiddleware, async (req, res) => {
  const connection = await pool.getConnection();
  try {
    const userId = req.user.id;
    const { amount } = req.body || {};
    if (!amount || amount <= 0) return res.status(400).json({ message: 'Invalid amount' });

    await connection.beginTransaction();

    // Update balance
    await connection.query('UPDATE users SET balance = balance + :amount WHERE id = :idx', { amount, idx: userId });

    // Record transaction
    // Find a portfolio for the user (transaction needs portfolio_id in current join logic)
    const [ports] = await connection.query('SELECT id FROM portfolios WHERE user_id = :uid LIMIT 1', { uid: userId });
    let portfolioId = ports.length ? ports[0].id : null;

    if (!portfolioId) {
      // Create default portfolio if none exists
      const [newPort] = await connection.query('INSERT INTO portfolios (user_id, name) VALUES (:uid, "Utama")', { uid: userId });
      portfolioId = newPort.insertId;
    }

    // Explicitly provide all required fields including symbol 'CASH'
    const query = `
      INSERT INTO transactions 
      (user_id, portfolio_id, product_id, type, symbol, amount, quantity, price, occurred_at, note) 
      VALUES 
      (:uid, :pid, NULL, 'TOPUP', 'CASH', :amount, 0, 0, NOW(), 'Top Up Saldo')
    `;

    await connection.query(query, { uid: userId, pid: portfolioId, amount });

    const [rows] = await connection.query('SELECT balance FROM users WHERE id = :id', { id: userId });

    await connection.commit();
    return res.json({ message: 'Topup successful', balance: rows[0].balance });
  } catch (e) {
    if (connection) await connection.rollback();
    console.error('Topup error:', e);
    return res.status(500).json({ message: 'Server error' });
  } finally {
    if (connection) connection.release();
  }
});

// Hapus akun sendiri (berdasarkan token)
router.delete('/me', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    await pool.query('DELETE FROM users WHERE id = :id', { id: userId });
    return res.status(204).send();
  } catch (e) {
    return res.status(500).json({ message: 'Server error' });
  }
});

// Update profile
router.patch('/me', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    const { display_name, email, profile_picture } = req.body || {};

    // We only update fields that are provided
    const fields = [];
    const params = { id: userId };

    if (display_name !== undefined) {
      fields.push('display_name = :display_name');
      params.display_name = display_name;
    }
    if (email !== undefined) {
      fields.push('email = :email');
      params.email = email;
    }
    if (profile_picture !== undefined) {
      fields.push('profile_picture = :profile_picture');
      params.profile_picture = profile_picture;
    }

    if (fields.length === 0) return res.status(400).json({ message: 'No fields to update' });

    const query = `UPDATE users SET ${fields.join(', ')} WHERE id = :id`;
    await pool.query(query, params);

    return res.json({ message: 'Profile updated' });
  } catch (e) {
    console.error('Update profile error:', e);
    return res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
