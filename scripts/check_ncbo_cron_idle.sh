#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROJECT_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)

COMPOSE_FILE=${COMPOSE_FILE:-$PROJECT_DIR/docker-compose.production.yml}
COMPOSE_PROFILE=${COMPOSE_PROFILE:-4store}
IDLE_WINDOW_MINUTES=${IDLE_WINDOW_MINUTES:-5}

ACTIVE_PATTERNS='Extracting metadata from the ontology submission|Processing ontology submission|queue_submission|Requeued stale UPLOADED submission|Completed rebuilding|There is a total of [1-9][0-9]* ontologies to process|There is a total of [1-9][0-9]* submissions to process'

logs=$(cd "$PROJECT_DIR" && docker compose -f "$COMPOSE_FILE" --profile "$COMPOSE_PROFILE" logs --since "${IDLE_WINDOW_MINUTES}m" ncbo-cron-worker 2>/dev/null || true)

if [[ -z "$logs" ]]; then
  echo "[idle-check] ncbo-cron-worker has no recent logs in the last ${IDLE_WINDOW_MINUTES}m; treating as idle"
  exit 0
fi

if grep -Eq "$ACTIVE_PATTERNS" <<<"$logs"; then
  echo "[idle-check] ncbo-cron-worker appears busy in the last ${IDLE_WINDOW_MINUTES}m"
  exit 1
fi

echo "[idle-check] ncbo-cron-worker appears idle in the last ${IDLE_WINDOW_MINUTES}m"