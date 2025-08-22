#!/bin/sh

set -e

# Mode switching entrypoint script for MetaMCP
APP_MODE=${APP_MODE:-production}
CONFIG_DIR=${CONFIG_DIR:-/app/config}

echo "🚀 Starting MetaMCP in $APP_MODE mode..."
echo "📁 Working directory: $(pwd)"
echo "🔧 Config directory: $CONFIG_DIR"

# Function to load mode-specific configuration
load_config() {
    if [ -f "$CONFIG_DIR/$APP_MODE.json" ]; then
        echo "📋 Loading $APP_MODE configuration from $CONFIG_DIR/$APP_MODE.json"
        # Export configuration as environment variables
        # This is a simple example - you might want more sophisticated config loading
        export CONFIG_LOADED=true
    else
        echo "⚠️  No mode-specific config found at $CONFIG_DIR/$APP_MODE.json, using defaults"
    fi
}

# Function to wait for postgres
wait_for_postgres() {
    echo "⏳ Waiting for PostgreSQL to be ready..."
    until pg_isready -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" 2>/dev/null; do
        echo "   PostgreSQL not ready, waiting 2 seconds..."
        sleep 2
    done
    echo "✅ PostgreSQL is ready!"
}

# Function to run migrations
run_migrations() {
    echo "🔄 Running database migrations..."
    cd /app/apps/backend
    
    if [ -d "drizzle" ] && [ "$(ls -A drizzle/*.sql 2>/dev/null)" ]; then
        echo "   Found migration files, running migrations..."
        if pnpm exec drizzle-kit migrate; then
            echo "✅ Migrations completed successfully!"
        else
            echo "❌ Migration failed! Exiting..."
            exit 1
        fi
    else
        echo "   No migrations found or directory empty"
    fi
    
    cd /app
}

# Function to start services based on mode
start_services() {
    case "$APP_MODE" in
        "production")
            start_production_services
            ;;
        "development")
            start_development_services
            ;;
        "test")
            start_test_services
            ;;
        *)
            echo "❌ Unknown APP_MODE: $APP_MODE"
            echo "   Valid modes: production, development, test"
            exit 1
            ;;
    esac
}

# Production mode: Start built applications
start_production_services() {
    echo "🚀 Starting production services..."
    
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

# Development mode: Start with hot reload
start_development_services() {
    echo "🔧 Starting development services with hot reload..."
    echo "   Note: This requires source code to be mounted at /app/src"
    
    if [ -f "/app/src/package.json" ]; then
        echo "✅ Source code detected, starting development mode..."
        cd /app/src
        pnpm install
        pnpm dev &
        PNPM_PID=$!
        echo "✅ Development servers started (PID: $PNPM_PID)"
    else
        echo "⚠️  No source code mounted, falling back to production mode..."
        start_production_services
        return
    fi
    
    # Setup cleanup and wait
    setup_signal_handlers
    wait_for_development
}

# Test mode: Run tests and exit
start_test_services() {
    echo "🧪 Starting test mode..."
    
    # Start backend for testing
    cd /app/apps/backend
    PORT=12009 node dist/index.js &
    BACKEND_PID=$!
    
    # Wait for backend to be ready
    sleep 3
    if ! kill -0 $BACKEND_PID 2>/dev/null; then
        echo "❌ Backend server died! Cannot run tests..."
        exit 1
    fi
    
    echo "✅ Backend ready for testing"
    echo "🧪 Tests would run here (implement your test suite)"
    
    # Cleanup
    kill $BACKEND_PID 2>/dev/null
    echo "✅ Test mode completed"
}

# Signal handling for graceful shutdown
setup_signal_handlers() {
    trap 'cleanup_services' TERM INT
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
    echo "   Mode:     $APP_MODE"
    
    # Wait for both processes
    wait $BACKEND_PID
    wait $FRONTEND_PID
}

# Wait for development services
wait_for_development() {
    echo "🎯 Development services running!"
    echo "   Frontend: http://localhost:12008 (with hot reload)"
    echo "   Backend:  http://localhost:12009 (with hot reload)"
    echo "   Mode:     $APP_MODE"
    
    # Wait for the pnpm dev process
    wait $PNPM_PID || true
}

# Main execution flow
main() {
    # Load configuration
    load_config
    
    # Set default postgres connection values
    POSTGRES_HOST=${POSTGRES_HOST:-postgres}
    POSTGRES_PORT=${POSTGRES_PORT:-5432}
    POSTGRES_USER=${POSTGRES_USER:-postgres}
    
    # Wait for database (except in test mode without DB)
    if [ "$APP_MODE" != "test" ] || [ -n "$DATABASE_URL" ]; then
        wait_for_postgres
        run_migrations
    fi
    
    # Start services based on mode
    start_services
}

# Run main function
main "$@"