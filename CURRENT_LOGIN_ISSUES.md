# MetaMCP Login Issues - Current Status (Sep 30, 2025)

## Critical Issues Blocking Login

### 1. ❌ **500 Error on Sign-In** (BLOCKER)
**Symptom**:
```
POST https://mcp.delo.sh/api/auth/sign-in/email
Status: 500 Internal Server Error
```

**Root Cause**: Traefik reverse proxy is NOT passing required headers for better-auth

**Fix Required**: Configure Traefik to pass X-Forwarded headers

### 2. ❌ **Container Unhealthy**
```bash
$ docker ps
NAME      STATUS
metamcp   Up X minutes (unhealthy)
```

**Cause**: Health check failing (checks port 12008, but endpoint not responding)
**Impact**: May cause container restarts, intermittent service

### 3. ❌ **OIDC Button Missing from Login Page**
- tRPC endpoint returns: `{"result":{"data":[]}}`
- Expected: `{"result":{"data":[{"id":"oidc","name":"OIDC","enabled":true}]}}`
- Backend confirms: "✓ OIDC Providers configured: 1"

## What We've Completed ✅

1. **Rebuilt Docker image** with latest source code (--no-cache)
2. **Pushed to correct registry** (ghcr.io/delorenj/metamcp:latest)
3. **Confirmed OIDC env vars** are set correctly in container
4. **Reset password** for jaradd@gmail.com to 'Password123'
5. **Enabled signup** in database

## Required Fixes (In Order of Priority)

### PRIORITY 1: Configure Traefik for better-auth

Reference: `nginx.conf.example` lines 116-141

**Add these Traefik configuration**:

The example nginx config shows these critical settings:
```nginx
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
```

**Traefik equivalent** (add to your Traefik config or compose labels):

```yaml
services:
  metamcp:
    labels:
      # Routing
      - "traefik.enable=true"
      - "traefik.http.routers.metamcp.rule=Host(`mcp.delo.sh`)"
      - "traefik.http.routers.metamcp.entrypoints=websecure"
      - "traefik.http.routers.metamcp.tls=true"

      # Service points to frontend port
      - "traefik.http.services.metamcp.loadbalancer.server.port=12008"

      # CRITICAL: Headers middleware for better-auth
      - "traefik.http.middlewares.metamcp-headers.headers.customrequestheaders.Host=mcp.delo.sh"
      - "traefik.http.middlewares.metamcp-headers.headers.customrequestheaders.X-Forwarded-Host=mcp.delo.sh"
      - "traefik.http.middlewares.metamcp-headers.headers.customrequestheaders.X-Forwarded-Proto=https"
      - "traefik.http.middlewares.metamcp-headers.headers.customrequestheaders.X-Forwarded-Port=443"
      - "traefik.http.middlewares.metamcp-headers.headers.customrequestheaders.X-Real-IP=true"

      # Apply middleware
      - "traefik.http.routers.metamcp.middlewares=metamcp-headers"
```

### PRIORITY 2: Clean up .env file

**Remove duplicate entries** at lines 106-110:
```env
# DELETE THESE LINES (they override correct settings):
APP_URL=https://mcp.delo.sh
NEXT_PUBLIC_APP_URL=https://mcp.delo.sh
BETTER_AUTH_SECRET=95f815281b98c36acdb205414d6f9babec8acef5e2d4feeda5ec5b80043d0f7e
DATABASE_URL=postgresql://postgres:postgres@postgres:5432/metamcp
```

### PRIORITY 3: Fix Health Check

**Option A**: Update compose.yml:
```yaml
services:
  metamcp:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:12009/api/auth/list-sessions"]
      interval: 30s
      timeout: 10s
      start_period: 40s
      retries: 3
```

**Option B**: Rebuild with updated Dockerfile

## Testing After Fixes

```bash
# 1. Test sign-in endpoint
curl -X POST "https://mcp.delo.sh/api/auth/sign-in/email" \
  -H "Content-Type: application/json" \
  -d '{"email":"jaradd@gmail.com","password":"Password123"}'

# Expected: {"session":...} or redirect, NOT 500 error

# 2. Test OIDC providers endpoint
curl -s "https://mcp.delo.sh/trpc/frontend.config.getAuthProviders"

# Expected: {"result":{"data":[{"id":"oidc","name":"OIDC","enabled":true}]}}

# 3. Check container health
docker ps --filter "name=metamcp"

# Expected: STATUS shows "healthy" not "unhealthy"
```

## Login Credentials (Ready to Use)

**Email**: jaradd@gmail.com
**Password**: Password123

## Environment Info

**Container**: ghcr.io/delorenj/metamcp:latest (built Sep 30 21:32)
**Database**: postgresql://delorenj:Ittr5eesol@host.docker.internal:15434/metamcp_db
**Frontend**: Port 12008 (internal), proxied via Traefik
**Backend**: Port 12009 (internal), accessed via Next.js rewrites

## Key Insights

1. **Redirect behavior**: `/login` → `/en/login` (i18n middleware adds locale)
2. **Next.js rewrites**: `/trpc/*` → backend `/trpc/frontend/*`
3. **OIDC is configured**: Backend logs confirm "✓ OIDC Providers configured: 1"
4. **Services are running**: Both frontend (PID 53) and backend (PID 40) processes active

## Mystery: OIDC Endpoint Returning Empty

Despite all evidence showing OIDC is configured:
- ✅ All OIDC_ environment variables are set
- ✅ Auth system logs "✓ OIDC Providers configured: 1"
- ✅ Compiled code has correct getAuthProviders logic
- ❌ tRPC endpoint returns empty array

**Hypothesis**: May be related to Traefik header issue or Next.js/tRPC caching

**Action**: After fixing Traefik headers, test again. If still empty, add debug logging to configService.getAuthProviders()

---

## Next Steps

1. **Configure Traefik** with proper headers (see Priority 1 above)
2. **Clean .env** file
3. **Rebuild if needed**: `docker build --no-cache -t ghcr.io/delorenj/metamcp:latest .`
4. **Push**: `docker push ghcr.io/delorenj/metamcp:latest`
5. **Redeploy**: `docker compose down && docker compose pull && docker compose up -d`
6. **Test login** with credentials above
7. **Verify OIDC button** appears on /en/login page
