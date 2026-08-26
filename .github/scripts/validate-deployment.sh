#!/usr/bin/env bash
set -euo pipefail

: "${DOKPLOY_COMPOSE_ID:?Set the DOKPLOY_COMPOSE_ID repository variable}"
: "${DOKPLOY_COMPOSE_NAME:?Set the DOKPLOY_COMPOSE_NAME repository variable}"
: "${SERVER_ENV_FILE:?Set the SERVER_ENV_FILE repository variable}"
: "${DOKPLOY_API_KEY:?Set the DOKPLOY_API_KEY repository secret}"
: "${SSH_HOST:?Set the SSH_HOST repository secret}"
: "${SSH_PRIVATE_KEY:?Set the SSH_PRIVATE_KEY repository secret}"
: "${SSH_USER:?Set the SSH_USER repository secret}"
: "${COMPOSE_FILE:?COMPOSE_FILE is required}"
: "${SSH_PORT:?SSH_PORT is required}"

test -f "$COMPOSE_FILE"
[[ "$DOKPLOY_COMPOSE_ID" =~ ^[A-Za-z0-9_-]+$ ]]
[[ "$DOKPLOY_COMPOSE_NAME" =~ ^[A-Za-z0-9._-]+$ ]]
[[ "$SERVER_ENV_FILE" =~ ^/[A-Za-z0-9._/-]+$ ]]
[[ "$SSH_PORT" =~ ^[0-9]+$ ]]
