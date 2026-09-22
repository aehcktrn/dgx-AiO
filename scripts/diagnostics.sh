#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"
require_user

echo "== System =="
uname -a
free -h || true
df -h "$ROOT" || true
nvidia-smi || true

echo "== Listening ports =="
sudo ss -lntp | grep -E ':(8080|8188|11434)\b' || true

echo "== Docker services =="
if [[ -f "$ROOT/.env" ]]; then dc ps; else echo ".env missing"; fi

echo "== ComfyUI =="
systemctl --no-pager --full status dgx-comfy.service 2>/dev/null || true

echo "== APIs =="
for url in http://127.0.0.1:11434/api/version http://127.0.0.1:8080/health http://127.0.0.1:8188/system_stats; do
  printf '%-48s ' "$url"
  if curl -fsS --max-time 4 "$url" >/dev/null; then echo OK; else echo FAIL; fi
done

echo "== Ollama resident models =="
if [[ -f "$ROOT/.env" ]]; then dc exec -T ollama ollama ps || true; fi
