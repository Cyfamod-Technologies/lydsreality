#!/bin/sh
set -eu

mkdir -p \
    storage/framework/cache/data \
    storage/framework/sessions \
    storage/framework/views \
    storage/logs \
    bootstrap/cache

chown -R www-data:www-data storage bootstrap/cache

php artisan package:discover --ansi
[ -L public/storage ] || php artisan storage:link
php artisan config:cache
php artisan route:cache || true
php artisan view:cache

exec "$@"
