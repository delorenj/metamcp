#!/bin/sh

set -e

PROJECT_ROOT="${PWD}"

echo "Starting MetaMCP services..."

# Function to run migrations
run_migrations() {
  echo "Running database migrations..."
  cd $PROJECT_ROOT/apps/backend

  # Check if migrations need to be run
  if [ -d "drizzle" ] && [ "$(ls -A drizzle/*.sql 2>/dev/null)" ]; then
    echo "Found migration files, running migrations..."
    # Use local drizzle-kit since env vars are available at system level in Docker
    if pnpm exec drizzle-kit migrate; then
      echo "Migrations completed successfully!"
    else
      echo "❌ Migration failed! Exiting..."
      exit 1
    fi
  else
    echo "No migrations found or directory empty"
  fi

  cd $PROJECT_ROOT
}

# Set default values for postgres connection if not provided
POSTGRES_HOST=${PGHOST}
POSTGRES_PORT=5432
POSTGRES_USER=${PGUSER}

run_migrations

# Start backend in the background
echo "Starting backend server..."

cd $PROJECT_ROOT/apps/backend
PORT=12009 node dist/index.js &
BACKEND_PID=$!

# Wait a moment for backend to start
sleep 3

# Check if backend is still running
if ! kill -0 $BACKEND_PID 2>/dev/null; then
  echo "❌ Backend server died! Exiting..."
  exit 1
fi
echo "✅ Backend server started successfully (PID: $BACKEND_PID)"

# Start frontend
echo "Starting frontend server..."
cd $PROJECT_ROOT/apps/frontend
PORT=12008 pnpm start &
FRONTEND_PID=$!

# Wait a moment for frontend to start
sleep 3

# Check if frontend is still running
if ! kill -0 $FRONTEND_PID 2>/dev/null; then
  echo "❌ Frontend server died! Exiting..."
  kill $BACKEND_PID 2>/dev/null
  exit 1
fi
echo "✅ Frontend server started successfully (PID: $FRONTEND_PID)"

# Function to cleanup on exit
cleanup() {
  echo "Shutting down services..."
  kill $BACKEND_PID 2>/dev/null || true
  kill $FRONTEND_PID 2>/dev/null || true
  wait $BACKEND_PID 2>/dev/null || true
  wait $FRONTEND_PID 2>/dev/null || true
  echo "Services stopped"
}

# Trap signals for graceful shutdown
trap cleanup TERM INT

echo "Services started successfully!"
echo "Backend running on port 12009"
echo "Frontend running on port 12008"

# Wait for both processes
wait $BACKEND_PID
wait $FRONTEND_PID
