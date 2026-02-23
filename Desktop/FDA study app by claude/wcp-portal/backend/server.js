// WCP Backend Server - Main Entry Point
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const authRoutes = require('./routes/auth');
const studyRoutes = require('./routes/studies');
const surveyRoutes = require('./routes/surveys');
const consentRoutes = require('./routes/consent');
const enrollmentRoutes = require('./routes/enrollment');
const userRoutes = require('./routes/users');

const app = express();

// ============================================================================
// MIDDLEWARE
// ============================================================================

// Security headers
app.use(helmet());

// CORS
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:3000',
  credentials: true,
}));

// Body parsing
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ============================================================================
// AUTHENTICATION MIDDLEWARE
// ============================================================================

const verifyToken = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid token' });
  }
};

// ============================================================================
// ROUTES
// ============================================================================

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'WCP Server is running' });
});

// Public routes
app.use('/api/auth', authRoutes);

// Protected routes
app.use('/api/studies', verifyToken, studyRoutes);
app.use('/api/surveys', verifyToken, surveyRoutes);
app.use('/api/consent', verifyToken, consentRoutes);
app.use('/api/enrollment', verifyToken, enrollmentRoutes);
app.use('/api/users', verifyToken, userRoutes);

// ============================================================================
// ERROR HANDLING
// ============================================================================

app.use((err, req, res, next) => {
  console.error(err);
  res.status(err.status || 500).json({
    error: err.message || 'Internal server error'
  });
});

// ============================================================================
// START SERVER
// ============================================================================

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`
╔════════════════════════════════════════════════════════════╗
║  GI Clinical Studies - Web Configuration Portal (WCP)     ║
║  Version 1.0.0                                              ║
║  Server running on http://localhost:${PORT}                    ║
╚════════════════════════════════════════════════════════════╝
  `);
});

module.exports = app;
