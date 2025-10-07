# Cognee MCP Server - Streamable HTTP Transport
FROM python:3.11-alpine

WORKDIR /app

# Install system dependencies
RUN apk add --no-cache \
    curl \
    bash \
    git \
    build-base \
    postgresql-client

# Install uv package manager
ENV UV_INSTALL_DIR=/opt/uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    ln -sf /opt/uv/uv /usr/local/bin/uv && \
    ln -sf /opt/uv/uvx /usr/local/bin/uvx

ENV PATH="/opt/uv:$PATH"

# Copy requirements
COPY requirements.txt .

# Install Python dependencies via uv
RUN uv pip install --system -r requirements.txt

# Copy Cognee server script
COPY server.py .
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# Create non-root user
RUN addgroup -g 1001 -S cognee && \
    adduser -S cognee -u 1001 && \
    chown -R cognee:cognee /app

USER cognee

# Expose streamable HTTP port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Start Cognee MCP server
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
