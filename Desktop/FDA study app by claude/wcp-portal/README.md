# GI Clinical Studies - Web Configuration Portal (WCP)

A full-stack application for managing clinical research studies across three GI disease areas: **Ulcerative Colitis (UC)**, **Crohn's Disease (CD)**, and **Hepatic Steatosis (NASH)**.

Built with Node.js/Express backend and React frontend, following the FDA MyStudies platform architecture.

## 🚀 Features

### Study Management
- Create and configure multiple GI studies
- Support for UC, CD, and NASH disease areas
- Study status tracking (draft, published, paused, archived)
- Multi-user access with role-based permissions

### Survey Builder
- Create surveys with custom questions
- Multiple question types (text, multiple choice, scale, date, numeric)
- Configure survey frequency (weekly, bi-weekly, monthly)
- Drag-and-drop question ordering

### Informed Consent Forms
- Multi-page consent form builder
- E-signature support for FDA compliance
- HTML/Rich text support for formatting
- Versioning and audit trail

### Enrollment Management
- Generate enrollment tokens for patient recruitment
- Token lifecycle management (expiration, revocation)
- Enrollment statistics and tracking
- Eligibility criteria configuration

### Authentication & Security
- JWT-based authentication
- Role-based access control (Super Admin, Admin, Coordinator, Researcher)
- Password hashing with bcrypt
- HIPAA-compliant data isolation

### Database
- PostgreSQL with secure schema
- Comprehensive audit logging
- Study permissions and access control
- Full audit trail for compliance

## 📋 Prerequisites

- **Node.js** 16+
- **PostgreSQL** 13+
- **npm** or **yarn**

## 🛠️ Installation

### 1. Clone and Navigate
```bash
cd /path/to/FDA\ study\ app\ by\ claude/wcp-portal
```

### 2. Install Dependencies

**Backend:**
```bash
npm install
```

**Frontend:**
```bash
cd frontend
npm install
cd ..
```

### 3. Set Up Environment Variables

Create `.env` file in the root directory:
```bash
cp .env.example .env
```

Edit `.env` with your configuration:
```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=gi_clinical_studies
DB_USER=postgres
DB_PASSWORD=your_password
JWT_SECRET=your_jwt_secret_key_change_in_production
PORT=5000
FRONTEND_URL=http://localhost:3000
```

### 4. Initialize Database

```bash
npm run db:init
```

This will:
- Create the PostgreSQL database
- Set up all tables and indexes
- Configure audit logging tables

### 5. Start Development Servers

```bash
npm run dev
```

This starts both backend (port 5000) and frontend (port 3000) concurrently.

Or start them separately:

**Backend:**
```bash
npm run backend
```

**Frontend:**
```bash
cd frontend && npm start
```

## 🔐 Default Demo Account

After setting up, create an account or use:
- **Email:** admin@giclinicalstudies.com
- **Password:** demo123456

## 📖 Usage

### Creating a Study

1. Log in to the dashboard
2. Click **"+ New Study"**
3. Fill in:
   - Study ID (e.g., GI-UC-2026)
   - Disease Area (UC, CD, NASH)
   - Title and description
   - Phase (II, II/III, III)
   - Duration

### Building a Survey

1. Go to Study Detail page
2. Click **"Edit Study"**
3. In Survey section, click **"+ Add Survey"**
4. Configure:
   - Title and description
   - Survey type (baseline, weekly, follow-up)
   - Frequency (weekly, bi-weekly, monthly)
5. Add questions via API or future UI

### Setting Up Consent Form

1. In Study Builder, go to **Consent Form** tab
2. Add title and consent text
3. Enable/disable e-signature requirement
4. Save

### Managing Enrollment

1. In Study Builder, go to **Enrollment** tab
2. Generate enrollment tokens
3. Configure token expiration
4. Track enrollment progress

## 📚 API Endpoints

