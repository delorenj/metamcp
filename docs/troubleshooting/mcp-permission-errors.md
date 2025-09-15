# MCP Server Permission Errors Troubleshooting

## Problem Description

You may encounter permission errors when MCP servers try to create log directories:

```
Error: EACCES: permission denied, mkdir 'logs'
```

This commonly happens with:
- `letta-mcp-server`
- `delonet-letta` server
- Other MCP servers that need to write logs

## Root Cause

MCP servers are being started from directories where they don't have write permissions, or they're trying to create directories in locations where the user doesn't have write access.

## Quick Fix

Run the permission fix script:

```bash
./scripts/fix-mcp-permissions.sh
```

## Manual Fix Steps

### 1. Create Logs Directory

```bash
# In your metamcp project directory
mkdir -p logs
chmod 755 logs
```

### 2. Create Temporary MCP Directory

```bash
# Create a temporary directory for MCP servers
mkdir -p /tmp/mcp-servers/logs
chmod 755 /tmp/mcp-servers/logs
```

### 3. Update Claude Desktop Configuration

Edit `~/.config/Claude/claude_desktop_config.json` to include proper environment variables and working directory:

```json
{
  "mcpServers": {
    "delonet-tools": {
      "command": "/home/delorenj/.local/mise",
      "args": [
        "x", "--", "npx", "-y", "mcp-remote",
        "https://mcp.delo.sh/metamcp/delonet/mcp",
        "--header", "Authorization: Bearer=${DELONET_API_KEY}"
      ],
      "env": {
        "DELONET_API_KEY": "your-api-key",
        "HOME": "/home/delorenj",
        "TMPDIR": "/tmp",
        "LOGS_DIR": "/home/delorenj/code/utils/metamcp/logs"
      },
      "cwd": "/home/delorenj/code/utils/metamcp"
    }
  }
}
```

### 4. Restart Claude Desktop

After making configuration changes, restart Claude Desktop to apply the new settings.

## Verification

### Check Directory Permissions

```bash
ls -la logs/
ls -la /tmp/mcp-servers/
```

### Monitor MCP Server Logs

```bash
# Watch for new log files
tail -f logs/*.log

# Check Claude Desktop logs
tail -f ~/.config/Claude/logs/*.log
```

### Test MCP Server Connection

```bash
# Test the delonet-tools MCP server
curl -s https://mcp.delo.sh/metamcp/delonet/mcp \
  -H "Authorization: Bearer your-api-key"
```

## Common Issues

### Issue: "Session not found"
- **Cause**: API key authentication issue
- **Fix**: Verify the API key is correct and properly formatted

### Issue: "Authentication required"
- **Cause**: Missing or malformed Authorization header
- **Fix**: Ensure the Bearer token format is correct

### Issue: Still getting permission errors
- **Cause**: MCP server is starting from a different directory
- **Fix**: Set the `cwd` property in the MCP server configuration

## Environment Variables

Set these environment variables to help MCP servers find the right directories:

```bash
export LOGS_DIR="/home/delorenj/code/utils/metamcp/logs"
export TMPDIR="/tmp"
export HOME="/home/delorenj"
```

## Prevention

To prevent future permission issues:

1. Always run MCP servers from directories where you have write permissions
2. Set explicit working directories in MCP server configurations
3. Use environment variables to specify log directories
4. Regularly check and maintain proper directory permissions

## Related Files

- `scripts/fix-mcp-permissions.sh` - Automated fix script
- `~/.config/Claude/claude_desktop_config.json` - Claude Desktop MCP configuration
- `config/mcp-servers.json` - MetaMCP server configuration
- `logs/` - Application logs directory
