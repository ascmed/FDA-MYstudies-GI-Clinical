# WCP API Documentation

Complete API reference for the GI Clinical Studies Web Configuration Portal.

## Base URL
```
http://localhost:5000/api
```

## Authentication

All endpoints (except `/auth`) require a JWT token in the `Authorization` header:
```
Authorization: Bearer <JWT_TOKEN>
```

## Response Format

All responses are JSON:
```json
{
  "message": "Success message",
  "data": {},
  "error": "Error message (if applicable)"
}
```

---

## 🔐 Authentication Endpoints

### Register User
**POST** `/auth/register`

Create a new user account.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "firstName": "John",
  "lastName": "Doe",
  "role": "coordinator"
}
```

**Response (201):**
```json
{
  "message": "User registered successfully",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "role": "coordinator"
  },
  "token": "JWT_TOKEN"
}
```

**Errors:**
- `400` - Missing email or password
- `409` - User already exists

---

### Login User
**POST** `/auth/login`

Authenticate and get JWT token.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response (200):**
```json
{
  "message": "Login successful",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "role": "coordinator"
  },
  "token": "JWT_TOKEN"
}
```

**Errors:**
- `401` - Invalid credentials

---

### Verify Token
**GET** `/auth/verify`

Verify JWT token validity.

**Response (200):**
```json
{
  "valid": true,
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "role": "coordinator"
  }
}
```

---

## 📚 Study Endpoints

### Create Study
**POST** `/studies`

Create a new clinical study.

**Request Body:**
```json
{
  "studyId": "GI-UC-2026",
  "title": "Ulcerative Colitis Study 2026",
  "description": "A study on UC treatment efficacy",
  "diseaseArea": "UC",
  "phase": "Phase III",
  "durationWeeks": 52
}
```

**Response (201):**
```json
{
  "message": "Study created successfully",
  "study": {
    "id": "uuid",
    "study_id": "GI-UC-2026",
    "title": "Ulcerative Colitis Study 2026",
    "disease_area": "UC",
    "phase": "Phase III",
    "duration_weeks": 52,
    "status": "draft",
    "created_by": "uuid",
    "created_at": "2024-02-23T10:00:00Z"
  }
}
```

**Errors:**
- `400` - Missing required fields
- `409` - Study ID already exists

---

### Get All Studies
**GET** `/studies`

List all studies accessible to the user.

**Query Parameters:**
- None

**Response (200):**
```json
[
  {
    "id": "uuid",
    "study_id": "GI-UC-2026",
    "title": "Ulcerative Colitis Study",
    "disease_area": "UC",
    "status": "published",
    "created_at": "2024-02-23T10:00:00Z"
  }
]
```

---

### Get Study Details
**GET** `/studies/:studyId`

Get detailed information about a specific study.

**Parameters:**
- `studyId` (UUID or study_id string)

**Response (200):**
```json
{
  "id": "uuid",
  "study_id": "GI-UC-2026",
  "title": "Ulcerative Colitis Study",
  "description": "...",
  "disease_area": "UC",
  "phase": "Phase III",
  "duration_weeks": 52,
  "status": "published",
  "surveys": [
    {
      "id": "uuid",
      "title": "Weekly Mayo Score",
      "frequency": "weekly"
    }
  ],
  "consentForm": {
    "id": "uuid",
    "title": "Study Informed Consent",
    "requires_signature": true
  },
  "enrollmentConfig": {
    "requires_token": true,
    "max_participants": 500
  },
  "branding": {
    "app_color_primary": "#1A6B4A",
    "app_color_secondary": "#2E9D6E"
  }
}
```

---

### Update Study
**PUT** `/studies/:studyId`

Update study information.

**Request Body:**
```json
{
  "title": "Updated Title",
  "description": "Updated description",
  "status": "published",
  "phase": "Phase III",
  "durationWeeks": 52
}
```

**Response (200):**
```json
{
  "message": "Study updated successfully",
  "study": { /* updated study object */ }
}
```

---

### Publish Study
**POST** `/studies/:studyId/publish`

Publish a study (makes it live).

**Requirements:**
- Study must have at least one survey
- User must be study creator/admin

**Response (200):**
```json
{
  "message": "Study published successfully",
  "study": {
    "status": "published"
  }
}
```

---

## 📋 Survey Endpoints

### Create Survey
**POST** `/surveys`

Create a survey within a study.

**Request Body:**
```json
{
  "studyId": "uuid",
  "title": "Weekly Symptom Check",
  "description": "Daily symptom tracking",
  "surveyType": "weekly",
  "frequency": "weekly",
  "displayOrder": 1
}
```

**Response (201):**
```json
{
  "message": "Survey created successfully",
  "survey": {
    "id": "uuid",
    "study_id": "uuid",
    "title": "Weekly Symptom Check",
    "survey_type": "weekly",
    "frequency": "weekly",
    "is_active": true
  }
}
```

---

### Get Surveys for Study
**GET** `/surveys/study/:studyId`

List all surveys in a study.

**Response (200):**
```json
[
  {
    "id": "uuid",
    "title": "Weekly Symptom Check",
    "survey_type": "weekly",
    "frequency": "weekly"
  }
]
```

---

### Get Survey with Questions
**GET** `/surveys/:surveyId`

Get detailed survey including questions and choices.

**Response (200):**
```json
{
  "id": "uuid",
  "title": "Weekly Symptom Check",
  "questions": [
    {
      "id": "uuid",
      "question_text": "How many stools per day?",
      "question_type": "numeric",
      "is_required": true,
      "choices": []
    }
  ]
}
```

---

### Add Question to Survey
**POST** `/surveys/:surveyId/questions`

Add a question to a survey.

**Request Body:**
```json
{
  "questionText": "How many stools per day?",
  "questionType": "numeric",
  "displayOrder": 1,
  "isRequired": true,
  "helpText": "Please enter the number of bowel movements"
}
```

**Question Types:**
- `text` - Short text input
- `multiple_choice` - Multiple choice question
- `scale` - Rating scale (1-10)
- `date` - Date picker
- `time` - Time picker
- `numeric` - Number input

**Response (201):**
```json
{
  "message": "Question added successfully",
  "question": {
    "id": "uuid",
    "survey_id": "uuid",
    "question_text": "How many stools per day?",
    "question_type": "numeric"
  }
}
```

---

### Add Question Choices
**POST** `/surveys/question/:questionId/choices`

Add answer choices to a multiple-choice question.

**Request Body:**
```json
{
  "choiceText": "Mild",
  "choiceValue": "1",
  "displayOrder": 1
}
```

**Response (201):**
```json
{
  "message": "Choice added successfully",
  "choice": {
    "id": "uuid",
    "question_id": "uuid",
    "choice_text": "Mild",
    "choice_value": "1"
  }
}
```

---

## 📝 Consent Form Endpoints

### Create Consent Form
**POST** `/consent`

Create an informed consent form for a study.

**Request Body:**
```json
{
  "studyId": "uuid",
  "title": "Study Informed Consent",
  "content": "This is an informed consent form...",
  "requiresSignature": true,
  "signatureDateCaptured": true
}
```

**Response (201):**
```json
{
  "message": "Consent form created successfully",
  "consentForm": {
    "id": "uuid",
    "study_id": "uuid",
    "title": "Study Informed Consent",
    "requires_signature": true,
    "is_active": true,
    "version": 1
  }
}
```

---

### Get Consent Form
**GET** `/consent/study/:studyId`

Get the active consent form for a study.

**Response (200):**
```json
{
  "id": "uuid",
  "study_id": "uuid",
  "title": "Study Informed Consent",
  "content": "Full consent text...",
  "requires_signature": true,
  "pages": [
    {
      "id": "uuid",
      "page_number": 1,
      "title": "Introduction",
      "content": "..."
    }
  ]
}
```

---

### Add Consent Page
**POST** `/consent/:consentId/pages`

Add a page to a multi-page consent form.

**Request Body:**
```json
{
  "pageNumber": 1,
  "title": "Introduction",
  "content": "Page content...",
  "displayOrder": 1
}
```

**Response (201):**
```json
{
  "message": "Consent page added successfully",
  "page": {
    "id": "uuid",
    "consent_form_id": "uuid",
    "page_number": 1,
    "title": "Introduction"
  }
}
```

---

## 🎟️ Enrollment Endpoints

### Generate Enrollment Tokens
**POST** `/enrollment/generate-tokens`

Generate enrollment tokens for patient recruitment.

**Request Body:**
```json
{
  "studyId": "uuid",
  "count": 10,
  "expiresInDays": 30
}
```

**Response (201):**
```json
{
  "message": "10 enrollment tokens generated successfully",
  "tokens": [
    "ABC123DEF456",
    "GHI789JKL012"
  ],
  "expiresAt": "2024-03-25T10:00:00Z"
}
```

---

### Get Enrollment Tokens
**GET** `/enrollment/tokens/:studyId`

List enrollment tokens for a study.

**Query Parameters:**
- `used=true|false` - Filter by usage status
- `unused=true` - Get only unused tokens

**Response (200):**
```json
[
  {
    "id": "uuid",
    "token": "ABC123DEF456",
    "is_used": false,
    "used_at": null,
    "expires_at": "2024-03-25T10:00:00Z",
    "created_at": "2024-02-23T10:00:00Z"
  }
]
```

---

### Get Enrollment Stats
**GET** `/enrollment/stats/:studyId`

Get enrollment statistics.

**Response (200):**
```json
{
  "total_tokens": 100,
  "used_tokens": 45,
  "available_tokens": 50,
  "expired_tokens": 5
}
```

---

### Get Enrollment Config
**GET** `/enrollment/config/:studyId`

Get enrollment configuration.

**Response (200):**
```json
{
  "id": "uuid",
  "study_id": "uuid",
  "max_participants": 500,
  "current_participants": 45,
  "requires_token": true,
  "allow_self_enrollment": false,
  "eligibility_criteria": "Age 18-65..."
}
```

---

### Update Enrollment Config
**PUT** `/enrollment/config/:studyId`

Update enrollment configuration.

**Request Body:**
```json
{
  "maxParticipants": 500,
  "requiresToken": true,
  "allowSelfEnrollment": false,
  "eligibilityCriteria": "Age 18-65, confirmed diagnosis"
}
```

---

### Revoke Token
**POST** `/enrollment/revoke-token/:tokenId`

Revoke an enrollment token.

**Response (200):**
```json
{
  "message": "Token revoked successfully",
  "token": {
    "id": "uuid",
    "expires_at": "2024-02-23T10:00:00Z"
  }
}
```

---

## 👤 User Endpoints

### Get Current User
**GET** `/users/me`

Get information about the logged-in user.

**Response (200):**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "role": "coordinator",
  "is_active": true,
  "created_at": "2024-02-23T10:00:00Z"
}
```

