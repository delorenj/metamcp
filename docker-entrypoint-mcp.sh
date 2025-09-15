#!/bin/sh
set -e

echo "🚀 Starting MetaMCP Consolidated Server..."
echo "📁 Working directory: $(pwd)"
echo "🔧 Config directory: ${CONFIG_DIR:-/config}"

# Configure MCP servers from volume
/usr/local/bin/configure-mcp.sh

CONFIG_FILE="${CONFIG_DIR:-/config}/mcp-servers.json"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ MCP configuration file not found: $CONFIG_FILE"
    exit 1
fi

echo "📋 Loading MCP servers from: $CONFIG_FILE"

# Install MCP tools dynamically based on configuration
echo "📦 Installing required MCP tools..."

# Use npm to install the MCP packages globally since they're publicly available
npm install -g \
    "claude-flow@alpha" \
    "ruv-swarm" \
    "kapture-mcp@latest" \
    "@21st-dev/magic@latest" \
    "n8n-mcp" \
    "@delorenj/mcp-server-trello@1.3.1" || echo "⚠️ Some packages may have failed to install"

# Create a simple MCP orchestrator server
echo "🎯 Starting MCP Server Orchestrator..."

# Create a basic HTTP server that serves MCP server status and health
cat > /tmp/mcp-server.js << 'EOF'
const http = require('http');
const fs = require('fs');
const { spawn } = require('child_process');

const CONFIG_FILE = process.env.CONFIG_DIR + '/mcp-servers.json';
const PORT = process.env.MCP_PORT || 3000;

let mcpServers = {};
let config = {};

// Load configuration
function loadConfig() {
    try {
        const configData = fs.readFileSync(CONFIG_FILE, 'utf8');
        config = JSON.parse(configData);
        console.log(`📋 Loaded ${config.servers?.length || 0} MCP server configurations`);
        return true;
    } catch (error) {
        console.error('❌ Failed to load MCP configuration:', error.message);
        return false;
    }
}

// Start MCP servers based on configuration
function startMCPServers() {
    if (!config.servers) {
        console.log('⚠️ No servers configured');
        return;
    }

    config.servers.forEach(server => {
        if (server.enabled === false) {
            console.log(`⏭️ Skipping disabled server: ${server.name}`);
            return;
        }

        console.log(`🚀 Starting MCP server: ${server.name}`);
        
        try {
            const process = spawn(server.command, server.args || [], {
                env: { ...process.env, ...(server.env || {}) },
                stdio: ['pipe', 'pipe', 'pipe']
            });

            process.stdout.on('data', (data) => {
                console.log(`[${server.name}] ${data.toString().trim()}`);
            });

            process.stderr.on('data', (data) => {
                console.error(`[${server.name}] ERROR: ${data.toString().trim()}`);
            });

            process.on('close', (code) => {
                console.log(`[${server.name}] Process exited with code ${code}`);
                delete mcpServers[server.name];
            });

            mcpServers[server.name] = {
                process,
                config: server,
                startTime: new Date(),
                status: 'running'
            };

        } catch (error) {
            console.error(`❌ Failed to start ${server.name}:`, error.message);
        }
    });
}

// HTTP server for health checks and status
const server = http.createServer((req, res) => {
    const url = req.url;
    
    res.setHeader('Content-Type', 'application/json');
    
    if (url === '/health') {
        res.writeHead(200);
        res.end(JSON.stringify({ 
            status: 'healthy', 
            timestamp: new Date().toISOString(),
            servers: Object.keys(mcpServers).length
        }));
    } else if (url === '/status') {
        res.writeHead(200);
        const status = {
            config: config,
            servers: Object.keys(mcpServers).map(name => ({
                name,
                status: mcpServers[name].status,
                startTime: mcpServers[name].startTime,
                uptime: Date.now() - mcpServers[name].startTime.getTime()
            }))
        };
        res.end(JSON.stringify(status, null, 2));
    } else {
        res.writeHead(404);
        res.end(JSON.stringify({ error: 'Not found' }));
    }
});

// Cleanup on exit
process.on('SIGTERM', () => {
    console.log('🛑 Shutting down MCP servers...');
    Object.values(mcpServers).forEach(server => {
        server.process.kill();
    });
    process.exit(0);
});

// Start everything
if (loadConfig()) {
    startMCPServers();
    
    server.listen(PORT, '0.0.0.0', () => {
        console.log(`✅ MCP Server Orchestrator listening on port ${PORT}`);
        console.log(`🔗 Health: http://localhost:${PORT}/health`);
        console.log(`📊 Status: http://localhost:${PORT}/status`);
    });
} else {
    process.exit(1);
}
EOF

# Start the MCP server orchestrator
exec node /tmp/mcp-server.js