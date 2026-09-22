#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"
require_user

errors=0
check() {
  local label=$1; shift
  if "$@" >/dev/null 2>&1; then printf '[OK]   %s\n' "$label"; else printf '[FAIL] %s\n' "$label"; errors=$((errors+1)); fi
}

echo "dgx-AiO doctor"
echo "=============="
check "ARM64 host" bash -c '[[ "$(uname -m)" == aarch64 ]]'
check "NVIDIA GPU" nvidia-smi
check "Docker" sudo docker info
check "Ollama API" curl -fsS --max-time 4 http://127.0.0.1:11434/api/version
check "Open WebUI" curl -fsS --max-time 4 http://127.0.0.1:8080/health
check "ComfyUI API" curl -fsS --max-time 4 http://127.0.0.1:8188/system_stats
check "ComfyUI service" systemctl is-active --quiet dgx-comfy.service
check "Z-Image files" bash -c 'test -s /srv/dgx-ai/comfy/ComfyUI/models/diffusion_models/z_image_turbo_bf16.safetensors && test -s /srv/dgx-ai/comfy/ComfyUI/models/text_encoders/qwen_3_4b.safetensors && test -s /srv/dgx-ai/comfy/ComfyUI/models/vae/ae.safetensors'

if [[ -f "$ROOT/.env" ]]; then
  echo
  echo "Models:"
  dc exec -T ollama ollama list || errors=$((errors+1))
fi

echo
if (( errors == 0 )); then
  echo "Core stack healthy."
else
  echo "$errors core check(s) failed. Run scripts/diagnostics.sh and read docs/TROUBLESHOOTING.md."
  exit 1
fi