---

### Get All Users (Admin)
**GET** `/users`

List all users (Super Admin only).

**Response (200):**
```json
[
  {
    "id": "uuid",
    "email": "user@example.com",
    "first_name": "John",
    "role": "coordinator",
    "is_active": true
  }
]
```

---

### Update User Role (Admin)
**PUT** `/users/:userId/role`

Update a user's role (Super Admin only).

**Request Body:**
```json
{
  "role": "admin"
}
```

**Valid Roles:**
- `super_admin` - Full system access
- `admin` - Study and user management
- `coordinator` - Study operation
- `researcher` - Read-only access

---

### Deactivate User (Admin)
**PUT** `/users/:userId/deactivate`

Deactivate a user account.

**Response (200):**
```json
{
  "message": "User deactivated successfully",
  "user": {
    "id": "uuid",
    "is_active": false
  }
}
```

---

## 🔍 Error Codes

| Code | Meaning |
|------|---------|
| `200` | Success |
| `201` | Created |
| `400` | Bad Request |
| `401` | Unauthorized |
| `403` | Forbidden |
| `404` | Not Found |
| `409` | Conflict |
| `500` | Server Error |

---

## 🔄 Request/Response Examples

### Create Study and Survey
```bash
# 1. Create study
STUDY=$(curl -X POST http://localhost:5000/api/studies \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "studyId": "GI-UC-2026",
    "title": "UC Study",
    "diseaseArea": "UC"
  }' | jq -r '.study.id')

# 2. Create survey
curl -X POST http://localhost:5000/api/surveys \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"studyId\": \"$STUDY\",
    \"title\": \"Weekly Check\",
    \"frequency\": \"weekly\"
  }"
```

---

## 📖 Rate Limits

Currently no rate limiting. Production deployment should implement:
- 100 requests/minute per user
- 1000 requests/minute per IP
- 10MB max request size

---

## 🔐 Security Notes

- All passwords hashed with bcrypt (10 salt rounds)
- JWT tokens expire in 7 days (configurable)
- All data encrypted at rest in production
- HIPAA audit logging on all operations
- SQL injection prevention via parameterized queries
