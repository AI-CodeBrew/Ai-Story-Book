# AI Storybook Configuration Guide

This guide will help you configure the AI Storybook app with your API keys and Firebase setup.

## 1. Environment Variables Setup

The app uses environment variables for secure configuration. Follow these steps:

### Step 1: Get Your API Keys
1. **Gemini AI API Key**: 
   - Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Create a new API key
   - Copy the key for later use

2. **Firebase Configuration**:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project or use existing one
   - Enable Firestore database
   - Get your Firebase configuration

### Step 2: Configure Environment Variables
1. Copy `backend/env.example` to `backend/.env`
2. Fill in your API keys and Firebase credentials
3. For production (Vercel), add these as environment variables in Vercel dashboard

## 2. Firebase Setup

### Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: "AI Storybook"
4. Enable Google Analytics (optional)
5. Click "Create project"

### Step 2: Enable Firestore Database
1. In Firebase Console, go to "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select a location close to your users
5. Click "Done"

### Step 3: Set Up Security Rules
Add these Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write access to feedback collection
    match /feedback/{document} {
      allow read, write: if true;
    }
    
    // Allow read/write access to reported_messages collection
    match /reported_messages/{document} {
      allow read, write: if true;
    }
  }
}
```

### Step 4: Get Firebase Configuration
1. In Firebase Console, go to Project Settings
2. Scroll down to "Your apps"
3. Click "Add app" and choose "Web"
4. Register app with name "AI Storybook Web"
5. Copy the configuration object

## 3. Environment Configuration

### Backend Configuration
Create a `.env` file in the `backend` directory:

```env
# API Keys
GEMINI_API_KEY=your_gemini_api_key_here

# Firebase Configuration
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_PRIVATE_KEY_ID=your_private_key_id
FIREBASE_PRIVATE_KEY=your_private_key
FIREBASE_CLIENT_EMAIL=your_client_email
FIREBASE_CLIENT_ID=your_client_id
FIREBASE_AUTH_URI=https://accounts.google.com/o/oauth2/auth
FIREBASE_TOKEN_URI=https://oauth2.googleapis.com/token
FIREBASE_AUTH_PROVIDER_X509_CERT_URL=https://www.googleapis.com/oauth2/v1/certs
FIREBASE_CLIENT_X509_CERT_URL=your_cert_url

# Server Configuration
PORT=8080
```

### Frontend Configuration
For Flutter, you'll need to add Firebase configuration files:

1. **Android**: Add `google-services.json` to `fairytale-app/android/app/`
2. **iOS**: Add `GoogleService-Info.plist` to `fairytale-app/ios/Runner/`

## 4. Running the Application

### Start Backend
```bash
cd backend
python app.py
```

The server will start on `http://localhost:8080`

### Start Frontend
```bash
flutter run
```

## 5. Testing the Setup

### Test Backend
1. Check if server is running: `http://localhost:8080/api/health`
2. Should return: `{"status": "healthy", "timestamp": "..."}`

### Test Frontend
1. Launch the Flutter app
2. Navigate to story generation
3. Try creating a simple story
4. Check if images and audio work

## 6. Deployment Configuration

### Vercel Deployment
1. **Environment Variables**: Add all environment variables in Vercel dashboard
2. **Build Command**: `pip install -r requirements.txt`
3. **Output Directory**: `.`
4. **Install Command**: Leave empty (handled by build command)

### Play Store Deployment
1. **API Endpoint**: Update `fairytale-app/lib/services/api_service.dart` with your Vercel URL
2. **Build**: `flutter build appbundle`
3. **Upload**: Follow Google Play Console guidelines

## 7. Troubleshooting

### Common Issues

**Backend Issues:**
- **API Key Error**: Make sure your Gemini API key is correctly set in environment variables
- **Firebase Connection Error**: Check Firebase credentials and network connection
- **Port Already in Use**: Change PORT in .env file or kill existing process

**Frontend Issues:**
- **Network Error**: Ensure backend is running and accessible
- **Image Loading Error**: Check if image URLs are valid
- **Audio Not Working**: Verify device permissions and TTS setup

### Debug Mode
Enable debug logging by setting environment variables:

```bash
# Backend debug
export FLASK_ENV=development
python app.py

# Frontend debug
flutter run --debug
```

## 8. Production Deployment

### Backend Deployment (Vercel)
1. Push code to GitHub
2. Connect repository to Vercel
3. Set environment variables in Vercel dashboard
4. Deploy automatically

### Frontend Deployment (Play Store)
1. Build for production: `flutter build appbundle`
2. Follow Google Play Console guidelines
3. Upload the AAB file
4. Update API endpoint to production URL

## 9. Security Considerations

1. **Environment Variables**: Never commit API keys to version control
2. **Firebase Rules**: Implement proper security rules for production
3. **CORS**: Configure CORS properly for production domains
4. **Rate Limiting**: Implement rate limiting for API endpoints
5. **Input Validation**: Validate all user inputs

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review Firebase and API documentation
3. Open an issue in the repository
4. Check logs for detailed error messages
