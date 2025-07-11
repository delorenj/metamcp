#!/usr/bin/env zsh

# Debug routing script for MetaMCP
# This helps identify routing issues

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== MetaMCP Routing Debug ===${NC}\n"

# Test frontend
echo -e "${YELLOW}Testing Frontend (http://localhost:12008)...${NC}"
if curl -s http://localhost:12008 > /dev/null; then
    echo -e "${GREEN}✓ Frontend is accessible${NC}"
    echo "Frontend response status:"
    curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost:12008
else
    echo -e "${RED}✗ Frontend is not accessible${NC}"
fi

# Test backend
echo -e "\n${YELLOW}Testing Backend (http://localhost:12009)...${NC}"
if curl -s http://localhost:12009 > /dev/null; then
    echo -e "${GREEN}✓ Backend is accessible${NC}"
else
    echo -e "${RED}✗ Backend is not accessible${NC}"
fi

# Test backend API routes
echo -e "\n${YELLOW}Testing Backend API routes...${NC}"

echo "GET /health:"
curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost:12009/health 2>/dev/null || echo "Failed to connect"

echo "GET /api/auth/session:"
curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost:12009/api/auth/session 2>/dev/null || echo "Failed to connect"

echo "GET /trpc/..."
curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost:12009/trpc/ 2>/dev/null || echo "Failed to connect"

# Test frontend routes
echo -e "\n${YELLOW}Testing Frontend routes...${NC}"

echo "GET / (home):"
curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost:12008/ 2>/dev/null || echo "Failed to connect"

echo "GET /api-keys:"
curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost:12008/api-keys 2>/dev/null || echo "Failed to connect"

# Test Traefik routes (if running)
echo -e "\n${YELLOW}Testing Traefik routes...${NC}"
if netstat -an | grep -q ":80.*LISTEN"; then
    echo "Testing main route (http://localhost/):"
    curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost/ 2>/dev/null || echo "Failed to connect"
    
    echo "Testing api-keys route (http://localhost/api-keys):"
    curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost/api-keys 2>/dev/null || echo "Failed to connect"
else
    echo -e "${YELLOW}Traefik not running on port 80${NC}"
fi

# Check Next.js app structure
echo -e "\n${YELLOW}Checking Next.js app structure...${NC}"
echo "App directory routes found:"
find apps/frontend/app -name "page.tsx" | sed 's|apps/frontend/app||g' | sed 's|/page.tsx||g' | sed 's|^/||g' | while read route; do
    if [[ -z "$route" ]]; then
        echo "  / (root)"
    else
        # Convert (sidebar) group routes
        clean_route=$(echo "$route" | sed 's|(sidebar)/||g')
        echo "  /$clean_route"
    fi
done

echo -e "\n${BLUE}=== Debug Complete ===${NC}"
echo -e "\n${YELLOW}Quick troubleshooting tips:${NC}"
echo "1. If frontend shows 404 for /api-keys, try rebuilding: cd apps/frontend && pnpm build"
echo "2. If Traefik is not routing correctly, check your dynamic config"
echo "3. The api-keys page should be available at: http://localhost:12008/api-keys"
echo "4. Use the start scripts: ./scripts/start-frontend.sh and ./scripts/start-backend.sh"
