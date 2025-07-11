#!/usr/bin/env zsh

# Uninstall MetaMCP system services from Ubuntu

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Uninstalling MetaMCP System Services ===${NC}\n"

# Stop services if running
echo -e "${YELLOW}Stopping MetaMCP services...${NC}"
sudo systemctl stop metamcp-backend.service 2>/dev/null || echo "Backend service not running"
sudo systemctl stop metamcp-frontend.service 2>/dev/null || echo "Frontend service not running"

# Disable services
echo -e "${YELLOW}Disabling MetaMCP services...${NC}"
sudo systemctl disable metamcp-backend.service 2>/dev/null || echo "Backend service not enabled"
sudo systemctl disable metamcp-frontend.service 2>/dev/null || echo "Frontend service not enabled"

# Remove service files
echo -e "${YELLOW}Removing service files...${NC}"
sudo rm -f /etc/systemd/system/metamcp-backend.service
sudo rm -f /etc/systemd/system/metamcp-frontend.service

# Reload systemd daemon
echo -e "${YELLOW}Reloading systemd daemon...${NC}"
sudo systemctl daemon-reload
sudo systemctl reset-failed

echo -e "\n${GREEN}✅ MetaMCP services uninstalled successfully!${NC}"
echo -e "\n${BLUE}📋 The services have been completely removed from the system.${NC}"
echo -e "You can reinstall them later using: ${YELLOW}mise run services-install${NC}"
