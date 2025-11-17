const jwt = require('jsonwebtoken');
const { pool } = require('../db');

function authMiddleware(req, res, next) {
  const header = req.headers['authorization'] || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ message: 'Missing token' });
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    req.user = { id: Number(payload.sub) };
    return next();
  } catch (e) {
    return res.status(401).json({ message: 'Invalid token' });
  }
}

async function adminOnly(req, res, next) {
  try {
    if (!req.user || !req.user.id) {
      return res.status(401).json({ message: 'Unauthorized' });
    }
    const [rows] = await pool.query('SELECT role FROM users WHERE id = :id', {
      id: req.user.id,
    });
    if (!rows.length || rows[0].role !== 'admin') {
      return res.status(403).json({ message: 'Admin only' });
    }
    req.user.role = rows[0].role;
    return next();
  } catch (e) {
    console.error('adminOnly error', e);
    return res.status(500).json({ message: 'Server error' });
  }
}

module.exports = { authMiddleware, adminOnly };
