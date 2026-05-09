#!/usr/bin/env bash
# teresia.sh — Daily operations script for the TeresIA portal (ia branch)
# Usage: ./teresia.sh [start|stop|restart|logs|status|update]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

usage() {
  echo "Usage: $0 {start|stop|restart|logs|status|update}"
  echo ""
  echo "  start    Start all services (docker compose up -d)"
  echo "  stop     Stop all services (docker compose down)"
  echo "  restart  Restart all services"
  echo "  logs     Follow logs for all services (Ctrl+C to stop)"
  echo "  status   Show status of all services"
  echo "  update   Pull latest changes (ia branch) and rebuild"
  exit 1
}

case "${1:-}" in
  start)
    echo "▶ Starting TeresIA portal..."
    docker compose up -d
    echo "✓ Services started. Portal available at http://localhost/teresia-portal/"
    ;;

  stop)
    echo "■ Stopping TeresIA portal..."
    docker compose down
    echo "✓ Services stopped."
    ;;

  restart)
    echo "↺ Restarting TeresIA portal..."
    docker compose down
    docker compose up -d
    echo "✓ Services restarted. Portal available at http://localhost/teresia-portal/"
    ;;

  logs)
    echo "📋 Following logs (Ctrl+C to stop)..."
    docker compose logs -f
    ;;

  status)
    echo "ℹ Status of TeresIA services:"
    docker compose ps
    ;;

  update)
    echo "⬇ Updating TeresIA portal from ia branch..."

    # Update portal repo
    git fetch origin
    git checkout ia
    git pull origin ia

    # Update submodules to latest ia branch
    git submodule update --remote --merge

    # Rebuild and restart containers
    echo "🔨 Rebuilding containers..."
    docker compose up -d --build

    echo "✓ Update complete. Portal available at http://localhost/teresia-portal/"
    ;;

  *)
    usage
    ;;
esac
