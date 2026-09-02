# Deployment Guide

## Backend Deployment (Vercel)

### Step 1: Prepare Your Code
1. Make sure your `backend/` folder contains:
   - `app.py` - Main Flask application
   - `requirements.txt` - Python dependencies
   - `vercel.json` - Vercel configuration

### Step 2: Push to GitHub
```bash
git add .
git commit -m "Add Python Flask backend"
git push origin main
```

### Step 3: Deploy on Vercel
1. Go to [Vercel](https://vercel.com)
2. Click "New Project"
3. Import your GitHub repository
4. Set build configuration:
   - **Framework Preset**: Other
   - **Build Command**: `pip install -r requirements.txt`
   - **Output Directory**: `backend`
   - **Install Command**: (leave empty)

### Step 4: Configure Environment Variables
In Vercel dashboard, add these environment variables:
- `GEMINI_API_KEY` - Your Gemini AI API key
- `FIREBASE_PROJECT_ID` - Your Firebase project ID
- `FIREBASE_PRIVATE_KEY` - Your Firebase private key
- `FIREBASE_CLIENT_EMAIL` - Your Firebase client email
- `FIREBASE_CLIENT_ID` - Your Firebase client ID
- `FIREBASE_AUTH_URI` - `https://accounts.google.com/o/oauth2/auth`
- `FIREBASE_TOKEN_URI` - `https://oauth2.googleapis.com/token`
- `FIREBASE_AUTH_PROVIDER_X509_CERT_URL` - `https://www.googleapis.com/oauth2/v1/certs`
- `FIREBASE_CLIENT_X509_CERT_URL` - Your Firebase cert URL

### Step 5: Deploy
Click "Deploy" and wait for the build to complete.

## Frontend Deployment (Play Store)

### Step 1: Update API Endpoint
In `fairytale-app/lib/services/api_service.dart`, change:
```dart
// For development - local Flask server
static const String baseUrl = 'http://localhost:8080/api';

// For production - Vercel deployment
static const String baseUrl = 'https://your-vercel-app.vercel.app/api';
```

### Step 2: Build for Production
```bash
# For Android
flutter build appbundle

# For iOS
flutter build ios --release
```

### Step 3: Upload to Play Store
1. Go to [Google Play Console](https://play.google.com/console)
2. Create a new app
3. Upload your AAB file
4. Fill in app details
5. Submit for review

## Testing Deployment

### Test Backend
1. Visit your Vercel URL: `https://your-app.vercel.app/api/health`
2. Should return: `{"status": "healthy", "timestamp": "..."}`

### Test Frontend
1. Install the app from Play Store
2. Try generating a story
3. Check if all features work correctly

## Troubleshooting

### Backend Issues
- **Build Failed**: Check if all dependencies are in `requirements.txt`
- **Environment Variables**: Make sure all variables are set in Vercel
- **Firebase Connection**: Verify Firebase credentials are correct

### Frontend Issues
- **API Connection**: Check if the API endpoint URL is correct
- **Build Errors**: Make sure all Flutter dependencies are compatible
- **App Store Rejection**: Follow Google Play guidelines carefully

## Production Checklist

### Backend (Vercel)
- [ ] All environment variables set
- [ ] Firebase credentials configured
- [ ] API endpoints tested
- [ ] CORS properly configured
- [ ] Error handling implemented

### Frontend (Play Store)
- [ ] API endpoint updated to production URL
- [ ] App icon and splash screen added
- [ ] App metadata filled in
- [ ] Privacy policy added
- [ ] App tested thoroughly
- [ ] AAB file generated successfully
