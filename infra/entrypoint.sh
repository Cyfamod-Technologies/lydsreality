#!/bin/sh

set -eu


echo "======================================"
echo "Starting Laravel application"
echo "======================================"


# Create Laravel required directories

mkdir -p \
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

if [ -f "/var/www/html/database.sql" ]; then


    echo "database.sql detected."



    TABLE_COUNT=$(php artisan db:table --json 2>/dev/null | grep -o '"name"' | wc -l || true)



    if [ "$TABLE_COUNT" -eq 0 ]; then


        echo "Database appears empty."
        echo "Importing database.sql..."



        php artisan db:unprepared "$(cat /var/www/html/database.sql)"



        echo "Database import completed."



    else


        echo "Database already contains tables."
        echo "Skipping database import."


    fi



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





echo "======================================"
echo "Laravel application ready"
echo "======================================"


exec "$@"