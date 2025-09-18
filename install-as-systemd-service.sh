#!/bin/bash
# MetaMCP Systemd Service Installer
# This script installs MetaMCP as a systemd service with proper resource limits

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         MetaMCP Systemd Service Installation            ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}✗ Docker is not running${NC}"
    echo "Please start Docker first: sudo systemctl start docker"
    exit 1
fi
echo -e "${GREEN}✓ Docker is running${NC}"

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${RED}✗ .env file not found${NC}"
    echo "Please create .env file with required environment variables"
    exit 1
fi
echo -e "${GREEN}✓ .env file found${NC}"

# Check if service file exists
if [ ! -f scripts/metamcp.service ]; then
    echo -e "${RED}✗ Service file not found${NC}"
    echo "Missing: scripts/metamcp.service"
    exit 1
fi
echo -e "${GREEN}✓ Service file found${NC}"

# Check if run script exists
if [ ! -f scripts/run-with-limits.sh ]; then
    echo -e "${RED}✗ Run script not found${NC}"
    echo "Missing: scripts/run-with-limits.sh"
    exit 1
fi
echo -e "${GREEN}✓ Run script found${NC}"

# Check if process monitor exists
if [ ! -f scripts/process-monitor.sh ]; then
    echo -e "${RED}✗ Process monitor script not found${NC}"
    echo "Missing: scripts/process-monitor.sh"
    exit 1
fi
echo -e "${GREEN}✓ Process monitor found${NC}"

echo ""
echo -e "${GREEN}All prerequisites met!${NC}"
echo ""

# Show what will be installed
echo -e "${BLUE}This will install MetaMCP with:${NC}"
echo "  • Docker memory limit: 4GB"
echo "  • Docker CPU limit: 2 cores" 
echo "  • Docker process limit: 100 PIDs"
echo "  • Automatic process monitoring"
echo "  • Automatic restart on failure"
echo "  • Start on system boot"
echo "  • Minimal systemd limits (no conflicts)"
echo ""

# Check if already installed
if systemctl list-units --full -all | grep -q "metamcp.service"; then
    echo -e "${YELLOW}MetaMCP service is already installed.${NC}"
    echo "This will restart the service."
    ACTION="reinstall"
else
    echo -e "${GREEN}Ready to install MetaMCP as a system service.${NC}"
    ACTION="install"
fi

# Confirm installation
echo -e "${YELLOW}This requires sudo privileges.${NC}"
echo ""
read -p "Do you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Installation cancelled${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Starting installation...${NC}"
echo ""

# Run the installation script with sudo
sudo bash scripts/install-systemd-service.sh

# Additional checks after installation
echo ""
echo -e "${BLUE}Post-installation checks:${NC}"

# Check if service is enabled
if systemctl is-enabled --quiet metamcp 2>/dev/null; then
    echo -e "${GREEN}✓ Service is enabled (will start on boot)${NC}"
else
    echo -e "${YELLOW}⚠ Service is not enabled${NC}"
fi

# Check if containers are running
if docker ps | grep -q metamcp; then
    echo -e "${GREEN}✓ MetaMCP container is running${NC}"
else
    echo -e "${RED}✗ MetaMCP container is not running${NC}"
fi

if docker ps | grep -q metamcp-process-monitor; then
    echo -e "${GREEN}✓ Process monitor is running${NC}"
else
    echo -e "${YELLOW}⚠ Process monitor is not running${NC}"
fi

# Show resource limits
echo ""
echo -e "${BLUE}Applied Resource Limits:${NC}"
docker inspect metamcp 2>/dev/null | grep -E '"Memory":|"NanoCpus":|"PidsLimit":' | head -3 || echo "Container is starting..."

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         Installation Complete!                          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Access MetaMCP at: https://mcp.delo.sh"
echo ""
echo "Monitoring commands:"
echo "  • Service status:  systemctl status metamcp"
echo "  • Service logs:    journalctl -u metamcp -f"
echo "  • Container stats: docker stats metamcp"
echo "  • Process count:   docker exec metamcp ps aux | grep -c 'npm exec'"
echo ""
echo "Management commands:"
echo "  • Restart service: sudo systemctl restart metamcp"
echo "  • Stop service:    sudo systemctl stop metamcp"
echo "  • Disable service: sudo systemctl disable metamcp"
echo ""