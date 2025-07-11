#!/usr/bin/env zsh

# Install MetaMCP as system services on Ubuntu using systemd

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Installing MetaMCP System Services (Ubuntu/systemd) ===${NC}\n"

# Get the absolute path to the project
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
USER=$(whoami)

echo -e "${YELLOW}Project root: $PROJECT_ROOT${NC}"
echo -e "${YELLOW}Running as user: $USER${NC}\n"

# Ensure the project is built
echo -e "${YELLOW}Ensuring project is built...${NC}"
cd "$PROJECT_ROOT"
mise run build

# Create backend service
echo -e "${YELLOW}Creating backend systemd service...${NC}"

sudo tee /etc/systemd/system/metamcp-backend.service > /dev/null << EOF
[Unit]
Description=MetaMCP Backend Service
After=network.target
Wants=network.target

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=$PROJECT_ROOT
Environment=NODE_ENV=production
Environment=PORT=12009
Environment=PATH=/usr/local/bin:/usr/bin:/bin:$HOME/.local/bin:$HOME/.mise/bin
ExecStartPre=/usr/bin/mise exec -- node --version
ExecStart=/usr/bin/mise exec -- node apps/backend/dist/index.js
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=metamcp-backend

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=$PROJECT_ROOT
ProtectHome=read-only

[Install]
WantedBy=multi-user.target
EOF

echo -e "${GREEN}✓ Backend service created${NC}"

# Create frontend service
echo -e "${YELLOW}Creating frontend systemd service...${NC}"

sudo tee /etc/systemd/system/metamcp-frontend.service > /dev/null << EOF
[Unit]
Description=MetaMCP Frontend Service
After=network.target metamcp-backend.service
Wants=network.target
Requires=metamcp-backend.service

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=$PROJECT_ROOT/apps/frontend
Environment=NODE_ENV=production
Environment=PORT=12008
Environment=PATH=/usr/local/bin:/usr/bin:/bin:$HOME/.local/bin:$HOME/.mise/bin
ExecStartPre=/usr/bin/mise exec -- node --version
ExecStart=/usr/bin/mise exec -- node .next/standalone/server.js
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=metamcp-frontend

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=$PROJECT_ROOT
ProtectHome=read-only

[Install]
WantedBy=multi-user.target
EOF

echo -e "${GREEN}✓ Frontend service created${NC}"

# Reload systemd and enable services
echo -e "${YELLOW}Reloading systemd daemon...${NC}"
sudo systemctl daemon-reload

echo -e "${YELLOW}Enabling services for auto-start...${NC}"
sudo systemctl enable metamcp-backend.service
sudo systemctl enable metamcp-frontend.service

echo -e "\n${GREEN}✅ MetaMCP services installed successfully!${NC}"
echo -e "\n${BLUE}📋 Service Management Commands:${NC}"
echo -e "  • Start services: ${YELLOW}mise run services-start${NC}"
echo -e "  • Stop services: ${YELLOW}mise run services-stop${NC}"
echo -e "  • Restart services: ${YELLOW}mise run services-restart${NC}"
echo -e "  • Check status: ${YELLOW}mise run services-status${NC}"
echo -e "  • View logs: ${YELLOW}sudo journalctl -u metamcp-backend.service -f${NC}"
echo -e "  • View logs: ${YELLOW}sudo journalctl -u metamcp-frontend.service -f${NC}"
echo -e "\n${BLUE}📋 Direct systemctl Commands:${NC}"
echo -e "  • ${YELLOW}sudo systemctl start metamcp-backend.service${NC}"
echo -e "  • ${YELLOW}sudo systemctl start metamcp-frontend.service${NC}"
echo -e "  • ${YELLOW}sudo systemctl status metamcp-backend.service${NC}"
echo -e "  • ${YELLOW}sudo systemctl status metamcp-frontend.service${NC}"
