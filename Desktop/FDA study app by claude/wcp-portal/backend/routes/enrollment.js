// Enrollment management routes
const express = require('express');
const router = express.Router();
const pool = require('../config/db');
const { v4: uuidv4 } = require('uuid');

// ============================================================================
// GENERATE ENROLLMENT TOKENS
// ============================================================================
router.post('/generate-tokens', async (req, res) => {
  const { studyId, count, expiresInDays } = req.body;
  const userId = req.user.id;

  try {
    // Verify study exists and user has permission
    const studyResult = await pool.query(
      `SELECT s.id FROM studies s WHERE s.id = $1 AND s.created_by = $2`,
      [studyId, userId]
    );

    if (studyResult.rows.length === 0) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }

    const study = studyResult.rows[0];
    const tokens = [];
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + (expiresInDays || 30));

    for (let i = 0; i < (count || 10); i++) {
      const token = generateToken();
      tokens.push(token);

      await pool.query(
        `INSERT INTO enrollment_tokens (study_id, token, created_by, expires_at)
         VALUES ($1, $2, $3, $4)`,
        [study.id, token, userId, expiresAt]
      );
    }

    res.status(201).json({
      message: `${count} enrollment tokens generated successfully`,
      tokens,
      expiresAt,
    });
  } catch (error) {
    console.error('Generate tokens error:', error);
    res.status(500).json({ error: 'Failed to generate tokens' });
  }
});

// ============================================================================
// GET ENROLLMENT TOKENS FOR STUDY
// ============================================================================
router.get('/tokens/:studyId', async (req, res) => {
  const { studyId } = req.params;
  const { used, unused } = req.query;

  try {
    let query = 'SELECT * FROM enrollment_tokens WHERE study_id = $1';
    const params = [studyId];

    if (used === 'true') {
      query += ' AND is_used = TRUE';
    } else if (unused === 'true') {
      query += ' AND is_used = FALSE';
    }

    query += ' ORDER BY created_at DESC';

    const result = await pool.query(query, params);

    res.json(result.rows);
  } catch (error) {
    console.error('Get tokens error:', error);
    res.status(500).json({ error: 'Failed to fetch tokens' });
  }
});

// ============================================================================
// GET ENROLLMENT CONFIG
// ============================================================================
router.get('/config/:studyId', async (req, res) => {
  const { studyId } = req.params;

  try {
    const result = await pool.query(
      'SELECT * FROM enrollment_config WHERE study_id = $1',
      [studyId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Enrollment config not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Get enrollment config error:', error);
    res.status(500).json({ error: 'Failed to fetch enrollment config' });
  }
});

// ============================================================================
// UPDATE ENROLLMENT CONFIG
// ============================================================================
router.put('/config/:studyId', async (req, res) => {
  const { studyId } = req.params;
  const { maxParticipants, requiresToken, allowSelfEnrollment, eligibilityCriteria } = req.body;

  try {
    const result = await pool.query(
      `UPDATE enrollment_config SET max_participants = COALESCE($1, max_participants),
                                    requires_token = COALESCE($2, requires_token),
                                    allow_self_enrollment = COALESCE($3, allow_self_enrollment),
                                    eligibility_criteria = COALESCE($4, eligibility_criteria),
                                    updated_at = NOW()
       WHERE study_id = $5
       RETURNING *`,
      [maxParticipants, requiresToken, allowSelfEnrollment, eligibilityCriteria, studyId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Enrollment config not found' });
    }

    res.json({
      message: 'Enrollment config updated successfully',
      config: result.rows[0],
    });
  } catch (error) {
    console.error('Update enrollment config error:', error);
    res.status(500).json({ error: 'Failed to update enrollment config' });
  }
});

// ============================================================================
// REVOKE TOKEN
// ============================================================================
router.post('/revoke-token/:tokenId', async (req, res) => {
  const { tokenId } = req.params;

  try {
    const result = await pool.query(
      `UPDATE enrollment_tokens SET expires_at = NOW() WHERE id = $1 RETURNING *`,
      [tokenId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Token not found' });
    }

    res.json({
      message: 'Token revoked successfully',
      token: result.rows[0],
    });
  } catch (error) {
    console.error('Revoke token error:', error);
    res.status(500).json({ error: 'Failed to revoke token' });
  }
});

// ============================================================================
// GET TOKEN STATS
// ============================================================================
router.get('/stats/:studyId', async (req, res) => {
  const { studyId } = req.params;

  try {
    const result = await pool.query(
      `SELECT
        COUNT(*) as total_tokens,
        SUM(CASE WHEN is_used = TRUE THEN 1 ELSE 0 END) as used_tokens,
        SUM(CASE WHEN is_used = FALSE THEN 1 ELSE 0 END) as available_tokens,
        SUM(CASE WHEN expires_at < NOW() THEN 1 ELSE 0 END) as expired_tokens
       FROM enrollment_tokens
       WHERE study_id = $1`,
      [studyId]
    );

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Get token stats error:', error);
    res.status(500).json({ error: 'Failed to fetch token stats' });
  }
});

// ============================================================================
// HELPER FUNCTION - Generate random alphanumeric token
// ============================================================================
function generateToken() {
  return Math.random().toString(36).substring(2, 12).toUpperCase() +
         Math.random().toString(36).substring(2, 12).toUpperCase();
}

module.exports = router;
