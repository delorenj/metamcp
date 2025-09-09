# MCP Server Session Invalidation Flow

```mermaid
sequenceDiagram
    participant User
    participant Frontend
    participant Backend
    participant McpServerPool
    participant MetaMcpServerPool
    participant McpServer

    User->>Frontend: Updates MCP server command/args
    Frontend->>Backend: PATCH /mcp-servers/{uuid}
    Backend->>Backend: Update server in database
    
    Note over Backend: New invalidation flow
    Backend->>McpServerPool: invalidateIdleSession(serverUuid, newParams)
    Note over McpServerPool: Check if server is currently idle
    
    alt Server has idle session
        McpServerPool->>McpServer: Terminate idle session
        McpServer-->>McpServerPool: Session terminated
        Note over McpServerPool: Remove from pool
    else Server is active or no session
        Note over McpServerPool: Mark for invalidation on next idle
    end
    
    Backend-->>Frontend: 200 OK - Server updated
    Frontend-->>User: Success notification
    
    Note over McpServerPool: Next time server is requested
    McpServerPool->>McpServer: Start new session with updated params
```

## Key Changes

1. **Immediate Invalidation**: When server config changes, immediately invalidate idle sessions
2. **Lazy Loading**: Active sessions continue until idle, then get invalidated
3. **Config Refresh**: New sessions automatically use updated configuration
4. **No Restart Required**: Changes take effect without service restart