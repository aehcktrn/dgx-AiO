#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"
require_user
require_env

# Re-running this script may resolve upstream tags to newer blobs. Treat model pulls as upgrades.
models=(
  "qwen3-coder:30b-a3b-q4_K_M"
  "huihui_ai/qwen3-coder-abliterated:30b-a3b-instruct-q4_K_M"
  "huihui_ai/qwen3-abliterated:30b-a3b-instruct-2507-q4_K_M"
  "qwen3:30b-a3b-instruct-2507-q4_K_M"
  "bge-m3:latest"
)
for model in "${models[@]}"; do
  echo "==> Pulling $model"
  dc exec -T ollama ollama pull "$model"
done

for profile in cyber-reference cyber-libre discussion-libre internet-reference; do
  dc exec -T ollama ollama create "$profile" -f "/modelfiles/$profile.Modelfile"
done

curl -fsS http://127.0.0.1:11434/api/tags > "$ROOT/state/model-tags.json"
for model in cyber-reference cyber-libre discussion-libre internet-reference; do
  dc exec -T ollama ollama show "$model" > "$ROOT/state/$model-info.txt"
  dc exec -T ollama ollama show --modelfile "$model" > "$ROOT/state/$model-resolved.Modelfile"
done

dc up -d open-webui
echo "Open WebUI started. Continue with scripts/03-comfy.sh."
