#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"
require_user
[[ "$ROOT" == /srv/dgx-ai ]] || { echo "Install/copy the project into /srv/dgx-ai first." >&2; exit 1; }
[[ ! -e "$ROOT/.env" ]] || { echo ".env already exists; refusing to overwrite an installed system." >&2; exit 1; }

for tool in curl jq openssl python3 git; do
  command -v "$tool" >/dev/null || { echo "Missing tool: $tool" >&2; exit 1; }
done

nvidia-smi
sudo docker info >/dev/null
sudo docker compose version

umask 077
mkdir -p "$ROOT/state" "$ROOT/data/ollama" "$ROOT/data/openwebui"
chmod 700 "$ROOT/state" "$ROOT/data"
sudo chown root:root "$ROOT/data/ollama" "$ROOT/data/openwebui"
sudo chmod 700 "$ROOT/data/ollama" "$ROOT/data/openwebui"

# Qualified source tags for v0.1.0. The installer resolves immutable digests and records them.
OLLAMA_SOURCE="${OLLAMA_SOURCE:-ollama/ollama:0.34.2}"
WEBUI_SOURCE="${WEBUI_SOURCE:-ghcr.io/open-webui/open-webui:v0.11.4}"

for image in "$OLLAMA_SOURCE" "$WEBUI_SOURCE"; do
  sudo docker pull --platform linux/arm64 "$image"
  arch=$(sudo docker image inspect "$image" --format '{{.Architecture}}')
  [[ "$arch" == arm64 ]] || { echo "Non-ARM64 image: $image ($arch)" >&2; exit 1; }
done

ollama_digest=$(sudo docker image inspect "$OLLAMA_SOURCE" --format '{{index .RepoDigests 0}}')
webui_digest=$(sudo docker image inspect "$WEBUI_SOURCE" --format '{{index .RepoDigests 0}}')
[[ "$ollama_digest" == *@sha256:* && "$webui_digest" == *@sha256:* ]] || { echo "Missing container digest." >&2; exit 1; }

sudo docker run --rm --platform linux/arm64 --gpus all --entrypoint nvidia-smi "$ollama_digest"

password=$(openssl rand -hex 24)
secret=$(openssl rand -hex 32)
cat > "$ROOT/.env" <<ENV
OLLAMA_IMAGE=$ollama_digest
WEBUI_IMAGE=$webui_digest
WEBUI_SECRET_KEY=$secret
WEBUI_ADMIN_EMAIL=admin@example.com
WEBUI_ADMIN_PASSWORD=$password
OLLAMA_MAX_LOADED_MODELS=1
ENV

cat > "$ROOT/.bootstrap-password" <<EOF2
Local account: admin@example.com
Initial password: $password
Change this password in Open WebUI, then run scripts/05-clear-bootstrap.sh
EOF2
chmod 600 "$ROOT/.env" "$ROOT/.bootstrap-password"

printf 'UTC=%s\nOLLAMA_SOURCE=%s\nWEBUI_SOURCE=%s\nOLLAMA_DIGEST=%s\nWEBUI_DIGEST=%s\n'   "$(date -u +%FT%TZ)" "$OLLAMA_SOURCE" "$WEBUI_SOURCE" "$ollama_digest" "$webui_digest"   > "$ROOT/state/container-versions.txt"
sudo docker image inspect "$OLLAMA_SOURCE" "$WEBUI_SOURCE" > "$ROOT/state/container-inspect.json"

dc config --quiet
dc up -d ollama
for _ in $(seq 1 60); do
  if curl -fsS --max-time 3 http://127.0.0.1:11434/api/version > "$ROOT/state/ollama-version.json"; then
    echo "Ollama ready."
    exit 0
  fi
  sleep 2
done

echo "Ollama did not become ready. Check: sudo docker compose logs ollama" >&2
exit 1
