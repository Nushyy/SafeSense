
# 🛡️ SafeSense

## Intelligent Community-Based Crime Reporting and Alert System for South Africa

**ITMDA3-34 Group Project**

**Stronger Communities, Safer Together.**

---

## 📖 Project Overview

SafeSense is an intelligent, community-based crime reporting and alert system designed to improve public safety and community awareness in South Africa.

The application provides a platform where community members can report crime incidents, access location-based safety information, participate in community discussions, manage emergency contacts, and access safety-related features.

The project aims to promote safer neighbourhoods through technology, communication, and community participation.

---

## 👥 Project Team

| Team Member | Role |
|-------------|------|
| Ronee Helepi | Integrations and Database Engineer |
| Bradley Horing | Backend Engineer |
| Kamohelo Mahao | Systems Engineer |
| Khalie Novazi | Frontend Engineer |
| Thanushri Sagadevan | Full Stack Engineer |

---

## 🛠️ Technology Stack

SafeSense is developed using Flutter and Dart, allowing the application to share a codebase across Android, iOS, and web platforms.

| Technology | Purpose |
|------------|---------|
| Flutter | Cross-platform frontend development |
| Dart | Application programming language |
| Supabase | Backend services |
| PostgreSQL | Relational database |
| Supabase Authentication | User authentication |
| Supabase Storage | File storage |
| Firebase Hosting | Web hosting and deployment |
| Flutter Map | Interactive maps |
| OpenStreetMap | Geographic map data |
| Geolocator | Device location services |
| Git | Version control |
| GitHub | Source code hosting and collaboration |

---

## ✨ Application Features

### 1. Authentication and User Accounts

- User registration.
- User login and logout.
- Secure authentication.
- Session management.
- Personal account management.

### 2. Profile Management

- View personal profile information.
- Manage names and usernames.
- Manage contact information.
- Manage neighbourhood information.
- Access profile-related settings.
- View personal crime-report statistics.

### 3. Crime Reporting

- Report crime incidents within the community.
- Provide information about incidents.
- Support community-based crime reporting.
- Store crime-related information using backend services.
- Improve local crime awareness.

### 4. Community Bulletin Board

- View community posts.
- Create community posts.
- Browse posts by location.
- Search for supported South African locations.
- Comment on community posts.
- View community discussions.

**Community Post Categories:**

- Missing Persons
- Neighbourhood Watch
- Safety Information
- Pets
- Meetings

### 5. Map and Location Awareness

- Interactive map interface.
- Location-related safety information.
- Map-based community awareness.
- Geographic support for incident reporting and discovery.

### 6. Notifications and Alerts

- Crime alert preferences.
- Emergency alert preferences.
- Community announcement preferences.
- Notification settings management.

### 7. Privacy and Safety

- Profile visibility preferences.
- Trusted Circle location-sharing preferences.
- Personal safety settings.

### 8. Emergency Contacts

- Add emergency contacts.
- Store contact names.
- Store telephone numbers.
- Store relationships.
- Remove emergency contacts.

### 9. SOS Emergency Feature

- Emergency SOS interface.
- Quick access to an emergency action.
- Safety-related interactions.

> **Important:** The SOS functionality is not a substitute for official emergency services. Any real-world emergency-response integration must be verified before use.

---

## 📂 Project Folder Structure

The application is organised into reusable components, screens, services, and feature modules.

```text
SafeSense/
├── android/
├── ios/
├── web/
├── assets/
├── lib/
│   ├── main.dart
│   ├── community/
│   ├── components/
│   ├── core/
│   ├── features/
│   ├── screens/
│   ├── services/
│   └── theme/
├── test/
├── pubspec.yaml
├── firebase.json
├── .gitignore
└── README.md
```

---

## 💻 How to Run SafeSense

### Prerequisites

Ensure that the following are installed:

- Flutter SDK
- Dart SDK
- Visual Studio Code or Android Studio
- Git
- Google Chrome or a supported mobile device/emulator

You will also need authorised access to the SafeSense Supabase project.

### Step 1: Clone the Repository

```bash
git clone https://github.com/Nushyy/SafeSense.git
cd SafeSense
```

### Step 2: Switch to the Development Branch

```bash
git fetch origin
git switch development
git pull --ff-only origin development
```

### Step 3: Install Dependencies

```bash
flutter pub get
```

### Step 4: Configure Supabase

Create a `.env` file in the project root.

Add the following configuration:

```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_PUBLISHABLE_KEY=your_supabase_publishable_key
```

Replace the placeholders with the appropriate values from your Supabase project.

> **Security:** Never commit `.env`, private credentials, or Supabase service-role keys to GitHub.

### Step 5: Load Environment Variables

For Windows PowerShell, run:

