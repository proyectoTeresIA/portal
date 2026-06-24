#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROJECT_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)

load_dotenv_file() {
  local dotenv_file="$1"
  local line key value

  [[ -f "$dotenv_file" ]] || return 0

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    [[ -z "${line//[[:space:]]/}" ]] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue

    if [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=(.*)$ ]]; then
      key="${BASH_REMATCH[1]}"
      value="${BASH_REMATCH[2]}"

      # Trim outer whitespace.
      value="${value#"${value%%[![:space:]]*}"}"
      value="${value%"${value##*[![:space:]]}"}"

      # Drop inline comments of the form: VALUE # comment
      value="${value%%[[:space:]]#*}"

      # Unquote simple single/double-quoted values.
      if [[ "$value" =~ ^\"(.*)\"$ ]]; then
        value="${BASH_REMATCH[1]}"
      elif [[ "$value" =~ ^\'(.*)\'$ ]]; then
        value="${BASH_REMATCH[1]}"
      fi

      export "$key=$value"
    fi
  done < "$dotenv_file"
}

load_dotenv_file "$PROJECT_DIR/.env"

COMPOSE_FILE=${COMPOSE_FILE:-$PROJECT_DIR/docker-compose.production.yml}
COMPOSE_PROFILE=${COMPOSE_PROFILE:-4store}
BACKUP_DIR=${BACKUP_DIR:-/root/backup_ontoportal}
BACKUP_RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-15}
BACKUP_RETENTION_COUNT=${BACKUP_RETENTION_COUNT:-0}
FOURSTORE_VOLUME=${FOURSTORE_VOLUME:-portal_4store}
SOLR_VOLUME=${SOLR_VOLUME:-portal_solr}
IDLE_WINDOW_MINUTES=${IDLE_WINDOW_MINUTES:-5}
ALLOW_BUSY_WORKER=${ALLOW_BUSY_WORKER:-false}

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
TARGET_DIR="$BACKUP_DIR/$TIMESTAMP"

SERVICES_TO_STOP=(ncbo-cron-worker frontend api 4store-ut solr-ut)
SERVICES_TO_START=(4store-ut solr-ut api frontend ncbo-cron-worker)

check_worker_idle() {
  if [[ "$ALLOW_BUSY_WORKER" == "true" ]]; then
    echo "[backup] skipping worker-idle check because ALLOW_BUSY_WORKER=true"
    return 0
  fi

  IDLE_WINDOW_MINUTES="$IDLE_WINDOW_MINUTES" \
    "$SCRIPT_DIR/check_ncbo_cron_idle.sh"
}

prune_old_backups() {
  local backup_count="${BACKUP_RETENTION_COUNT:-0}"

  if [[ "$backup_count" =~ ^[0-9]+$ ]] && (( backup_count > 0 )); then
    echo "[backup] pruning by count, keeping latest $backup_count backups"
    mapfile -t backup_dirs < <(find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
    local total=${#backup_dirs[@]}

    if (( total > backup_count )); then
      local to_delete=$((total - backup_count))
      for ((i = 0; i < to_delete; i++)); do
        rm -rf "$BACKUP_DIR/${backup_dirs[$i]}"
      done
    fi
    return 0
  fi

  echo "[backup] pruning backups older than $BACKUP_RETENTION_DAYS days"
  find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d -mtime +"$BACKUP_RETENTION_DAYS" -exec rm -rf {} +
}

mkdir -p "$TARGET_DIR"

restart_services() {
  cd "$PROJECT_DIR"
  docker compose -f "$COMPOSE_FILE" --profile "$COMPOSE_PROFILE" up -d "${SERVICES_TO_START[@]}" >/dev/null
}

trap restart_services EXIT

cd "$PROJECT_DIR"

echo "[backup] checking ncbo-cron-worker idleness (window: ${IDLE_WINDOW_MINUTES}m)"
check_worker_idle

echo "[backup] stopping services: ${SERVICES_TO_STOP[*]}"
docker compose -f "$COMPOSE_FILE" --profile "$COMPOSE_PROFILE" stop "${SERVICES_TO_STOP[@]}"

echo "[backup] archiving 4store volume $FOURSTORE_VOLUME"
docker run --rm \
  -v "$FOURSTORE_VOLUME:/data:ro" \
  -v "$TARGET_DIR:/backup" \
  alpine sh -lc 'tar czf /backup/4store.tgz -C /data .'

echo "[backup] archiving solr volume $SOLR_VOLUME"
docker run --rm \
  -v "$SOLR_VOLUME:/data:ro" \
  -v "$TARGET_DIR:/backup" \
  alpine sh -lc 'tar czf /backup/solr.tgz -C /data .'

cat > "$TARGET_DIR/manifest.txt" <<EOF
timestamp=$TIMESTAMP
compose_file=$COMPOSE_FILE
compose_profile=$COMPOSE_PROFILE
project_dir=$PROJECT_DIR
4store_volume=$FOURSTORE_VOLUME
solr_volume=$SOLR_VOLUME
retention_days=$BACKUP_RETENTION_DAYS
retention_count=$BACKUP_RETENTION_COUNT
idle_window_minutes=$IDLE_WINDOW_MINUTES
allow_busy_worker=$ALLOW_BUSY_WORKER
EOF

prune_old_backups

echo "[backup] completed: $TARGET_DIR"