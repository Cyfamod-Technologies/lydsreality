#!/usr/bin/env bash
set -euo pipefail

: "${SSH_HOST:?SSH_HOST is required}"
: "${SSH_PRIVATE_KEY:?SSH_PRIVATE_KEY is required}"
: "${SSH_PORT:?SSH_PORT is required}"

install -d -m 700 "$HOME/.ssh"
key_file="$HOME/.ssh/dokploy_deploy_key"

if [[ "$SSH_PRIVATE_KEY" == *"PRIVATE KEY-----"* ]]; then
  printf '%s\n' "${SSH_PRIVATE_KEY//\\n/$'\n'}" | tr -d '\r' > "$key_file"
elif ! printf '%s' "$SSH_PRIVATE_KEY" | base64 --decode > "$key_file" 2>/dev/null; then
  echo "::error::SSH_PRIVATE_KEY is neither a private key nor a base64-encoded private key."
  exit 1
fi

chmod 600 "$key_file"
ssh-keygen -y -P '' -f "$key_file" >/dev/null
ssh-keyscan -T 15 -p "$SSH_PORT" -H "$SSH_HOST" > "$HOME/.ssh/known_hosts"
chmod 600 "$HOME/.ssh/known_hosts"
