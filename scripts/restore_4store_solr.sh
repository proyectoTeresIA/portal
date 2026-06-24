#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROJECT_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)

if [[ -f "$PROJECT_DIR/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$PROJECT_DIR/.env"
  set +a
fi

COMPOSE_FILE=${COMPOSE_FILE:-$PROJECT_DIR/docker-compose.production.yml}
COMPOSE_PROFILE=${COMPOSE_PROFILE:-4store}
BACKUP_DIR=${BACKUP_DIR:-/root/backup_ontoportal}
FOURSTORE_VOLUME=${FOURSTORE_VOLUME:-portal_4store}
SOLR_VOLUME=${SOLR_VOLUME:-portal_solr}

BACKUP_REF=${1:-}
if [[ -z "$BACKUP_REF" ]]; then
  echo "Usage: $0 <backup-timestamp-or-directory>"
  echo "Example: $0 20260623-033000"
  exit 1
fi

if [[ -d "$BACKUP_REF" ]]; then
  SOURCE_DIR=$(cd -- "$BACKUP_REF" && pwd)
else
  SOURCE_DIR="$BACKUP_DIR/$BACKUP_REF"
fi

if [[ ! -f "$SOURCE_DIR/4store.tgz" ]]; then
  echo "Missing backup file: $SOURCE_DIR/4store.tgz"
  exit 1
fi

if [[ ! -f "$SOURCE_DIR/solr.tgz" ]]; then
  echo "Missing backup file: $SOURCE_DIR/solr.tgz"
  exit 1
fi

SERVICES_TO_STOP=(ncbo-cron-worker frontend api 4store-ut solr-ut)
SERVICES_TO_START=(4store-ut solr-ut api frontend ncbo-cron-worker)

restart_services() {
  cd "$PROJECT_DIR"
  docker compose -f "$COMPOSE_FILE" --profile "$COMPOSE_PROFILE" up -d "${SERVICES_TO_START[@]}" >/dev/null
}

trap restart_services EXIT

cd "$PROJECT_DIR"

echo "[restore] stopping services: ${SERVICES_TO_STOP[*]}"
docker compose -f "$COMPOSE_FILE" --profile "$COMPOSE_PROFILE" stop "${SERVICES_TO_STOP[@]}"

echo "[restore] wiping volume $FOURSTORE_VOLUME"
docker run --rm -v "$FOURSTORE_VOLUME:/data" alpine sh -lc 'rm -rf /data/*'

echo "[restore] restoring 4store from $SOURCE_DIR/4store.tgz"
docker run --rm \
  -v "$FOURSTORE_VOLUME:/data" \
  -v "$SOURCE_DIR:/backup:ro" \
  alpine sh -lc 'tar xzf /backup/4store.tgz -C /data'

echo "[restore] wiping volume $SOLR_VOLUME"
docker run --rm -v "$SOLR_VOLUME:/data" alpine sh -lc 'rm -rf /data/*'

echo "[restore] restoring solr from $SOURCE_DIR/solr.tgz"
docker run --rm \
  -v "$SOLR_VOLUME:/data" \
  -v "$SOURCE_DIR:/backup:ro" \
  alpine sh -lc 'tar xzf /backup/solr.tgz -C /data'

echo "[restore] completed from $SOURCE_DIR"