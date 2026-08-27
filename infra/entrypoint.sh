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


# Fix permissions

chown -R www-data:www-data storage bootstrap/cache



echo "Checking database connection..."



# Wait for MySQL to be ready

if [ -n "${DB_HOST:-}" ]; then

    until mysqladmin ping \
        -h "$DB_HOST" \
        -u "$DB_USERNAME" \
        -p"$DB_PASSWORD" \
        --silent
    do
        echo "Waiting for database server..."
        sleep 5
    done


    echo "Database server is available."

else

    echo "DB_HOST not configured. Skipping database check."

fi




# Import database.sql if database is empty

if [ -f "/var/www/html/database.sql" ]; then


    echo "Found database.sql"



    TABLE_COUNT=$(mysql \
        -h "$DB_HOST" \
        -u "$DB_USERNAME" \
        -p"$DB_PASSWORD" \
        "$DB_DATABASE" \
        -e "SHOW TABLES;" 2>/dev/null | wc -l || true)



    if [ "$TABLE_COUNT" -le 1 ]; then


        echo "Database is empty."
        echo "Importing database.sql..."



        mysql \
            -h "$DB_HOST" \
            -u "$DB_USERNAME" \
            -p"$DB_PASSWORD" \
            "$DB_DATABASE" < /var/www/html/database.sql



        echo "Database import completed."



    else


        echo "Database already contains tables."
        echo "Skipping import."


    fi



else


    echo "No database.sql found."
    echo "Skipping database import."


fi





echo "Running Laravel setup..."



php artisan package:discover --ansi



# Create storage link

if [ ! -L public/storage ]; then

    php artisan storage:link || true

fi




# Production cache

php artisan config:clear

php artisan cache:clear


php artisan config:cache

php artisan route:cache || true

php artisan view:cache




echo "======================================"
echo "Laravel application ready"
echo "======================================"


exec "$@"