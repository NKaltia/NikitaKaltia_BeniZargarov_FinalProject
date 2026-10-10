#!/usr/bin/env bash
#
# backup.sh - Back up the Drupal site (database + site files)
#
# Creates two files in the ./backups folder:
#   1. drupal_db_backup.sql          -> full PostgreSQL database dump
#   2. drupal_sites_backup.tar.gz    -> /var/www/html/sites (settings.php, uploaded files)
#
# Usage: ./backup.sh
#

set -e  # stop immediately if any command fails

# ---- Settings (must match docker-compose.yml) ----
DB_CONTAINER="drupal-db"
SITE_CONTAINER="drupal-site"
DB_USER="root"
DB_NAME="drupal"
BACKUP_DIR="./backups"
DB_BACKUP_FILE="$BACKUP_DIR/drupal_db_backup.sql"
SITES_BACKUP_FILE="$BACKUP_DIR/drupal_sites_backup.tar.gz"

echo "=========================================="
echo "   Drupal backup - starting"
echo "=========================================="

# ---- 1. Check that both containers are running ----
for container in "$DB_CONTAINER" "$SITE_CONTAINER"; do
    if [ -z "$(docker ps -q -f name="^${container}$")" ]; then
        echo "ERROR: container '$container' is not running."
        echo "Start it first with: docker compose up -d"
        exit 1
    fi
done
echo "[OK] Both containers are running."

# ---- 2. Create the backups folder if it doesn't exist ----
mkdir -p "$BACKUP_DIR"

# ---- 3. Back up the database ----
# --clean --if-exists: the dump first drops existing tables,
# so it can be restored even into a database that already has data.
echo "[..] Backing up database '$DB_NAME'..."
docker exec "$DB_CONTAINER" sh -c "exec pg_dump -U $DB_USER --clean --if-exists $DB_NAME" > "$DB_BACKUP_FILE"
echo "[OK] Database saved to $DB_BACKUP_FILE"

# ---- 4. Back up the Drupal 'sites' folder ----
# Contains settings.php (DB connection details) and uploaded files.
# Cache folders (css/js/php) are skipped - Drupal rebuilds them automatically.
echo "[..] Backing up Drupal site files..."
docker exec "$SITE_CONTAINER" tar czf - \
    --exclude=./default/files/css \
    --exclude=./default/files/js \
    --exclude=./default/files/php \
    -C /var/www/html/sites . > "$SITES_BACKUP_FILE"
echo "[OK] Site files saved to $SITES_BACKUP_FILE"

# ---- 5. Summary ----
echo "=========================================="
echo "   Backup completed successfully!"
echo "=========================================="
ls -lh "$BACKUP_DIR"
echo ""
echo "Next step: commit and push the backup to Git:"
echo "  git add backups/ && git commit -m \"Update backup\" && git push"
