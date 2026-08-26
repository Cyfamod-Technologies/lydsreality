#!/usr/bin/env bash
set -euo pipefail

: "${DEPLOY_COMPOSE:?DEPLOY_COMPOSE is required}"
: "${DOKPLOY_API_KEY:?DOKPLOY_API_KEY is required}"
: "${DOKPLOY_COMPOSE_ID:?DOKPLOY_COMPOSE_ID is required}"
: "${DOKPLOY_COMPOSE_NAME:?DOKPLOY_COMPOSE_NAME is required}"
: "${DOKPLOY_URL:?DOKPLOY_URL is required}"
: "${GITHUB_RUN_ATTEMPT:?GITHUB_RUN_ATTEMPT is required}"
: "${GITHUB_RUN_ID:?GITHUB_RUN_ID is required}"
: "${SERVER_ENV_FILE:?SERVER_ENV_FILE is required}"
: "${SSH_HOST:?SSH_HOST is required}"
: "${SSH_PORT:?SSH_PORT is required}"
: "${SSH_USER:?SSH_USER is required}"

key_file="$HOME/.ssh/dokploy_deploy_key"
remote_compose="/tmp/lydsreality-compose-${GITHUB_RUN_ID}-${GITHUB_RUN_ATTEMPT}.yml"
remote_script="/tmp/lydsreality-deploy-${GITHUB_RUN_ID}-${GITHUB_RUN_ATTEMPT}.sh"
ssh_args=(
  -i "$key_file"
  -p "$SSH_PORT"
  -o BatchMode=yes
  -o IdentitiesOnly=yes
  -o StrictHostKeyChecking=yes
)

scp -i "$key_file" -P "$SSH_PORT" \
  -o BatchMode=yes -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes \
  "$DEPLOY_COMPOSE" "$SSH_USER@$SSH_HOST:$remote_compose"

scp -i "$key_file" -P "$SSH_PORT" \
  -o BatchMode=yes -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes \
  .github/scripts/dokploy-api-deploy.sh "$SSH_USER@$SSH_HOST:$remote_script"

api_key_b64=$(printf '%s' "$DOKPLOY_API_KEY" | base64 | tr -d '\n')
echo "::add-mask::$api_key_b64"

ssh "${ssh_args[@]}" "$SSH_USER@$SSH_HOST" \
  "API_KEY_B64='$api_key_b64' DOKPLOY_COMPOSE_ID='$DOKPLOY_COMPOSE_ID' \
   DOKPLOY_COMPOSE_NAME='$DOKPLOY_COMPOSE_NAME' DOKPLOY_URL='$DOKPLOY_URL' \
   SERVER_ENV_FILE='$SERVER_ENV_FILE' REMOTE_COMPOSE='$remote_compose' \
   REMOTE_SCRIPT='$remote_script' bash '$remote_script'"
