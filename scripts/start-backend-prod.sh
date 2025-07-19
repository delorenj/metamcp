#!/bin/bash
# Load environment variables
cd /home/delorenj/code/mcp/metamcp
source /home/delorenj/.bashrc
eval "$(mise exec -- sh -c 'env')"

# Start the backend
cd apps/backend
exec node dist/index.js