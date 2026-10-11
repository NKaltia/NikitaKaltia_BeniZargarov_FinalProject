#!/bin/bash
# restore.sh - restore the Drupal site from the backup in the repo
#
# Uses the two files that backup.sh creates in ./backups:
#   1. drupal_db_backup.sql         -> loaded into the PostgreSQL container
#   2. drupal_sites_backup.tar.gz   -> extracted into /var/www/html/sites
#                                      (settings.php + uploaded files)
#
# Usage: ./restore.sh

# ---- Settings (must match docker-compose.yml) ----
DB_CONTAINER="drupal-db"
DRUPAL_CONTAINER="drupal-site"
DB_USER="root"
DB_NAME="drupal"
BACKUP_DIR="./backups"
DB_BACKUP_FILE="$BACKUP_DIR/drupal_db_backup.sql"
SITES_BACKUP_FILE="$BACKUP_DIR/drupal_sites_backup.tar.gz"

# always run from the repo folder, wherever the script was called from
cd "$(dirname "$0")"

echo "getting latest backup from git..."
git pull

# make sure both backup files exist
for f in "$DB_BACKUP_FILE" "$SITES_BACKUP_FILE"; do
    if [ ! -f "$f" ]; then
        echo "ERROR: backup file $f not found."
        exit 1
    fi
done

# if the containers aren't running, run setup first
if ! docker ps | grep -q "$DB_CONTAINER"; then
    echo "containers not running, running setup.sh..."
    ./setup.sh || exit 1
fi

echo "waiting for the database to be ready..."
until docker exec "$DB_CONTAINER" pg_isready -U "$DB_USER" -d "$DB_NAME" > /dev/null 2>&1; do
    sleep 2
done

echo "restoring database..."
docker exec -i "$DB_CONTAINER" psql -q -U "$DB_USER" "$DB_NAME" < "$DB_BACKUP_FILE" > /dev/null

# restore settings.php and uploaded files (otherwise drupal shows the install page)
# backup.sh packed the *contents* of /var/www/html/sites, so we unpack into the same folder
echo "restoring drupal files..."
docker exec -i "$DRUPAL_CONTAINER" tar -xzf - -C /var/www/html/sites < "$SITES_BACKUP_FILE"
docker exec "$DRUPAL_CONTAINER" chown -R www-data:www-data /var/www/html/sites

echo "restarting drupal..."
docker restart "$DRUPAL_CONTAINER" > /dev/null

echo "done! go to http://localhost:8080"
