# Cognee MCP Docker Container

## Overview

This directory contains the Docker configuration for running Cognee as an MCP server with streamable HTTP transport.

## Files

- `Dockerfile` - Container image definition
- `requirements.txt` - Python dependencies
- `server.py` - Cognee MCP server startup script
- `entrypoint.sh` - Container entrypoint with validation

## Quick Start

### Build Image

```bash
docker build -t cognee-mcp:latest .
```

### Run Locally

```bash
docker run -p 8000:8000 \
  -e TRANSPORT_MODE=http \
  -e COGNEE_LLM_PROVIDER=openai \
  -e OPENAI_API_KEY=your-key \
  cognee-mcp:latest
```

### Test Health

```bash
curl http://localhost:8000/health
```

## Environment Variables

### Required

- `COGNEE_LLM_PROVIDER` - LLM provider (`openai`, `anthropic`)
- Provider API key:
  - `OPENAI_API_KEY` (if provider is openai)
  - `ANTHROPIC_API_KEY` (if provider is anthropic)

### Optional

- `TRANSPORT_MODE` - Transport type (default: `http`)
- `COGNEE_HOST` - Server host (default: `0.0.0.0`)
- `COGNEE_PORT` - Server port (default: `8000`)
- `COGNEE_PATH` - MCP endpoint path (default: `/mcp`)
- `COGNEE_MEMORY_BACKEND` - Memory backend (default: `local`)
- `COGNEE_DATABASE_URL` - PostgreSQL connection string

## Docker Compose

This container is designed to run via Docker Compose:

```yaml
cognee-mcp:
  build: ./cognee-mcp-docker
  environment:
    - COGNEE_LLM_PROVIDER=openai
    - OPENAI_API_KEY=${OPENAI_API_KEY}
  ports:
    - "8000:8000"
```

## Health Check

The container includes a health check endpoint:

```bash
curl http://localhost:8000/health
```

Expected response:
```json
{
  "status": "healthy",
  "service": "cognee-mcp",
  "transport": "http"
}
```

## Troubleshooting

### Container won't start

Check logs:
```bash
docker logs cognee-mcp
```

### Missing dependencies

Rebuild image:
```bash
docker compose build --no-cache cognee-mcp
```

### Permission errors

Ensure directories have correct ownership:
```bash
chown -R 1001:1001 /app/data
```

## Development

### Local Testing

```bash
# Install dependencies
pip install -r requirements.txt

# Run server
python server.py
```

### Updating Dependencies

Edit `requirements.txt` and rebuild:
```bash
docker compose build cognee-mcp
docker compose up -d cognee-mcp
```

## Resource Requirements

- **CPU**: 0.5-1.0 cores
- **Memory**: 1-2GB (4GB for large knowledge graphs)
- **Disk**: 500MB + storage for knowledge graphs

## Security

- Runs as non-root user (UID 1001)
- No new privileges allowed
- Resource limits enforced
- Health checks enabled

## License

See main repository license.
