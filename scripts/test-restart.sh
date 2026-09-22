#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"
require_user
require_env

wait_url() {
  local name="$1" url="$2"
  for _ in $(seq 1 90); do
    if curl -fsS --max-time 4 "$url" >/dev/null 2>&1; then echo "[OK] $name recovered"; return 0; fi
    sleep 2
  done
  echo "[FAIL] $name did not recover: $url" >&2
  return 1
}

echo "Restarting local AI services..."
dc restart ollama open-webui
sudo systemctl restart dgx-comfy.service
wait_url "Ollama" "http://127.0.0.1:11434/api/version"
wait_url "Open WebUI" "http://127.0.0.1:8080/health"
wait_url "ComfyUI" "http://127.0.0.1:8188/system_stats"
bash "$ROOT/scripts/test-network-bindings.sh"
echo "restart-persistence-ok"
