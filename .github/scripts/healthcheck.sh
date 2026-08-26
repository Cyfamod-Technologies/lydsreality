#!/usr/bin/env bash
set -euo pipefail

: "${HEALTHCHECK_URL:?HEALTHCHECK_URL is required}"

for attempt in $(seq 1 30); do
  if curl --fail --silent --show-error --location --max-time 15 "$HEALTHCHECK_URL" >/dev/null; then
    echo "Health check passed: $HEALTHCHECK_URL"
    exit 0
  fi

  echo "Health check attempt ${attempt}/30 failed."
  sleep 10
done

echo "Health check failed: $HEALTHCHECK_URL"
exit 1
