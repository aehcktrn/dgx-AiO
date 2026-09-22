#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"
require_user
require_env

tmp="$(mktemp -d "$ROOT/state/backup-test.XXXXXX")"
cleanup() { rm -rf "$tmp"; }
trap cleanup EXIT
bash "$ROOT/scripts/backup.sh" "$tmp"
archive="$(find "$tmp" -maxdepth 1 -type f -name 'dgx-aio-*.tar.gz' -print -quit)"
[[ -n "$archive" ]] || { echo "[FAIL] Backup archive missing." >&2; exit 1; }
[[ -f "$archive.sha256" ]] || { echo "[FAIL] Backup checksum missing." >&2; exit 1; }
( cd "$tmp"; sha256sum -c "$(basename "$archive").sha256" )
listing="$(tar -tzf "$archive")"
required=( '.env' 'compose.yaml' 'VERSION' 'modelfiles/' 'workflows/' 'config/' 'data/openwebui/' )
for item in "${required[@]}"; do
  grep -Fq "$item" <<<"$listing" || { echo "[FAIL] Expected backup entry missing: $item" >&2; exit 1; }
done
echo "backup-integrity-ok"
