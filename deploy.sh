#!/usr/bin/env bash
set -euxo pipefail

export COMPOSE_BAKE=true
export DOCKER_HOST="ssh://admin@truenas.usagi.zone"
export OUT_DIR="/mnt/zpool0/box/Public/shamiradio/"

docker compose up --build -d --force-recreate
