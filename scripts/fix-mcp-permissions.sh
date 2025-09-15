#!/bin/bash

# Fix MCP Server Permissions Script
# This script resolves permission issues with MCP servers that need to create log directories

set -e

echo "🔧 Fixing MCP server permissions..."

# Create logs directory in the metamcp project
METAMCP_DIR="/home/delorenj/code/utils/metamcp"
LOGS_DIR="$METAMCP_DIR/logs"

if [ ! -d "$LOGS_DIR" ]; then
    echo "📁 Creating logs directory: $LOGS_DIR"
    mkdir -p "$LOGS_DIR"
fi

# Set proper permissions
chmod 755 "$LOGS_DIR"
echo "✅ Set permissions for logs directory"

# Create a temporary directory for MCP servers if needed
TEMP_MCP_DIR="/tmp/mcp-servers"
if [ ! -d "$TEMP_MCP_DIR" ]; then
    echo "📁 Creating temporary MCP directory: $TEMP_MCP_DIR"
    mkdir -p "$TEMP_MCP_DIR"
    chmod 755 "$TEMP_MCP_DIR"
fi

# Create logs subdirectory in temp
TEMP_LOGS_DIR="$TEMP_MCP_DIR/logs"
if [ ! -d "$TEMP_LOGS_DIR" ]; then
    echo "📁 Creating temporary logs directory: $TEMP_LOGS_DIR"
    mkdir -p "$TEMP_LOGS_DIR"
    chmod 755 "$TEMP_LOGS_DIR"
fi

echo "✅ MCP server permissions fixed!"
echo "📍 Logs directory: $LOGS_DIR"
echo "📍 Temp MCP directory: $TEMP_MCP_DIR"
echo ""
echo "💡 If you're still experiencing issues:"
echo "   1. Restart Claude Desktop"
echo "   2. Check that the delonet-tools MCP server is configured correctly"
echo "   3. Verify the API key is valid"
echo ""
echo "🔍 To monitor MCP server logs:"
echo "   tail -f $LOGS_DIR/*.log"
