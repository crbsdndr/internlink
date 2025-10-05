# Multi-stage build for Laravel application
FROM php:8.2-fpm-alpine AS base

ARG ENABLE_REDIS_EXTENSION=1
ARG REDIS_EXT_VERSION=6.0.2
ARG INSTALL_COMPOSER_DEPENDENCIES=1
ARG INSTALL_NODE_DEPENDENCIES=1
ARG PRESERVE_NODE_MODULES=0

# Install system dependencies
RUN apk add --no-cache \
    nginx \
    supervisor \
    curl \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libzip-dev \
    icu-dev \
    oniguruma-dev \
    postgresql-dev \
    git \
    unzip \
    chromium \
    nss \
    freetype \
    freetype-dev \
    harfbuzz \
    ca-certificates \
    ttf-freefont

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        pdo \
        pdo_pgsql \
        pgsql \
        gd \
        zip \
        intl \
        mbstring \
        bcmath \
        opcache

# Install Redis extension (optional with fallback to latest release)
RUN set -eux; \
    if [ "${ENABLE_REDIS_EXTENSION}" = "1" ]; then \
        apk add --no-cache --virtual .build-deps $PHPIZE_DEPS; \
        pecl channel-update pecl.php.net; \
        if ! printf "\n" | pecl install "redis-${REDIS_EXT_VERSION}"; then \
            echo "Falling back to latest redis extension from PECL"; \
            printf "\n" | pecl install redis; \
        fi; \
        docker-php-ext-enable redis; \
        apk del .build-deps; \
    else \
        echo "Skipping Redis extension installation"; \
    fi

# Install Composer and configure defaults to avoid permission/timeouts
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer
ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_PROCESS_TIMEOUT=0

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY . .

# Fix git ownership issue
RUN git config --global --add safe.directory /var/www/html

# Install PHP dependencies (optional)
RUN if [ "${INSTALL_COMPOSER_DEPENDENCIES}" = "1" ]; then \
        composer install --no-dev --optimize-autoloader --no-interaction --no-progress; \
    else \
        echo "Skipping composer install"; \
    fi

# Install Node dependencies and build assets (optional)
RUN if [ "${INSTALL_NODE_DEPENDENCIES}" = "1" ]; then \
        apk add --no-cache --virtual .node-build-deps nodejs npm; \
        npm ci && npm run build; \
        npm cache clean --force; \
        if [ "${PRESERVE_NODE_MODULES}" != "1" ]; then \
            rm -rf node_modules; \
        else \
            echo "Preserving node_modules directory"; \
        fi; \
        apk del .node-build-deps; \
    else \
        echo "Skipping Node install and build"; \
    fi

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/storage \
    && chmod -R 775 /var/www/html/bootstrap/cache \
    && mkdir -p /var/log/supervisor \
    && chown -R www-data:www-data /var/log/supervisor

# Copy Nginx configuration
COPY docker/nginx/default.conf /etc/nginx/http.d/default.conf

# Copy Supervisor configuration
COPY docker/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose port
EXPOSE 80

# Start supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Development stage
FROM base AS development

ARG INSTALL_COMPOSER_DEPENDENCIES=1
ARG INSTALL_NODE_DEPENDENCIES=1
ARG PRESERVE_NODE_MODULES=0

# Install development dependencies
RUN if [ "${INSTALL_COMPOSER_DEPENDENCIES}" = "1" ]; then \
        composer install --optimize-autoloader --no-interaction --no-progress; \
    else \
        echo "Skipping composer install (development stage)"; \
    fi

# Install development Node dependencies
RUN if [ "${INSTALL_NODE_DEPENDENCIES}" = "1" ]; then \
        apk add --no-cache --virtual .node-build-deps nodejs npm; \
        npm ci; \
        npm cache clean --force; \
        if [ "${PRESERVE_NODE_MODULES}" != "1" ]; then \
            rm -rf node_modules; \
        else \
            echo "Preserving node_modules directory (development stage)"; \
        fi; \
        apk del .node-build-deps; \
    else \
        echo "Skipping npm ci (development stage)"; \
    fi

# Copy development configuration
COPY docker/nginx/dev.conf /etc/nginx/http.d/default.conf

# Expose development port
EXPOSE 80 5173

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
