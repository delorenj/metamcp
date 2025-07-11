# MetaMCP mise Task Reference

This project uses `mise` for task orchestration and dependency management. Here's your complete workflow guide:

## 🚀 Quick Start

```bash
# Complete setup (first time)
mise run setup

# Development
mise run dev          # Start dev environment
mise run quick        # Quick dev start (no build)
mise run fresh        # Clean + rebuild + start

# Production
mise run prod         # Start production environment
mise run ship         # Prepare for deployment
```

## 📦 Build & Dependencies

```bash
mise run install      # Install dependencies
mise run build        # Build all applications
mise run clean        # Clean build artifacts
mise run typecheck    # TypeScript checking
mise run lint         # Run linters
mise run test         # Run tests
```

## 🗄️ Database Operations

```bash
mise run db-migrate   # Run migrations
mise run db-reset     # Reset database
mise run db-studio    # Open Drizzle Studio
```

## 🚦 Individual Services

```bash
mise run backend      # Start backend only
mise run frontend     # Start frontend only (dev)
mise run frontend-prod # Start frontend (production)
```

## 🔧 System Services (Ubuntu)

```bash
# Installation
mise run services-install    # Install systemd services
mise run services-uninstall  # Remove systemd services

# Control
mise run services-start      # Start services
mise run services-stop       # Stop services
mise run services-restart    # Restart services
mise run services-enable     # Enable auto-start on boot
mise run services-disable    # Disable auto-start

# Monitoring
mise run services-status     # Check service status
mise run logs-backend        # Backend logs (live)
mise run logs-frontend       # Frontend logs (live)
mise run logs-all           # All logs (live)
```

## 🏥 Health & Debug

```bash
mise run health       # Check service health
mise run logs         # Basic connectivity check
```

## 🐳 Docker Support

```bash
mise run docker-build # Build Docker images
mise run docker-up    # Start with Docker Compose
mise run docker-down  # Stop Docker containers
```

## 📋 Common Workflows

### Development Setup
```bash
git clone <repo>
cd metamcp
mise run setup
mise run dev
```

### Production Deployment
```bash
mise run ship                    # Prepare deployment
mise run services-install        # Install services
mise run services-start          # Start services
mise run services-enable         # Enable auto-start
```

### Troubleshooting
```bash
mise run health                  # Check status
mise run logs-all               # View logs
mise run services-restart       # Restart services
```

### Daily Development
```bash
mise run quick                   # Quick start
mise run logs-backend           # Monitor backend
# Make changes...
mise run services-restart       # Apply changes
```

## 🌐 Service URLs

- **Backend**: http://localhost:12009
- **Frontend**: http://localhost:12008  
- **Public**: https://mcp.delo.sh
- **Database Studio**: Available via `mise run db-studio`

## 📁 Important Paths

- **Database**: `apps/backend/db.sqlite`
- **Backend Build**: `apps/backend/dist/`
- **Frontend Build**: `apps/frontend/.next/`
- **Service Logs**: `sudo journalctl -u metamcp-*`

## 🔑 Environment Variables

All configured in `.mise.toml`:
- `METAMCP_BACKEND_PORT=12009`
- `METAMCP_FRONTEND_PORT=12008`
- `METAMCP_PUBLIC_URL=https://mcp.delo.sh`

---

**💡 Pro Tips:**
- Use `mise run quick` for daily development
- Use `mise run fresh` when things get weird
- Use `mise run logs-all` to monitor production
- Services auto-restart on failure when installed as systemd services
