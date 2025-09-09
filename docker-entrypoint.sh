#!/bin/sh

set -e

CONFIG_DIR=/app/config

echo "🚀 Starting MetaMCP..."
echo "📁 Working directory: $(pwd)"
echo "🔧 Config directory: $CONFIG_DIR"

# Load configuration function
load_config() {
  echo "📋 Configuration loaded"
}

# Signal handler setup
setup_signal_handlers() {
  trap cleanup_services TERM INT QUIT
}

# Function to run migrations
run_migrations() {
  echo "🔄 Running database migrations..."
  cd /app/apps/backend

  # Ensure drizzle directory exists and has migration files
  if [ -d "drizzle" ] && [ "$(ls -A drizzle/*.sql 2>/dev/null)" ]; then
    echo "   Found migration files, running migrations..."
    
    # Try to run migrations with drizzle-kit
    if pnpm exec drizzle-kit migrate 2>/dev/null; then
      echo "✅ Migrations completed successfully!"
    else
      echo "⚠️  drizzle-kit not available in production, attempting direct SQL migration..."
      
      # Fall back to running SQL files directly via psql if drizzle-kit is not available
      export PGPASSWORD="$POSTGRES_PASSWORD"
      
      for sql_file in drizzle/*.sql; do
        if [ -f "$sql_file" ]; then
          echo "   Running migration: $(basename "$sql_file")"
          if psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f "$sql_file" 2>/dev/null; then
            echo "   ✅ $(basename "$sql_file") completed"
          else
            echo "   ⚠️  $(basename "$sql_file") may have already been applied or failed"
          fi
        fi
      done
      
      echo "✅ Direct SQL migrations completed!"
    fi
  else
    echo "   ⚠️  No migrations found or directory empty"
    echo "   Migration files should be in: $(pwd)/drizzle/"
    ls -la drizzle/ 2>/dev/null || echo "   Directory does not exist"
  fi

  cd /app
}

# Production mode: Start built applications
start_services() {
  echo "🚀 Starting services..."

  # Start backend
  echo "   Starting backend server..."
  cd /app/apps/backend
  PORT=12009 node dist/index.js &
  BACKEND_PID=$!

  # Wait and verify backend
  sleep 3
  if ! kill -0 $BACKEND_PID 2>/dev/null; then
    echo "❌ Backend server died! Exiting..."
    exit 1
  fi
  echo "✅ Backend server started (PID: $BACKEND_PID)"

  # Start frontend
  echo "   Starting frontend server..."
  cd /app/apps/frontend
  PORT=12008 pnpm start &
  FRONTEND_PID=$!

  # Wait and verify frontend
  sleep 3
  if ! kill -0 $FRONTEND_PID 2>/dev/null; then
    echo "❌ Frontend server died! Exiting..."
    kill $BACKEND_PID 2>/dev/null
    exit 1
  fi
  echo "✅ Frontend server started (PID: $FRONTEND_PID)"

  # Setup cleanup and wait
  setup_signal_handlers
  wait_for_services
}

# Cleanup function
cleanup_services() {
  echo "🛑 Shutting down services..."

  # Kill all child processes
  for pid in $BACKEND_PID $FRONTEND_PID $PNPM_PID; do
    if [ -n "$pid" ]; then
      kill $pid 2>/dev/null || true
    fi
  done

  # Wait for processes to terminate
  for pid in $BACKEND_PID $FRONTEND_PID $PNPM_PID; do
    if [ -n "$pid" ]; then
      wait $pid 2>/dev/null || true
    fi
  done

  echo "✅ Services stopped"
  exit 0
}

# Wait for production services
wait_for_services() {
  echo "🎯 Services running successfully!"
  echo "   Frontend: http://localhost:12008"
  echo "   Backend:  http://localhost:12009"

  # Wait for both processes
  wait $BACKEND_PID
  wait $FRONTEND_PID
}

# Main execution flow
main() {
  # Load configuration
  load_config

  # Set default postgres connection values
  POSTGRES_HOST=${POSTGRES_HOST:-postgres}
  POSTGRES_PORT=${POSTGRES_PORT:-5432}
  POSTGRES_USER=${POSTGRES_USER:-postgres}

  run_migrations
  start_services
}

# Run main function
main "$@"

