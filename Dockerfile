# syntax=docker/dockerfile:1

FROM php:8.2-fpm-alpine AS runtime

# Install system dependencies
ARG ADD_XDEBUG=0
ARG ADD_SWOOLE=0
ARG ADD_MARIADBCLIENT=0
RUN apk update && \
    apk add --no-cache \
    $PHPIZE_DEPS \
    build-base \
    libzip-dev \
    zip \
    unzip \
    git \
    fcgi \
    nodejs \
    npm \
    && ([ "$ADD_MARIADBCLIENT" != "1" ] || apk add mariadb-client) \
    && apk add --update linux-headers \
    && pecl install -o -f redis excimer && docker-php-ext-enable redis excimer \
    && ([ "$ADD_XDEBUG" != "1" ] || (pecl install xdebug-3.2.1 && docker-php-ext-enable xdebug && chmod 666 /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini)) \
    && ([ "$ADD_SWOOLE" != "1" ] || (pecl install swoole && docker-php-ext-enable swoole)) \
    && docker-php-ext-install pdo_mysql bcmath zip opcache \
    && apk del $PHPIZE_DEPS build-base

# Install Tools
RUN curl -sLO https://gordalina.github.io/cachetool/downloads/cachetool-3.2.2.phar \
    && chmod +x cachetool-3.2.2.phar \
    && mv cachetool-3.2.2.phar /usr/local/bin/cachetool \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && curl -1sLf  'https://github.com/mozilla/sops/releases/download/v3.7.3/sops-v3.7.3.linux.amd64' > /usr/local/bin/sops \
    && chmod +x /usr/local/bin/sops

# Configure PHP and PHP-FPM
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
