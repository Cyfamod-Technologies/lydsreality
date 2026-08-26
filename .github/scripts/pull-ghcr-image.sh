#!/usr/bin/env bash
set -euo pipefail

: "${GHCR_TOKEN:?GHCR_TOKEN is required}"
: "${GITHUB_ACTOR:?GITHUB_ACTOR is required}"
: "${IMAGE:?IMAGE is required}"
: "${SSH_HOST:?SSH_HOST is required}"
: "${SSH_PORT:?SSH_PORT is required}"
: "${SSH_USER:?SSH_USER is required}"

ssh_args=(
  -i "$HOME/.ssh/dokploy_deploy_key"
  -p "$SSH_PORT"
  -o BatchMode=yes
  -o IdentitiesOnly=yes
  -o StrictHostKeyChecking=yes
  -o ConnectTimeout=15
)

printf '%s' "$GHCR_TOKEN" | ssh "${ssh_args[@]}" "$SSH_USER@$SSH_HOST" \
  "docker login ghcr.io --username '$GITHUB_ACTOR' --password-stdin"

ssh "${ssh_args[@]}" "$SSH_USER@$SSH_HOST" \
  "docker pull '$IMAGE' && docker image inspect '$IMAGE' >/dev/null"
