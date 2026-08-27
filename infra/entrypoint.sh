#!/bin/sh

set -eu


echo "Starting Laravel container..."


mkdir -p \
    storage/framework/cache/data \
    storage/framework/sessions \
    storage/framework/views \
    storage/logs \
    bootstrap/cache


chown -R www-data:www-data storage bootstrap/cache


echo "Checking database initialization..."


if [ -f /var/www/html/database.sql ]; then

    echo "database.sql found"

    # Wait for database
    until php artisan db:show >/dev/null 2>&1
    do
        echo "Waiting for database connection..."
        sleep 5
    done


    # Check if Laravel has already been initialized
    TABLE_COUNT=$(php artisan db:table --json 2>/dev/null | grep -o '"name"' | wc -l || true)


    if [ "$TABLE_COUNT" -eq 0 ]; then

        echo "Database appears empty. Importing database.sql..."

        php artisan db:unprepared "$(cat /var/www/html/database.sql)"

        echo "Database import completed."

    else

        echo "Database already initialized. Skipping import."

    fi

else

    echo "No database.sql found. Skipping database import."

fi



echo "Running Laravel setup..."


php artisan package:discover --ansi


[ -L public/storage ] || php artisan storage:link


php artisan config:cache

php artisan route:cache || true

php artisan view:cache



echo "Laravel ready."


exec "$@"