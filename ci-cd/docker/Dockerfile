# =============================================================
# Multi-stage Dockerfile for TRAVEL-WEB Microservices
# Builds any service via SERVICE_NAME build arg
# =============================================================
# Build context: web/TRAVEL-WEB/
# Usage:
#   docker build --build-arg SERVICE_NAME=api-gateway -t travel-web-api-gateway -f ci-cd/docker/Dockerfile web/TRAVEL-WEB/
#   docker build --build-arg SERVICE_NAME=auth-service -t travel-web-auth-service -f ci-cd/docker/Dockerfile web/TRAVEL-WEB/
# =============================================================

ARG SERVICE_NAME

# ---- Stage 1: Builder ----
FROM node:20-alpine AS builder
WORKDIR /app

ARG SERVICE_NAME
ENV SERVICE_NAME=${SERVICE_NAME}

# 1. Root manifests (cache layer)
COPY package.json package-lock.json tsconfig.base.json ./

# 2. All workspace sources (node_modules/dist excluded via .dockerignore)
COPY packages ./packages
COPY services ./services
COPY apps ./apps

# 3. Install all workspace deps from root
RUN npm ci --legacy-peer-deps

# 4. Build shared packages
RUN npm -w @travel-web/contracts run build \
    && npm -w @travel-web/shared run build

# 5. Generate Prisma client if service has prisma schema
RUN if [ -f "./services/${SERVICE_NAME}/prisma/schema.prisma" ]; then \
      npx prisma generate --schema=./services/${SERVICE_NAME}/prisma/schema.prisma; \
    fi

# 6. Compile the service
RUN npm -w ${SERVICE_NAME} run build

# 7. Ensure prisma dir exists (even if empty) for COPY in runner stage
RUN mkdir -p ./services/${SERVICE_NAME}/prisma

# ---- Stage 2: Production Runner ----
FROM node:20-alpine AS runner
WORKDIR /app

ARG SERVICE_NAME
ENV SERVICE_NAME=${SERVICE_NAME}

RUN apk add --no-cache openssl

# Security: run as non-root user
RUN addgroup --system --gid 1001 appuser \
    && adduser --system --uid 1001 appuser

# Copy shared packages
COPY --from=builder /app/packages/contracts ./packages/contracts
COPY --from=builder /app/packages/shared ./packages/shared

# Copy service dist, package.json, and node_modules
COPY --from=builder /app/services/${SERVICE_NAME}/dist ./services/${SERVICE_NAME}/dist
COPY --from=builder /app/services/${SERVICE_NAME}/package.json ./services/${SERVICE_NAME}/package.json
COPY --from=builder /app/services/${SERVICE_NAME}/node_modules ./services/${SERVICE_NAME}/node_modules
COPY --from=builder /app/node_modules ./node_modules

# Copy Prisma client if generated
RUN if [ -d "/app/services/${SERVICE_NAME}/node_modules/.prisma" ]; then \
      cp -r /app/services/${SERVICE_NAME}/node_modules/.prisma /app/node_modules/.prisma 2>/dev/null || true; \
    fi

# Copy Prisma schema for migrations at runtime
COPY --from=builder /app/services/${SERVICE_NAME}/prisma ./services/${SERVICE_NAME}/prisma

WORKDIR /app/services/${SERVICE_NAME}

ENV NODE_ENV=production

USER appuser

# Start command determined by service's package.json "start" script
CMD ["node", "dist/index.js"]
