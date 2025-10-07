# Cognee MCP Integration Guide

## Overview

Cognee is an AI memory engine that builds knowledge graphs from text and enables semantic search. This integration runs Cognee as a streamable HTTP MCP server within the metamcp infrastructure.

## Architecture

```
Client → Traefik → metamcp/cognee → Cognee MCP Container
                ↓
         Knowledge Graph Storage
```

### Key Components

1. **Cognee MCP Container**: Python-based service running Cognee with streamable HTTP transport
2. **Backend Proxy Router**: Express.js router handling session management and authentication
3. **Traefik**: Reverse proxy with SSL termination and streaming optimization
4. **Knowledge Graph Storage**: Local or PostgreSQL-backed persistent storage

## Configuration

### Environment Variables

Add to your `.env` file:

```bash
# Required: LLM Provider
COGNEE_LLM_PROVIDER=openai  # or anthropic

# Required: API Keys (based on provider)
OPENAI_API_KEY=sk-...
# OR
ANTHROPIC_API_KEY=sk-ant-...

# Memory Backend
COGNEE_MEMORY_BACKEND=local  # or postgres

# Optional: PostgreSQL for persistent storage
COGNEE_DATABASE_URL=postgresql://user:pass@host:port/cognee
```

### Docker Compose

The Cognee service is defined in `compose.yml`:

```yaml
cognee-mcp:
  build: ./cognee-mcp-docker
  container_name: cognee-mcp
  restart: unless-stopped
  # ... (see compose.yml for full configuration)
```

## Endpoints

### Streamable HTTP MCP

**Base URL**: `https://mcp.delo.sh/metamcp/cognee/{endpoint_name}/mcp`

**Methods**:
- `POST` - Initialize new session or send requests
- `GET` - Retrieve session data
- `DELETE` - Cleanup session

**Headers**:
```http
Content-Type: application/json
X-API-Key: your-api-key
mcp-session-id: session-uuid  # After first request
mcp-protocol-version: 2025-03-26
```

### Health Check

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
  }
}
```

## Available Tools

Cognee MCP provides these tools:

### 1. `cognify`
Converts data into a structured knowledge graph and stores it in memory.

**Input**:
```json
{
  "text": "Your text to analyze and store",
  "metadata": {
    "source": "document-name",
    "date": "2025-01-06"
  }
}
```

### 2. `codify`
Analyzes code repositories and builds a code graph.

**Input**:
```json
{
  "repository_path": "/path/to/repo",
  "language": "typescript",
  "analyze_dependencies": true
}
```

### 3. `search`
Query memory with multiple modes.

**Modes**:
- `GRAPH_COMPLETION` - Semantic graph traversal
- `RAG_COMPLETION` - Retrieval-augmented generation
- `CODE` - Code-specific search
- `CHUNKS` - Raw text chunks
- `INSIGHTS` - High-level insights

**Input**:
```json
{
  "query": "What is the authentication flow?",
  "mode": "GRAPH_COMPLETION",
  "limit": 10
}
```

### 4. `list_data`
Lists all datasets in memory.

### 5. `delete`
Removes specific data from memory.

**Input**:
```json
{
  "data_id": "uuid-of-data"
}
```

### 6. `prune`
Resets entire memory (use with caution).

## Usage Examples

### Example 1: Store and Query Knowledge

```bash
# 1. Create session
curl -X POST https://mcp.delo.sh/metamcp/cognee/my-endpoint/mcp \
  -H "X-API-Key: your-key" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/call",
    "params": {
      "name": "cognify",
      "arguments": {
        "text": "Claude Code is an AI-powered development tool that integrates with VS Code."
      }
    }
  }'

# Response includes mcp-session-id header

# 2. Search knowledge
curl -X POST https://mcp.delo.sh/metamcp/cognee/my-endpoint/mcp \
  -H "X-API-Key: your-key" \
  -H "mcp-session-id: your-session-id" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/call",
    "params": {
      "name": "search",
      "arguments": {
        "query": "What is Claude Code?",
        "mode": "GRAPH_COMPLETION"
      }
    }
  }'

# 3. Cleanup session
curl -X DELETE https://mcp.delo.sh/metamcp/cognee/my-endpoint/mcp \
  -H "X-API-Key: your-key" \
  -H "mcp-session-id: your-session-id"
```

### Example 2: Analyze Code Repository

```bash
curl -X POST https://mcp.delo.sh/metamcp/cognee/my-endpoint/mcp \
  -H "X-API-Key: your-key" \
  -H "mcp-session-id: your-session-id" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/call",
    "params": {
      "name": "codify",
      "arguments": {
        "repository_path": "/app/code",
        "language": "typescript"
      }
    }
  }'
