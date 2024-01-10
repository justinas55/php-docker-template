# syntax=docker/dockerfile:1

FROM php:8.2-fpm-alpine as runtime

ARG NGINX_VERSION=nginx-1.25.3

RUN apk --update add --no-cache openssl-dev pcre-dev zlib-dev wget build-base $PHPIZE_DEPS zip unzip libzip-dev git fcgi && \
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
    apk add --no-cache supervisor redis gettext && \
    pecl install -o -f redis excimer && \
    docker-php-ext-enable redis excimer && \
    docker-php-ext-install pdo_mysql bcmath zip opcache && \
    apk del build-base $PHPIZE_DEPS && \
    rm -rf /tmp/src && \
    rm -rf /var/cache/apk/*

# Install Tools
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Configure PHP-FPM
RUN function phpfpm_set() { \
    ESCAPED_VALUE=$(printf '%s\n' "$2" | sed -e 's/\([.\/]\)/\\\1/g'); \
    conffile=/usr/local/etc/php-fpm.d/zz-docker.conf ; \
    if grep -e "^;\?$1\\s*=" $conffile ; then \ 
    sed -i -e "s/^;\?\($1\\s*=\).*/\\1 $ESCAPED_VALUE/g" $conffile ; \
    else \
    echo "$1 = $2" >> $conffile ; \
    fi \
    } \
    && phpfpm_set listen /run/php-fpm.sock \
    && phpfpm_set listen.owner php-fpm \
    && phpfpm_set listen.group www \
    && phpfpm_set user php-fpm \
    && phpfpm_set group www

# Add supervisord configuration
COPY deployment/docker-entrypoint.sh /docker-entrypoint.sh
COPY deployment/supervisord.conf /etc/supervisord.conf
COPY deployment/nginx.conf.template /etc/nginx/conf/nginx.conf.template

RUN addgroup -g 1010 www \
    && adduser -s /bin/sh -H -u 1000 -S -G www php-fpm \
    && adduser -s /bin/sh -H -u 1012 -S -G www nginx \
    && touch /run/php-fpm.sock \
    && chmod 660 /run/php-fpm.sock \
    && chown php-fpm:www /run/php-fpm.sock

# by default don't trust X-Real-IP
ENV NGINX_REAL_IP_FROM=0.0.0.0/32
ENV NGINX_CSP=

# Set working directory and expose necessary ports
WORKDIR /app
EXPOSE 80

# Define the entry point
ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]

FROM runtime as dev

RUN apk add --no-cache nodejs npm \
    && rm -rf /var/cache/apk/*
