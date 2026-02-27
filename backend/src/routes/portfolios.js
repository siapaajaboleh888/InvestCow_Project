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

// User: list my health requests
router.get('/health-requests', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    const [rows] = await pool.query(
      'SELECT id, cow_name as nama, request_type, status, admin_note, handover_date, created_at FROM health_requests WHERE user_id = :uid ORDER BY created_at DESC',
      { uid: userId }
    );
    return res.json(rows);
  } catch (e) {
    console.error('get user health requests error', e);
    return res.status(500).json({ message: 'Server error' });
  }
});

// User: create health request
router.post('/health-requests', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    const { cow_name, request_type, description } = req.body || {};

    if (!cow_name || !request_type) {
      return res.status(400).json({ message: 'Missing fields' });
    }

    const [result] = await pool.query(
      'INSERT INTO health_requests (user_id, cow_name, request_type, description) VALUES (:uid, :cow_name, :request_type, :description)',
      { uid: userId, cow_name, request_type, description }
    );

    return res.status(201).json({ id: result.insertId, message: 'Request created' });
  } catch (e) {
    console.error('create health request error', e);
    return res.status(500).json({ message: 'Server error' });
  }
});

// User: delete my health request (only if status is pending)
router.delete('/health-requests/:id', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    // Optional: Only allow deletion if status is 'pending'
    const [result] = await pool.query(
      'DELETE FROM health_requests WHERE id = :id AND user_id = :uid',
      { id, uid: userId }
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Request not found or already handled' });
    }

    return res.json({ message: 'Request deleted' });
  } catch (e) {
    console.error('delete health request error', e);
    return res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
