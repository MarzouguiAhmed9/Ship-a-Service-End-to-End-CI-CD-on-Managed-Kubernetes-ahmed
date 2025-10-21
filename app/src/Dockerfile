# ============================================================================
# BUILD STAGE - Compile Go application
# ============================================================================
FROM golang:1.23-alpine3.20 AS builder

# Security: Run as non-root during build
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy go mod files first (better caching)
COPY go.mod go.sum* ./
RUN go mod download || go mod init app && go mod tidy

# Copy source code
COPY . .

# Build with security flags
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build \
    -ldflags="-w -s -extldflags '-static'" \
    -trimpath \
    -o app \
    .

# ============================================================================
# RUNTIME STAGE - Minimal secure image
# ============================================================================
FROM alpine:3.20

# Security: Update all packages to latest
RUN apk upgrade --no-cache && \
    apk add --no-cache \
    ca-certificates \
    wget \
    tzdata && \
    rm -rf /var/cache/apk/*

# Create non-root user
RUN addgroup -S appgroup && \
    adduser -S appuser -G appgroup && \
    mkdir -p /app && \
    chown -R appuser:appgroup /app

WORKDIR /app

# Switch to non-root user
USER appuser

# Copy binary from builder (owned by appuser)
COPY --from=builder --chown=appuser:appgroup /app/app .

# Environment variables
ENV SYS_ENV=helloworld \
    PORT=8080 \
    GO_ENV=production

# Expose port (non-privileged)
EXPOSE 8080

# Health check
HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/healthz || exit 1

# Security: Read-only filesystem (optional)
# Add this if your app doesn't need to write files
# USER appuser:appgroup
# RUN chmod 500 /app/app

# Start application
CMD ["./app"]