#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"
require_user
require_env

echo "Running core smoke tests..."
python3 "$ROOT/scripts/test-chat.py" --model cyber-reference
python3 "$ROOT/scripts/test-chat.py" --model discussion-libre
bash "$ROOT/scripts/test-web-egress.sh"

echo
cat "$ROOT/.bootstrap-password"
echo
echo "Open WebUI is bound to localhost. From your workstation, use:"
echo "  ssh -L 8080:127.0.0.1:8080 USER@SPARK_IP"
echo "Then open: http://127.0.0.1:8080"
echo
echo "Configure the documented Workspace presets using docs/OPENWEBUI.md."
