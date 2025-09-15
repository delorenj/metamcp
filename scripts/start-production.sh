#!/bin/bash

# MetaMCP Production Startup Script
# Safely stops development processes and starts containerized version

set -e

echo "🚀 Starting MetaMCP Production Deployment..."

# Function to safely kill processes
kill_dev_processes() {
    echo "🛑 Stopping development processes..."

    # Kill pnpm processes
    pkill -f "pnpm" 2>/dev/null || true

    # Kill tsx processes
    pkill -f "tsx" 2>/dev/null || true

    # Kill tsup processes
    pkill -f "tsup" 2>/dev/null || true

    # Kill esbuild processes
    pkill -f "esbuild" 2>/dev/null || true

    # Kill next dev processes
    pkill -f "next dev" 2>/dev/null || true

    # Wait for processes to terminate
    sleep 3

    echo "✅ Development processes stopped"
}

# Function to start production containers
start_production() {
    echo "🐳 Starting production containers..."

    cd /home/delorenj/code/utils/metamcp

    # Stop any existing containers
    docker compose -f docker-compose.production.yml down 2>/dev/null || true

    # Build and start with resource limits
    docker compose -f docker-compose.production.yml up --build -d

    echo "✅ Production containers started"
}

# Function to verify deployment
verify_deployment() {
    echo "🔍 Verifying deployment..."

    # Wait for services to be ready
    sleep 10

    # Check container status
    docker compose -f docker-compose.production.yml ps

    # Check process count in container
    PROCESS_COUNT=$(docker exec metamcp-app ps aux 2>/dev/null | grep -E "(npm|node)" | wc -l || echo "0")
    echo "📊 Current process count in container: $PROCESS_COUNT"

    if [ "$PROCESS_COUNT" -le 15 ]; then
        echo "✅ Process count is within limits"
    else
        echo "⚠️  Process count is high, monitor closely"
    fi
}

# Main execution
main() {
    kill_dev_processes
    start_production
    verify_deployment

    echo ""
    echo "🎉 MetaMCP Production Deployment Complete!"
    echo ""
    echo "📊 Container Status:"
    docker compose -f docker-compose.production.yml ps
    echo ""
    echo "📝 To monitor logs:"
    echo "   docker compose -f docker-compose.production.yml logs -f"
    echo ""
    echo "🛠️  To stop:"
    echo "   docker compose -f docker-compose.production.yml down"
}

# Execute main function
main "$@"