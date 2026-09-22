#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
  echo "Run this installer as your normal admin user, not with sudo bash." >&2
  exit 1
fi

SRC="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TARGET=/srv/dgx-ai

echo "dgx-AiO $(cat "$SRC/VERSION")"
echo "Target: $TARGET"

sudo apt-get update
sudo apt-get install -y --no-remove \
  ca-certificates curl git jq openssl python3 python3-venv python3-dev \
  build-essential tar

if [[ "$SRC" != "$TARGET" ]]; then
  sudo install -d -m 755 -o "$(id -u)" -g "$(id -g)" "$TARGET"
  tar --exclude='.git' --exclude='data' --exclude='state' --exclude='comfy' \
      -C "$SRC" -cf - . | tar -C "$TARGET" -xf -
fi

cd "$TARGET"
bash scripts/00-preflight.sh
bash scripts/01-prepare.sh
bash scripts/02-models.sh
bash scripts/03-comfy.sh
bash scripts/04-postinstall.sh

echo
echo "Installation core complete."
echo "Read: $TARGET/docs/OPENWEBUI.md"
echo "Run:  cd $TARGET && bash scripts/doctor.sh"
