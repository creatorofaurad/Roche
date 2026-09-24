#!/usr/bin/env bash
set -euo pipefail

echo "[Test] Verifying Docker Compose stack config..."

DOCKER_FILE="integrations/docker/Dockerfile"
COMPOSE_FILE="integrations/docker/docker-compose.yml"

if [ ! -f "$DOCKER_FILE" ]; then
    echo "FAILED: $DOCKER_FILE not found"
    exit 1
fi

if [ ! -f "$COMPOSE_FILE" ]; then
    echo "FAILED: $COMPOSE_FILE not found"
    exit 1
fi

echo "SUCCESS: Docker Compose files verified."
