#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"
require_user
[[ "$ROOT" == /srv/dgx-ai ]] || { echo "Service paths target /srv/dgx-ai." >&2; exit 1; }
[[ "$(uname -m)" == aarch64 ]] || { echo "ARM64 expected." >&2; exit 1; }

C="$ROOT/comfy"
[[ ! -e "$C/ComfyUI" && ! -e "$C/venv" ]] || {
  echo "ComfyUI/venv already exists; refusing to install over an existing environment." >&2
  echo "Use scripts/doctor.sh and docs/TROUBLESHOOTING.md for recovery." >&2
  exit 1
}

# Triton compiles a small CUDA helper locally; compiler + Python headers are required.
sudo apt-get update
sudo apt-get install -y --no-remove build-essential python3-dev python3-venv

if ! id dgx-comfy >/dev/null 2>&1; then
  sudo useradd --system --user-group --home-dir "$C" --shell /usr/sbin/nologin dgx-comfy
else
  [[ "$(getent passwd dgx-comfy | cut -d: -f6)" == "$C" ]] || { echo "dgx-comfy exists with another home." >&2; exit 1; }
fi
sudo install -d -o dgx-comfy -g dgx-comfy -m 750 "$C" "$C/.cache"
runcomfy() { sudo -u dgx-comfy env HOME="$C" "$@"; }

runcomfy git clone --depth 1 --branch v0.33.2 https://github.com/Comfy-Org/ComfyUI.git "$C/ComfyUI"
runcomfy python3 -m venv "$C/venv"
runcomfy "$C/venv/bin/python" -m pip install --upgrade pip
runcomfy "$C/venv/bin/python" -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu130
runcomfy "$C/venv/bin/python" -c "import importlib.metadata as m,pathlib;pathlib.Path('$C/torch-constraints.txt').write_text(''.join(n+'=='+m.version(n)+'\\n' for n in ('torch','torchvision','torchaudio')))"
runcomfy "$C/venv/bin/python" -m pip install -c "$C/torch-constraints.txt" -r "$C/ComfyUI/requirements.txt"

set +e
pip_check=$(runcomfy "$C/venv/bin/python" -m pip check 2>&1)
pip_rc=$?
set -e
if (( pip_rc != 0 )); then
  filtered=$(printf '%s\n' "$pip_check" | grep -v -E '^nvidia-cusparselt-cu13 0\.8\.1 is not supported on this platform$' || true)
  if [[ -n "$filtered" ]]; then
    printf '%s\n' "$pip_check" >&2
    echo "pip check failed with an unqualified dependency error." >&2
    exit 1
  fi
  echo "[WARN] Ignoring the known nvidia-cusparselt-cu13 0.8.1 ARM64/SBSA metadata warning only."
  printf '%s\n' "$pip_check" > "$ROOT/state/comfy-pip-check-warning.txt"
fi

runcomfy "$C/venv/bin/python" "$ROOT/scripts/check_torch.py" | tee "$ROOT/state/torch-check.json"
runcomfy "$C/venv/bin/python" "$ROOT/scripts/check_triton.py" | tee "$ROOT/state/triton-check.json"
runcomfy "$C/venv/bin/python" -m pip freeze > "$ROOT/state/comfy-pip-freeze.txt"
runcomfy git -C "$C/ComfyUI" rev-parse HEAD > "$ROOT/state/comfy-commit.txt"
runcomfy "$C/venv/bin/python" "$ROOT/scripts/download_image_models.py" "$C"
sudo cp "$C/image-models.json" "$ROOT/state/image-models.json"
sudo chown "$(id -u):$(id -g)" "$ROOT/state/image-models.json"

sudo install -m 644 "$ROOT/docs/dgx-comfy.service" /etc/systemd/system/dgx-comfy.service
sudo systemctl daemon-reload
sudo systemctl enable --now dgx-comfy.service

for _ in $(seq 1 90); do
  if curl -fsS --max-time 3 http://127.0.0.1:8188/system_stats > "$ROOT/state/comfy-system-stats.json"; then
    echo "ComfyUI ready. Running image smoke test..."
    python3 "$ROOT/scripts/test-image.py"
    exit 0
  fi
  sleep 2
done

echo "ComfyUI not ready. Check: sudo journalctl -u dgx-comfy -n 100 --no-pager" >&2
exit 1
