# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY apps/frontend/package.json ./apps/frontend/
COPY apps/backend/package.json ./apps/backend/
COPY packages/ ./packages/

# Install dependencies
RUN corepack enable pnpm && pnpm install --frozen-lockfile

# Copy source code
COPY . .

# Build the application
RUN pnpm build

# Production stage
FROM node:20-alpine AS production

WORKDIR /app

# Install production dependencies only
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY apps/frontend/package.json ./apps/frontend/
COPY apps/backend/package.json ./apps/backend/
COPY packages/ ./packages/

RUN corepack enable pnpm && pnpm install --frozen-lockfile --prod

# Copy built application and packages
COPY --from=builder /app/apps/frontend/.next ./apps/frontend/.next
COPY --from=builder /app/apps/frontend/public ./apps/frontend/public
COPY --from=builder /app/apps/backend/dist ./apps/backend/dist
COPY --from=builder /app/apps/backend/drizzle ./apps/backend/drizzle
COPY --from=builder /app/packages/zod-types/dist ./packages/zod-types/dist
COPY --from=builder /app/packages/trpc/dist ./packages/trpc/dist

# Copy other necessary files
COPY apps/frontend/next.config.js ./apps/frontend/
COPY turbo.json ./

# Install curl for health checks and postgresql-client for database connectivity
RUN apk add --no-cache curl postgresql-client bash

# Install bun in a shared location accessible by the non-root runtime user
ENV BUN_INSTALL=/opt/bun
RUN mkdir -p /opt/bun && \
  curl -fsSL https://bun.sh/install | bash \
  && ln -sf /opt/bun/bin/bun /usr/local/bin/bun \
  && printf '#!/bin/sh\nexec /opt/bun/bin/bun x "$@"\n' > /usr/local/bin/bunx \
  && chmod +x /usr/local/bin/bunx

# Install uv in a shared location accessible by the non-root runtime user
ENV UV_INSTALL_DIR=/opt/uv
RUN mkdir -p /opt/uv && \
  curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=$UV_INSTALL_DIR sh \
  && ln -sf /opt/uv/uv /usr/local/bin/uv \
  && ln -sf /opt/uv/uvx /usr/local/bin/uvx

ENV PATH="/opt/bun/bin:/opt/uv:$PATH"

# Copy and set up entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Create non-root user and logs directory
RUN addgroup -g 1001 -S nodejs && \
    adduser -S metamcp -u 1001 && \
    mkdir -p /app/logs && \
    chown -R metamcp:nodejs /app && \
    chown -R metamcp:nodejs /opt/bun && \
    chown -R metamcp:nodejs /opt/uv

USER metamcp

EXPOSE 12008
EXPOSE 12009

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD sh -c 'curl -f http://"$(hostname -i)":12008/health || exit 1'

# Start the application using the entrypoint script
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
