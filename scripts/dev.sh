#!/usr/bin/env zsh

# Development script for MetaMCP - starts both frontend and backend

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== MetaMCP Development Setup ===${NC}\n"

# Function to cleanup background processes
cleanup() {
    echo -e "\n${YELLOW}Shutting down services...${NC}"
    if [[ -n $BACKEND_PID ]]; then
        kill $BACKEND_PID 2>/dev/null || true
    fi
    if [[ -n $FRONTEND_PID ]]; then
        kill $FRONTEND_PID 2>/dev/null || true
    fi
    wait 2>/dev/null || true
    echo -e "${GREEN}Services stopped.${NC}"
    exit 0
}

# Trap cleanup on script exit
trap cleanup SIGINT SIGTERM EXIT

# Check if we're in the right directory
if [[ ! -f "package.json" ]]; then
    echo -e "${RED}Error: Not in MetaMCP root directory${NC}"
    exit 1
fi

echo -e "${YELLOW}Installing dependencies...${NC}"
pnpm install

echo -e "\n${YELLOW}Building backend...${NC}"
cd apps/backend
pnpm build
cd ../..

echo -e "\n${YELLOW}Starting backend on port 12009...${NC}"
cd apps/backend
PORT=12009 node dist/index.js &
BACKEND_PID=$!
cd ../..

# Wait a moment for backend to start
sleep 2

echo -e "\n${YELLOW}Starting frontend on port 12008...${NC}"
cd apps/frontend

# Try development mode first (avoids standalone issues)
pnpm start:dev &
FRONTEND_PID=$!
cd ../..

echo -e "\n${GREEN}✓ Backend running on http://localhost:12009${NC}"
echo -e "${GREEN}✓ Frontend running on http://localhost:12008${NC}"
echo -e "${BLUE}✓ Access via Traefik at https://mcp.delo.sh${NC}"

echo -e "\n${YELLOW}Press Ctrl+C to stop all services${NC}\n"

# Wait for background processes
wait
