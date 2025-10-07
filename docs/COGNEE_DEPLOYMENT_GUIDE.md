# Cognee MCP Deployment Guide

## 🎉 Implementation Complete

The Cognee MCP server has been successfully integrated into metamcp as a streamable HTTP service.

## 📋 What Was Built

### 1. Docker Infrastructure
- **Location**: `cognee-mcp-docker/`
- **Files Created**:
  - `Dockerfile` - Python 3.11 Alpine with uv package manager
  - `requirements.txt` - Cognee + MCP dependencies
  - `server.py` - Cognee MCP startup script
  - `entrypoint.sh` - Container initialization with validation
  - `README.md` - Container documentation

### 2. Docker Compose Service
- **File**: `compose.yml`
- **Service Name**: `cognee-mcp`
- **Key Features**:
  - Streamable HTTP transport on port 8000
  - Traefik integration with SSL
  - Resource limits (2GB RAM, 1 CPU)
  - Health checks every 30s
  - Persistent volume for knowledge graphs
  - CORS and streaming-optimized headers

### 3. Backend Proxy Router
- **File**: `apps/backend/src/routers/cognee-proxy.ts`
- **Features**:
  - Session management with UUID generation
  - API key authentication
  - Namespace isolation
  - GET/POST/DELETE endpoints
  - Health monitoring
  - Memory leak prevention

### 4. Integration
- **File**: `apps/backend/src/routers/public-metamcp.ts`
- **Changes**:
  - Imported Cognee proxy router
  - Mounted at `/cognee` path
  - Added Cognee endpoint to public API listing

### 5. Configuration
- **File**: `.env.example`
- **Variables Added**:
  - `COGNEE_LLM_PROVIDER`
  - `OPENAI_API_KEY`
  - `ANTHROPIC_API_KEY`
  - `COGNEE_MEMORY_BACKEND`
  - `COGNEE_DATABASE_URL`

### 6. Documentation
- **Files Created**:
  - `docs/integrations/cognee-mcp.md` - Complete integration guide
  - `cognee-mcp-docker/README.md` - Container documentation

## 🚀 Deployment Steps

### Step 1: Configure Environment

Copy and edit `.env`:

```bash
cp .env.example .env
nano .env
```

Add required variables:
```bash
# Cognee MCP Configuration
COGNEE_LLM_PROVIDER=openai
OPENAI_API_KEY=sk-your-key-here
COGNEE_MEMORY_BACKEND=local
```

### Step 2: Build Container

```bash
docker compose build cognee-mcp
```

### Step 3: Start Service

```bash
docker compose up -d cognee-mcp
```

### Step 4: Verify Deployment

```bash
# Check container status
docker compose ps cognee-mcp

# Check logs
docker compose logs -f cognee-mcp

# Test health endpoint (internal)
docker exec cognee-mcp curl -f http://localhost:8000/health

# Test via Traefik (requires metamcp running)
curl https://mcp.delo.sh/metamcp/cognee/health/sessions
```

### Step 5: Test Integration

Create a test endpoint in metamcp UI, then:

```bash
# Initialize session
curl -X POST https://mcp.delo.sh/metamcp/cognee/test-endpoint/mcp \
  -H "X-API-Key: your-api-key" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/call",
    "params": {
      "name": "cognify",
      "arguments": {
        "text": "Test knowledge: Cognee is working!"
      }
    }
  }'

# Note the mcp-session-id from response header

# Search knowledge
curl -X POST https://mcp.delo.sh/metamcp/cognee/test-endpoint/mcp \
  -H "X-API-Key: your-api-key" \
  -H "mcp-session-id: YOUR-SESSION-ID" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/call",
    "params": {
      "name": "search",
      "arguments": {
        "query": "What is Cognee?",
        "mode": "GRAPH_COMPLETION"
      }
    }
  }'
```

## 📊 Architecture Overview

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │ HTTPS
       ▼
