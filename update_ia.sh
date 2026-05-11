#!/usr/bin/env bash
# update_ia.sh - Sync local repository and submodules with remote ia branch.
#
# Usage:
#   ./update_ia.sh
#   ./update_ia.sh --force-clean
#
# Behavior:
# - Default mode is safe: aborts if there are local changes.
# - --force-clean discards local changes (root + submodules) before syncing.

set -euo pipefail

FORCE_CLEAN=false

for arg in "$@"; do
  case "$arg" in
    --force-clean)
      FORCE_CLEAN=true
      ;;
    -h|--help)
      cat <<'EOF'
Usage: ./update_ia.sh [--force-clean]

Options:
  --force-clean   Discard local changes in root repo and submodules before sync.
  -h, --help      Show this help.
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $arg"
      echo "Use --help for usage."
      exit 1
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if ! command -v git >/dev/null 2>&1; then
  echo "Error: git is not installed or not in PATH."
  exit 1
fi

if [[ ! -d .git ]]; then
  echo "Error: this script must run from the project root (git repository)."
  exit 1
fi

ensure_clean_or_abort() {
  local repo_path="$1"
  if [[ -n "$(git -C "$repo_path" status --porcelain)" ]]; then
    echo "Error: local changes detected in $repo_path"
    echo "Commit/stash changes first, or run with --force-clean."
    exit 1
  fi
}

checkout_ia_branch() {
  local repo_path="$1"

  if git -C "$repo_path" show-ref --verify --quiet refs/heads/ia; then
    git -C "$repo_path" checkout ia >/dev/null
  elif git -C "$repo_path" ls-remote --exit-code --heads origin ia >/dev/null 2>&1; then
    git -C "$repo_path" checkout -b ia origin/ia >/dev/null
  else
    echo "Warning: branch 'ia' not found in origin for $repo_path. Skipping."
    return 1
  fi

  return 0
}

sync_repo_to_ia() {
  local repo_path="$1"

  git -C "$repo_path" fetch origin --prune

  if ! checkout_ia_branch "$repo_path"; then
    return 0
  fi

  if $FORCE_CLEAN; then
    git -C "$repo_path" reset --hard origin/ia
    git -C "$repo_path" clean -fd
  else
    git -C "$repo_path" pull --rebase origin ia
  fi
}

echo "[1/4] Syncing root repository to origin/ia..."
if $FORCE_CLEAN; then
  git reset --hard
  git clean -fd
else
  ensure_clean_or_abort "$SCRIPT_DIR"
fi
sync_repo_to_ia "$SCRIPT_DIR"

echo "[2/4] Initializing and syncing submodule metadata..."
git submodule sync --recursive
git submodule update --init --recursive

echo "[3/4] Syncing submodules to origin/ia when available..."
while IFS= read -r submodule_path; do
  [[ -z "$submodule_path" ]] && continue
  repo="$SCRIPT_DIR/$submodule_path"

  if $FORCE_CLEAN; then
    git -C "$repo" reset --hard
    git -C "$repo" clean -fd
  else
    ensure_clean_or_abort "$repo"
  fi

  sync_repo_to_ia "$repo"
done < <(git submodule foreach --quiet --recursive 'echo "$sm_path"')

echo "[4/4] Final status summary..."
echo "Root repository status:"
git status --short
echo
echo "Submodule status:"
git submodule status --recursive

echo
echo "Done. Local content synced with remote ia (root + submodules where branch ia exists)."