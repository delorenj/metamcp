#!/bin/sh
# MetaMCP Process Monitor - Docker Compose v2 compatible
# Monitors and kills excessive npm exec processes to prevent memory leaks

set -e

# Configuration
MAX_PROCESSES=15
CHECK_INTERVAL=30
CONTAINER_NAME="metamcp"
LOG_FILE="/tmp/process-monitor.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to count MCP processes
count_processes() {
    docker exec "$CONTAINER_NAME" sh -c "ps aux | grep -E 'npm exec|@modelcontextprotocol' | grep -v grep | wc -l" 2>/dev/null || echo "0"
}

# Function to get memory usage
get_memory_usage() {
    docker stats --no-stream --format "{{.MemUsage}}" "$CONTAINER_NAME" 2>/dev/null | awk '{print $1}'
}

# Function to kill excessive processes
kill_excessive_processes() {
    local current_count=$1
    local to_kill=$((current_count - MAX_PROCESSES))

    log_message "WARNING: Found $current_count processes (limit: $MAX_PROCESSES). Killing $to_kill processes..."

    # Kill the oldest processes first (by start time)
    docker exec "$CONTAINER_NAME" sh -c "
        ps aux | grep -E 'npm exec|@modelcontextprotocol' | grep -v grep | \
        sort -k9 | head -n $to_kill | awk '{print \$2}' | \
        while read pid; do
            kill -TERM \$pid 2>/dev/null || true
            sleep 0.1
        done
    " 2>/dev/null

    # Wait a moment for graceful shutdown
    sleep 2

    # Force kill any remaining
    docker exec "$CONTAINER_NAME" sh -c "
        ps aux | grep -E 'npm exec|@modelcontextprotocol' | grep -v grep | \
        sort -k9 | head -n $to_kill | awk '{print \$2}' | \
        while read pid; do
            kill -9 \$pid 2>/dev/null || true
        done
    " 2>/dev/null
}

# Function to perform emergency cleanup
emergency_cleanup() {
    log_message "CRITICAL: Performing emergency cleanup!"

    # Kill all but essential processes
    docker exec "$CONTAINER_NAME" sh -c "
        # Get the main node process PID
        MAIN_PID=\$(ps aux | grep 'node.*server' | grep -v grep | head -1 | awk '{print \$2}')

        # Kill all npm exec processes except the first 5
        ps aux | grep -E 'npm exec|@modelcontextprotocol' | grep -v grep | \
        awk '{print \$2}' | tail -n +6 | \
        while read pid; do
            kill -9 \$pid 2>/dev/null || true
        done
    " 2>/dev/null
}

# Main monitoring loop
log_message "MetaMCP Process Monitor started"
log_message "Configuration: MAX_PROCESSES=$MAX_PROCESSES, CHECK_INTERVAL=$CHECK_INTERVAL"

while true; do
    # Check if container is running
    if ! docker ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        log_message "Container $CONTAINER_NAME not running. Waiting..."
        sleep $CHECK_INTERVAL
        continue
    fi

    # Count current processes
    PROCESS_COUNT=$(count_processes)
    MEMORY_USAGE=$(get_memory_usage)

    # Log current status
    if [ "$PROCESS_COUNT" -gt "$MAX_PROCESSES" ]; then
        log_message "Status: Processes=$PROCESS_COUNT (OVER LIMIT), Memory=$MEMORY_USAGE"
        kill_excessive_processes "$PROCESS_COUNT"

        # Recheck after killing
        sleep 5
        NEW_COUNT=$(count_processes)
        log_message "After cleanup: Processes=$NEW_COUNT"

        # If still too many, emergency cleanup
        if [ "$NEW_COUNT" -gt $((MAX_PROCESSES * 2)) ]; then
            emergency_cleanup
        fi
    elif [ "$PROCESS_COUNT" -gt $((MAX_PROCESSES - 5)) ]; then
        log_message "Status: Processes=$PROCESS_COUNT (WARNING), Memory=$MEMORY_USAGE"
    fi

    # Parse memory usage and check if it's too high
    MEMORY_GB=$(echo "$MEMORY_USAGE" | sed 's/GiB//' | sed 's/MiB//' | awk '{print int($1)}')
    if [ "$MEMORY_GB" -gt 3 ] 2>/dev/null; then
        log_message "WARNING: High memory usage detected: $MEMORY_USAGE"
        # Trigger process cleanup even if count seems OK (could be zombie processes)
        if [ "$PROCESS_COUNT" -gt 10 ]; then
            kill_excessive_processes "$PROCESS_COUNT"
        fi
    fi

    sleep $CHECK_INTERVAL
done