# Configuration Directory

## Structure

```
config/
├── traefik/          # Traefik reverse proxy configurations
│   └── metamcp.yml   # Main MetaMCP routing configuration
├── deployment-guide.md
└── docker-entrypoint-unified.sh
```

## Traefik Configuration

The `traefik/metamcp.yml` file contains:

- **SSE-optimized middleware** for MCP streaming endpoints
- **Standard middleware** for UI/API routes  
- **Rate limiting** for API protection
- **Compression** for non-streaming content
- **Proper routing** with priority handling

### Key Features

- **Server-Sent Events (SSE) support** with no buffering
- **CORS configuration** for MCP protocol compatibility
- **Health checks** and load balancer configuration
- **Extended timeouts** for long-running MCP sessions

## Usage

Reference the traefik configuration in your docker-compose files:

```yaml
traefik:
  image: traefik:v3.0
  volumes:
    - ./config/traefik:/etc/traefik/dynamic
```

## Environment Variables

The configuration uses these environment variables:
- `METAMCP_DOMAIN` - Domain for routing rules
- `CERT_RESOLVER` - TLS certificate resolver name