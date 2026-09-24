# Roche Docker Setup Guide

Containerized execution environment for Roche EVM Security Engine.

## Running with Docker Compose

To start Roche API, Dashboard, Redis, and Prometheus:

```bash
docker-compose up --build -d
```

Services:
- **Roche API**: `http://localhost:8080`
- **Dashboard**: `http://localhost:3000`
- **Prometheus**: `http://localhost:9090`
- **Redis**: `localhost:6379`
