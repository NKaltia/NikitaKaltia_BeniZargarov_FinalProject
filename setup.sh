#!/usr/bin/env bash
#
# setup.sh - Set up the Docker environment for the Drupal site
#
# What it does:
#   1. Checks that Docker is installed and running
#   2. Downloads the latest images (postgres + drupal)
#   3. Creates the network, volumes and containers (via Docker Compose)
#   4. Waits until the database is ready
#
# Usage: ./setup.sh
#

set -e  # stop immediately if any command fails

# ---- Settings (must match docker-compose.yml) ----
COMPOSE_FILE="docker-compose.yml"
DB_CONTAINER="drupal-db"
DB_USER="root"
DB_NAME="drupal"
SITE_URL="http://localhost:8080"

echo "=========================================="
echo "   Drupal setup - starting"
echo "=========================================="

# ---- 1. Check that Docker is installed ----
if ! command -v docker > /dev/null 2>&1; then
    echo "ERROR: Docker is not installed."
    echo "Install it from https://docs.docker.com/get-docker/"
    exit 1
fi
echo "[OK] Docker is installed."

# ---- 2. Check that the Docker engine is running ----
if ! docker info > /dev/null 2>&1; then
    echo "ERROR: Docker is installed but not running."
    echo "Start Docker (or Docker Desktop) and try again."
    exit 1
fi
echo "[OK] Docker is running."

# ---- 3. Check that Docker Compose is available ----
if ! docker compose version > /dev/null 2>&1; then
    echo "ERROR: 'docker compose' is not available."
    echo "Install the Docker Compose plugin and try again."
    exit 1
fi
echo "[OK] Docker Compose is available."

# ---- 4. Check that the compose file exists ----
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "ERROR: $COMPOSE_FILE not found."
    echo "Run this script from the root folder of the repository."
    exit 1
fi
echo "[OK] Found $COMPOSE_FILE."

# ---- 5. Download the latest images ----
echo "[..] Downloading the latest images (this may take a few minutes)..."
docker compose pull
echo "[OK] Images are up to date."

# ---- 6. Create network + volumes and start the containers ----
echo "[..] Starting containers..."
docker compose up -d
echo "[OK] Containers started."

# ---- 7. Wait until PostgreSQL accepts connections ----
echo "[..] Waiting for the database to be ready..."
for i in $(seq 1 30); do
    if docker exec "$DB_CONTAINER" pg_isready -U "$DB_USER" -d "$DB_NAME" > /dev/null 2>&1; then
        echo "[OK] Database is ready."
        break
    fi
    if [ "$i" -eq 30 ]; then
        echo "ERROR: Database did not become ready in time."
        echo "Check the logs with: docker logs $DB_CONTAINER"
        exit 1
    fi
    sleep 2
done

# ---- 8. Summary ----
echo "=========================================="
echo "   Setup completed successfully!"
echo "=========================================="
docker ps --filter "network=drupal-net"
echo ""
echo "Next steps:"
echo "  - First time?           Open $SITE_URL and run the Drupal installer."
echo "  - Restoring a backup?   Run ./restore.sh"
