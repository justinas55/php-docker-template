#!/bin/bash

set -e -o pipefail

if [ -n "$1" ]; then
    ESCAPED_ARGS=$(printf "%q " "$@")
    echo "$ESCAPED_ARGS"
    docker-compose exec shell su -l app -c "$ESCAPED_ARGS"
else
    docker-compose exec shell su -l app
fi
