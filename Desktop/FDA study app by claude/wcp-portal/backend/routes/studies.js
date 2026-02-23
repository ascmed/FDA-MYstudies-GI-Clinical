// Study management routes
const express = require('express');
const router = express.Router();
const pool = require('../config/db');
const { v4: uuidv4 } = require('uuid');

// ============================================================================
// CREATE STUDY
// ============================================================================
router.post('/', async (req, res) => {
  const { studyId, title, description, diseaseArea, phase, durationWeeks } = req.body;
  const userId = req.user.id;

  try {
    // Validate required fields
    if (!studyId || !title || !diseaseArea) {
      return res.status(400).json({ error: 'studyId, title, and diseaseArea required' });
    }

    // Check if study ID already exists
    const existing = await pool.query('SELECT id FROM studies WHERE study_id = $1', [studyId]);
    if (existing.rows.length > 0) {
      return res.status(409).json({ error: 'Study ID already exists' });
    }

    // Create study
    const result = await pool.query(
      `INSERT INTO studies (study_id, title, description, disease_area, phase, duration_weeks, created_by)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [studyId, title, description, diseaseArea, phase, durationWeeks, userId]
    );

    const study = result.rows[0];

    // Grant creator admin access
    await pool.query(
      `INSERT INTO study_permissions (study_id, user_id, permission_level)
       VALUES ($1, $2, 'admin')`,
      [study.id, userId]
    );

    // Create enrollment config
    await pool.query(
      `INSERT INTO enrollment_config (study_id)
       VALUES ($1)`,
      [study.id]
    );

    // Create branding config
    await pool.query(
      `INSERT INTO study_branding (study_id, app_color_primary, app_color_secondary)
       VALUES ($1, $2, $3)`,
      [study.id, '#1A6B4A', '#2E9D6E'] // GI Clinical Studies green
    );

    res.status(201).json({
      message: 'Study created successfully',
      study,
    });
  } catch (error) {
    console.error('Create study error:', error);
    res.status(500).json({ error: 'Failed to create study' });
  }
});

// ============================================================================
// GET ALL STUDIES (for current user)
// ============================================================================
router.get('/', async (req, res) => {
  const userId = req.user.id;

  try {
    let query;
    let params;

    // Super admin sees all studies
    if (req.user.role === 'super_admin') {
      query = `SELECT s.* FROM studies s ORDER BY s.created_at DESC`;
      params = [];
    } else {
      // Other users see only studies they have access to
      query = `
        SELECT DISTINCT s.* FROM studies s
        LEFT JOIN study_permissions sp ON s.id = sp.study_id
        WHERE sp.user_id = $1 OR s.created_by = $1
        ORDER BY s.created_at DESC
      `;
      params = [userId];
    }

    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (error) {
    console.error('Get studies error:', error);
    res.status(500).json({ error: 'Failed to fetch studies' });
  }
});

// ============================================================================
// GET STUDY BY ID
// ============================================================================
router.get('/:studyId', async (req, res) => {
  const { studyId: studyIdParam } = req.params;
  const userId = req.user.id;

  try {
    // Get study (check permissions)
    const studyResult = await pool.query(
      `SELECT s.* FROM studies s
       LEFT JOIN study_permissions sp ON s.id = sp.study_id
       WHERE (s.id = $1 OR s.study_id = $1) AND (sp.user_id = $2 OR s.created_by = $2 OR $3 = 'super_admin')
       LIMIT 1`,
      [studyIdParam, userId, req.user.role]
    );

    if (studyResult.rows.length === 0) {
      return res.status(404).json({ error: 'Study not found' });
    }

    const study = studyResult.rows[0];

    // Get related data
    const [surveys, consent, enrollment, branding] = await Promise.all([
      pool.query('SELECT * FROM surveys WHERE study_id = $1 ORDER BY display_order', [study.id]),
      pool.query('SELECT * FROM consent_forms WHERE study_id = $1 AND is_active = true', [study.id]),
      pool.query('SELECT * FROM enrollment_config WHERE study_id = $1', [study.id]),
      pool.query('SELECT * FROM study_branding WHERE study_id = $1', [study.id]),
    ]);

    res.json({
      ...study,
      surveys: surveys.rows,
      consentForm: consent.rows[0],
      enrollmentConfig: enrollment.rows[0],
      branding: branding.rows[0],
    });
  } catch (error) {
    console.error('Get study error:', error);
    res.status(500).json({ error: 'Failed to fetch study' });
  }
});

// ============================================================================
// UPDATE STUDY
// ============================================================================
router.put('/:studyId', async (req, res) => {
  const { studyId: studyIdParam } = req.params;
  const { title, description, status, phase, durationWeeks } = req.body;
  const userId = req.user.id;

  try {
    // Get study and check permissions
    const studyResult = await pool.query(
      `SELECT s.* FROM studies s
       LEFT JOIN study_permissions sp ON s.id = sp.study_id
       WHERE (s.id = $1 OR s.study_id = $1) AND (sp.permission_level = 'admin' AND sp.user_id = $2 OR s.created_by = $2)
       LIMIT 1`,
      [studyIdParam, userId]
    );

    if (studyResult.rows.length === 0) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }

    const study = studyResult.rows[0];

    // Update study
    const result = await pool.query(
      `UPDATE studies SET title = COALESCE($1, title),
                         description = COALESCE($2, description),
                         status = COALESCE($3, status),
                         phase = COALESCE($4, phase),
                         duration_weeks = COALESCE($5, duration_weeks),
                         updated_at = NOW()
       WHERE id = $6
       RETURNING *`,
      [title, description, status, phase, durationWeeks, study.id]
    );

    res.json({
      message: 'Study updated successfully',
      study: result.rows[0],
    });
  } catch (error) {
    console.error('Update study error:', error);
    res.status(500).json({ error: 'Failed to update study' });
  }
});

// ============================================================================
// PUBLISH STUDY
// ============================================================================
router.post('/:studyId/publish', async (req, res) => {
  const { studyId: studyIdParam } = req.params;
  const userId = req.user.id;

  try {
    // Verify study exists and user has permission
    const studyResult = await pool.query(
      `SELECT s.* FROM studies s WHERE (s.id = $1 OR s.study_id = $1) AND s.created_by = $2`,
      [studyIdParam, userId]
    );

    if (studyResult.rows.length === 0) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }

    const study = studyResult.rows[0];

    // Check if study has required components
    const surveyCount = await pool.query(
      'SELECT COUNT(*) FROM surveys WHERE study_id = $1',
      [study.id]
    );

    if (parseInt(surveyCount.rows[0].count) === 0) {
      return res.status(400).json({ error: 'Study must have at least one survey' });
    }

    // Update status to published
    const result = await pool.query(
      `UPDATE studies SET status = 'published', updated_at = NOW() WHERE id = $1 RETURNING *`,
      [study.id]
    );

    res.json({
      message: 'Study published successfully',
      study: result.rows[0],
    });
  } catch (error) {
    console.error('Publish study error:', error);
    res.status(500).json({ error: 'Failed to publish study' });
  }
});

module.exports = router;
