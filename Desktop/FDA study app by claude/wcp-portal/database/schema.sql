-- GI Clinical Studies - Database Schema
-- PostgreSQL Schema for WCP (Web Configuration Portal)

-- ============================================================================
-- USERS & AUTHENTICATION
-- ============================================================================

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  first_name VARCHAR(255),
  last_name VARCHAR(255),
  role VARCHAR(50) NOT NULL DEFAULT 'coordinator', -- super_admin, admin, coordinator, researcher
  is_active BOOLEAN DEFAULT TRUE,
  last_login TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

-- ============================================================================
-- STUDIES
-- ============================================================================

CREATE TABLE IF NOT EXISTS studies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  study_id VARCHAR(50) UNIQUE NOT NULL, -- GI-UC-2026, GI-CD-2026, GI-NASH-2026
  title VARCHAR(255) NOT NULL,
  description TEXT,
  disease_area VARCHAR(100) NOT NULL, -- UC, CD, NASH
  phase VARCHAR(20), -- Phase II, Phase II/III, Phase III
  duration_weeks INT,
  status VARCHAR(50) DEFAULT 'draft', -- draft, published, paused, archived
  created_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_studies_disease_area ON studies(disease_area);
CREATE INDEX idx_studies_status ON studies(status);

-- ============================================================================
-- SURVEYS
-- ============================================================================

CREATE TABLE IF NOT EXISTS surveys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  study_id UUID NOT NULL REFERENCES studies(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  survey_type VARCHAR(50), -- baseline, weekly, monthly, follow_up
  frequency VARCHAR(50), -- one_time, weekly, bi_weekly, monthly
  display_order INT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_surveys_study_id ON surveys(study_id);
CREATE INDEX idx_surveys_frequency ON surveys(frequency);

-- ============================================================================
-- SURVEY QUESTIONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  survey_id UUID NOT NULL REFERENCES surveys(id) ON DELETE CASCADE,
  question_text TEXT NOT NULL,
  question_type VARCHAR(50) NOT NULL, -- text, multiple_choice, scale, date, time, numeric
  display_order INT,
  is_required BOOLEAN DEFAULT TRUE,
  help_text TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_questions_survey_id ON questions(survey_id);

-- ============================================================================
-- QUESTION CHOICES (for multiple choice questions)
-- ============================================================================

CREATE TABLE IF NOT EXISTS question_choices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
  choice_text VARCHAR(255) NOT NULL,
  choice_value VARCHAR(100),
  display_order INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_choices_question_id ON question_choices(question_id);

-- ============================================================================
-- INFORMED CONSENT FORMS
-- ============================================================================

CREATE TABLE IF NOT EXISTS consent_forms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  study_id UUID NOT NULL REFERENCES studies(id) ON DELETE CASCADE,
  version INT DEFAULT 1,
  title VARCHAR(255),
  content TEXT NOT NULL, -- HTML or formatted text
  requires_signature BOOLEAN DEFAULT TRUE,
  signature_date_captured BOOLEAN DEFAULT TRUE,
  is_active BOOLEAN DEFAULT TRUE,
  created_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_consent_study_id ON consent_forms(study_id);
CREATE INDEX idx_consent_active ON consent_forms(is_active);

-- ============================================================================
-- CONSENT PAGES (for multi-page consents)
-- ============================================================================

CREATE TABLE IF NOT EXISTS consent_pages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  consent_form_id UUID NOT NULL REFERENCES consent_forms(id) ON DELETE CASCADE,
  page_number INT NOT NULL,
  title VARCHAR(255),
  content TEXT NOT NULL,
  display_order INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_consent_pages_form_id ON consent_pages(consent_form_id);

-- ============================================================================
-- ENROLLMENT CONFIGURATION
-- ============================================================================

CREATE TABLE IF NOT EXISTS enrollment_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  study_id UUID NOT NULL REFERENCES studies(id) ON DELETE CASCADE,
  enrollment_token_format VARCHAR(50) DEFAULT 'alphanumeric', -- alphanumeric, numeric, uuid
  max_participants INT,
  current_participants INT DEFAULT 0,
  allow_self_enrollment BOOLEAN DEFAULT FALSE,
  requires_token BOOLEAN DEFAULT TRUE,
  eligibility_criteria TEXT, -- JSON or text description
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_enrollment_config_study_id ON enrollment_config(study_id);

-- ============================================================================
-- ENROLLMENT TOKENS
-- ============================================================================

CREATE TABLE IF NOT EXISTS enrollment_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  study_id UUID NOT NULL REFERENCES studies(id) ON DELETE CASCADE,
  token VARCHAR(255) UNIQUE NOT NULL,
  participant_id UUID, -- Links to participant after enrollment
  is_used BOOLEAN DEFAULT FALSE,
  used_at TIMESTAMP,
  created_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP
);

