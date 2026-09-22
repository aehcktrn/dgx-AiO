#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"
require_user
require_env

out=${1:-$ROOT/backups}
mkdir -p "$out"
stamp=$(date -u +%Y%m%dT%H%M%SZ)
archive="$out/dgx-aio-$stamp.tar.gz"

echo "Stopping Open WebUI briefly for a consistent SQLite backup..."
dc stop open-webui >/dev/null
trap 'dc up -d open-webui >/dev/null 2>&1 || true' EXIT

tar -C "$ROOT" -czf "$archive"   .env   compose.yaml   VERSION   modelfiles   workflows   config   state   data/openwebui

sha256sum "$archive" > "$archive.sha256"
echo "Backup: $archive"
echo "Models and ComfyUI weights are intentionally excluded; use a full filesystem backup if offline restoration is required."
