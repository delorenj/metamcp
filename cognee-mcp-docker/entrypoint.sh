#!/bin/bash
set -e

echo "🧠 Starting Cognee MCP Server..."
echo "📁 Working directory: $(pwd)"
echo "🔧 Transport mode: ${TRANSPORT_MODE:-http}"
echo "🌐 Host: ${COGNEE_HOST:-0.0.0.0}"
echo "🔌 Port: ${COGNEE_PORT:-8000}"
echo "📍 Path: ${COGNEE_PATH:-/mcp}"

# Validate environment
if [ -z "$COGNEE_LLM_PROVIDER" ]; then
    echo "❌ Error: COGNEE_LLM_PROVIDER is required"
    exit 1
fi

echo "🤖 LLM Provider: $COGNEE_LLM_PROVIDER"

# Check for API key based on provider
case "$COGNEE_LLM_PROVIDER" in
    openai)
        if [ -z "$OPENAI_API_KEY" ]; then
            echo "❌ Error: OPENAI_API_KEY is required for OpenAI provider"
            exit 1
        fi
        echo "✅ OpenAI API key configured"
        ;;
    anthropic)
        if [ -z "$ANTHROPIC_API_KEY" ]; then
            echo "❌ Error: ANTHROPIC_API_KEY is required for Anthropic provider"
            exit 1
        fi
        echo "✅ Anthropic API key configured"
        ;;
    *)
        echo "⚠️  Warning: Unknown LLM provider: $COGNEE_LLM_PROVIDER"
        ;;
esac

# Start the server
echo "🚀 Starting Cognee MCP server..."
exec python server.py
