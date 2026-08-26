#!/usr/bin/env bash
set -euo pipefail

: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
: "${GITHUB_SHA:?GITHUB_SHA is required}"
: "${GITHUB_ENV:?GITHUB_ENV is required}"
: "${RUNNER_TEMP:?RUNNER_TEMP is required}"
: "${COMPOSE_FILE:?COMPOSE_FILE is required}"

image_repository="ghcr.io/${GITHUB_REPOSITORY,,}"
image="${image_repository}:sha-${GITHUB_SHA}"
deploy_compose="$RUNNER_TEMP/docker-compose.dokploy.yml"

python3 - "$COMPOSE_FILE" "$deploy_compose" "$image" <<'PY'
import sys

source, destination, image = sys.argv[1:]
marker = "${APP_IMAGE:?APP_IMAGE is required}"

with open(source, encoding="utf-8") as file:
    compose = file.read()

if compose.count(marker) != 1:
    raise SystemExit("Expected exactly one APP_IMAGE marker")

with open(destination, "w", encoding="utf-8") as file:
    file.write(compose.replace(marker, image))
PY

APP_KEY=compose-validation-only \
APP_URL=https://example.invalid \
DB_DATABASE=compose_validation \
DB_USERNAME=compose_validation \
DB_PASSWORD=compose-validation-only \
  docker compose --file "$deploy_compose" config --quiet

if grep --fixed-strings 'build:' "$deploy_compose"; then
  echo "::error::The Dokploy Compose file must not contain build directives."
  exit 1
fi

{
  echo "IMAGE_REPOSITORY=$image_repository"
  echo "IMAGE=$image"
  echo "DEPLOY_COMPOSE=$deploy_compose"
} >> "$GITHUB_ENV"
