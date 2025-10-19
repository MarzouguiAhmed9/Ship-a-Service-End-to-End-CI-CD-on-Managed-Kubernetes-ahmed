# App - Simple HTTP Service

This is a tiny HTTP service written in Go.

## Features

- `/healthz` endpoint returns `200` with JSON payload.
- JSON includes `SYS_ENV` environment variable.

---

## Build & Run Locally

### 1. Build the Docker image

From the `app/src` directory:

```bash
docker build -t app:latest .
This uses the Dockerfile’s default settings, including SYS_ENV=helloworld.

2. Run the container
docker run -p 8080:8080 app:latest
Container listens on port 8080.

Default SYS_ENV is helloworld.

3. Test the endpoint
curl http://localhost:8080/healthz
Expected output:
json
Copier le code
{
  "status": "ok",
  "SYS_ENV": "helloworld"
}

