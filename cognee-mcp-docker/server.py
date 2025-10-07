#!/usr/bin/env python3
"""
Cognee MCP Server - Streamable HTTP Transport
Runs Cognee as an MCP server with HTTP streaming support
"""

import os
import sys
import asyncio
import logging
from pathlib import Path

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def main():
    """Start Cognee MCP server with streamable HTTP transport"""

    # Get configuration from environment
    transport = os.getenv('TRANSPORT_MODE', 'http')
    host = os.getenv('COGNEE_HOST', '0.0.0.0')
    port = int(os.getenv('COGNEE_PORT', '8000'))
    path = os.getenv('COGNEE_PATH', '/mcp')

    logger.info(f"Starting Cognee MCP Server")
    logger.info(f"Transport: {transport}")
    logger.info(f"Host: {host}")
    logger.info(f"Port: {port}")
    logger.info(f"Path: {path}")

    # Validate required environment variables
    required_vars = ['COGNEE_LLM_PROVIDER']
    missing_vars = [var for var in required_vars if not os.getenv(var)]

    if missing_vars:
        logger.error(f"Missing required environment variables: {', '.join(missing_vars)}")
        sys.exit(1)

    # Import and run Cognee server
    try:
        # This assumes cognee-mcp has a server module that can be imported
        # Adjust based on actual Cognee MCP implementation
        import subprocess

        cmd = [
            'python', '-m', 'cognee_mcp.server',
            '--transport', transport,
            '--host', host,
            '--port', str(port),
            '--path', path
        ]

        logger.info(f"Executing: {' '.join(cmd)}")
        subprocess.run(cmd, check=True)

    except ImportError as e:
        logger.error(f"Failed to import Cognee MCP: {e}")
        logger.info("Attempting alternative startup method...")

        # Fallback: Try direct cognee-mcp command
        try:
            import subprocess
            cmd = [
                'cognee-mcp',
                '--transport', transport,
                '--host', host,
                '--port', str(port),
                '--path', path
            ]

            logger.info(f"Executing: {' '.join(cmd)}")
            subprocess.run(cmd, check=True)

        except Exception as e:
            logger.error(f"Failed to start Cognee MCP server: {e}")
            sys.exit(1)

    except Exception as e:
        logger.error(f"Failed to start Cognee MCP server: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
