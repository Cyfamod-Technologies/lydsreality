#!/bin/sh

set -eu


echo "======================================"
echo "Starting Laravel application"
echo "======================================"


# Create Laravel required directories

mkdir -p \
    storage/app/purifier \
    storage/framework/cache/data \
    storage/framework/sessions \
    storage/framework/views \
    storage/logs \
    bootstrap/cache


# Fix Laravel permissions

chown -R www-data:www-data storage bootstrap/cache



echo "Checking database connection..."



# Wait until Laravel can connect to database

if [ -n "${DB_HOST:-}" ]; then

    until php artisan db:show >/dev/null 2>&1
    do
        echo "Waiting for database server..."
        sleep 5
    done


    echo "Database connection successful."

else

    echo "DB_HOST is not configured."
    echo "Skipping database connection check."

fi





# Import database.sql only when database is empty

if [ -n "${DB_HOST:-}" ] && [ -f "/var/www/html/database.sql" ]; then


    echo "database.sql detected."



    export MYSQL_PWD="${DB_PASSWORD:-}"

    TABLE_COUNT=$(mysql \
        --host="$DB_HOST" \
        --port="${DB_PORT:-3306}" \
        --user="${DB_USERNAME:-root}" \
        --batch \
        --skip-column-names \
        "${DB_DATABASE:?DB_DATABASE is required}" \
        --execute='SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE();')



    if [ "$TABLE_COUNT" -eq 0 ]; then


        echo "Database appears empty."
        echo "Importing database.sql..."



        mysql \
            --host="$DB_HOST" \
            --port="${DB_PORT:-3306}" \
            --user="${DB_USERNAME:-root}" \
            "$DB_DATABASE" < /var/www/html/database.sql



        echo "Database import completed."



    else


        echo "Database already contains tables."
        echo "Skipping database import."


    fi



elif [ -z "${DB_HOST:-}" ]; then


    echo "DB_HOST is not configured."
    echo "Skipping database import."


else


    echo "No database.sql found."
    echo "Skipping database import."


fi





echo "Running Laravel setup..."



php artisan package:discover --ansi



# Create storage symlink

if [ ! -L public/storage ]; then

    php artisan storage:link || true

fi




# Clear old caches

php artisan config:clear

php artisan cache:clear




# Build production caches

php artisan config:cache

php artisan route:cache || true

php artisan view:cache


# Cache commands can recreate storage directories as root. Repair ownership
# after they finish so Apache's www-data workers can write runtime caches.
mkdir -p storage/app/purifier
chown -R www-data:www-data storage bootstrap/cache
chmod -R ug+rwX storage bootstrap/cache




echo "======================================"
echo "Laravel application ready"
echo "======================================"


exec "$@"
