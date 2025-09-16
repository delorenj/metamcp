#!/bin/bash
# Run MetaMCP with proper resource limits using docker run

set -e

# Configuration
CONTAINER_NAME="metamcp"
IMAGE="delorenj/metamcp:latest"
MEMORY_LIMIT="4g"
MEMORY_SWAP_LIMIT="4g"
CPU_LIMIT="2.0"
PIDS_LIMIT="100"

echo "Stopping existing container if running..."
docker stop $CONTAINER_NAME 2>/dev/null || true
docker rm $CONTAINER_NAME 2>/dev/null || true

echo "Loading environment variables..."
if [ -f .env ]; then
  set -a
  source .env
  set +a
fi

echo "Starting MetaMCP with resource limits..."
docker run -d \
  --name $CONTAINER_NAME \
  --restart unless-stopped \
  --memory=$MEMORY_LIMIT \
  --memory-swap=$MEMORY_SWAP_LIMIT \
  --cpus=$CPU_LIMIT \
  --pids-limit=$PIDS_LIMIT \
  --ulimit nproc=100:100 \
  --ulimit nofile=1024:2048 \
  --security-opt no-new-privileges:true \
  --env-file .env \
  -e POSTGRES_HOST=postgres_db \
  -e POSTGRES_PORT=5432 \
  -e POSTGRES_USER="${POSTGRES_USER}" \
  -e POSTGRES_PASSWORD="${POSTGRES_PASSWORD}" \
  -e POSTGRES_DB="${POSTGRES_DB:-metamcp}" \
  -e DATABASE_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres_db:5432/${POSTGRES_DB:-metamcp}" \
  -e APP_URL=https://mcp.delo.sh \
  -e NEXT_PUBLIC_APP_URL=https://mcp.delo.sh \
  -e BETTER_AUTH_SECRET="${BETTER_AUTH_SECRET}" \
  -e OIDC_CLIENT_ID="${OIDC_CLIENT_ID:-}" \
  -e OIDC_CLIENT_SECRET="${OIDC_CLIENT_SECRET:-}" \
  -e OIDC_DISCOVERY_URL="${OIDC_DISCOVERY_URL:-}" \
  -e TRANSFORM_LOCALHOST_TO_DOCKER_INTERNAL=true \
  -e NODE_OPTIONS="--max-old-space-size=2048" \
  -e UV_THREADPOOL_SIZE=4 \
  -v metamcp-cache:/app/.cache \
  -v $(pwd)/scripts:/scripts:ro \
  --network proxy \
  --label "traefik.enable=true" \
  --label "traefik.docker.network=proxy" \
  --label "traefik.http.services.metamcp.loadbalancer.server.port=12008" \
  --label "traefik.http.routers.metamcp.rule=Host(\`mcp.delo.sh\`)" \
  --label "traefik.http.routers.metamcp.entrypoints=websecure" \
  --label "traefik.http.routers.metamcp.tls.certresolver=letsencrypt" \
  --label "traefik.http.routers.metamcp.service=metamcp" \
  --label "traefik.http.routers.metamcp.priority=100" \
  --label "traefik.http.routers.metamcp-sse.rule=Host(\`mcp.delo.sh\`) && (PathPrefix(\`/mcp-proxy/\`) || PathPrefix(\`/metamcp/\`))" \
  --label "traefik.http.routers.metamcp-sse.entrypoints=websecure" \
  --label "traefik.http.routers.metamcp-sse.tls.certresolver=letsencrypt" \
  --label "traefik.http.routers.metamcp-sse.service=metamcp-sse" \
  --label "traefik.http.routers.metamcp-sse.priority=150" \
  --label "traefik.http.services.metamcp-sse.loadbalancer.server.port=12008" \
  --label "traefik.http.services.metamcp-sse.loadbalancer.responseforwarding.flushinterval=1ms" \
  --label "traefik.http.middlewares.metamcp-headers.headers.customrequestheaders.X-Forwarded-Proto=https" \
  --label "traefik.http.middlewares.metamcp-headers.headers.customresponseheaders.Access-Control-Allow-Origin=*" \
  --label "traefik.http.middlewares.metamcp-headers.headers.customresponseheaders.Access-Control-Allow-Methods=GET,POST,PUT,DELETE,OPTIONS" \
  --label "traefik.http.middlewares.metamcp-headers.headers.customresponseheaders.Access-Control-Allow-Headers=content-type,authorization,x-api-key,mcp-protocol-version,mcp-session-id" \
  --label "traefik.http.routers.metamcp.middlewares=metamcp-headers" \
  --label "traefik.http.routers.metamcp-sse.middlewares=metamcp-headers" \
  --health-cmd="curl -f http://localhost:12008/health || exit 1" \
  --health-interval=30s \
  --health-timeout=10s \
  --health-retries=3 \
  --health-start-period=40s \
  $IMAGE

echo "Container started successfully!"
echo ""
echo "Verifying resource limits..."
sleep 3

# Verify limits are applied
echo "Resource limits applied:"
docker inspect $CONTAINER_NAME | grep -E '"Memory":|"NanoCpus":|"PidsLimit":|"CpuQuota":' | head -5

echo ""
echo "Current resource usage:"
docker stats --no-stream $CONTAINER_NAME

echo ""
echo "Process count:"
docker exec $CONTAINER_NAME sh -c "ps aux | grep -E 'npm exec|@modelcontextprotocol' | grep -v grep | wc -l" 2>/dev/null || echo "0"

echo ""
echo "Container is running with proper resource limits!"
echo "Monitor with: docker stats $CONTAINER_NAME"