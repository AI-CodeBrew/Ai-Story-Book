#!/bin/bash
echo "🚀 Starting AI Storybook App..."
echo "=================================="

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting Python Flask backend server..."
cd "$SCRIPT_DIR/backend" && python app.py &
BACKEND_PID=$!

echo "Waiting for backend to start..."
sleep 3

echo "Starting Flutter frontend app..."
cd "$SCRIPT_DIR/fairytale-app/frontend" && flutter run -d windows &
FRONTEND_PID=$!

echo ""
echo "✅ Both backend and frontend are starting..."
echo "Backend will be available at: http://localhost:8080"
echo "Frontend will open in a new window"
echo ""
echo "Press Ctrl+C to stop both servers..."

# Wait for user to stop
trap "echo 'Stopping servers...'; kill $BACKEND_PID $FRONTEND_PID; exit" INT
wait
