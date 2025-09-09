# MetaMCP - Production Deployment

Simple, production-ready MetaMCP deployment with Traefik integration.

## Quick Start

1. **Configure environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your settings
   ```

2. **Deploy**:
   ```bash
   mise run deploy
   ```

3. **Access**: https://mcp.delo.sh

## Configuration

### Required Environment Variables

- `POSTGRES_USER` - PostgreSQL username (uses your existing postgres container)
- `POSTGRES_PASSWORD` - PostgreSQL password  
- `POSTGRES_DB` - Database name (default: metamcp)
- `BETTER_AUTH_SECRET` - Authentication secret

### Optional OIDC

- `OIDC_CLIENT_ID`
- `OIDC_CLIENT_SECRET` 
- `OIDC_DISCOVERY_URL`

## Management with Mise

```bash
mise run start      # Start services
mise run stop       # Stop services  
mise run restart    # Restart services
mise run logs       # View logs
mise run health     # Check health
mise run shell      # Open container shell
mise run clean      # Clean up containers/images
mise run update     # Full update cycle
```

## Infrastructure

- **Domain**: mcp.delo.sh (via Traefik)
- **Container**: metamcp (single container)
- **Network**: proxy (connects to existing Traefik)
- **Database**: Uses existing PostgreSQL container
- **SSL**: Automatic via Traefik Let's Encrypt

## Architecture

```
Internet → Traefik (SSL/Routing) → MetaMCP Container → Existing PostgreSQL
```

## Features

- ✅ Single container deployment
- ✅ Traefik integration with SSL
- ✅ SSE/MCP streaming optimized
- ✅ CORS and security headers
- ✅ Health checks and monitoring
- ✅ Connects to existing infrastructure
- ✅ Mise task runner for management

## Troubleshooting

- **Check logs**: `mise run logs`
- **Health check**: `mise run health` 
- **Container status**: `docker ps | grep metamcp`
- **Network**: Ensure 'proxy' network exists and Traefik is running