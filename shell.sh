#!/bin/bash

set -e -o pipefail

imagetag=$(basename $(pwd))-dev-shell
echo Image tag: $imagetag
docker build -t $imagetag -f deployment/Dockerfile --target dev .
docker run -it -v $(pwd):/app -w /app -e HOME=/app $imagetag sh