#!/bin/bash
# Install MetaMCP as a systemd service
# Run this script with sudo: sudo ./install-systemd-service.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== MetaMCP Systemd Service Installation ===${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
   echo -e "${RED}Error: Please run this script with sudo${NC}"
   echo "Usage: sudo $0"
   exit 1
fi

# Variables
SERVICE_NAME="metamcp"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
SOURCE_FILE="/home/delorenj/code/utils/metamcp/scripts/metamcp.service"

# Step 1: Stop any existing service
echo -e "${YELLOW}Step 1: Stopping existing service if running...${NC}"
systemctl stop ${SERVICE_NAME} 2>/dev/null || true
systemctl disable ${SERVICE_NAME} 2>/dev/null || true

# Step 2: Copy service file
echo -e "${YELLOW}Step 2: Installing service file...${NC}"
cp ${SOURCE_FILE} ${SERVICE_FILE}
chmod 644 ${SERVICE_FILE}
echo -e "${GREEN}✓ Service file installed${NC}"

# Step 3: Reload systemd
echo -e "${YELLOW}Step 3: Reloading systemd daemon...${NC}"
systemctl daemon-reload
echo -e "${GREEN}✓ Systemd reloaded${NC}"

# Step 4: Enable service
echo -e "${YELLOW}Step 4: Enabling service for auto-start...${NC}"
systemctl enable ${SERVICE_NAME}
echo -e "${GREEN}✓ Service enabled${NC}"

# Step 5: Start service
echo -e "${YELLOW}Step 5: Starting MetaMCP service...${NC}"
systemctl start ${SERVICE_NAME}
sleep 5
echo -e "${GREEN}✓ Service started${NC}"

# Step 6: Check status
echo -e "${YELLOW}Step 6: Checking service status...${NC}"
if systemctl is-active --quiet ${SERVICE_NAME}; then
    echo -e "${GREEN}✓ Service is running successfully!${NC}"
else
    echo -e "${RED}✗ Service failed to start${NC}"
    echo "Showing recent logs:"
    journalctl -u ${SERVICE_NAME} --no-pager -n 20
    exit 1
fi

# Step 7: Show service details
echo ""
echo -e "${GREEN}=== Service Status ===${NC}"
systemctl status ${SERVICE_NAME} --no-pager

echo ""
echo -e "${GREEN}=== Docker Container Status ===${NC}"
docker ps --filter name=metamcp --format "table {{.Names}}\t{{.Status}}\t{{.State}}"

echo ""
echo -e "${GREEN}=== Resource Usage ===${NC}"
docker stats --no-stream metamcp metamcp-process-monitor 2>/dev/null || echo "Containers starting..."

echo ""
echo -e "${GREEN}=== Installation Complete ===${NC}"
echo ""
echo "Useful commands:"
echo "  Check status:  systemctl status ${SERVICE_NAME}"
echo "  View logs:     journalctl -u ${SERVICE_NAME} -f"
echo "  Restart:       systemctl restart ${SERVICE_NAME}"
echo "  Stop:          systemctl stop ${SERVICE_NAME}"
echo "  Disable:       systemctl disable ${SERVICE_NAME}"
echo ""
echo -e "${GREEN}MetaMCP is now running as a systemd service with resource limits!${NC}"
echo "The service will automatically start on system boot."