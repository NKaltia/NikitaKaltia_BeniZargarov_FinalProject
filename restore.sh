#!/bin/bash
# restore the drupal site from the backup in the repo

DB_TYPE="postgres"
NETWORK="drupal-net"
DB_CONTAINER="drupal-db"
DRUPAL_CONTAINER="drupal-site"
DB_NAME="drupal"

cd "$(dirname "$0")"

echo "getting latest backup from git..."
git pull

# if the containers arent running run setup first
if ! docker ps | grep -q "$DB_CONTAINER"; then
    echo "containers not running, running setup.sh..."
    ./setup.sh
fi

echo "waiting for the database to start..."
sleep 20

echo "restoring database..."
if [ "$DB_TYPE" = "mysql" ]; then
    docker exec "$DB_CONTAINER" sh -c "exec mysqladmin -uroot -p$DB_PASS create $DB_NAME" 2>/dev/null
    gunzip < my-drupal.backup.sql.gz | docker exec -i "$DB_CONTAINER" sh -c "exec mysql -h 127.0.0.1 -uroot -p$DB_PASS --force $DB_NAME"
else
    docker exec -i "$DB_CONTAINER" psql -U root "$DB_NAME" < drupal_db_backup.sql
fi

# restore settings.php and uploaded files (otherwise drupal shows the install page)
if [ -f drupal_sites_backup.tar.gz ]; then
    echo "restoring drupal files..."
    docker exec -i "$DRUPAL_CONTAINER" tar -xzf - -C /var/www/html < drupal_sites_backup.tar.gz
    docker exec "$DRUPAL_CONTAINER" chown -R www-data:www-data /var/www/html/sites
fi

echo "restarting drupal..."
docker restart "$DRUPAL_CONTAINER"

echo "done! go to http://localhost:8080"
