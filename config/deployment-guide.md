# MetaMCP Consolidated Docker Deployment Guide

## 🎯 Quick Start (Simplified Deployment)

### **Option 1: Use Unified Configuration (Recommended)**

1. **Copy the unified files:**
   ```bash
   # Copy unified configuration files to your project root
   cp config/docker-compose-unified.yml ./docker-compose.yml
   cp config/.env-unified ./.env
   cp config/Dockerfile-unified ./Dockerfile
   cp config/docker-entrypoint-unified.sh ./docker-entrypoint.sh
   chmod +x docker-entrypoint.sh
   ```

2. **Deploy with a single command:**
   ```bash
   # Production deployment
   docker-compose up -d
   ```

**That's it! You now have:**
- ✅ Single `docker-compose.yml` file
- ✅ Single `.env` configuration file  
- ✅ Optional config directory mounting (`./config`)
- ✅ Mode switching via environment variables

### **Option 2: Development Mode**

```bash
# Enable development mode with hot reload
APP_MODE=development SOURCE_MOUNT_TYPE=bind SOURCE_MOUNT_SOURCE=. docker-compose up
```

### **Option 3: Test Mode**

```bash
# Run in test mode
APP_MODE=test docker-compose up
```

## 🔧 Configuration Management

### **Environment Variables (Single .env file)**
```bash
# Core configuration
APP_MODE=production           # production | development | test
APP_URL=http://localhost:12008
POSTGRES_PASSWORD=secure_password_here
BETTER_AUTH_SECRET=your-secure-secret-here

# Optional: Development overrides
# SOURCE_MOUNT_TYPE=bind       # Enables hot reload
# SOURCE_MOUNT_SOURCE=.        # Mounts current directory
```

### **Config Directory Structure**
```
config/
├── production.json          # Production-specific settings
├── development.json         # Development overrides
├── test.json               # Test environment settings
└── postgres/               # PostgreSQL init scripts
    └── init.sql
```

### **Volume Mounting Strategy**

| Mode | Config Mount | Source Mount | Database Volume |
|------|-------------|--------------|-----------------|
| **Production** | `./config:/app/config:ro` | None | `postgres_data_production` |
| **Development** | `./config:/app/config:ro` | `.:/app/src` | `postgres_data_development` |
| **Test** | `./config:/app/config:ro` | None | `postgres_data_test` |

## 🚀 Deployment Scenarios

### **1. Simple Production Deployment**
```bash
# Just works with defaults
docker-compose up -d
```

### **2. Production with Custom Domain**
```bash
# Override APP_URL for your domain
APP_URL=https://metamcp.yourdomain.com docker-compose up -d
```

### **3. Development with Hot Reload**
```bash
# Mount source code for hot reloading
APP_MODE=development \
SOURCE_MOUNT_TYPE=bind \
SOURCE_MOUNT_SOURCE=. \
docker-compose up
```

### **4. Staging Environment**
```bash
# Custom environment for staging
APP_MODE=production \
APP_URL=https://staging.metamcp.com \
POSTGRES_DB=metamcp_staging \
docker-compose up -d
```

### **5. Multiple Environments Side-by-Side**
```bash
# Production
APP_MODE=production docker-compose -p metamcp-prod up -d

# Staging  
APP_MODE=development APP_URL=http://localhost:12018 FRONTEND_PORT=12018 \
docker-compose -p metamcp-staging up -d
```

## 📁 Migration from Current Setup

### **Step 1: Backup Current Setup**
```bash
# Backup current configuration
cp docker-compose.yml docker-compose.yml.backup
cp docker-compose.dev.yml docker-compose.dev.yml.backup
cp .env .env.backup
```

### **Step 2: Replace with Unified Configuration**
```bash
# Replace with unified files
cp config/docker-compose-unified.yml ./docker-compose.yml
cp config/.env-unified ./.env
cp config/Dockerfile-unified ./Dockerfile
cp config/docker-entrypoint-unified.sh ./docker-entrypoint.sh
chmod +x docker-entrypoint.sh
```

### **Step 3: Update Build Process**
```bash
# Update package.json scripts
# Replace existing docker scripts with:
"dev:docker": "APP_MODE=development SOURCE_MOUNT_TYPE=bind SOURCE_MOUNT_SOURCE=. docker-compose up",
"prod:docker": "docker-compose up -d",
"test:docker": "APP_MODE=test docker-compose up"
```

