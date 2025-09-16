#!/bin/bash
# Apply MetaMCP Memory Leak Fix
# This script applies the comprehensive fix for the memory leak issue

set -e

echo "====================================="
echo "MetaMCP Memory Leak Fix Deployment"
echo "====================================="
echo ""

# Check if running as appropriate user
if [ "$USER" != "delorenj" ] && [ "$USER" != "root" ]; then
    echo "Warning: Running as $USER. You may need appropriate permissions."
fi

# Step 1: Kill excessive processes in current container
echo "Step 1: Cleaning up existing processes..."
if docker ps --format "{{.Names}}" | grep -q "^metamcp$"; then
    echo "Found running container. Cleaning processes..."

    # Get current process count
    CURRENT_PROCS=$(docker exec metamcp sh -c "ps aux | grep -E 'npm exec|@modelcontextprotocol' | grep -v grep | wc -l" 2>/dev/null || echo "0")
    echo "Current MCP processes: $CURRENT_PROCS"

    if [ "$CURRENT_PROCS" -gt 20 ]; then
        echo "Killing excessive processes..."
        docker exec metamcp sh -c '
            ps aux | grep -E "npm exec|@modelcontextprotocol" | grep -v grep | \
            tail -n +16 | awk "{print \$2}" | xargs -r kill -9
        ' 2>/dev/null || true
        echo "Cleanup complete."
    fi
else
    echo "Container not running. Skipping cleanup."
fi

# Step 2: Backup current compose file
echo ""
echo "Step 2: Backing up current configuration..."
if [ -f compose.yml ]; then
    cp compose.yml compose.yml.backup.$(date +%Y%m%d-%H%M%S)
    echo "Backup created."
fi

# Step 3: Check Docker Compose version
echo ""
echo "Step 3: Checking Docker Compose version..."
COMPOSE_VERSION=$(docker compose version --short 2>/dev/null || docker-compose version --short 2>/dev/null || echo "unknown")
echo "Docker Compose version: $COMPOSE_VERSION"

# Step 4: Apply the fix
echo ""
echo "Step 4: Applying the fix..."
echo "Using compose-fixed.yml with proper resource limits..."

# Step 5: Restart with fixed configuration
echo ""
echo "Step 5: Restarting MetaMCP with resource limits..."
echo "Stopping current container..."
docker compose -f compose.yml down 2>/dev/null || docker-compose -f compose.yml down 2>/dev/null || true

echo "Starting with fixed configuration..."
docker compose -f compose-fixed.yml up -d || docker-compose -f compose-fixed.yml up -d

# Step 6: Verify the fix
echo ""
echo "Step 6: Verifying the fix..."
sleep 5

# Check if container is running
if docker ps --format "{{.Names}}" | grep -q "^metamcp$"; then
    echo "✓ Container is running"

    # Check resource limits
    echo ""
    echo "Checking applied limits..."
    docker inspect metamcp | grep -E '"Memory|"CpuQuota|"PidsLimit|"MemorySwap' | head -10 || true

    # Check current stats
    echo ""
    echo "Current resource usage:"
    docker stats --no-stream metamcp

    echo ""
    echo "✓ Fix successfully applied!"
else
    echo "✗ Container failed to start. Check logs with: docker logs metamcp"
    exit 1
fi

# Step 7: Set up monitoring
echo ""
echo "Step 7: Setting up continuous monitoring..."
if [ -f scripts/process-monitor.sh ]; then
    echo "Process monitor script is ready."
    echo "To run it manually: ./scripts/process-monitor.sh"
    echo "It will also run automatically via the process-monitor container."
fi

echo ""
echo "====================================="
echo "Fix Deployment Complete!"
echo "====================================="
echo ""
echo "Key improvements applied:"
echo "  ✓ Hard memory limit: 4GB"
echo "  ✓ PID limit: 25 processes max"
echo "  ✓ CPU limit: 2 cores"
echo "  ✓ Swap disabled"
echo "  ✓ Process monitoring active"
echo "  ✓ Health checks with process counting"
echo ""
echo "Monitoring commands:"
echo "  - Check processes: docker exec metamcp ps aux | grep -c 'npm exec'"
echo "  - Watch resources: docker stats metamcp"
echo "  - View logs: docker logs -f metamcp"
echo "  - Monitor script logs: docker logs -f metamcp-process-monitor"
echo ""
echo "If you need to make this permanent:"
echo "  1. Replace compose.yml with compose-fixed.yml"
echo "  2. Or install as systemd service:"
echo "     sudo cp scripts/metamcp-systemd.service /etc/systemd/system/"
echo "     sudo systemctl daemon-reload"
echo "     sudo systemctl enable metamcp"
echo ""