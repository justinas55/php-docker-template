#!/bin/bash

set -e -o pipefail

docker-compose exec app-web su -l app
