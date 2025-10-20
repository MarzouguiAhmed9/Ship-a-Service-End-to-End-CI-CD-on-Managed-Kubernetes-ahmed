# Build stage
FROM golang:1.21-alpine3.18 AS builder
WORKDIR /app

# Copy and build
COPY . .
RUN go mod init app || true
RUN go mod tidy
RUN go build -o app

# Runtime stage
FROM alpine:3.18
WORKDIR /app

# Install wget for healthcheck, minimal packages, no cache
RUN apk add --no-cache wget \
    && addgroup -S appgroup \
    && adduser -S appuser -G appgroup
USER appuser

# Copy binary from builder
COPY --from=builder /app/app .

# Env and port
ENV SYS_ENV=helloworld
EXPOSE 8080

# Healthcheck
HEALTHCHECK --interval=15s --timeout=5s CMD wget -qO- http://localhost:8080/healthz || exit 1

# Start app
CMD ["./app"]