CREATE INDEX idx_tokens_study_id ON enrollment_tokens(study_id);
CREATE INDEX idx_tokens_value ON enrollment_tokens(token);
CREATE INDEX idx_tokens_used ON enrollment_tokens(is_used);

-- ============================================================================
-- STUDY SCHEDULE
-- ============================================================================

CREATE TABLE IF NOT EXISTS study_schedule (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  study_id UUID NOT NULL REFERENCES studies(id) ON DELETE CASCADE,
  survey_id UUID NOT NULL REFERENCES surveys(id) ON DELETE CASCADE,
  schedule_type VARCHAR(50), -- calendar_based, enrollment_anchored
  start_date DATE,
  frequency_days INT, -- For bi-weekly, monthly, etc.
  notification_enabled BOOLEAN DEFAULT TRUE,
  notification_time TIME,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_schedule_study_id ON study_schedule(study_id);

-- ============================================================================
-- STUDY RESOURCES
-- ============================================================================

CREATE TABLE IF NOT EXISTS study_resources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  study_id UUID NOT NULL REFERENCES studies(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  resource_type VARCHAR(50), -- pdf, link, video, image, text
  url VARCHAR(500),
  file_path VARCHAR(500),
  display_order INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_resources_study_id ON study_resources(study_id);

-- ============================================================================
-- STUDY BRANDING
-- ============================================================================

CREATE TABLE IF NOT EXISTS study_branding (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  study_id UUID NOT NULL REFERENCES studies(id) ON DELETE CASCADE,
  app_icon_url VARCHAR(500),
  app_color_primary VARCHAR(7), -- Hex color
  app_color_secondary VARCHAR(7),
  app_logo_url VARCHAR(500),
  splash_screen_url VARCHAR(500),
  home_screen_image_url VARCHAR(500),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_branding_study_id ON study_branding(study_id);

-- ============================================================================
-- AUDIT LOG
-- ============================================================================

CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  action VARCHAR(255) NOT NULL,
  entity_type VARCHAR(100), -- study, survey, user, etc.
  entity_id UUID,
  changes JSONB,
  ip_address VARCHAR(45),
  user_agent TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_created_at ON audit_logs(created_at);

-- ============================================================================
-- STUDY PERMISSIONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS study_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  study_id UUID NOT NULL REFERENCES studies(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  permission_level VARCHAR(50) DEFAULT 'viewer', -- viewer, editor, admin
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(study_id, user_id)
);

CREATE INDEX idx_permissions_study_id ON study_permissions(study_id);
CREATE INDEX idx_permissions_user_id ON study_permissions(user_id);

-- ============================================================================
-- MAYO SCORE QUESTIONS (UC Study)
-- ============================================================================

CREATE TABLE IF NOT EXISTS mayo_score_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  survey_id UUID NOT NULL REFERENCES surveys(id) ON DELETE CASCADE,
  include_stool_frequency BOOLEAN DEFAULT TRUE,
  include_rectal_bleeding BOOLEAN DEFAULT TRUE,
  include_mucosal_appearance BOOLEAN DEFAULT TRUE,
  include_physician_rating BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- HARVEY BRADSHAW INDEX (CD Study)
-- ============================================================================

CREATE TABLE IF NOT EXISTS hbi_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  survey_id UUID NOT NULL REFERENCES surveys(id) ON DELETE CASCADE,
  include_stool_count BOOLEAN DEFAULT TRUE,
  include_abdominal_pain BOOLEAN DEFAULT TRUE,
  include_general_wellbeing BOOLEAN DEFAULT TRUE,
  include_complications BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- NASH METABOLIC TRACKING
-- ============================================================================

CREATE TABLE IF NOT EXISTS nash_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  survey_id UUID NOT NULL REFERENCES surveys(id) ON DELETE CASCADE,
  track_weight BOOLEAN DEFAULT TRUE,
  track_fatigue BOOLEAN DEFAULT TRUE,
  track_pain BOOLEAN DEFAULT TRUE,
  track_activity BOOLEAN DEFAULT TRUE,
  track_alcohol_use BOOLEAN DEFAULT TRUE,
  track_diet BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
