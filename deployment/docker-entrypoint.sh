#!/bin/sh

set -eo pipefail

[ -f docker-pre-init.sh ] && bash docker-pre-init.sh

echo "Now: "`date -Iseconds`

export NGINX_REAL_IP_FROM=${NGINX_REAL_IP_FROM:-0.0.0.0/32}
export NGINX_ROOT=${NGINX_ROOT:-/app/public}

[ -f /etc/nginx/conf/nginx.conf.template ] && envsubst '$NGINX_CSP $NGINX_REAL_IP_FROM $NGINX_ROOT' < /etc/nginx/conf/nginx.conf.template > /etc/nginx/conf/nginx.conf

[ -f docker-before-start.sh ] && bash docker-before-start.sh

echo "Running command '$@'"

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- php-fpm "$@"
fi

exec "$@"

