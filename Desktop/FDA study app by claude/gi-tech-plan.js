const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  Header, Footer, AlignmentType, HeadingLevel, BorderStyle, WidthType,
  ShadingType, VerticalAlign, PageNumber, PageBreak, LevelFormat,
  TableOfContents, UnderlineType
} = require('docx');
const fs = require('fs');

// ── Colors ────────────────────────────────────────────────────────────────
const C = {
  green:      "1A6B4A",
  greenLight: "E8F5EF",
  greenMid:   "2E9D6E",
  orange:     "C2410C",
  orangeLight:"FFF7ED",
  purple:     "7C3AED",
  purpleLight:"F5F3FF",
  blue:       "0369A1",
  blueLight:  "E0F2FE",
  headerBg:   "0D3B26",
  rowAlt:     "F0F9F4",
  border:     "AECFBE",
  dark:       "1F2937",
  gray:       "6B7280",
  white:      "FFFFFF",
  yellow:     "FEF3C7",
  red:        "FEE2E2",
};

const border = (color = C.border) => ({ style: BorderStyle.SINGLE, size: 6, color });
const cellBorders = (color = C.border) => ({ top: border(color), bottom: border(color), left: border(color), right: border(color) });

function hdr(text, lvl = HeadingLevel.HEADING_1, color = C.green, spaceB = 300, spaceA = 160) {
  return new Paragraph({
    heading: lvl,
    spacing: { before: spaceB, after: spaceA },
    children: [new TextRun({ text, color, bold: true })]
  });
}

function p(children, opts = {}) {
  if (typeof children === 'string') children = [new TextRun({ text: children, color: C.dark })];
  return new Paragraph({ spacing: { after: 120, line: 276, lineRule: 'auto' }, ...opts, children });
}

function bold(text, color = C.dark) { return new TextRun({ text, bold: true, color }); }
function run(text, color = C.dark, opts = {}) { return new TextRun({ text, color, ...opts }); }

function bullet(text, level = 0, color = C.dark) {
  const children = typeof text === 'string'
    ? [new TextRun({ text, color })]
    : text;
  return new Paragraph({
    numbering: { reference: "bullets", level },
    spacing: { after: 80 },
    children
  });
}

function numbered(text, level = 0, color = C.dark) {
  return new Paragraph({
    numbering: { reference: "numbers", level },
    spacing: { after: 80 },
    children: [new TextRun({ text, color })]
  });
}

// Section divider line
function divider() {
  return new Paragraph({
    border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: C.green } },
    spacing: { after: 200 },
    children: []
  });
}

// Colored callout box (simulated with a 1-cell table)
function callout(label, text, bg, borderColor, labelColor) {
  return new Table({
    width: { size: 9360, type: WidthType.DXA },
    columnWidths: [9360],
    rows: [new TableRow({ children: [new TableCell({
      borders: cellBorders(borderColor),
      shading: { fill: bg, type: ShadingType.CLEAR },
      margins: { top: 140, bottom: 140, left: 200, right: 200 },
      width: { size: 9360, type: WidthType.DXA },
      children: [new Paragraph({
        spacing: { after: 60 },
        children: [bold(label + "  ", labelColor), run(text, C.dark)]
      })]
    })]})],
  });
}

// Standard data table
function dataTable(headers, rows, colWidths) {
  const totalW = colWidths.reduce((a, b) => a + b, 0);
  const makeCell = (text, isHeader, width, bg) => new TableCell({
    borders: cellBorders(C.border),
    shading: { fill: isHeader ? C.headerBg : (bg || C.white), type: ShadingType.CLEAR },
    margins: { top: 100, bottom: 100, left: 140, right: 140 },
    width: { size: width, type: WidthType.DXA },
    verticalAlign: VerticalAlign.CENTER,
    children: [new Paragraph({ spacing: { after: 0 }, children: [
      isHeader
        ? new TextRun({ text: text || '', bold: true, color: C.white, size: 20 })
        : new TextRun({ text: text || '', color: C.dark, size: 20 })
    ]})]
  });

  return new Table({
    width: { size: totalW, type: WidthType.DXA },
    columnWidths: colWidths,
    rows: [
      new TableRow({ tableHeader: true, children: headers.map((h, i) => makeCell(h, true, colWidths[i])) }),
      ...rows.map((row, ri) =>
        new TableRow({ children: row.map((cell, i) => makeCell(cell, false, colWidths[i], ri % 2 === 1 ? C.rowAlt : C.white)) })
      )
    ]
  });
}

function spacer(pts = 120) {
  return new Paragraph({ spacing: { after: pts }, children: [] });
}

