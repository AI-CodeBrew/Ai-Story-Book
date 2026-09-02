#!/bin/bash
echo "🚀 Setting up AI Storybook App..."
echo "=================================="

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python is not installed. Please install Python 3.8+ first."
    echo "Visit: https://www.python.org/downloads/"
    exit 1
fi

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter SDK first."
    echo "Visit: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Python and Flutter are installed"

echo "Installing Python backend dependencies..."
cd backend
pip install -r requirements.txt

if [ $? -eq 0 ]; then
    echo "✅ Backend dependencies installed successfully"
else
    echo "❌ Failed to install backend dependencies"
    exit 1
fi

cd ../fairytale-app/frontend

echo "Installing Flutter frontend dependencies..."
flutter pub get

if [ $? -eq 0 ]; then
    echo "✅ Frontend dependencies installed successfully"
else
    echo "❌ Failed to install frontend dependencies"
    exit 1
fi

echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "Next steps:"
echo "1. Configure your API keys in environment variables"
echo "2. Start the backend: cd backend && python app.py"
echo "3. Start the frontend: cd fairytale-app/frontend && flutter run"
echo "4. Start the website: cd fairytale-web && npm run dev"
echo ""
echo "For detailed instructions, see README.md"
