# =============================================================
# Multi-stage Dockerfile for TRAVEL-WEB (Next.js)
# Optimized for production with minimal image size
# =============================================================
# Build context: web/TRAVEL-WEB/
# Usage: docker build -t travel-web -f ci-cd/docker/Dockerfile web/TRAVEL-WEB/
# =============================================================

# ---- Stage 1: Dependencies ----
FROM node:20-alpine AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Copy dependency manifests
COPY package.json package-lock.json ./
COPY prisma ./prisma/

# Install dependencies (clean install for reproducible builds)
RUN npm ci --ignore-scripts
# Generate Prisma client
RUN npx prisma generate

# ---- Stage 2: Builder ----
FROM node:20-alpine AS builder
WORKDIR /app

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Set build-time environment variables
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production

# Dummy env vars for build time only (real values injected at runtime via Secrets Manager)
ENV DATABASE_URL="postgresql://dummy:dummy@localhost:5432/dummy"
ENV NEXTAUTH_SECRET="build-time-placeholder"
ENV NEXTAUTH_URL="http://localhost:3000"
ENV STRIPE_SECRET_KEY="sk_test_build_placeholder"
ENV STRIPE_WEBHOOK_SECRET="whsec_build_placeholder"
ENV CLOUDINARY_API_KEY="build_placeholder"
ENV CLOUDINARY_API_SECRET="build_placeholder"
ENV CLOUDINARY_CLOUD_NAME="build_placeholder"
ENV RESEND_API_KEY="re_build_placeholder"

# Build the Next.js application
RUN npm run build

# ---- Stage 3: Production Runner ----
FROM node:20-alpine AS runner
WORKDIR /app

# Security: run as non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Set production environment
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# Copy only the necessary files for production
COPY --from=builder /app/public ./public

# Automatically leverage output traces to reduce image size
# https://nextjs.org/docs/advanced-features/output-file-tracing
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# Copy Prisma schema for runtime (needed for prisma client)
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/prisma.config.ts ./prisma.config.ts
COPY --from=deps /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=deps /app/node_modules/@prisma ./node_modules/@prisma
COPY --from=deps /app/node_modules/prisma ./node_modules/prisma

# Switch to non-root user
USER nextjs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/ || exit 1

# Start the application
CMD ["node", "server.js"]