// ── Document Body ──────────────────────────────────────────────────────────
const children = [

  // ── Cover Page ────────────────────────────────────────────────────────
  new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { before: 1440, after: 240 },
    children: [new TextRun({ text: "GI Clinical Studies.com", bold: true, size: 56, color: C.green, font: "Arial" })]
  }),
  new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { after: 160 },
    children: [new TextRun({ text: "Technical Implementation Plan", bold: true, size: 40, color: C.dark, font: "Arial" })]
  }),
  new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { after: 80 },
    children: [new TextRun({ text: "FDA MyStudies Platform — Full-Stack Deployment", size: 26, color: C.gray, font: "Arial" })]
  }),
  new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { after: 80 },
    children: [new TextRun({ text: "Ulcerative Colitis  ·  Crohn's Disease  ·  Hepatic Steatosis (NASH)", size: 24, color: C.greenMid, bold: true, font: "Arial" })]
  }),
  new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { after: 80 },
    children: [new TextRun({ text: "Version 1.0  |  February 2026", size: 22, color: C.gray, font: "Arial" })]
  }),
  new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { after: 80 },
    children: [new TextRun({ text: "Prepared for: Dr. Saini  |  GIClinicalStudies.com", size: 22, color: C.gray, font: "Arial", italics: true })]
  }),

  spacer(800),
  new Paragraph({ children: [new PageBreak()] }),

  // ── Table of Contents ─────────────────────────────────────────────────
  new TableOfContents("Table of Contents", { hyperlink: true, headingStyleRange: "1-3" }),
  new Paragraph({ children: [new PageBreak()] }),

  // ── 1. Executive Summary ──────────────────────────────────────────────
  hdr("1. Executive Summary"),
  divider(),
  p([
    run("GI Clinical Studies.com is implementing the "),
    bold("FDA MyStudies open-source platform"),
    run(" to deploy research-grade, HIPAA- and FISMA-compliant mobile study apps for three GI disease areas: "),
    bold("Ulcerative Colitis (UC)"),
    run(", "),
    bold("Crohn's Disease (CD)"),
    run(", and "),
    bold("Hepatic Steatosis (NASH/MAFLD)"),
    run(". This document outlines every technical component required for a complete deployment — from mobile app to backend data submission — and provides a phased roadmap for the build.")
  ]),
  spacer(100),
  p([
    run("The FDA MyStudies platform is "),
    bold("proven in GI research"),
    run(": the "),
    bold("IBD PROdigy app"),
    run(" (funded by the Crohn's & Colitis Foundation) and the "),
    bold("SPARC IBD study"),
    run(" are both built on this exact codebase. GI Clinical Studies.com can follow the same blueprint, rebranded and configured for its three studies.")
  ]),
  spacer(120),

  callout("KEY OUTCOME:", "Patients complete surveys on their iOS or Android device. Responses are encrypted in transit, stored in a FISMA/21 CFR Part 11-compliant LabKey Response Server, and exported to the study sponsor in SAS, Excel, or R format — fully auditable and IND-ready.", C.greenLight, C.greenMid, C.green),
  spacer(200),

  hdr("What These Documents Provide", HeadingLevel.HEADING_2, C.greenMid, 200, 120),
  dataTable(
    ["Document", "What It Covers", "Completeness"],
    [
      ["FDA Quick Overview (2026)", "Features, question types, enrollment & consent flow", "✅ Complete"],
      ["Technical Setup Document", "All 4 server components, iOS/Android build steps, deployment guide", "✅ Complete"],
      ["FDA Technical Background", "Compliance (21 CFR Part 11, FISMA), IND readiness, IBD precedent", "✅ Complete"],
      ["FDA/GitHub Repository", "Full open-source code — all 6 submodules (iOS, Android, WCP, servers)", "✅ Complete (code)"],
      ["GitHub README", "Git clone/pull instructions, component architecture, setup links", "✅ Complete"],
    ],
    [3200, 4000, 2160]
  ),
  spacer(120),
  callout("IMPORTANT NOTE:", "The setup documents point to detailed sub-pages on the FDA MyStudies wiki. Those linked pages (e.g., WCP setup, iOS Xcode guide, LabKey Response Server config) must be accessed separately from the FDA documentation site. A developer will need all linked sub-documents plus a LabKey Server instance.", C.yellow, C.orange, C.orange),

  new Paragraph({ children: [new PageBreak()] }),

  // ── 2. System Architecture ────────────────────────────────────────────
  hdr("2. System Architecture Overview"),
  divider(),
  p("The FDA MyStudies system has four major components that must be deployed and connected. All communicate via secure REST APIs."),
  spacer(120),

  dataTable(
    ["Component", "Technology", "Role", "Hosted By"],
    [
      ["Web Configuration Portal (WCP)", "Java (Spring)", "Admins design surveys, set schedules, manage consent, publish studies", "GI Clinical Studies (self-host or cloud)"],
      ["User Registration Server", "LabKey Server (Java)", "Participant sign-up, login, study enrollment metadata, push notifications", "GI Clinical Studies (LabKey instance)"],
      ["Response Server", "LabKey Server", "Receives & stores all participant survey responses — the sponsor backend", "GI Clinical Studies (LabKey instance)"],
      ["Mobile App — iOS", "Swift / ResearchKit", "Participant-facing app: surveys, consent, dashboard", "Apple App Store"],
      ["Mobile App — Android", "Java / ResearchStack", "Participant-facing app: surveys, consent, dashboard", "Google Play Store"],
    ],
    [2800, 2000, 2800, 1760]
  ),
  spacer(160),

  hdr("Data Flow", HeadingLevel.HEADING_2, C.greenMid, 200, 120),
  p([
    bold("Step 1 — Study Design: "),
    run("Study coordinator logs into the WCP and configures GI studies (UC, CD, NASH): survey questions, schedule, consent forms, eligibility criteria, and branding.")
  ]),
  bullet([bold("Output: "), run("Study metadata published to all connected mobile apps.")]),
  spacer(80),
  p([bold("Step 2 — Participant Enrollment: "), run("Patient downloads the GI Clinical Studies iOS or Android app, enters their enrollment token, reviews consent, e-signs, and joins the study.")]),
  bullet([bold("Output: "), run("Enrollment record created in User Registration Server under anonymized Participant ID.")]),
  spacer(80),
  p([bold("Step 3 — Survey Completion: "), run("Patient receives push notifications per study schedule (weekly for UC, bi-weekly for CD, monthly for NASH). Patient completes survey; responses saved locally on device and submitted when internet is available.")]),
  bullet([bold("Output: "), run("Encrypted responses sent to Response Server, stored against Participant ID (never name or PHI).")]),
  spacer(80),
  p([bold("Step 4 — Sponsor Data Access: "), run("Study sponsor/coordinator logs into LabKey admin portal, accesses partitioned study folder, and exports data in SAS, Excel, or R format for statistical analysis.")]),
  bullet([bold("Output: "), run("Clean, analyzable dataset with full audit trail — IND-ready.")]),

  new Paragraph({ children: [new PageBreak()] }),

  // ── 3. Component Setup ────────────────────────────────────────────────
  hdr("3. Component Setup Requirements"),
  divider(),

  // 3.1 WCP
  hdr("3.1  Web Configuration Portal (WCP)", HeadingLevel.HEADING_2, C.greenMid, 200, 100),
  p("The WCP is a Java web application where your team designs and manages all three GI studies. No mobile code changes are needed when adding or editing study content."),
  spacer(80),
  dataTable(
    ["Requirement", "Detail"],
    [
      ["Language / Framework", "Java (Spring MVC) — pre-built, open source"],
      ["Build Tool", "Maven or Gradle"],
      ["Database", "MySQL 5.7+ or PostgreSQL"],
      ["App Server", "Apache Tomcat 8.5+"],
      ["Server OS", "Ubuntu 20.04 LTS or RHEL 8+"],
      ["SSL/TLS", "Required — HTTPS only (Let's Encrypt or commercial cert)"],
      ["Admin Access", "Super Admin email configured at setup; role-based access for each study"],
      ["GitHub Source", "github.com/FDA-MyStudies/ → WCP and WCP-WS submodules"],
    ],
    [3600, 5760]
  ),
  spacer(120),
  p("What you can configure in the WCP for each GI study:"),
  bullet("Study name, description, branding (GI Clinical Studies.com colors and logo)"),
  bullet("Eligibility test (token-based for pre-screened patients)"),
  bullet("Informed consent — multi-page, e-signature, PDF generation"),
  bullet("Survey questions: Mayo Score (UC), Harvey-Bradshaw Index (CD), metabolic tracking (NASH)"),
  bullet("Schedule: weekly (UC), bi-weekly (CD), monthly (NASH) — or enrollment-date-anchored"),
  bullet("Push notifications (APNS / FCM)"),
  bullet("Resources: PDFs, links, study FAQs"),
  bullet("Dashboard stats: study completion %, on-time rate, trend graphs"),
  spacer(160),

  // 3.2 User Registration Server
  hdr("3.2  User Registration Server", HeadingLevel.HEADING_2, C.greenMid, 200, 100),
  p("Built on the LabKey Server framework. Handles all participant account creation, login, and study participation metadata. Does NOT store actual response data — that goes to the Response Server."),
  spacer(80),
  dataTable(
    ["Requirement", "Detail"],
    [
      ["Platform", "LabKey Server (open source, Apache 2.0 license)"],
      ["Java Version", "JDK 11+"],
      ["Database", "PostgreSQL 13+ (recommended for LabKey)"],
      ["Minimum RAM", "8 GB (16 GB recommended for production)"],
      ["Storage", "50 GB+ depending on participant volume"],
      ["Folder Structure", "Org Folder → App Folder → Study Folder (one per study: UC, CD, NASH)"],
      ["Key Setup Step", "Create folder structure BEFORE publishing studies from WCP"],
      ["Push Notifications", "Connects to APNS (Apple) and Firebase (Google) — credentials required"],
      ["GitHub Source", "github.com/FDA-MyStudies/ → UserReg-WS submodule"],
    ],
    [3600, 5760]
  ),
  spacer(120),
  callout("MULTI-APP NOTE:", "Each GI study app must have its own folder in the User Registration Server. Participants must sign up separately for each app. User data is not shared between study apps.", C.blueLight, C.blue, C.blue),
  spacer(160),

  // 3.3 Response Server
  hdr("3.3  Response Server — Sponsor Backend", HeadingLevel.HEADING_2, C.greenMid, 200, 100),
  p([
    run("The Response Server is "),
    bold("the backend that receives and stores all participant survey responses"),
    run(". It is also the primary data source for the study sponsor. It is built on LabKey Server and can be the same LabKey instance as the User Registration Server or a separate one.")
  ]),
  spacer(80),
  dataTable(
    ["Requirement", "Detail"],
    [
      ["Platform", "LabKey Server (same infrastructure as User Registration Server)"],
      ["Participant Privacy", "Responses stored against anonymized Participant ID only — no names or PHI linkage"],
      ["Data Security", "Encrypted at rest and in transit; FISMA-compliant audit logging"],
      ["PHI Column Marking", "Admins can mark individual columns as PHI to restrict visibility"],
      ["Access Control", "Role-based permissions per study folder (UC, CD, NASH can be partitioned)"],
      ["Enrollment Tokens", "Generated here and distributed to patients by coordinator"],
      ["Study Folders", "Create one project per study using the same Study ID as WCP"],
      ["Data Export Formats", "SAS, Excel (.xlsx), R, CSV — automatic/recurring extraction available"],
      ["Audit Trail", "Full event logging for 21 CFR Part 11 / IND compliance"],
      ["GitHub Source", "github.com/FDA-MyStudies/ → Response submodule"],
    ],
    [3600, 5760]
  ),
  spacer(120),

  hdr("Sponsor Data Access Workflow", HeadingLevel.HEADING_3, C.green, 160, 100),
  numbered("Coordinator logs into LabKey admin portal"),
  numbered("Navigates to the relevant study subfolder (e.g., GIClinicalStudies/UC/Week3)"),
  numbered("Reviews survey data grid — filtered by date, participant, or survey type"),
  numbered("Exports to SAS or Excel for statistical analysis"),
  numbered("Optional: configures automated recurring data extraction via API"),
  spacer(160),

  // 3.4 iOS
  hdr("3.4  Mobile App — iOS", HeadingLevel.HEADING_2, C.greenMid, 200, 100),
  dataTable(
    ["Requirement", "Detail"],
    [
      ["Framework", "Apple ResearchKit (Swift) — open source"],
      ["Dev Environment", "Xcode 14+ on macOS 13+"],
      ["iOS Target", "iOS 14.0 minimum"],
      ["Apple Developer Account", "Required — $99/year; needed for TestFlight and App Store submission"],
      ["Bundle ID", "Set unique bundle ID for GI Clinical Studies (e.g., com.giclinicalstudies.app)"],
      ["App Token", "Generated by WCP and configured in Xcode before build"],
      ["Server URLs", "3 URLs configured: Registration Server, WCP Server, Response Server"],
      ["Push Notifications (APNS)", "Apple Push Notification Service certificate required from Apple Developer portal"],
      ["HealthKit Integration", "Optional — allows pulling Apple Health data as survey responses"],
      ["Branding", "App icon, color scheme, home screen image, study thumbnails — all configurable"],
      ["Standalone App Option", "Can be published as standalone app (requires separate App Store approval)"],
      ["GitHub Source", "github.com/FDA-MyStudies/ → iOS submodule"],
    ],
    [3600, 5760]
  ),
  spacer(160),

  // 3.5 Android
  hdr("3.5  Mobile App — Android", HeadingLevel.HEADING_2, C.greenMid, 200, 100),
  dataTable(
    ["Requirement", "Detail"],
    [
      ["Framework", "ResearchStack (Java/Kotlin) — open source"],
      ["Dev Environment", "Android Studio 2022+"],
      ["Android Target", "Android 8.0 (API 26) minimum"],
      ["Google Play Account", "Required — $25 one-time fee; needed for Play Store submission"],
      ["Firebase Project", "Required for push notifications (FCM) — free Google account"],
      ["Server Configuration", "Same 3 server URLs as iOS (set in build config files)"],
      ["Branding", "Same assets as iOS: icon, colors, home screen image"],
      ["Offline Support", "Surveys saved locally; submitted when connectivity restored"],
      ["GitHub Source", "github.com/FDA-MyStudies/ → Android submodule"],
    ],
    [3600, 5760]
  ),

  new Paragraph({ children: [new PageBreak()] }),

  // ── 4. Infrastructure ─────────────────────────────────────────────────
  hdr("4. Infrastructure & Hosting"),
  divider(),
  p("All server components must be deployed on secure, internet-accessible infrastructure. Below are the recommended options for GI Clinical Studies.com."),
  spacer(120),

  dataTable(
    ["Option", "Provider", "Best For", "Est. Monthly Cost", "HIPAA BAA Available"],
    [
      ["Cloud (Recommended)", "AWS or Microsoft Azure", "Scalability, managed services, easiest compliance", "$200–$600/mo", "✅ Yes"],
      ["Cloud (Budget)", "Google Cloud Platform", "Cost-effective, Firebase integration for push", "$150–$400/mo", "✅ Yes"],
      ["Managed LabKey", "LabKey.com hosted service", "Simplest setup — LabKey manages the servers", "Contact LabKey for pricing", "✅ Yes"],
      ["On-Premises", "Your own servers", "Maximum control; requires IT team", "Hardware + IT costs", "Internal policy"],
    ],
    [2000, 1800, 2400, 1760, 1400]
  ),
  spacer(120),

  hdr("Minimum Server Specifications (Cloud VM)", HeadingLevel.HEADING_2, C.greenMid, 200, 100),
  dataTable(
    ["Server", "CPU", "RAM", "Storage", "Notes"],
    [
      ["WCP + WCP-WS", "4 vCPU", "8 GB", "50 GB SSD", "Can be combined with User Reg server for small deployments"],
      ["User Registration Server", "4 vCPU", "16 GB", "100 GB SSD", "LabKey requires significant memory"],
      ["Response Server", "8 vCPU", "32 GB", "500 GB SSD", "Scales with participant data volume; separate from User Reg for production"],
      ["Database (PostgreSQL)", "4 vCPU", "16 GB", "200 GB SSD", "Shared or separate; automated daily backups required"],
    ],
    [2800, 1000, 1000, 1400, 3160]
  ),
  spacer(120),

  callout("SECURITY REQUIREMENTS:", "All servers must use HTTPS (TLS 1.2+). Database must be encrypted at rest. Backups must be automated and tested. Access logs must be retained for audit purposes (21 CFR Part 11). A HIPAA Business Associate Agreement (BAA) must be signed with the cloud provider.", C.red, C.orange, C.orange),

  new Paragraph({ children: [new PageBreak()] }),

  // ── 5. GI Study Configuration ─────────────────────────────────────────
  hdr("5. GI Study-Specific Configuration"),
  divider(),

  hdr("5.1  Ulcerative Colitis Study", HeadingLevel.HEADING_2, C.orange, 200, 100),
  dataTable(
    ["Setting", "Value"],
    [
      ["Study ID (WCP)", "GI-UC-2026"],
      ["Phase", "Phase III"],
      ["Duration", "52 Weeks"],
      ["Survey Schedule", "Weekly (calendar-based or enrollment-date-anchored)"],
      ["Primary Instrument", "Mayo Score (stool frequency, rectal bleeding, physician global assessment)"],
      ["Secondary Measures", "Symptom burden, medication adherence, QoL (IBDQ items)"],
      ["Eligibility", "Enrollment token — pre-screened patients from EHR or physician referral"],
      ["Consent", "Multi-page e-consent with UC-specific risks, benefits, and privacy disclosure"],
      ["Dashboard", "Configurable: Mayo Score trend graph, on-time completion %, study progress %"],
      ["Data Export", "Weekly SAS/Excel export to UC study sponsor folder"],
      ["App Icon / Color", "GI Clinical Studies green + UC orange accent (#C2410C)"],
      ["Resource PDFs", "UC Medication Guide, CCFA patient resources, coordinator contact"],
    ],
    [3200, 6160]
  ),
  spacer(160),

  hdr("5.2  Crohn's Disease Study", HeadingLevel.HEADING_2, C.purple, 200, 100),
  dataTable(
    ["Setting", "Value"],
    [
      ["Study ID (WCP)", "GI-CD-2026"],
      ["Phase", "Phase II/III"],
      ["Duration", "48 Weeks"],
      ["Survey Schedule", "Bi-weekly"],
      ["Primary Instrument", "Harvey-Bradshaw Index (HBI) — stool count, wellbeing, abdominal pain, complications"],
      ["Secondary Measures", "Nutritional status, unscheduled visits, fistula/fissure tracking"],
      ["Eligibility", "Enrollment token — coordinator distributed to confirmed CD patients"],
      ["Consent", "Multi-page e-consent covering CD-specific study procedures and data use"],
      ["Dashboard", "HBI trend line, complication frequency tracker, study activity calendar"],
      ["Data Export", "Bi-weekly SAS/Excel export; option for LabKey API automated extraction"],
      ["App Icon / Color", "GI Clinical Studies green + CD purple accent (#7C3AED)"],
      ["Resource PDFs", "Crohn's & Colitis Foundation links, diet guide, emergency contacts"],
    ],
    [3200, 6160]
  ),
  spacer(160),

  hdr("5.3  Hepatic Steatosis (NASH) Study", HeadingLevel.HEADING_2, C.blue, 200, 100),
  dataTable(
    ["Setting", "Value"],
    [
      ["Study ID (WCP)", "GI-NASH-2026"],
      ["Phase", "Phase II"],
      ["Duration", "24 Weeks"],
      ["Survey Schedule", "Monthly"],
      ["Primary Measures", "Weight, fatigue level, RUQ pain, physical activity (days/week), alcohol use"],
      ["Secondary Measures", "Diet quality, jaundice signs (yellowing, dark urine), ankle swelling, bruising"],
      ["Eligibility", "Enrollment token — pre-screened from hepatology clinic patients"],
      ["Consent", "Multi-page e-consent with NASH metabolic study disclosure"],
      ["Dashboard", "Weight trend graph, activity streak tracker, metabolic score summary"],
      ["Data Export", "Monthly SAS/Excel export; R script templates for metabolic analysis"],
      ["App Icon / Color", "GI Clinical Studies green + NASH blue accent (#0369A1)"],
      ["Resource PDFs", "NASH patient guide, dietary recommendations, hepatology team contacts"],
    ],
    [3200, 6160]
  ),

  new Paragraph({ children: [new PageBreak()] }),

  // ── 6. Phased Build Roadmap ───────────────────────────────────────────
  hdr("6. Phased Build Roadmap"),
  divider(),
  p("The build is organized into four phases. Each phase can be undertaken by a developer team familiar with Java, iOS/Android, and server administration. Total estimated timeline: 20–28 weeks."),
  spacer(120),

  hdr("Phase 1 — Infrastructure & Backend (Weeks 1–6)", HeadingLevel.HEADING_2, C.greenMid, 200, 100),
  dataTable(
    ["Task", "Who", "Duration", "Output"],
    [
      ["Select cloud hosting provider (AWS/Azure recommended); sign HIPAA BAA", "IT/Admin", "1 week", "Hosting contract + BAA"],
      ["Provision servers (4 VMs: WCP, User Reg, Response, Database)", "DevOps", "1 week", "Live server infrastructure"],
      ["Install and configure PostgreSQL on database server", "Backend Dev", "3 days", "Database ready"],
      ["Deploy LabKey Server for User Registration Server", "Backend Dev", "2 weeks", "LabKey User Reg running"],
      ["Deploy LabKey Server for Response Server; create UC/CD/NASH project folders", "Backend Dev", "1 week", "Response Server with 3 study folders"],
      ["Configure SSL/TLS on all servers; set up firewall rules", "DevOps", "3 days", "HTTPS enforced"],
      ["Set up automated database backups and monitoring", "DevOps", "2 days", "Backup pipeline active"],
    ],
    [3500, 1400, 1200, 3260]
  ),
  spacer(160),

  hdr("Phase 2 — Web Configuration Portal (Weeks 5–10)", HeadingLevel.HEADING_2, C.greenMid, 200, 100),
  dataTable(
    ["Task", "Who", "Duration", "Output"],
    [
      ["Clone WCP and WCP-WS submodules from GitHub", "Backend Dev", "1 day", "Code base ready"],
      ["Configure WCP properties files (database, server URLs, super admin email)", "Backend Dev", "3 days", "WCP configured"],
      ["Build and deploy WCP to Tomcat server", "Backend Dev", "3 days", "WCP live and accessible"],
      ["Create Super Admin account; set up WCP user roles for study coordinators", "Admin", "1 day", "Admin access established"],
      ["Configure GI Clinical Studies branding (colors, logo, name)", "Designer + Dev", "3 days", "Branded WCP portal"],
      ["Build UC study in WCP (consent, eligibility, all 8 survey questions, schedule)", "Study Coordinator + Dev", "1 week", "UC study configured"],
      ["Build CD study in WCP (HBI-based survey, bi-weekly schedule)", "Study Coordinator + Dev", "1 week", "CD study configured"],
      ["Build NASH study in WCP (metabolic survey, monthly schedule)", "Study Coordinator + Dev", "1 week", "NASH study configured"],
      ["Configure push notification credentials (APNS + FCM) in WCP", "Dev", "2 days", "Push notifications enabled"],
      ["Generate enrollment tokens for each study in Response Server", "Study Coordinator", "1 day", "Enrollment tokens ready"],
    ],
    [3500, 1400, 1200, 3260]
  ),
  spacer(160),

  hdr("Phase 3 — Mobile Apps (Weeks 10–18)", HeadingLevel.HEADING_2, C.greenMid, 200, 100),
  dataTable(
    ["Task", "Who", "Duration", "Output"],
    [
      ["Clone iOS submodule; open project in Xcode; configure 3 server URLs", "iOS Dev", "2 days", "Project building locally"],
      ["Apply GI Clinical Studies branding to iOS app (icon, splash, color scheme)", "iOS Dev + Designer", "3 days", "Branded iOS app"],
      ["Build and test iOS app with UC study (enrollment, consent, surveys, dashboard)", "iOS Dev", "2 weeks", "UC flow working on iOS"],
      ["Extend iOS app testing to CD and NASH studies", "iOS Dev", "1 week", "All 3 studies on iOS"],
      ["Submit to Apple TestFlight for internal testing; fix bugs", "iOS Dev", "1 week", "TestFlight build"],
      ["Submit iOS app to App Store for review", "iOS Dev", "1–2 weeks (Apple review)", "iOS app live"],
      ["Clone Android submodule; configure server URLs; apply branding", "Android Dev", "1 week", "Android project configured"],
      ["Build and test Android app with all 3 GI studies", "Android Dev", "2 weeks", "Android working"],
      ["Submit to Google Play internal track; test; fix bugs", "Android Dev", "1 week", "Play internal build"],
      ["Submit Android app to Google Play Store for review", "Android Dev", "1 week (Google review)", "Android app live"],
    ],
    [3500, 1400, 1200, 3260]
  ),
  spacer(160),

  hdr("Phase 4 — Testing, Compliance & Launch (Weeks 18–28)", HeadingLevel.HEADING_2, C.greenMid, 200, 100),
  dataTable(
    ["Task", "Who", "Duration", "Output"],
    [
      ["End-to-end test: enroll test participant, complete surveys, verify data in LabKey", "QA + Dev", "1 week", "Full data flow validated"],
      ["21 CFR Part 11 validation documentation (audit trail, e-signature log review)", "Regulatory + Dev", "2 weeks", "IND compliance documentation"],
      ["IRB application for each study (UC, CD, NASH) — review and approval", "Study Team / IRB", "4–8 weeks (parallel)", "IRB approvals"],
      ["HIPAA Risk Assessment and BAA review for all vendors", "Compliance Officer", "1 week", "HIPAA documentation"],
      ["Pilot test with 5–10 patients per study; collect feedback", "Study Coordinator", "2 weeks", "Pilot feedback report"],
      ["Bug fixes and final adjustments based on pilot", "Dev Team", "1 week", "Production-ready app"],
      ["Distribute enrollment tokens to first cohort (UC, CD, NASH)", "Study Coordinator", "1 day", "Cohort enrolled"],
      ["Full study launch — monitor Response Server; validate first submissions", "All Teams", "Ongoing", "Studies live"],
    ],
    [3500, 1400, 1200, 3260]
  ),

  new Paragraph({ children: [new PageBreak()] }),

  // ── 7. Team & Resources ───────────────────────────────────────────────
  hdr("7. Team & Resource Requirements"),
  divider(),
  dataTable(
    ["Role", "Skills Required", "Phase", "Est. Hours"],
    [
      ["Backend Developer (1–2)", "Java, Spring, Maven, LabKey Server, PostgreSQL, Linux server admin", "1, 2", "200–280 hrs"],
      ["iOS Developer (1)", "Swift, Xcode, ResearchKit, Apple Developer Portal, APNS", "3", "120–160 hrs"],
      ["Android Developer (1)", "Java/Kotlin, Android Studio, ResearchStack, Firebase/FCM", "3", "120–160 hrs"],
      ["DevOps Engineer (1, part-time)", "AWS/Azure, Terraform or manual VM setup, SSL, PostgreSQL backup", "1", "40–60 hrs"],
      ["UI/UX Designer (1, part-time)", "App icon, branding assets, color scheme per study", "2, 3", "20–30 hrs"],
      ["Study Coordinator", "WCP admin, survey content input, enrollment token distribution", "2, 4", "40–60 hrs"],
      ["Regulatory / Compliance", "21 CFR Part 11, HIPAA, IRB submissions", "4", "40–80 hrs"],
    ],
    [2400, 3200, 1200, 2560]
  ),
  spacer(120),
  callout("TOTAL ESTIMATED BUILD TIME:", "20–28 weeks from kickoff to full launch across all three studies, with a team of 4–6 people. IRB approval timelines (4–8 weeks) are typically the longest variable. Phases 1–3 can partially overlap.", C.greenLight, C.greenMid, C.green),

  new Paragraph({ children: [new PageBreak()] }),

  // ── 8. Regulatory & Compliance ────────────────────────────────────────
  hdr("8. Regulatory & Compliance Checklist"),
  divider(),

  hdr("8.1  HIPAA Compliance", HeadingLevel.HEADING_2, C.greenMid, 200, 100),
  bullet([bold("Business Associate Agreement (BAA)"), run(": Required with cloud provider (AWS/Azure), LabKey (if managed), and any third-party services.")]),
  bullet([bold("Data Minimization: "), run("Response Server stores anonymized Participant ID only. No names, DOB, or contact info in response tables.")]),
  bullet([bold("Encryption: "), run("All data encrypted in transit (TLS 1.2+) and at rest (AES-256 recommended).")]),
  bullet([bold("Access Controls: "), run("Role-based access in LabKey; only authorized coordinators can view response data.")]),
  bullet([bold("Breach Notification: "), run("HIPAA-compliant incident response plan required before study launch.")]),
  spacer(120),

  hdr("8.2  21 CFR Part 11 (Electronic Records / IND Studies)", HeadingLevel.HEADING_2, C.greenMid, 200, 100),
  bullet([bold("E-Signature: "), run("The app generates a signed consent PDF — meets 21 CFR Part 11 e-signature requirements.")]),
  bullet([bold("Audit Trail: "), run("LabKey Response Server logs all data entries with timestamp and Participant ID. Do not disable event logging.")]),
  bullet([bold("Data Integrity: "), run("Responses cannot be modified after submission without a traceable amendment record.")]),
  bullet([bold("System Validation: "), run("A validation protocol (IQ/OQ/PQ) should be completed and documented for the full system before IND submission.")]),
  spacer(120),

  hdr("8.3  IRB Requirements", HeadingLevel.HEADING_2, C.greenMid, 200, 100),
  bullet("Separate IRB submissions required for UC, CD, and NASH studies (or a single submission covering all three as related protocols — consult your IRB)."),
  bullet("IRB application must include: study protocol, informed consent form text (as configured in WCP), data security plan, HIPAA authorization, and privacy policy for the app."),
  bullet("The consent form generated by the app must match exactly the IRB-approved consent — test this before launch."),
  bullet("The app itself may be reviewed as a study device or software — confirm with your IRB whether a Device section is needed."),
  spacer(160),

  callout("IBD PRECEDENT:", "The SPARC IBD study and IBD PROdigy app — built on this same FDA MyStudies codebase and funded by the Crohn's & Colitis Foundation — successfully obtained IRB approval and HIPAA compliance for UC and CD research. GI Clinical Studies.com can cite this precedent and reference their consent architecture as a model.", C.purpleLight, C.purple, C.purple),

  new Paragraph({ children: [new PageBreak()] }),

  // ── 9. Key Links & References ─────────────────────────────────────────
  hdr("9. Key Resources & References"),
  divider(),
  dataTable(
    ["Resource", "URL / Location"],
    [
      ["GitHub Source Code (all 6 submodules)", "github.com/FDA-MyStudies/FDA-My-Studies-Mobile-Application-System"],
      ["FDA MyStudies Technical Setup Documentation", "fdamystudieshelp.atlassian.net (linked from GitHub README)"],
      ["WCP Setup Sub-Document", "Section 3 of FDA Technical Setup Document — see linked wiki page"],
      ["iOS Build Guide (Xcode)", "Section 5 of FDA Technical Setup Document — see linked wiki page"],
      ["Android Build Guide", "Section 6 of FDA Technical Setup Document — see linked wiki page"],
      ["Response Server / LabKey Setup", "Section 7 of FDA Technical Setup Document + LabKey documentation"],
      ["LabKey Server (open source)", "labkey.com — Apache 2.0 license"],
      ["Apple ResearchKit (iOS framework)", "researchkit.org / github.com/ResearchKit/ResearchKit"],
      ["ResearchStack (Android framework)", "researchstack.org"],
      ["Apple Developer Program", "developer.apple.com — $99/year required for App Store submission"],
      ["Google Play Console", "play.google.com/console — $25 one-time fee"],
      ["SPARC IBD / IBD PROdigy precedent", "Crohn's & Colitis Foundation — sparc-ibd.org"],
      ["21 CFR Part 11 Guidance", "fda.gov/regulatory-information/search-fda-guidance-documents"],
    ],
    [3200, 6160]
  ),
  spacer(200),

  // ── 10. Next Steps ────────────────────────────────────────────────────
  hdr("10. Recommended Next Steps"),
  divider(),
  numbered("Select and contract with a cloud provider (AWS or Azure); sign HIPAA BAA."),
  numbered("Engage a development team with Java + iOS/Android mobile experience."),
  numbered("Clone the FDA MyStudies GitHub repository and review all 6 submodule build guides."),
  numbered("Stand up development/staging servers using the infrastructure spec in Section 4."),
  numbered("Begin WCP configuration for the UC study first (simplest Phase III design) as a reference build."),
  numbered("Prepare and submit IRB applications for all three studies in parallel with development."),
  numbered("Target TestFlight / Play internal testing at Week 16; full launch at Week 28."),
  spacer(160),

  callout("RECOMMENDATION:", "Start with the UC study as your first live deployment. It has the most established outcome measures (Mayo Score) and the most direct parallel to the IBD PROdigy app. Once the UC pipeline is proven end-to-end, the CD and NASH studies can be added to the same platform with minimal additional infrastructure work.", C.greenLight, C.greenMid, C.green),

  spacer(300),

  // ── Footer note ───────────────────────────────────────────────────────
  new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { before: 400 },
    border: { top: { style: BorderStyle.SINGLE, size: 6, color: C.border } },
    children: [
      new TextRun({ text: "GI Clinical Studies.com  ·  Technical Implementation Plan  ·  Confidential  ·  February 2026", color: C.gray, size: 18, italics: true })
    ]
  }),
];

