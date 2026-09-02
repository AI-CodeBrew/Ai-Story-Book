# AI Storybook App

A complete AI-powered storybook application with Python Flask backend and Flutter frontend, featuring AI story generation, beautiful illustrations, audio narration, and feedback system.

## Features

- **AI Story Generation**: Create unique stories using Gemini AI
- **Theme Selection**: Choose from Adventure, Fantasy, Space, Nature, Friendship, and Science themes
- **AI-Generated Illustrations**: Beautiful images generated for each story
- **Audio Narration**: Text-to-speech functionality for story reading
- **Feedback System**: User feedback collection and analysis
- **Beautiful UI**: Modern, responsive design with smooth animations
- **Firebase Integration**: Backend data storage and management
- **Vercel Ready**: Backend optimized for Vercel deployment
- **Play Store Ready**: Frontend optimized for mobile app stores

## Quick Start

1. **Install Dependencies**:
```bash
# Install Python backend dependencies
cd backend && pip install -r requirements.txt

# Install Flutter frontend dependencies
cd fairytale-app && flutter pub get

# Install website dependencies
cd fairytale && npm install
```

2. **Start Both Backend and Frontend** (Windows):
```bash
start_app.bat
```

Or (Mac/Linux):
```bash
chmod +x start_app.sh
./start_app.sh
```

3. **Manual Start**:
   - Backend: `cd backend && python app.py`
   - Frontend: `cd fairytale-app && flutter run`
   - Website: `cd fairytale && npm run dev`

## Project Structure

```
Ai-Story-Book/
├── backend/                   # Python Flask backend (shared by fairytale-app and fairytale)
│   ├── app.py                 # Main Flask application
│   ├── requirements.txt       # Python dependencies
│   ├── vercel.json            # Vercel deployment config
│   ├── env.example            # Environment variables template
│   ├── mongo.py, story_repository.py, analytics_service.py, auth_service.py
│   ├── bunny_storage.py
│   ├── gemini_image_service.py
│   ├── gemini_text_service.py
│   ├── feedback_service.py
│   └── test_backend.py
├── fairytale-app/              # The Flutter mobile app (no nested frontend/ folder)
│   ├── pubspec.yaml            # Flutter dependencies
│   ├── lib/
│   │   ├── screens/
│   │   │   ├── home_screen.dart
│   │   │   ├── story_generator_screen.dart
│   │   │   └── story_viewer_screen.dart
│   │   ├── providers/
│   │   │   ├── story_provider.dart
│   │   │   └── theme_provider.dart
│   │   ├── models/
│   │   │   └── story.dart
│   │   ├── services/
│   │   │   └── api_service.dart
│   │   ├── utils/
│   │   │   └── app_colors.dart
│   │   ├── start_feedback_widget.dart
│   │   └── main.dart
│   └── assets/
├── fairytale/                  # The public website + /admin dashboard (Next.js)
│   └── src/
│       ├── app/               # pages, /generate, /story/[id], /admin
│       ├── components/, hooks/, lib/
│       └── proxy.ts           # gates /admin/*
├── start_app.bat              # Windows startup script
├── start_app.sh               # Unix startup script
├── setup.bat                  # Windows setup script
├── setup.sh                   # Unix setup script
├── README.md
├── CONFIGURATION.md
└── DEPLOYMENT.md
```

## Backend Setup

### Prerequisites
- Python 3.8+ 
- Firebase project setup
- Gemini AI API key

### Installation

1. Install Python dependencies:
```bash
cd backend
pip install -r requirements.txt
```

2. Configure environment variables:
   - Copy `env.example` to `.env`
   - Add your Gemini AI API key
   - Add Firebase credentials

3. Run the server:
```bash
python app.py
```

The server will start on `http://localhost:8080`

## Frontend Setup

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Android Studio / VS Code
- Android/iOS device or emulator

### Installation

1. Dependencies are already installed from the main setup
2. Run the app:
```bash
flutter run
```

## Deployment

### Backend Deployment (Vercel)
1. Push your code to GitHub
2. Connect your repository to Vercel
3. Set environment variables in Vercel dashboard
4. Deploy automatically

### Frontend Deployment (Play Store)
1. Build the app: `flutter build appbundle`
2. Follow Google Play Console guidelines
3. Upload the APK/AAB file
4. Update API endpoint in `api_service.dart` to your Vercel URL

## API Endpoints

### Backend API

- `POST /api/stories/generate` - Generate a new story
- `POST /api/feedback` - Submit story feedback
- `GET /api/feedback/{storyId}` - Get feedback for a story
- `GET /api/feedback/{storyId}/stats` - Get feedback statistics
- `GET /api/health` - Health check

## Technologies Used

### Backend
- **Python** - Programming language
- **Flask** - Web server framework
- **Google Generative AI** - AI story generation
- **Firebase Admin** - Database and authentication
- **Vercel** - Deployment platform

### Frontend
- **Flutter** - Cross-platform UI framework
- **Provider** - State management
- **Google Fonts** - Typography
- **Flutter TTS** - Text-to-speech
- **Cached Network Image** - Image caching
- **HTTP** - API communication

## Usage

1. **Install Dependencies**: Run setup scripts or manual installation
2. **Start the Backend**: Run `cd backend && python app.py`
3. **Launch the Frontend**: Run `cd fairytale-app && flutter run`
   - or launch the website instead: `cd fairytale && npm run dev`
4. **Create Stories**: 
   - Choose a theme (Adventure, Fantasy, Space, etc.)
   - Enter your story prompt
   - Add optional context
   - Generate the story
5. **Enjoy**: Read, listen, and provide feedback on your AI-generated stories

## Configuration

### Environment Variables
The backend uses environment variables for configuration. Copy `backend/env.example` to `backend/.env` and fill in your values.

### Firebase Setup
1. Create a Firebase project
2. Enable Firestore database
3. Add Firebase configuration files
4. Set up security rules

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For support and questions, please open an issue in the repository.