### **Step 4: Test All Modes**
```bash
# Test production mode
docker-compose up -d
curl http://localhost:12008/health

# Test development mode  
APP_MODE=development SOURCE_MOUNT_TYPE=bind SOURCE_MOUNT_SOURCE=. docker-compose up
# Verify hot reload works

# Cleanup
docker-compose down -v
```

## 🛠️ Advanced Configuration

### **Custom Configuration Files**
Create mode-specific JSON configs in `./config/`:

```json
// config/production.json
{
  "database": {
    "pool": {
      "min": 5,
      "max": 20
    }
  },
  "logging": {
    "level": "warn"
  }
}

// config/development.json  
{
  "database": {
    "pool": {
      "min": 1,
      "max": 5
    }
  },
  "logging": {
    "level": "debug"
  }
}
```

### **PostgreSQL Initialization**
Add custom PostgreSQL setup in `./config/postgres/`:

```sql
-- config/postgres/init.sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
```

### **OIDC Configuration**
Enable OpenID Connect by setting environment variables:

```bash
# Add to .env for OIDC support
OIDC_CLIENT_ID=your-client-id
OIDC_CLIENT_SECRET=your-client-secret  
OIDC_DISCOVERY_URL=https://your-provider.com/.well-known/openid-configuration
```

## 📊 Monitoring & Health Checks

### **Health Check Endpoints**
- Frontend: `http://localhost:12008/health`
- Backend: `http://localhost:12009/health`

### **Container Health Monitoring**
```bash
# Check container health
docker ps
docker-compose ps

# View logs
docker-compose logs -f metamcp
docker-compose logs -f postgres

# Monitor resource usage
docker stats
```

### **Database Health**
```bash
# Connect to PostgreSQL
docker-compose exec postgres psql -U metamcp_user -d metamcp_db

# Check database status
docker-compose exec postgres pg_isready -U metamcp_user
```

## 🔒 Security Best Practices

### **Production Security Checklist**
- [ ] Change `BETTER_AUTH_SECRET` to a strong random value
- [ ] Update `POSTGRES_PASSWORD` to a secure password
- [ ] Set `APP_URL` to your actual domain
- [ ] Configure HTTPS termination (nginx/traefik)
- [ ] Limit `POSTGRES_EXTERNAL_PORT` access
- [ ] Review and update OIDC configuration

### **Environment Variable Security**
```bash
# Generate secure secrets
openssl rand -hex 32  # For BETTER_AUTH_SECRET
openssl rand -base64 32  # For POSTGRES_PASSWORD
```

## 🚨 Troubleshooting

### **Common Issues**

**Port conflicts:**
```bash
# Change ports if needed
FRONTEND_PORT=13008 BACKEND_PORT=13009 docker-compose up
```

**Permission issues:**
```bash
# Fix config directory permissions
chmod -R 755 ./config
```

**Database connection issues:**
```bash
# Check PostgreSQL logs
docker-compose logs postgres

# Verify database is ready
docker-compose exec postgres pg_isready -U metamcp_user
```

**Hot reload not working:**
```bash
# Ensure source mounting is enabled
APP_MODE=development SOURCE_MOUNT_TYPE=bind SOURCE_MOUNT_SOURCE=. docker-compose up

# Check mounted volumes
docker-compose exec metamcp ls -la /app/src
```

### **Debug Mode**
```bash
# Enable debug logging
DEBUG=* docker-compose up

# Check container filesystem
docker-compose exec metamcp sh
```

## 📈 Performance Optimization

### **Production Optimizations**
- Use environment variable `NODE_ENV=production`
- Enable PostgreSQL connection pooling in config
- Set appropriate restart policies
- Configure resource limits:

```yaml
# Add to docker-compose.yml
services:
  metamcp:
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '0.5'
```

### **Development Optimizations**
- Use bind mounts for hot reload
- Disable production optimizations
- Enable debug logging
- Use polling for file watching in containers

This consolidated setup gives you exactly what you wanted: **single docker-compose.yml + single .env + optional config directory** for all your deployment needs!