// ── Build Document ─────────────────────────────────────────────────────────
const doc = new Document({
  styles: {
    default: {
      document: { run: { font: "Arial", size: 22, color: C.dark } }
    },
    paragraphStyles: [
      { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 36, bold: true, font: "Arial", color: C.green },
        paragraph: { spacing: { before: 320, after: 200 }, outlineLevel: 0 } },
      { id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 28, bold: true, font: "Arial", color: C.greenMid },
        paragraph: { spacing: { before: 240, after: 160 }, outlineLevel: 1 } },
      { id: "Heading3", name: "Heading 3", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 24, bold: true, font: "Arial", color: C.green },
        paragraph: { spacing: { before: 200, after: 120 }, outlineLevel: 2 } },
    ]
  },
  numbering: {
    config: [
      { reference: "bullets",
        levels: [
          { level: 0, format: LevelFormat.BULLET, text: "\u2022", alignment: AlignmentType.LEFT,
            style: { paragraph: { indent: { left: 720, hanging: 360 } } } },
          { level: 1, format: LevelFormat.BULLET, text: "\u25E6", alignment: AlignmentType.LEFT,
            style: { paragraph: { indent: { left: 1080, hanging: 360 } } } },
        ]
      },
      { reference: "numbers",
        levels: [
          { level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.LEFT,
            style: { paragraph: { indent: { left: 720, hanging: 360 } } } },
        ]
      },
    ]
  },
  sections: [{
    properties: {
      page: {
        size: { width: 12240, height: 15840 },
        margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 }
      }
    },
    headers: {
      default: new Header({
        children: [new Paragraph({
          alignment: AlignmentType.RIGHT,
          border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: C.green } },
          spacing: { after: 120 },
          children: [
            new TextRun({ text: "GI Clinical Studies.com  ·  Technical Implementation Plan", color: C.gray, size: 18 })
          ]
        })]
      })
    },
    footers: {
      default: new Footer({
        children: [new Paragraph({
          alignment: AlignmentType.CENTER,
          border: { top: { style: BorderStyle.SINGLE, size: 6, color: C.border } },
          children: [
            new TextRun({ text: "Page ", color: C.gray, size: 18 }),
            new TextRun({ children: [PageNumber.CURRENT], color: C.gray, size: 18 }),
            new TextRun({ text: " of ", color: C.gray, size: 18 }),
            new TextRun({ children: [PageNumber.TOTAL_PAGES], color: C.gray, size: 18 }),
            new TextRun({ text: "  ·  Confidential", color: C.gray, size: 18 }),
          ]
        })]
      })
    },
    children
  }]
});

Packer.toBuffer(doc).then(buf => {
  fs.writeFileSync('/sessions/eloquent-kind-hypatia/mnt/outputs/GI-Clinical-Studies-Technical-Plan.docx', buf);
  console.log('✅ Document written successfully');
});
