#!/usr/bin/env zsh

# Frontend start script for MetaMCP
# This handles the standalone Next.js configuration properly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting MetaMCP Frontend...${NC}"

# Navigate to frontend directory
cd "$(dirname "$0")/../apps/frontend"

# Check if we're in the right directory
if [[ ! -f "package.json" ]]; then
    echo -e "${RED}Error: package.json not found. Are you in the frontend directory?${NC}"
    exit 1
fi

# Check if build exists
if [[ ! -d ".next" ]]; then
    echo -e "${YELLOW}No build found. Running build first...${NC}"
    pnpm build
fi

# Check for standalone build
if [[ -f ".next/standalone/server.js" ]]; then
    echo -e "${GREEN}Using standalone server (.next/standalone/server.js)...${NC}"
    cd .next/standalone
    PORT=${PORT:-12008} node server.js
elif [[ -f ".next/standalone/apps/frontend/server.js" ]]; then
    echo -e "${GREEN}Using standalone server (.next/standalone/apps/frontend/server.js)...${NC}"
    PORT=${PORT:-12008} node .next/standalone/apps/frontend/server.js
else
    echo -e "${YELLOW}Standalone server not found. Building first...${NC}"
    pnpm build
    if [[ -f ".next/standalone/server.js" ]]; then
        echo -e "${GREEN}Now using standalone server...${NC}"
        cd .next/standalone
        PORT=${PORT:-12008} node server.js
    else
        echo -e "${RED}Build failed or standalone not configured properly${NC}"
        exit 1
    fi
fi
