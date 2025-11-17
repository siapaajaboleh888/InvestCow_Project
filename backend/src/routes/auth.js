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
      'SELECT id, password_hash, display_name, role FROM users WHERE email = :email',
      { email }
    );
    if (!rows.length) return res.status(401).json({ message: 'Invalid credentials' });
    const user = rows[0];
    const ok = await bcrypt.compare(password, user.password_hash);
    if (!ok) return res.status(401).json({ message: 'Invalid credentials' });
    const token = jwt.sign({}, process.env.JWT_SECRET, { subject: String(user.id), expiresIn: '7d' });
    return res.json({ id: user.id, email, display_name: user.display_name, role: user.role || 'user', token });
  } catch (e) {
    console.error('login error:', e);
    return res.status(500).json({ message: 'Server error' });
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

module.exports = router;
