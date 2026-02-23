# Quick Start Guide

Get the GI Clinical Studies WCP up and running in 5 minutes.

## Prerequisites
- Node.js 16+
- PostgreSQL 13+
- npm

## 1. Install Dependencies (2 min)

```bash
cd wcp-portal

# Install backend dependencies
npm install

# Install frontend dependencies
cd frontend && npm install && cd ..
```

## 2. Configure Database (1 min)

Create `.env` file:
```bash
cp .env.example .env
```

Edit `.env`:
```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=gi_clinical_studies
DB_USER=postgres
DB_PASSWORD=your_postgres_password
JWT_SECRET=change_this_to_random_string_in_production
```

## 3. Initialize Database (1 min)

```bash
npm run db:init
```

## 4. Start Development Servers (1 min)

```bash
npm run dev
```

This starts:
- **Backend:** http://localhost:5000
- **Frontend:** http://localhost:3000

## 5. Login & Explore

Go to http://localhost:3000

Create a new account or use demo:
- Email: admin@giclinicalstudies.com
- Password: demo123456

## 📚 What You Can Do

### Dashboard
- Create a new study (e.g., GI-UC-2026)
- Select disease area (UC, CD, NASH)
- View all your studies

### Study Builder
- Add surveys with questions
- Configure informed consent forms
- Set up enrollment tokens
- Track study metrics

### API Testing
Test endpoints with curl:

```bash
# Get studies
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:5000/api/studies

# Create survey
curl -X POST http://localhost:5000/api/surveys \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "studyId": "study-uuid",
    "title": "Weekly Symptom Check",
    "frequency": "weekly"
  }'
```

## 🔧 Troubleshooting

### PostgreSQL Connection Error
```
Check that PostgreSQL is running:
- Mac: brew services start postgresql
- Linux: sudo systemctl start postgresql
- Windows: Check Services
```

### Port Already in Use
```bash
# Backend (5000)
lsof -i :5000
kill -9 <PID>

# Frontend (3000)
lsof -i :3000
kill -9 <PID>
```

### Database Already Exists
```bash
# Drop and recreate
npm run db:init
```

## 📖 Next Steps

1. **Read the full README:** `./README.md`
2. **Explore the API:** Routes are in `backend/routes/`
3. **Add more features:** Studies, surveys, questions
4. **Deploy:** See deployment section in README

## 🎯 Common Tasks

### Create a Study via API
```bash
curl -X POST http://localhost:5000/api/studies \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN" \
  -d '{
    "studyId": "GI-UC-2026",
    "title": "UC Study 2026",
    "description": "Ulcerative Colitis Research",
    "diseaseArea": "UC",
    "phase": "Phase III",
    "durationWeeks": 52
  }'
```

### Create a Survey
```bash
curl -X POST http://localhost:5000/api/surveys \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN" \
  -d '{
    "studyId": "study-id-uuid",
    "title": "Weekly Mayo Score",
    "surveyType": "weekly",
    "frequency": "weekly"
  }'
```

### Generate Enrollment Tokens
```bash
curl -X POST http://localhost:5000/api/enrollment/generate-tokens \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN" \
  -d '{
    "studyId": "study-id-uuid",
    "count": 10,
    "expiresInDays": 30
  }'
```

## 💡 Tips

- The database automatically creates audit logs for compliance
- All API responses are paginated and timestamped
- User roles: super_admin, admin, coordinator, researcher
- Studies can be published, paused, or archived
- Consent forms support HTML formatting

## 📞 Need Help?

1. Check the full README.md
2. Review database schema: `database/schema.sql`
3. Check API route files in `backend/routes/`
4. Read through the component files in `frontend/src/`
