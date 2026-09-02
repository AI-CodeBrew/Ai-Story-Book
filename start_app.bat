@echo off
echo 🚀 Starting AI Storybook App...
echo ==================================

echo Starting Python Flask backend server...
start "Backend Server" cmd /k "cd /d %~dp0backend && python app.py"

echo Waiting for backend to start...
timeout /t 3 /nobreak >nul

echo Starting Flutter frontend app...
start "Frontend App" cmd /k "cd /d %~dp0fairytale-app\frontend && flutter run -d windows"

echo.
echo ✅ Both backend and frontend are starting...
echo Backend will be available at: http://localhost:8080
echo Frontend will open in a new window
echo.
echo Press any key to close this window...
pause >nul
