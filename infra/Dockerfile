FROM node:22-bookworm-slim AS frontend

WORKDIR /app

ENV PUPPETEER_SKIP_DOWNLOAD=true

COPY package.json package-lock.json ./
COPY platform ./platform
COPY webpack.mix.js ./
COPY public ./public
COPY resources ./resources

RUN set -eux; \
    for asset_type in core packages plugins; do \
        for source_dir in platform/$asset_type/*/public; do \
            [ -d "$source_dir" ] || continue; \
            module_name="$(basename "$(dirname "$source_dir")")"; \
            target_dir="public/vendor/core/$asset_type/$module_name"; \
            mkdir -p "$target_dir"; \
            cp -a "$source_dir/." "$target_dir/"; \
        done; \
    done; \
    for source_dir in platform/themes/*/public; do \
        [ -d "$source_dir" ] || continue; \
        theme_name="$(basename "$(dirname "$source_dir")")"; \
        target_dir="public/themes/$theme_name"; \
        mkdir -p "$target_dir"; \
        cp -a "$source_dir/." "$target_dir/"; \
    done; \
    npm install --ignore-scripts --no-audit --no-fund \
    && npm run production

FROM php:8.3-apache-bookworm

ENV APACHE_DOCUMENT_ROOT=/var/www/html/public

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        libfreetype6-dev \
        libicu-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libzip-dev \
        unzip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" \
        bcmath \
        calendar \
        exif \
        gd \
        intl \
        opcache \
        pdo_mysql \
        zip \
    && a2enmod expires headers rewrite \
    && sed -ri 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer
COPY --chown=www-data:www-data . .

RUN composer install \
    --no-dev \
    --no-interaction \
    --no-progress \
    --prefer-dist \
    --optimize-autoloader \
    --no-scripts \
    && composer clear-cache

COPY --from=frontend --chown=www-data:www-data /app/public ./public
COPY infra/php-production.ini /usr/local/etc/php/conf.d/zz-production.ini
COPY infra/apache-vhost.conf /etc/apache2/sites-available/000-default.conf
COPY infra/entrypoint.sh /usr/local/bin/entrypoint

RUN chmod +x /usr/local/bin/entrypoint \
    && mkdir -p storage/framework/cache/data storage/framework/sessions storage/framework/views storage/logs bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache

EXPOSE 80

ENTRYPOINT ["entrypoint"]
CMD ["apache2-foreground"]
