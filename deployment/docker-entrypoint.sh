#!/bin/sh

set -eo pipefail

phpfpm_set() {
	ESCAPED_VALUE=$(printf '%s\n' "$2" | sed -e 's/\([.\/]\)/\\\1/g')
	conffile=/usr/local/etc/php-fpm.d/zz-docker.conf
	if grep -e "^;\?$1\\s*=" $conffile; then
		sed -i -e "s/^;\?\($1\\s*=\).*/\\1 $ESCAPED_VALUE/g" $conffile
	else
		echo "$1 = $2" >>$conffile
	fi
}

# Change user/group IDs without touching file permissions
sed -i "s/^\(app:[^:]*\):[0-9]*:[0-9]*:\(.*\)$/\\1:$DOCKER_USER_ID:$DOCKER_GROUP_ID:\\2/" /etc/passwd
sed -i "s/^\(app:[^:]*\):[0-9]*:\(.*\)$/\\1:$DOCKER_GROUP_ID:\\2/" /etc/group

#usermod -u $DOCKER_USER_ID -g $DOCKER_GROUP_ID app
touch /run/php-fpm.sock
chmod 660 /run/php-fpm.sock
chown app:app /run/php-fpm.sock
chmod +x /docker-entrypoint.sh

phpfpm_set listen /run/php-fpm.sock
phpfpm_set listen.owner app
phpfpm_set listen.group app
phpfpm_set user app
phpfpm_set group app

echo "Running as user app:app [$DOCKER_USER_ID:$DOCKER_GROUP_ID]"

[ -f docker-pre-init.sh ] && bash docker-pre-init.sh

echo "Now: "$(date -Iseconds)

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

