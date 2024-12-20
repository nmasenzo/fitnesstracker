# Fitness Tracker App Configuration

## Overview
The Fitness Tracker App is a mobile and web-based application for tracking exercises, offering features such as exercise recommendations, a body heat map, and activity logging. It integrates:

* Backend: Django REST API with PostgreSQL database
* Frontend: Flutter + Dart
* Containerization: Docker

<img width="397" alt="image" src="https://github.com/user-attachments/assets/a2e7bac0-3646-457e-b666-5dfa71f95f12" />

## Prerequisites
Before you begin, ensure you have the following installed on your system:

* **Operating System**: Windows, macOS, or Linux
* **Dart**: [Install Dart](https://dart.dev/get-dart)
* **Flutter SDK**: [Install Flutter](https://flutter.dev/docs/get-started/install)
* **Android Studio**: [Download Android Studio](https://developer.android.com/studio)
* **Docker Desktop and CLI**: [Install Docker](https://www.docker.com/get-started)
* **Python 3**: [Download Python](https://www.python.org/downloads/)
## Project Setup

### Step 1: Clone the Repository
Clone the repository and navigate to the project directory:

```bash
git clone https://github.com/nmasenzo/fitnesstracker
cd fitnesstracker
```

### Step 2: Add Environment Files

#### a. PostgreSQL .env File
Create a .env file in the postgres directory with the following content:

```plaintext
POSTGRES_USER=admin
POSTGRES_PASSWORD=11223344
POSTGRES_DB=fitnesstrackerapp
```

```bash
touch postgres/.env
```

#### b. Flutter .env File
Create a .env file in the frontend/fitnesstracker directory with the following content:

```plaintext
# Local Server
BACKEND_BASE_URL=http://10.0.2.2:8000

# Uncomment for Cloud Server
# BACKEND_BASE_URL=http://69.164.222.179:8000
```

```bash
touch frontend/fitnesstracker/.env
```

### Step 3: Firebase Configuration

1. Go to the Firebase Console
2. Add the sign in method "Email/Password" to the project.
3. Create a new project and add an Android app to it. Name the app com.example.fitnesstracker.
4. Download the google-services.json file
5. Place google-services.json in frontend/fitnesstracker/android/app/:

```
frontend/
├── fitnesstracker/
    └── android/
        └── app/
            └── google-services.json
```

#### Firebase Admin SDK

1. Place the firebase-admin-sdk.json file in the backend/config/ directory:

```bash
mkdir backend/config
cd backend/config
touch firebase-admin-sdk.json
```

### Step 4: Backend Setup

1. Start Docker Desktop
2. Navigate to the root directory and run the following commands:

```bash
sudo docker-compose up -d
sudo docker exec -it fitnesstracker-backend-1 /bin/bash
```

3. Inside the backend container, set up and initialize:

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cd fitnesstracker
python3 manage.py makemigrations
python3 manage.py migrate
python3 manage.py load_exercises
exit
```

### Step 5: Frontend Setup

1. Navigate to the frontend/fitnesstracker directory:

```bash
cd frontend/fitnesstracker
```

2. Fetch Flutter dependencies and run the app:

```bash
flutter pub get
flutter run
```

## Running the Application

1. Ensure the backend and database services are running via Docker
2. Start the Flutter app on an Android emulator or physical device

## Contributors

| Contributor  | Areas of Expertise and Contribution |
|------------|-----------------------------------|
| Nikita Masenzov | Designed Figma UI, developed Django REST API, integrated Firebase, configured Docker, QA testing, implemented major features |
| Jerry Bao  | Figma design, researched datasets, developed body heat map with exercise recommendations |
| Kirtan Patel  | Initial Flutter layouts, body heat map implementation, Figma design assistance |
| Justin Jeffery  | Dashboard, activity log, profile Flutter layouts, Figma design assistance |
| Istiak Zaman  | Interactive SVG research, body heat map assistance, bug testing |

## User Guide

### App Demo and APK
[Download APK and Demo Video](https://drive.google.com/file/d/1cjEQAl1WBREgA3EZzpnDjcY90IQ-G1lF/view)

### Testing Strategies
* Functional testing with sample user interactions
* Automated API endpoint testing using Postman

## Technology Stack

### Backend
* Framework: Django
* Database: PostgreSQL
* Containerization: Docker

### Frontend
* Framework: Flutter + Dart
* Firebase: Authentication and Cloud Functions

## Features and Technical Implementation

1. User Authentication: Integrated with Firebase Auth
2. Exercise Recommendations: Uses interactive body heat map
3. Activity Logging: Tracks user activities and stores logs
4. Responsive UI: Designed with Flutter to support multiple devices

## Packages and APIs

### Firebase
* Reason: Provides authentication
* Usage: User login, signup, and authentication

### Django REST Framework
[Postman REST API Documentation](https://documenter.getpostman.com/view/39859441/2sAYJ3DLp8#05c67971-d1f6-4868-83dc-6462bc2dc887)

### Flutter Packages
* http: Handles API requests
* provider: State management for Flutter
