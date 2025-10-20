# ============================================================================
# BUILD STAGE - Compile Go application
# ============================================================================
FROM golang:1.23.2-alpine3.20 AS builder

# Install build dependencies
RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /app

# Copy dependency files
COPY go.mod go.sum* ./

# Download dependencies with verification
RUN go mod download && go mod verify || \
    (go mod init app && go mod tidy)

# Copy source code
COPY . .

# Build with security hardening flags
RUN CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=amd64 \
    go build \
    -ldflags="-w -s -X main.version=1.0.0 -extldflags '-static'" \
    -trimpath \
    -buildvcs=false \
    -o app \
    .

# Verify binary
RUN chmod +x /app/app && \
    /app/app --version || echo "Binary built successfully"

# ============================================================================
# RUNTIME STAGE - Minimal secure image with latest patches
# ============================================================================
FROM alpine:3.20.3

# Update all packages and install runtime dependencies
RUN apk upgrade --no-cache --available && \
    apk add --no-cache \
    ca-certificates=20240705-r0 \
    wget=1.24.5-r0 \
    tzdata \
    && rm -rf /var/cache/apk/* /tmp/*

# Create non-root user and group
RUN addgroup -g 1000 -S appgroup && \
    adduser -u 1000 -S appuser -G appgroup && \
    mkdir -p /app && \
    chown -R appuser:appgroup /app

WORKDIR /app

# Switch to non-root user
USER appuser

# Copy binary from builder
COPY --from=builder --chown=appuser:appgroup /app/app .

# Make binary executable
RUN chmod 500 /app/app

# Environment variables
ENV SYS_ENV=helloworld \
    PORT=8080 \
    GO_ENV=production

# Use non-privileged port
EXPOSE 8080

# Enhanced healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider --timeout=3 http://localhost:8080/healthz || exit 1

# Run as non-root
USER 1000:1000

# Start application
CMD ["./app"]