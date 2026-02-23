// Survey management routes
const express = require('express');
const router = express.Router();
const pool = require('../config/db');

// ============================================================================
// CREATE SURVEY
// ============================================================================
router.post('/', async (req, res) => {
  const { studyId, title, description, surveyType, frequency, displayOrder } = req.body;
  const userId = req.user.id;

  try {
    // Verify study exists and user has access
    const studyResult = await pool.query(
      `SELECT s.id FROM studies s
       LEFT JOIN study_permissions sp ON s.id = sp.study_id
       WHERE s.id = $1 AND (sp.permission_level IN ('admin', 'editor') AND sp.user_id = $2 OR s.created_by = $2)`,
      [studyId, userId]
    );

    if (studyResult.rows.length === 0) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }

    // Create survey
    const result = await pool.query(
      `INSERT INTO surveys (study_id, title, description, survey_type, frequency, display_order)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [studyId, title, description, surveyType, frequency, displayOrder || 1]
    );

    res.status(201).json({
      message: 'Survey created successfully',
      survey: result.rows[0],
    });
  } catch (error) {
    console.error('Create survey error:', error);
    res.status(500).json({ error: 'Failed to create survey' });
  }
});

// ============================================================================
// GET SURVEYS FOR STUDY
// ============================================================================
router.get('/study/:studyId', async (req, res) => {
  const { studyId } = req.params;

  try {
    const result = await pool.query(
      `SELECT * FROM surveys WHERE study_id = $1 ORDER BY display_order`,
      [studyId]
    );

    res.json(result.rows);
  } catch (error) {
    console.error('Get surveys error:', error);
    res.status(500).json({ error: 'Failed to fetch surveys' });
  }
});

// ============================================================================
// GET SURVEY WITH QUESTIONS
// ============================================================================
router.get('/:surveyId', async (req, res) => {
  const { surveyId } = req.params;

  try {
    const surveyResult = await pool.query(
      'SELECT * FROM surveys WHERE id = $1',
      [surveyId]
    );

    if (surveyResult.rows.length === 0) {
      return res.status(404).json({ error: 'Survey not found' });
    }

    const survey = surveyResult.rows[0];

    // Get questions
    const questionsResult = await pool.query(
      `SELECT q.*, ARRAY_AGG(qc.* ORDER BY qc.display_order) as choices
       FROM questions q
       LEFT JOIN question_choices qc ON q.id = qc.question_id
       WHERE q.survey_id = $1
       GROUP BY q.id
       ORDER BY q.display_order`,
      [surveyId]
    );

    survey.questions = questionsResult.rows;

    res.json(survey);
  } catch (error) {
    console.error('Get survey error:', error);
    res.status(500).json({ error: 'Failed to fetch survey' });
  }
});

// ============================================================================
// UPDATE SURVEY
// ============================================================================
router.put('/:surveyId', async (req, res) => {
  const { surveyId } = req.params;
  const { title, description, frequency, displayOrder } = req.body;

  try {
    const result = await pool.query(
      `UPDATE surveys SET title = COALESCE($1, title),
                         description = COALESCE($2, description),
                         frequency = COALESCE($3, frequency),
                         display_order = COALESCE($4, display_order),
                         updated_at = NOW()
       WHERE id = $5
       RETURNING *`,
      [title, description, frequency, displayOrder, surveyId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Survey not found' });
    }

    res.json({
      message: 'Survey updated successfully',
      survey: result.rows[0],
    });
  } catch (error) {
    console.error('Update survey error:', error);
    res.status(500).json({ error: 'Failed to update survey' });
  }
});

// ============================================================================
// ADD QUESTION TO SURVEY
// ============================================================================
router.post('/:surveyId/questions', async (req, res) => {
  const { surveyId } = req.params;
  const { questionText, questionType, displayOrder, isRequired, helpText } = req.body;

  try {
    // Verify survey exists
    const surveyCheck = await pool.query('SELECT id FROM surveys WHERE id = $1', [surveyId]);
    if (surveyCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Survey not found' });
    }

    const result = await pool.query(
      `INSERT INTO questions (survey_id, question_text, question_type, display_order, is_required, help_text)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [surveyId, questionText, questionType, displayOrder || 1, isRequired !== false, helpText]
    );

    res.status(201).json({
      message: 'Question added successfully',
      question: result.rows[0],
    });
  } catch (error) {
    console.error('Add question error:', error);
    res.status(500).json({ error: 'Failed to add question' });
  }
});

// ============================================================================
// GET QUESTION
// ============================================================================
router.get('/question/:questionId', async (req, res) => {
  const { questionId } = req.params;

  try {
    const questionResult = await pool.query(
      'SELECT * FROM questions WHERE id = $1',
      [questionId]
    );

    if (questionResult.rows.length === 0) {
      return res.status(404).json({ error: 'Question not found' });
    }

    const question = questionResult.rows[0];

    // Get choices if multiple choice
    if (question.question_type === 'multiple_choice') {
      const choicesResult = await pool.query(
        'SELECT * FROM question_choices WHERE question_id = $1 ORDER BY display_order',
        [questionId]
      );
      question.choices = choicesResult.rows;
    }

    res.json(question);
  } catch (error) {
    console.error('Get question error:', error);
    res.status(500).json({ error: 'Failed to fetch question' });
  }
});

// ============================================================================
// UPDATE QUESTION
// ============================================================================
router.put('/question/:questionId', async (req, res) => {
  const { questionId } = req.params;
  const { questionText, helpText, isRequired, displayOrder } = req.body;

  try {
    const result = await pool.query(
      `UPDATE questions SET question_text = COALESCE($1, question_text),
                           help_text = COALESCE($2, help_text),
                           is_required = COALESCE($3, is_required),
                           display_order = COALESCE($4, display_order),
                           updated_at = NOW()
       WHERE id = $5
       RETURNING *`,
      [questionText, helpText, isRequired, displayOrder, questionId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Question not found' });
    }

    res.json({
      message: 'Question updated successfully',
      question: result.rows[0],
    });
  } catch (error) {
    console.error('Update question error:', error);
    res.status(500).json({ error: 'Failed to update question' });
  }
});

// ============================================================================
// ADD CHOICE TO QUESTION
// ============================================================================
router.post('/question/:questionId/choices', async (req, res) => {
  const { questionId } = req.params;
  const { choiceText, choiceValue, displayOrder } = req.body;

  try {
    const result = await pool.query(
      `INSERT INTO question_choices (question_id, choice_text, choice_value, display_order)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [questionId, choiceText, choiceValue, displayOrder || 1]
    );

    res.status(201).json({
      message: 'Choice added successfully',
      choice: result.rows[0],
    });
  } catch (error) {
    console.error('Add choice error:', error);
    res.status(500).json({ error: 'Failed to add choice' });
  }
});

module.exports = router;