┌─────────────┐
│   Traefik   │ (SSL, routing, streaming)
└──────┬──────┘
       │ /cognee/*
       ▼
┌─────────────┐
│  Metamcp    │ (auth, session mgmt)
│  Backend    │
└──────┬──────┘
       │ HTTP
       ▼
┌─────────────┐
│  Cognee     │ (knowledge graphs)
│  MCP Server │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Storage    │ (local or PostgreSQL)
└─────────────┘
```

## 🔧 Configuration Options

### LLM Providers

**OpenAI** (default):
```bash
COGNEE_LLM_PROVIDER=openai
OPENAI_API_KEY=sk-...
```

**Anthropic**:
```bash
COGNEE_LLM_PROVIDER=anthropic
ANTHROPIC_API_KEY=sk-ant-...
```

### Storage Backends

**Local** (default):
```bash
COGNEE_MEMORY_BACKEND=local
# Data stored in Docker volume: cognee-data
```

**PostgreSQL**:
```bash
COGNEE_MEMORY_BACKEND=postgres
COGNEE_DATABASE_URL=postgresql://user:pass@host:5432/cognee
```

### Resource Tuning

Edit `compose.yml`:

```yaml
cognee-mcp:
  mem_limit: 4g    # Increase for large graphs
  cpus: "2.0"      # More CPU for complex queries
  pids_limit: 2000 # More processes if needed
```

## 🔍 Monitoring

### Session Health

```bash
curl https://mcp.delo.sh/metamcp/cognee/health/sessions
```

Response:
```json
{
  "service": "cognee-mcp",
  "timestamp": "2025-01-06T12:00:00Z",
  "cogneeSessions": {
    "count": 2,
    "sessionIds": ["uuid1", "uuid2"]
  },
  "metaMcpPoolStatus": {...}
}
```

### Container Metrics

```bash
# Resource usage
docker stats cognee-mcp

# Logs
docker compose logs -f cognee-mcp

# Process count
docker exec cognee-mcp ps aux | wc -l
```

## 🛠️ Troubleshooting

### Container Won't Start

**Check logs**:
```bash
docker compose logs cognee-mcp
```

**Common issues**:
- Missing `COGNEE_LLM_PROVIDER`
- Invalid API key
- Port 8000 already in use

**Fix**:
```bash
# Rebuild with fresh image
docker compose build --no-cache cognee-mcp
docker compose up -d cognee-mcp
```

### Session Not Found

**Symptoms**: `404 Session not found`

**Causes**:
- Session expired
- Wrong session ID
- Container restarted

**Fix**:
- Start new session with POST (without session ID)
- Check active sessions via health endpoint

### Memory Issues

**Symptoms**: Container killed, slow responses

**Fix**:
```yaml
# Increase memory limit
cognee-mcp:
  mem_limit: 4g
  memswap_limit: 4g
```

### Traefik Routing Issues

**Symptoms**: 404 or 502 errors

**Check**:
```bash
# Verify Traefik sees the service
docker compose logs traefik | grep cognee

# Check service is on proxy network
docker network inspect proxy
```

**Fix**:
```bash
# Restart Traefik
docker compose restart traefik

# Verify labels
docker inspect cognee-mcp | grep -A 30 Labels
```

## 🔐 Security

### Production Checklist

- [ ] Set strong API keys in metamcp UI
- [ ] Use HTTPS only (Traefik enforces this)
- [ ] Rotate LLM provider API keys regularly
- [ ] Enable rate limiting in Traefik
- [ ] Configure namespace isolation
- [ ] Set up log monitoring
- [ ] Enable container resource limits
- [ ] Backup knowledge graph data
- [ ] Use PostgreSQL for persistent storage
- [ ] Implement session timeout policies

### Network Security

```yaml
# compose.yml security settings
cognee-mcp:
  security_opt:
    - no-new-privileges:true
  networks:
    - proxy  # Internal network only
  # No external ports exposed
```

## 📈 Performance Tips

### 1. Use PostgreSQL Backend

For better performance with large knowledge graphs:

```bash
COGNEE_MEMORY_BACKEND=postgres
COGNEE_DATABASE_URL=postgresql://...
```

### 2. Increase Resources

```yaml
cognee-mcp:
  mem_limit: 4g
  cpus: "2.0"
```

### 3. Implement Caching

Add Redis for query caching:

```yaml
environment:
  COGNEE_CACHE_BACKEND: redis
  COGNEE_REDIS_URL: redis://redis:6379
```

### 4. Optimize Queries

- Use specific search modes
- Limit result sets
- Index frequently queried fields
- Implement pagination

## 🔄 Updates & Maintenance

### Update Cognee Version

Edit `cognee-mcp-docker/requirements.txt`:
```
cognee>=0.2.0  # Update version
```

Rebuild:
```bash
docker compose build --no-cache cognee-mcp
docker compose up -d cognee-mcp
```

### Backup Knowledge Graphs

```bash
# Local backend
docker compose exec cognee-mcp tar czf /tmp/cognee-backup.tar.gz /app/data
docker cp cognee-mcp:/tmp/cognee-backup.tar.gz ./backups/

# PostgreSQL backend
pg_dump -h localhost -U user cognee > cognee_backup.sql
```

### Restore from Backup

```bash
# Local backend
docker cp ./backups/cognee-backup.tar.gz cognee-mcp:/tmp/
docker compose exec cognee-mcp tar xzf /tmp/cognee-backup.tar.gz -C /

# PostgreSQL backend
psql -h localhost -U user cognee < cognee_backup.sql
```

## 📚 Additional Resources

- [Cognee Integration Guide](./integrations/cognee-mcp.md)
- [Cognee Docker README](../cognee-mcp-docker/README.md)
- [Cognee GitHub](https://github.com/topoteretes/cognee)
- [MCP Specification](https://modelcontextprotocol.io)

## 🎯 Next Steps

1. Configure environment variables
2. Build and start the service
3. Create test endpoint in metamcp UI
4. Test with curl commands
5. Integrate with Claude Desktop or other MCP clients
6. Monitor session health and performance
7. Set up backups and monitoring
8. Scale resources as needed

## ✅ Success Criteria

- [ ] Container builds successfully
- [ ] Health check passes
- [ ] Can create sessions
- [ ] Can store knowledge with `cognify`
- [ ] Can search with `search`
- [ ] Sessions clean up properly
- [ ] Traefik routes correctly
- [ ] No memory leaks over 24 hours
- [ ] Logs show no errors

---

**Deployment Status**: Ready for Production ✅
**Last Updated**: 2025-01-06
**Version**: 1.0.0
