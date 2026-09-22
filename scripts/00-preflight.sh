#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"
require_user

fail=0
[[ "$(uname -m)" == aarch64 ]] || { echo "[FAIL] Expected aarch64/ARM64."; fail=1; }
command -v nvidia-smi >/dev/null || { echo "[FAIL] nvidia-smi missing."; fail=1; }
command -v docker >/dev/null || { echo "[FAIL] docker missing."; fail=1; }
sudo docker info >/dev/null 2>&1 || { echo "[FAIL] Docker daemon unavailable."; fail=1; }
sudo docker compose version >/dev/null 2>&1 || { echo "[FAIL] Docker Compose plugin unavailable."; fail=1; }

if command -v nvidia-smi >/dev/null; then
  echo "[OK] GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1 || true)"
fi
mem_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
if [[ -n "${mem_kb:-}" ]]; then
  mem_gib=$((mem_kb / 1024 / 1024))
  echo "[INFO] RAM: ~${mem_gib} GiB"
  (( mem_gib >= 100 )) || echo "[WARN] Less than 100 GiB detected; this profile targets DGX Spark-class memory."
fi

avail_kb=$(df -Pk "${ROOT}" 2>/dev/null | awk 'NR==2 {print $4}' || true)
if [[ -n "${avail_kb:-}" ]]; then
  avail_gib=$((avail_kb / 1024 / 1024))
  echo "[INFO] Free disk at ${ROOT}: ~${avail_gib} GiB"
  (( avail_gib >= 180 )) || echo "[WARN] Less than 180 GiB free; models may exhaust disk space."
fi

(( fail == 0 )) || exit 1
echo "[OK] Preflight passed."
