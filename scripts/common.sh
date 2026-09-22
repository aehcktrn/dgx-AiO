#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
require_user() {
  if [[ "$EUID" -eq 0 ]]; then
    echo "Run this script from the normal admin account, without sudo before bash." >&2
    exit 1
  fi
}
dc() {
  sudo docker compose --project-directory "$ROOT" --env-file "$ROOT/.env" -f "$ROOT/compose.yaml" "$@"
}
require_env() {
  [[ -f "$ROOT/.env" ]] || { echo "Run scripts/01-prepare.sh first." >&2; exit 1; }
}