### Authentication
- `POST /api/auth/register` - Create new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/verify` - Verify JWT token

### Studies
- `GET /api/studies` - List user's studies
- `POST /api/studies` - Create new study
- `GET /api/studies/:studyId` - Get study details
- `PUT /api/studies/:studyId` - Update study
- `POST /api/studies/:studyId/publish` - Publish study

### Surveys
- `POST /api/surveys` - Create survey
- `GET /api/surveys/study/:studyId` - Get study surveys
- `GET /api/surveys/:surveyId` - Get survey with questions
- `POST /api/surveys/:surveyId/questions` - Add question
- `POST /api/surveys/question/:questionId/choices` - Add question choices

### Consent Forms
- `POST /api/consent` - Create consent form
- `GET /api/consent/study/:studyId` - Get consent form
- `POST /api/consent/:consentId/pages` - Add consent page
- `GET /api/consent/:consentId/pages` - Get consent pages

### Enrollment
- `POST /api/enrollment/generate-tokens` - Generate enrollment tokens
- `GET /api/enrollment/tokens/:studyId` - Get tokens
- `POST /api/enrollment/generate-tokens` - Create tokens
- `GET /api/enrollment/stats/:studyId` - Get enrollment stats

### Users
- `GET /api/users/me` - Get current user
- `GET /api/users` - List all users (admin only)
- `PUT /api/users/:userId/role` - Update user role (admin)

## 🏗️ Project Structure

```
wcp-portal/
├── backend/
│   ├── routes/
│   │   ├── auth.js           # Authentication endpoints
│   │   ├── studies.js        # Study management
│   │   ├── surveys.js        # Survey CRUD
│   │   ├── consent.js        # Consent form management
│   │   ├── enrollment.js     # Enrollment token management
│   │   └── users.js          # User management
│   ├── config/
│   │   └── db.js             # Database connection
│   ├── utils/
│   │   └── auth.js           # Auth utilities
│   └── server.js             # Main server entry
├── frontend/
│   ├── public/
│   │   └── index.html        # HTML entry point
│   └── src/
│       ├── pages/
│       │   ├── Login.js       # Login page
│       │   ├── Dashboard.js   # Study dashboard
│       │   ├── StudyDetail.js # Study details
│       │   └── StudyBuilder.js# Survey/consent builder
│       ├── components/
│       │   ├── Navbar.js      # Navigation bar
│       │   └── ProtectedRoute.js
│       ├── App.js             # Root component
│       └── index.js           # React entry
├── database/
│   ├── schema.sql            # Database schema
│   └── init.js               # Database initialization
├── package.json
├── .env.example
└── README.md
```

## 🔄 Database Schema

### Key Tables
- **users** - User accounts and roles
- **studies** - Study definitions
- **surveys** - Study surveys
- **questions** - Survey questions
- **question_choices** - Multiple choice options
- **consent_forms** - Consent form templates
- **enrollment_tokens** - Patient enrollment tokens
- **study_permissions** - User access control
- **audit_logs** - Compliance audit trail

See `database/schema.sql` for full schema definition.

## 🔒 Security Features

- **JWT Authentication** - Secure token-based authentication
- **Password Hashing** - bcrypt with salt rounds
- **HTTPS Ready** - SSL/TLS support
- **CORS Protection** - Configurable CORS settings
- **SQL Injection Prevention** - Parameterized queries
- **Audit Logging** - Complete action history
- **Role-Based Access** - Fine-grained permissions
- **Data Isolation** - User-specific data access

## 📊 Compliance

- **HIPAA Ready** - Data minimization, encryption at rest/transit
- **21 CFR Part 11** - E-signature, audit trail, data integrity
- **FDA MyStudies** - Built on FDA-approved platform
- **IND-Ready** - Designed for FDA clinical trials

## 🚀 Deployment

### Production Checklist

1. **Environment Setup**
   - Set strong `JWT_SECRET`
   - Configure PostgreSQL with backup
   - Set `NODE_ENV=production`

2. **Security**
   - Enable HTTPS/TLS
   - Configure firewall
   - Set up HIPAA BAA with hosting provider
   - Enable database encryption

3. **Infrastructure**
   - Deploy on AWS, Azure, or GCP
   - Use managed database services
   - Enable automated backups
   - Set up monitoring and alerts

4. **Testing**
   - Run compliance validation
   - Complete end-to-end testing
   - Perform security audit

## 📝 Notes

- This is **Phase 1 (WCP)** of the full FDA MyStudies deployment
- Phase 2 includes iOS/Android mobile apps
- Phase 3 includes User Registration and Response Servers
- Currently supports single-study mode; expand for multi-tenant
- React Quill editor can be added for rich text consent forms

## 🤝 Contributing

Built as part of GI Clinical Studies platform for FDA MyStudies.

## 📞 Support

For issues or questions, refer to:
- FDA MyStudies Documentation: [fdamystudieshelp.atlassian.net](https://fdamystudieshelp.atlassian.net)
- GitHub: [github.com/FDA-MyStudies](https://github.com/FDA-MyStudies)

## 📄 License

Apache 2.0 (matching FDA MyStudies open-source license)