```

## Client Integration

### MCP SDK (TypeScript)

```typescript
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StreamableHTTPClientTransport } from "@modelcontextprotocol/sdk/client/streamableHttp.js";

const transport = new StreamableHTTPClientTransport({
  url: "https://mcp.delo.sh/metamcp/cognee/my-endpoint/mcp",
  headers: {
    "X-API-Key": "your-api-key",
  },
});

const client = new Client({
  name: "cognee-client",
  version: "1.0.0",
}, {
  capabilities: {},
});

await client.connect(transport);

// Use tools
const result = await client.callTool({
  name: "cognify",
  arguments: {
    text: "Your knowledge to store",
  },
});
```

### Claude Desktop

Add to `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "cognee": {
      "type": "http",
      "url": "https://mcp.delo.sh/metamcp/cognee/my-endpoint/mcp",
      "headers": {
        "X-API-Key": "your-api-key"
      }
    }
  }
}
```

## Deployment

### Build and Start

```bash
# Build Cognee container
docker compose build cognee-mcp

# Start services
docker compose up -d cognee-mcp

# Check logs
docker compose logs -f cognee-mcp

# Verify health
curl http://localhost:8000/health
```

### Production Checklist

- [ ] Set secure API keys in `.env`
- [ ] Configure LLM provider (OpenAI/Anthropic)
- [ ] Enable PostgreSQL for persistent storage (optional)
- [ ] Set resource limits (2GB RAM recommended)
- [ ] Configure backup strategy for knowledge graphs
- [ ] Monitor memory usage via `/health/sessions`
- [ ] Enable log aggregation
- [ ] Test session cleanup mechanisms

## Troubleshooting

### Issue: Container fails to start

**Check**:
```bash
docker compose logs cognee-mcp
```

**Common causes**:
- Missing `COGNEE_LLM_PROVIDER` environment variable
- Invalid API key for LLM provider
- Insufficient memory allocation

### Issue: Session not found

**Symptoms**: `404 Session not found` error

**Solutions**:
1. Verify session ID is correct
2. Check session hasn't expired
3. Review session list: `GET /health/sessions`

### Issue: Memory leaks

**Monitoring**:
```bash
# Check active sessions
curl https://mcp.delo.sh/metamcp/cognee/health/sessions

# Review container memory
docker stats cognee-mcp
```

**Solutions**:
1. Implement aggressive session cleanup
2. Set `mem_limit` in compose.yml
3. Restart container periodically via cron

### Issue: Slow response times

**Causes**:
- Large knowledge graphs
- Complex graph queries
- Insufficient resources

**Solutions**:
1. Increase CPU/memory limits
2. Use PostgreSQL backend for better performance
3. Optimize graph queries
4. Implement caching layer

## Performance Tuning

### Resource Limits

```yaml
# compose.yml
cognee-mcp:
  mem_limit: 4g  # Increase for large graphs
  cpus: "2.0"    # More CPU for complex queries
```

### Database Optimization

For PostgreSQL backend:

```sql
-- Create indexes for faster queries
CREATE INDEX idx_knowledge_nodes ON cognee_nodes(node_type);
CREATE INDEX idx_knowledge_edges ON cognee_edges(source_id, target_id);
```

### Caching Strategy

Implement Redis for frequently accessed queries:

```yaml
# compose.yml
environment:
  COGNEE_CACHE_BACKEND: redis
  COGNEE_REDIS_URL: redis://redis:6379
```

## Security Considerations

1. **API Key Management**: Use strong, unique keys per namespace
2. **Session Isolation**: Sessions are isolated by namespace UUID
3. **Rate Limiting**: Configure rate limits in Traefik
4. **Data Privacy**: Knowledge graphs contain sensitive data - secure storage
5. **Network Isolation**: Cognee container only accessible via Traefik

## Roadmap

- [ ] Vector database integration (Pinecone, Weaviate)
- [ ] Multi-tenancy support
- [ ] Graph visualization UI
- [ ] Advanced search filters
- [ ] Export/import knowledge graphs
- [ ] Real-time collaboration features

## Resources

- [Cognee GitHub](https://github.com/topoteretes/cognee)
- [Cognee MCP Server](https://github.com/topoteretes/cognee/tree/main/cognee-mcp)
- [MCP Specification](https://modelcontextprotocol.io)
- [Streamable HTTP Transport](https://modelcontextprotocol.io/specification/2025-03-26/basic/transports)

## Support

For issues specific to:
- **Cognee functionality**: [Cognee Issues](https://github.com/topoteretes/cognee/issues)
- **Metamcp integration**: [Metamcp Issues](https://github.com/yourusername/metamcp/issues)
- **MCP protocol**: [MCP Specification](https://modelcontextprotocol.io)
