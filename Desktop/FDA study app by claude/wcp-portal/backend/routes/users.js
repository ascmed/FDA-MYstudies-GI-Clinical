// User management routes
const express = require('express');
const router = express.Router();
const pool = require('../config/db');
const { hashPassword } = require('../utils/auth');

// ============================================================================
// GET CURRENT USER
// ============================================================================
router.get('/me', async (req, res) => {
  const userId = req.user.id;

  try {
    const result = await pool.query(
      'SELECT id, email, first_name, last_name, role, is_active, created_at FROM users WHERE id = $1',
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({ error: 'Failed to fetch user' });
  }
});

// ============================================================================
// GET ALL USERS (Super Admin Only)
// ============================================================================
router.get('/', async (req, res) => {
  const userRole = req.user.role;

  try {
    if (userRole !== 'super_admin') {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }

    const result = await pool.query(
      'SELECT id, email, first_name, last_name, role, is_active, last_login, created_at FROM users ORDER BY created_at DESC'
    );

    res.json(result.rows);
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});

// ============================================================================
// UPDATE USER ROLE (Super Admin Only)
// ============================================================================
router.put('/:userId/role', async (req, res) => {
  const { userId } = req.params;
  const { role } = req.body;
  const requestingUserRole = req.user.role;

  try {
    if (requestingUserRole !== 'super_admin') {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }

    if (!['super_admin', 'admin', 'coordinator', 'researcher'].includes(role)) {
      return res.status(400).json({ error: 'Invalid role' });
    }

    const result = await pool.query(
      'UPDATE users SET role = $1, updated_at = NOW() WHERE id = $2 RETURNING id, email, role',
      [role, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({
      message: 'User role updated successfully',
      user: result.rows[0],
    });
  } catch (error) {
    console.error('Update user role error:', error);
    res.status(500).json({ error: 'Failed to update user role' });
  }
});

// ============================================================================
// DEACTIVATE USER (Super Admin Only)
// ============================================================================
router.put('/:userId/deactivate', async (req, res) => {
  const { userId } = req.params;
  const requestingUserRole = req.user.role;

  try {
    if (requestingUserRole !== 'super_admin') {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }

    const result = await pool.query(
      'UPDATE users SET is_active = FALSE, updated_at = NOW() WHERE id = $1 RETURNING id, email, is_active',
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({
      message: 'User deactivated successfully',
      user: result.rows[0],
    });
  } catch (error) {
    console.error('Deactivate user error:', error);
    res.status(500).json({ error: 'Failed to deactivate user' });
  }
});

// ============================================================================
// GET USER'S STUDIES
// ============================================================================
router.get('/:userId/studies', async (req, res) => {
  const { userId } = req.params;

  try {
    const result = await pool.query(
      `SELECT DISTINCT s.*, sp.permission_level FROM studies s
       LEFT JOIN study_permissions sp ON s.id = sp.study_id
       WHERE (sp.user_id = $1 OR s.created_by = $1)
       ORDER BY s.created_at DESC`,
      [userId]
    );

    res.json(result.rows);
  } catch (error) {
    console.error('Get user studies error:', error);
    res.status(500).json({ error: 'Failed to fetch user studies' });
  }
});

// ============================================================================
// GRANT STUDY PERMISSION
// ============================================================================
router.post('/:userId/studies/:studyId/permission', async (req, res) => {
  const { userId, studyId } = req.params;
  const { permissionLevel } = req.body;
  const requestingUserRole = req.user.role;

  try {
    // Only admins can grant permissions
    const studyCheck = await pool.query(
      `SELECT s.* FROM studies s WHERE s.id = $1 AND s.created_by = $2`,
      [studyId, req.user.id]
    );

    if (studyCheck.rows.length === 0) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }

    if (!['viewer', 'editor', 'admin'].includes(permissionLevel)) {
      return res.status(400).json({ error: 'Invalid permission level' });
    }

    const result = await pool.query(
      `INSERT INTO study_permissions (study_id, user_id, permission_level)
       VALUES ($1, $2, $3)
       ON CONFLICT (study_id, user_id) DO UPDATE SET permission_level = $3
       RETURNING *`,
      [studyId, userId, permissionLevel]
    );

    res.json({
      message: 'Study permission granted successfully',
      permission: result.rows[0],
    });
  } catch (error) {
    console.error('Grant permission error:', error);
    res.status(500).json({ error: 'Failed to grant permission' });
  }
});

module.exports = router;
