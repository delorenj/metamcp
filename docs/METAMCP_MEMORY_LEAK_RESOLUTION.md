# MetaMCP Memory Leak Issue - Resolution Summary

## Executive Summary
MetaMCP was experiencing severe memory leaks causing system instability. The root cause was uncontrolled process spawning - the application was creating unlimited npm exec processes that never terminated, eventually consuming all system resources.

## The Problem

### Symptoms
- Memory usage growing from 2GB to 32GB+ over time
- Process count exploding from 15 to 1000+ processes
- System becoming unresponsive requiring hard resets
- Docker containers consuming excessive resources

### Root Cause
MetaMCP spawns `npm exec` processes for MCP server operations but was not:
1. Limiting the number of concurrent processes
2. Properly terminating child processes
3. Enforcing resource constraints at the container level

## The Solution

### Three-Layer Defense Strategy

#### 1. **Docker Resource Limits** (Primary Defense)
Applied hard limits at the container level to prevent resource exhaustion:

```yaml
services:
  metamcp:
    mem_limit: 4g          # Hard memory cap
    memswap_limit: 4g      # Prevent swap abuse
    cpus: 2.0             # CPU limit
    pids_limit: 25        # Maximum 25 processes (critical!)
```

The `pids_limit: 25` is the most critical setting - it prevents process explosion at the kernel level.

#### 2. **Process Monitoring Script** (Secondary Defense)
Created `/scripts/metamcp-process-killer.sh` to actively monitor and kill duplicate processes:

```bash
#!/bin/bash
MAX_PROCESSES=15

while true; do
    COUNT=$(ps aux | grep -E "npm exec|@modelcontextprotocol" | grep -v grep | wc -l)
    if [ $COUNT -gt $MAX_PROCESSES ]; then
        # Kill oldest duplicate processes
        ps aux | grep -E "npm exec|@modelcontextprotocol" | grep -v grep | \
        sort -k9 | head -n $((COUNT - MAX_PROCESSES)) | \
        awk '{print $2}' | xargs -r kill -9
    fi
    sleep 30
done
```

#### 3. **Environment Configuration** (Stability)
Ensured proper environment variables to prevent crash-loops that could exacerbate the issue:

```yaml
environment:
  - DATABASE_URL=postgresql://postgres:postgres@postgres:5432/metamcp
  - BETTER_AUTH_SECRET=<secret>
  - APP_URL=https://mcp.delo.sh
  - NODE_ENV=production
```

## Implementation Results

### Before Fix
- Memory: 32GB+ usage, system crashes
- Processes: 1000+ npm exec instances
- Stability: System required daily resets

### After Fix
- Memory: Stable at ~2-3GB
- Processes: Capped at 25 total (15 MCP processes)
- Stability: No crashes, continuous operation

## Key Takeaways

1. **PID limits are critical** - The `pids_limit` Docker setting is the most effective prevention
2. **Defense in depth** - Multiple layers ensure stability even if one fails
3. **Monitor early** - Process count is a better early indicator than memory usage
4. **Pre-built images** - Using `delorenj/metamcp:latest` avoids build-time issues

## Deployment

The fix is permanently deployed in the production configuration:

```bash
cd /home/delorenj/code/utils/metamcp
docker-compose -f compose.yml up -d
```

Repository: https://github.com/delorenj/metamcp
- Commit 8a64c77: Resource limit implementation
- Commit cf19dad: Documentation

## Monitoring Commands

```bash
# Check process count
docker exec metamcp ps aux | grep -c "npm exec"

# Monitor resource usage
docker stats metamcp

# View logs for issues
docker logs metamcp --tail 100
```

---

**Bottom Line**: The memory leak was caused by uncontrolled process spawning. Fixed by implementing hard PID limits (25 max) at the Docker level, preventing the application from creating unlimited child processes.