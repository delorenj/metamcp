# MetaMCP Development Setup

## 🚀 Quick Start

### Prerequisites
- Docker & Docker Compose v2
- Node.js 20+ & pnpm 10.12.0+
- PostgreSQL 16+ (for local development)

### Environment Setup

1. **Copy environment template**:
   ```bash
   cp example.env .env
   ```

2. **Configure database settings**:
   ```bash
   # Edit .env file
   POSTGRES_HOST=localhost
   POSTGRES_PORT=5432
   POSTGRES_USER=metamcp_user
   POSTGRES_PASSWORD=m3t4mcp
   POSTGRES_DB=metamcp_db
   ```

3. **Set application URLs**:
   ```bash
   APP_URL=http://localhost:12008
   NEXT_PUBLIC_APP_URL=http://localhost:12008
   ```

## 📦 Development Modes

### Docker Development (Recommended)

Start the development environment with hot reload:

```bash
# Start development stack
docker-compose -f docker-compose.dev.yml up

# Or with specific services
docker-compose -f docker-compose.dev.yml up postgres app
```

**Container naming**: `metamcp-app-development`, `metamcp-db-development`

### Local Development

For local development without Docker:

```bash
# Install dependencies
pnpm install

# Start development servers
pnpm dev

# Or start services individually
pnpm dev:frontend  # Port 12008
pnpm dev:backend   # Port 12009
```

### Test Environment

Run tests in isolated environment:

```bash
# Start test stack
docker-compose -f docker-compose.test.yml up

# Run specific tests
docker-compose -f docker-compose.test.yml exec app pnpm test
```

**Container naming**: `metamcp-app-test`, `metamcp-db-test`

## 🏗️ Architecture

### Service Structure
```
apps/
├── frontend/         # Next.js UI (Port 12008)
├── backend/          # Express API (Port 12009)
└── packages/         # Shared packages
    ├── trpc/         # tRPC definitions
    ├── zod-types/    # Shared types
    └── eslint-config/ # Linting rules
```

### Database
- **Development**: `postgres_data_dev` volume
- **Test**: `postgres_data` volume  
- **Production**: `postgres_data_production` volume

## 🔧 Development Tools

### Available Scripts
```bash
# From project root
pnpm build          # Build all packages
pnpm test           # Run test suite
pnpm lint           # Lint codebase
pnpm typecheck      # TypeScript checking

# Database management
pnpm db:generate    # Generate migrations
pnpm db:migrate     # Run migrations
pnpm db:seed        # Seed database
```

### Claude Flow Integration
```bash
# Use local CLI wrappers
./scripts/claude-flow sparc tdd \"feature\"
./scripts/claude-flow sparc run architect \"design\"

# Or direct npx usage
npx claude-flow@alpha sparc modes
```

## 🐛 Troubleshooting

### Common Issues

1. **Port conflicts**:
   ```bash
   # Check port usage
   lsof -i :12008
   lsof -i :12009
   ```

2. **Database connection issues**:
   ```bash
   # Check PostgreSQL status
   docker-compose -f docker-compose.dev.yml logs postgres
   
   # Reset database
   docker-compose -f docker-compose.dev.yml down -v
   docker-compose -f docker-compose.dev.yml up postgres
   ```

3. **Hot reload not working**:
   ```bash
   # Check volume mounts
   docker-compose -f docker-compose.dev.yml config
   
   # Restart with clean build
   docker-compose -f docker-compose.dev.yml down
   docker-compose -f docker-compose.dev.yml build --no-cache
   docker-compose -f docker-compose.dev.yml up
   ```

### Health Checks

All environments include health checks:
- **Frontend**: `http://localhost:12008/health`
- **Backend**: `http://localhost:12009/health`
- **Database**: Built-in PostgreSQL health check

### Environment Variables

Key variables for development:
```bash
# Development specific
NODE_ENV=development
WATCHPACK_POLLING=true
CHOKIDAR_USEPOLLING=true
NEXT_TELEMETRY_DISABLED=1

# Docker networking
TRANSFORM_LOCALHOST_TO_DOCKER_INTERNAL=true
```

## 🚀 Production Deployment

For production deployment:
```bash
# Use production compose
docker-compose -f docker-compose.yml up -d

# Or with custom configuration
APP_MODE=production docker-compose up -d
```

**Container naming**: `metamcp-app-production`, `metamcp-db-production`

## 📝 File Organization

### Clean Structure
```
metamcp/
├── apps/             # Application packages
├── config/           # Configuration files
│   └── traefik/     # Traefik routing
├── docs/            # Documentation
├── scripts/         # CLI tools & utilities
├── packages/        # Shared packages
└── [compose files]  # Docker orchestration
```

### Environment-Specific Files
- `docker-compose.yml` - Production
- `docker-compose.dev.yml` - Development  
- `docker-compose.test.yml` - Testing

Each environment uses consistent naming patterns and isolated resources.