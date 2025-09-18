# Changelog

## [2025-09-16] - Systemd Service Fix

### Fixed
- **Systemd service installation failure** - Service was failing with "Resource temporarily unavailable" (error 11)
- **Process limit conflicts** - Removed restrictive `LimitNPROC=500` that conflicted with user's 588+ active processes
- **Complex bash execution in systemd** - Simplified service to use direct docker commands instead of bash scripts

### Changed
- Streamlined systemd service to manage container state only
- Removed systemd-level resource limits (Docker handles resource constraints)
- Service now uses `docker start/stop/restart` commands directly

### Technical Details
- User process count: 588 (exceeded systemd limit of 500)
- Container resource limits: 4GB RAM, 2 CPU cores, 100 PIDs (unchanged)
- Service status: Active and enabled for auto-start
- Memory leak prevention: Still active via Docker constraints
