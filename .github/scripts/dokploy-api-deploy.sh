#!/usr/bin/env bash
set -Eeuo pipefail

: "${API_KEY_B64:?API_KEY_B64 is required}"
: "${DOKPLOY_COMPOSE_ID:?DOKPLOY_COMPOSE_ID is required}"
: "${DOKPLOY_COMPOSE_NAME:?DOKPLOY_COMPOSE_NAME is required}"
: "${DOKPLOY_URL:?DOKPLOY_URL is required}"
: "${REMOTE_COMPOSE:?REMOTE_COMPOSE is required}"
: "${REMOTE_SCRIPT:?REMOTE_SCRIPT is required}"
: "${SERVER_ENV_FILE:?SERVER_ENV_FILE is required}"

DOKPLOY_API_KEY=$(printf '%s' "$API_KEY_B64" | base64 --decode)
unset API_KEY_B64
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"; rm -f "$REMOTE_COMPOSE" "$REMOTE_SCRIPT"' EXIT

test -s "$REMOTE_COMPOSE"
test -s "$SERVER_ENV_FILE"

api_get() {
  local endpoint="$1" output="$2" code
  shift 2
  code=$(curl --silent --show-error --connect-timeout 10 --max-time 180 \
    --output "$output" --write-out '%{http_code}' --get "${DOKPLOY_URL}/api/${endpoint}" \
    --header "x-api-key: ${DOKPLOY_API_KEY}" "$@")
  [[ "$code" =~ ^2[0-9][0-9]$ ]] || {
    echo "Dokploy GET failed: $endpoint ($code)"
    test ! -s "$output" || cat "$output"
    return 1
  }
}

api_post() {
  local endpoint="$1" payload="$2" output="$3" code
  code=$(curl --silent --show-error --connect-timeout 10 --max-time 240 \
    --output "$output" --write-out '%{http_code}' --request POST "${DOKPLOY_URL}/api/${endpoint}" \
    --header "x-api-key: ${DOKPLOY_API_KEY}" --header 'Content-Type: application/json' \
    --data-binary "@$payload")
  [[ "$code" =~ ^2[0-9][0-9]$ ]] || {
    echo "Dokploy POST failed: $endpoint ($code)"
    test ! -s "$output" || cat "$output"
    return 1
  }
}

deployment_items() {
  python3 - "$1" "$2" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as file:
    value = json.load(file)

if isinstance(value, dict):
    value = next(
        (value[key] for key in ("deployments", "data", "items", "results")
         if isinstance(value.get(key), list)),
        [],
    )
if not isinstance(value, list):
    value = []

mode = sys.argv[2]
if mode == "before":
    ids = ",".join(
        str(item.get("deploymentId") or item.get("id"))
        for item in value
        if item.get("deploymentId") or item.get("id")
    )
    successful = {"done", "success", "successful", "completed"}
    has_success = any(
        str(item.get("status") or item.get("deploymentStatus") or item.get("state") or "").lower()
        in successful
        for item in value
    )
    print(("compose.redeploy" if has_success else "compose.deploy") + "|" + ids)
elif mode.startswith("new:"):
    excluded = set(filter(None, mode.removeprefix("new:").split(",")))
    items = [
        item for item in value
        if str(item.get("deploymentId") or item.get("id") or "") not in excluded
    ]
    items.sort(
        key=lambda item: str(item.get("createdAt") or item.get("updatedAt") or ""),
        reverse=True,
    )
    print(str(items[0].get("deploymentId") or items[0].get("id")) if items else "")
elif mode.startswith("status:"):
    target = mode.removeprefix("status:")
    item = next(
        (item for item in value
         if str(item.get("deploymentId") or item.get("id") or "") == target),
        {},
    )
    print(str(item.get("status") or item.get("deploymentStatus") or item.get("state") or "unknown").lower())
else:
    raise SystemExit(f"Unknown deployment parser mode: {mode}")
PY
}

update_json="$tmp_dir/update.json"
action_json="$tmp_dir/action.json"
response_json="$tmp_dir/response.json"
deployments_json="$tmp_dir/deployments.json"
export DOKPLOY_COMPOSE_ID DOKPLOY_COMPOSE_NAME SERVER_ENV_FILE REMOTE_COMPOSE
export update_json action_json

python3 - <<'PY'
import json
import os

with open(os.environ["REMOTE_COMPOSE"], encoding="utf-8") as file:
    compose = file.read()
with open(os.environ["SERVER_ENV_FILE"], encoding="utf-8-sig") as file:
    environment = file.read()

with open(os.environ["update_json"], "w", encoding="utf-8") as file:
    json.dump({
        "composeId": os.environ["DOKPLOY_COMPOSE_ID"],
        "sourceType": "raw",
        "composeType": "docker-compose",
        "composeFile": compose,
        "composePath": "./docker-compose.yml",
        "env": environment,
        "autoDeploy": False,
        "createEnvFile": True,
    }, file)

with open(os.environ["action_json"], "w", encoding="utf-8") as file:
    json.dump({
        "composeId": os.environ["DOKPLOY_COMPOSE_ID"],
        "title": "GitHub Actions deployment",
        "description": f"Deploy {os.environ['DOKPLOY_COMPOSE_NAME']} from GHCR",
    }, file)
PY

api_post compose.update "$update_json" "$response_json"
api_get compose.getConvertedCompose "$response_json" \
  --data-urlencode "composeId=${DOKPLOY_COMPOSE_ID}"
api_get deployment.allByCompose "$deployments_json" \
  --data-urlencode "composeId=${DOKPLOY_COMPOSE_ID}"

before_data=$(deployment_items "$deployments_json" before)
action="${before_data%%|*}"
before_ids="${before_data#*|}"
api_post "$action" "$action_json" "$response_json"

new_deployment_id=""
for attempt in $(seq 1 30); do
  sleep 4
  api_get deployment.allByCompose "$deployments_json" \
    --data-urlencode "composeId=${DOKPLOY_COMPOSE_ID}"
  new_deployment_id=$(deployment_items "$deployments_json" "new:$before_ids")
  test -z "$new_deployment_id" || break
  echo "Waiting for a new Dokploy deployment record (${attempt}/30)."
done

test -n "$new_deployment_id" || {
  echo "Dokploy did not create a deployment record."
  exit 1
}

for attempt in $(seq 1 180); do
  sleep 5
  api_get deployment.allByCompose "$deployments_json" \
    --data-urlencode "composeId=${DOKPLOY_COMPOSE_ID}"
  status=$(deployment_items "$deployments_json" "status:$new_deployment_id")
  echo "Dokploy deployment status: $status"
  case "$status" in
    done|success|successful|completed) exit 0 ;;
    error|failed|failure|cancelled|canceled) exit 1 ;;
  esac
done

echo "Dokploy deployment timed out."
exit 1
