# MetaMCP Docker Consolidation Strategy

## 🎯 Goal: Single Docker Image + Simple Compose

**Target Architecture:**
- **Single consolidated Docker image** with configurable modes
- **Single docker-compose.yml** file that works for all environments
- **Single .env file** for all configuration
- **Optional config volume mount** for advanced settings

## 🔧 Recommended Consolidation Strategy

### 1. **Unified Dockerfile Architecture**

```dockerfile
# Consolidated Multi-Mode Dockerfile
FROM ghcr.io/astral-sh/uv:debian AS base

# Single base with all dependencies
RUN apt-get update && apt-get install -y \
    curl gnupg postgresql-client tini \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g pnpm@10.12.0 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Build stage (same for all modes)
FROM base AS builder
WORKDIR /app
COPY . .
RUN pnpm install --frozen-lockfile && pnpm build

# Runtime stage with mode switching
FROM base AS runtime
WORKDIR /app

# Copy built application
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/apps ./apps
COPY --from=builder /app/node_modules ./node_modules

# Copy unified entrypoint script
COPY docker-entrypoint-unified.sh ./entrypoint.sh
RUN chmod +x entrypoint.sh

# Support for config mounting
VOLUME ["/app/config"]

# Environment-based configuration
ENV APP_MODE=production
ENV CONFIG_DIR=/app/config

EXPOSE 12008 12009
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:12008/health || exit 1

ENTRYPOINT ["/usr/bin/tini", "--", "./entrypoint.sh"]
```

### 2. **Unified Docker Compose**

```yaml
# Single docker-compose.yml for all environments
services:
  metamcp:
    image: ghcr.io/metatool-ai/metamcp:latest
    container_name: metamcp-${APP_MODE:-production}
    env_file: .env
    ports:
      - "${FRONTEND_PORT:-12008}:12008"
      - "${BACKEND_PORT:-12009}:12009"
    volumes:
      # Optional: Mount config directory for advanced settings
      - ${CONFIG_DIR:-./config}:/app/config:ro
      # Development mode: Mount source for hot reload
      - ${SOURCE_MOUNT:-empty_volume}:/app/src
    environment:
      APP_MODE: ${APP_MODE:-production}
      DATABASE_URL: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - metamcp-network

  postgres:
    image: postgres:16-alpine
    container_name: metamcp-postgres-${APP_MODE:-production}
    env_file: .env
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    ports:
      - "${POSTGRES_EXTERNAL_PORT:-9433}:5432"
    volumes:
      - postgres_data_${APP_MODE:-production}:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - metamcp-network

volumes:
  postgres_data_production:
  postgres_data_development:
  empty_volume:

networks:
  metamcp-network:
    driver: bridge
```

### 3. **Unified Environment Configuration**

```bash
# .env - Single environment file for all modes
NODE_ENV=production
APP_MODE=production  # production | development | test

# Application URLs
APP_URL=http://localhost:12008
NEXT_PUBLIC_APP_URL=${APP_URL}

# Port Configuration
FRONTEND_PORT=12008
BACKEND_PORT=12009
POSTGRES_EXTERNAL_PORT=9433

# Database Configuration
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_USER=metamcp_user
POSTGRES_PASSWORD=m3t4mcp
POSTGRES_DB=metamcp_db

# Security
BETTER_AUTH_SECRET=your-super-secret-key-change-this-in-production

# Optional: Volume mounting
CONFIG_DIR=./config
SOURCE_MOUNT=empty_volume  # Set to .:/app/src for development

# Docker Configuration
TRANSFORM_LOCALHOST_TO_DOCKER_INTERNAL=true
```

## 🚀 Implementation Benefits

### **Simplified Deployment**
```bash
# Production deployment
docker-compose up -d

# Development mode
APP_MODE=development SOURCE_MOUNT=.:/app/src docker-compose up

# Testing mode
APP_MODE=test docker-compose -f docker-compose.yml up
```

### **Configuration Management**
- **Default**: All settings in `.env`
- **Advanced**: Mount `./config` directory for complex configurations
- **Environment-specific**: Override via environment variables

### **Volume Strategy**
- **Production**: No source mounting, minimal volumes
- **Development**: Optional source mounting via environment variable
- **Configuration**: Always mount config directory for flexibility

## 📁 Recommended File Structure

```
metamcp/
├── docker-compose.yml          # Single compose file
├── Dockerfile                  # Unified Dockerfile
├── .env                        # Single environment file
├── .env.example               # Template
├── docker-entrypoint-unified.sh  # Mode-switching entrypoint
├── config/                     # Optional config directory
│   ├── production.json
│   ├── development.json
│   └── custom-settings.json
└── docs/
    └── deployment.md
```

## 🔄 Migration Strategy

1. **Create unified Dockerfile** with mode switching
2. **Consolidate compose files** into single file with environment-based configuration
3. **Create unified entrypoint script** that handles all modes
4. **Migrate environment variables** to single `.env` file
5. **Test all modes** (production, development, test)
6. **Update documentation** and deployment instructions

## 🎯 End Result

**Your goal achieved:**
- ✅ **Single docker-compose.yml** 
- ✅ **Single .env file**
- ✅ **Optional config directory mounting**
- ✅ **Simplified deployment process**
- ✅ **Mode switching via environment variables**