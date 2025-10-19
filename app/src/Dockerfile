# Build stage
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY . .
RUN go mod init app || true
RUN go mod tidy
RUN go build -o app

# Runtime stage
FROM alpine:latest
WORKDIR /app

# Non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

COPY --from=builder /app/app .

ENV SYS_ENV=helloworld
EXPOSE 8080

HEALTHCHECK --interval=15s --timeout=5s CMD wget -qO- http://localhost:8080/healthz || exit 1

CMD ["./app"]
