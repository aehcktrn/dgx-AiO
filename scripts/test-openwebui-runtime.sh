#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"
require_user
require_env

env_dump="$(dc exec -T open-webui env)"
required=(
  'OLLAMA_BASE_URL=http://127.0.0.1:11434'
  'COMFYUI_BASE_URL=http://127.0.0.1:8188'
  'ENABLE_IMAGE_GENERATION=true'
  'ENABLE_WEB_SEARCH=true'
  'ENABLE_OPENAI_API=false'
  'OFFLINE_MODE=true'
)
for entry in "${required[@]}"; do
  grep -Fxq "$entry" <<<"$env_dump" || { echo "[FAIL] Missing Open WebUI runtime setting: $entry" >&2; exit 1; }
done

dc exec -T open-webui python - <<'PY'
import urllib.request
for url in ("http://127.0.0.1:8080/health", "http://127.0.0.1:11434/api/version", "http://127.0.0.1:8188/system_stats"):
    with urllib.request.urlopen(url, timeout=8) as response:
        if response.status != 200: raise SystemExit(f"{url}: HTTP {response.status}")
        print("reachable", url)
PY
echo "openwebui-runtime-ok"
