#!/bin/bash
# Emergency MetaMCP Process Killer
# Immediately kills excessive npm exec processes to prevent memory exhaustion

echo "$(date): Starting emergency process killer..."

# Kill all but the first 15 npm exec processes
docker exec metamcp sh -c '
    ps aux | grep -E "npm exec|@modelcontextprotocol" | grep -v grep | \
    awk "{print \$2}" | tail -n +16 | xargs -r kill -9
'

# Get process count after killing
COUNT=$(docker exec metamcp ps aux | grep -E "npm exec|@modelcontextprotocol" | grep -v grep | wc -l)
echo "$(date): Killed excessive processes. Remaining: $COUNT"

# If still too many, be more aggressive
if [ $COUNT -gt 50 ]; then
    echo "$(date): Still too many processes, killing more aggressively..."
    docker exec metamcp sh -c '
        ps aux | grep -E "npm exec|@modelcontextprotocol" | grep -v grep | \
        awk "{print \$2}" | tail -n +11 | xargs -r kill -9
    '
fi

echo "$(date): Emergency cleanup complete"