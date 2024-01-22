# syntax=docker/dockerfile:1

FROM php:8.2-fpm-alpine as runtime

ARG NGINX_VERSION=nginx-1.25.3
RUN apk --update add --no-cache \
    openssl-dev \
    pcre-dev \
    zlib-dev \
    build-base \
    unzip \
    libzip-dev \
    $PHPIZE_DEPS \
    && \
    mkdir -p /tmp/src && \
    cd /tmp/src && \
    wget http://nginx.org/download/${NGINX_VERSION}.tar.gz && \
    tar -zxvf ${NGINX_VERSION}.tar.gz && \
    cd /tmp/src/${NGINX_VERSION} && \
    ./configure \
    --with-http_ssl_module \
    --with-http_gzip_static_module \
    --with-http_v2_module \
    --with-http_v3_module \
    --with-http_realip_module \
    --prefix=/etc/nginx \
    --http-log-path=/var/log/nginx/access.log \
    --error-log-path=/var/log/nginx/error.log \
    --sbin-path=/usr/local/sbin/nginx && \
    make && \
    make install && \
    cd / && \
    rm -rf /tmp/src && \
    apk add --no-cache supervisor redis gettext && \
    pecl install -o -f redis excimer && \
    docker-php-ext-enable redis excimer && \
    docker-php-ext-install pdo_mysql bcmath zip opcache && \
    apk del build-base $PHPIZE_DEPS && \
    rm -rf /var/cache/apk/*

ARG EXTRA_APKS="wget zip unzip git fcgi"
RUN apk --update add --no-cache $EXTRA_APKS && rm -rf /var/cache/apk/*

# Install Tools
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Add supervisord configuration
COPY deployment/docker-entrypoint.sh /docker-entrypoint.sh
COPY deployment/supervisord.conf /etc/supervisord.conf
COPY deployment/nginx.conf.template /etc/nginx/conf/nginx.conf.template

RUN chmod +x /docker-entrypoint.sh

ENV DOCKER_USER_ID=1000
ENV DOCKER_GROUP_ID=1000

RUN addgroup -g $DOCKER_GROUP_ID app \
    && adduser -s /bin/sh -H -h /app -u $DOCKER_USER_ID -S -G app app

# by default don't trust X-Real-IP
ENV NGINX_REAL_IP_FROM=0.0.0.0/32
ENV NGINX_CSP=
ENV HOME=/app

# Set working directory and expose necessary ports
WORKDIR /app
EXPOSE 80

# Define the entry point
ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]

FROM runtime as dev

RUN apk add --no-cache nodejs npm \
    && rm -rf /var/cache/apk/*
