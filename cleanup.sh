#!/bin/bash
# cleanup.sh - delete everything the project created in Docker
#
# Removes: both containers, the drupal-net network, both volumes
#          (database + Drupal site files) and the postgres/drupal images.
# Keeps:   the backups/ folder in the repo, so the site can be restored again.
#
# Usage: ./cleanup.sh

set -e  # stop immediately if any command fails

# always run from the repo folder, wherever the script was called from
cd "$(dirname "$0")"

echo "=========================================="
echo "   Drupal cleanup - starting"
echo "=========================================="

# make sure Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "ERROR: Docker is not running. Start Docker and try again."
    exit 1
fi

# -v          -> also delete the volumes
# --rmi all   -> also delete the images used by the project
echo "[..] Removing containers, network, volumes and images..."
docker compose down -v --rmi all
echo "[OK] Docker resources removed."

echo "=========================================="
echo "   Cleanup completed successfully!"
echo "=========================================="
echo "The backups/ folder was kept."
echo "To bring the site back: ./setup.sh and then ./restore.sh"