```powershell
Get-Content ".env" | ForEach-Object {
    $line = $_.Trim()
    if ($line -match '^(SUPABASE_URL|SUPABASE_PUBLISHABLE_KEY)\s*=\s*(.*)$') {
        $key = $matches[1]
        $value = $matches[2].Trim().Trim('"', "'")
        [Environment]::SetEnvironmentVariable($key, $value, 'Process')
    }
}
```

### Step 6: Run the Application

Run SafeSense in Google Chrome:

```powershell
flutter run -d chrome --dart-define="SUPABASE_URL=$env:SUPABASE_URL" --dart-define="SUPABASE_PUBLISHABLE_KEY=$env:SUPABASE_PUBLISHABLE_KEY"
```

To view available devices:

```bash
flutter devices
```

---

## 🗄️ Supabase Setup

SafeSense uses Supabase for authentication, database management, and backend integration.

### Backend Components

- **Supabase Authentication:** User registration and authentication.
- **PostgreSQL:** Persistent relational data storage.
- **Supabase Storage:** File storage.
- **Row Level Security (RLS):** Database access control.
- **Supabase Realtime:** Support for realtime features where implemented.

### Database Components

The backend supports data associated with:

- User profiles.
- Community posts.
- Community comments.
- Community post likes.
- South African areas and locations.
- Crime reporting and related application functionality.

### Supabase Collaboration

Team members should use their own Supabase accounts.

The project administrator can invite collaborators through the Supabase dashboard.

Never share passwords or private backend credentials.

---

## 🌿 Git Workflow

SafeSense uses Git and GitHub to support collaborative development.

### Branch Structure

| Branch | Purpose |
|--------|---------|
| `main` | Stable application code |
| `development` | Integration of completed features |
| `feature/*` | Individual feature development |

### Step 1: Retrieve the Latest Changes

```bash
git fetch origin
git switch development
git pull --ff-only origin development
```

### Step 2: Create a Feature Branch

```bash
git switch -c feature/your-feature-name
```

### Step 3: Develop and Test

Make the required changes and run:

```bash
flutter analyze
```

### Step 4: Commit Changes

```bash
git status
git add .
git commit -m "Describe the completed changes"
```

Review staged files before committing to avoid including sensitive information.

### Step 5: Push Changes

```bash
git push -u origin feature/your-feature-name
```

### Step 6: Create a Pull Request

Open GitHub and create a pull request targeting the `development` branch.

The changes should be reviewed and tested before integration.

> Avoid pushing unfinished changes directly to the `main` branch.

---

## 🚀 Firebase Hosting and Deployment

SafeSense uses Firebase Hosting to deploy the Flutter web application.

### Step 1: Build the Application

After loading the Supabase environment variables in PowerShell, run:

```powershell
flutter build web --release --dart-define="SUPABASE_URL=$env:SUPABASE_URL" --dart-define="SUPABASE_PUBLISHABLE_KEY=$env:SUPABASE_PUBLISHABLE_KEY"
```

The production build will be generated in:

```text
build/web
```

### Step 2: Authenticate with Firebase

```bash
firebase login
```

### Step 3: Deploy to Firebase Staging

```bash
firebase deploy --only hosting --project safesense-staging
```

### Hosted Application

**SafeSense Web Application:**

https://safesense-staging.web.app

---

## 🧪 Testing and Code Quality

SafeSense follows a modular development approach to improve code maintainability, readability, and collaboration.

### Static Analysis

```bash
flutter analyze
```

### Automated Testing

```bash
flutter test
```

### Recommended Functional Tests

- User registration and login.
- Logout and session handling.
- Profile management.
- Crime reporting.
- Community post creation.
- Community post retrieval.
- Community comments.
- Location selection.
- Navigation between screens.
- Form validation.
- Loading indicators.
- Error messages.
- Responsive layouts.
- Backend connectivity.

---

## 🔐 Security Considerations

SafeSense handles user and community information that requires appropriate protection.

Security considerations include:

- Secure authentication.
- User session management.
- Supabase Row Level Security.
- Input validation.
- Protection of private user information.
- Controlled database access.
- Secure handling of application credentials.

> Only public or publishable client-side keys should be included in web builds. Private service-role credentials must remain server-side.

---

## 🔗 Project Links

### GitHub Repository

https://github.com/Nushyy/SafeSense

### Hosted Web Application

https://safesense-staging.web.app

---

## 🎓 Academic Information

**Project Name:** SafeSense — Intelligent Community-Based Crime Reporting and Alert System for South Africa

**Module:** ITMDA3-34 Group Project

**Deliverable:** Deliverable 4 — Implementation

**Project Type:** Academic Group Software Development Project

---

## 🛡️ SafeSense

**Report. Alert. Protect.**

*Stronger Communities, Safer Together.*
