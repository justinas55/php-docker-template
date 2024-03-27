# Dockerized PHP project template tuned for Laravel

Idea? Start developing PHP projects on any PC or environment with Docker without setting up any dependiencies like PHP, NodeJS, Composer and so on.

## Requirements 
- Linux shell
- docker and docker-compose 

## How to use

- `docker-compose up -d shell` - will build environment image with PHP, Composer, NodeJS built-in and start a 'dummy' service
- `./shell.sh` - will open shell inside this 'dummy' service with current folder mapped to /app
- For Laravel, just follow official guide and run commands inside the shell.
