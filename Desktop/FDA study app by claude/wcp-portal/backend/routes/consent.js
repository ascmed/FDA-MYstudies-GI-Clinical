// Consent form routes
const express = require('express');
const router = express.Router();
const pool = require('../config/db');

// ============================================================================
// CREATE CONSENT FORM
// ============================================================================
router.post('/', async (req, res) => {
  const { studyId, title, content, requiresSignature, signatureDateCaptured } = req.body;
  const userId = req.user.id;

  try {
    // Verify study exists and user has access
    const studyResult = await pool.query(
      `SELECT s.id FROM studies s WHERE s.id = $1 AND s.created_by = $2`,
      [studyId, userId]
    );

    if (studyResult.rows.length === 0) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }

    // Deactivate previous consent forms
    await pool.query(
      'UPDATE consent_forms SET is_active = FALSE WHERE study_id = $1',
      [studyId]
    );

    // Create new consent form
    const result = await pool.query(
      `INSERT INTO consent_forms (study_id, title, content, requires_signature, signature_date_captured, created_by)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [studyId, title, content, requiresSignature !== false, signatureDateCaptured !== false, userId]
    );

    res.status(201).json({
      message: 'Consent form created successfully',
      consentForm: result.rows[0],
    });
  } catch (error) {
    console.error('Create consent form error:', error);
    res.status(500).json({ error: 'Failed to create consent form' });
  }
});

// ============================================================================
// GET CONSENT FORM FOR STUDY
// ============================================================================
router.get('/study/:studyId', async (req, res) => {
  const { studyId } = req.params;

  try {
    const result = await pool.query(
      `SELECT * FROM consent_forms WHERE study_id = $1 AND is_active = TRUE LIMIT 1`,
      [studyId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'No active consent form found' });
    }

    const consentForm = result.rows[0];

    // Get pages
    const pagesResult = await pool.query(
      'SELECT * FROM consent_pages WHERE consent_form_id = $1 ORDER BY page_number',
      [consentForm.id]
    );

    consentForm.pages = pagesResult.rows;

    res.json(consentForm);
  } catch (error) {
    console.error('Get consent form error:', error);
    res.status(500).json({ error: 'Failed to fetch consent form' });
  }
});

// ============================================================================
// UPDATE CONSENT FORM
// ============================================================================
router.put('/:consentId', async (req, res) => {
  const { consentId } = req.params;
  const { title, content, requiresSignature } = req.body;

  try {
    const result = await pool.query(
      `UPDATE consent_forms SET title = COALESCE($1, title),
                               content = COALESCE($2, content),
                               requires_signature = COALESCE($3, requires_signature),
                               updated_at = NOW()
       WHERE id = $4
       RETURNING *`,
      [title, content, requiresSignature, consentId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Consent form not found' });
    }

    res.json({
      message: 'Consent form updated successfully',
      consentForm: result.rows[0],
    });
  } catch (error) {
    console.error('Update consent form error:', error);
    res.status(500).json({ error: 'Failed to update consent form' });
  }
});

// ============================================================================
// ADD CONSENT PAGE
// ============================================================================
router.post('/:consentId/pages', async (req, res) => {
  const { consentId } = req.params;
  const { pageNumber, title, content, displayOrder } = req.body;

  try {
    // Verify consent form exists
    const consentCheck = await pool.query(
      'SELECT id FROM consent_forms WHERE id = $1',
      [consentId]
    );

    if (consentCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Consent form not found' });
    }

    const result = await pool.query(
      `INSERT INTO consent_pages (consent_form_id, page_number, title, content, display_order)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [consentId, pageNumber, title, content, displayOrder || pageNumber]
    );

    res.status(201).json({
      message: 'Consent page added successfully',
      page: result.rows[0],
    });
  } catch (error) {
    console.error('Add consent page error:', error);
    res.status(500).json({ error: 'Failed to add consent page' });
  }
});

// ============================================================================
// GET CONSENT PAGES
// ============================================================================
router.get('/:consentId/pages', async (req, res) => {
  const { consentId } = req.params;

  try {
    const result = await pool.query(
      'SELECT * FROM consent_pages WHERE consent_form_id = $1 ORDER BY page_number',
      [consentId]
    );

    res.json(result.rows);
  } catch (error) {
    console.error('Get consent pages error:', error);
    res.status(500).json({ error: 'Failed to fetch consent pages' });
  }
});

// ============================================================================
// UPDATE CONSENT PAGE
// ============================================================================
router.put('/page/:pageId', async (req, res) => {
  const { pageId } = req.params;
  const { title, content } = req.body;

  try {
    const result = await pool.query(
      `UPDATE consent_pages SET title = COALESCE($1, title),
                               content = COALESCE($2, content),
                               updated_at = NOW()
       WHERE id = $3
       RETURNING *`,
      [title, content, pageId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Consent page not found' });
    }

    res.json({
      message: 'Consent page updated successfully',
      page: result.rows[0],
    });
  } catch (error) {
    console.error('Update consent page error:', error);
    res.status(500).json({ error: 'Failed to update consent page' });
  }
});

// ============================================================================
// DELETE CONSENT PAGE
// ============================================================================
router.delete('/page/:pageId', async (req, res) => {
  const { pageId } = req.params;

  try {
    const result = await pool.query(
      'DELETE FROM consent_pages WHERE id = $1 RETURNING id',
      [pageId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Consent page not found' });
    }

    res.json({ message: 'Consent page deleted successfully' });
  } catch (error) {
    console.error('Delete consent page error:', error);
    res.status(500).json({ error: 'Failed to delete consent page' });
  }
});

module.exports = router;
