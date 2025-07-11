#!/usr/bin/env zsh

# Backend start script for MetaMCP

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting MetaMCP Backend...${NC}"

# Navigate to backend directory
cd "$(dirname "$0")/../apps/backend"

# Check if we're in the right directory
if [[ ! -f "package.json" ]]; then
    echo -e "${RED}Error: package.json not found. Are you in the backend directory?${NC}"
    exit 1
fi

# Check if dist exists
if [[ ! -d "dist" ]]; then
    echo -e "${YELLOW}No build found. Running build first...${NC}"
    pnpm build
fi

# Start the backend
echo -e "${GREEN}Starting backend on port ${PORT:-12009}...${NC}"
PORT=${PORT:-12009} node dist/index.js
