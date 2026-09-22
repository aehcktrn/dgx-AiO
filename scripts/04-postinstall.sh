#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"
require_user
require_env

echo "Running automated standard verification..."
bash "$ROOT/scripts/verify.sh"

echo
cat "$ROOT/.bootstrap-password"
echo
echo "Open WebUI is bound to localhost. From your workstation, use:"
echo "  ssh -L 8080:127.0.0.1:8080 USER@SPARK_IP"
echo "Then open: http://127.0.0.1:8080"
echo
echo "Configure the documented Workspace presets using docs/OPENWEBUI.md."
echo "Open WebUI UI-level E2E tests remain manual until v0.2 automates preset provisioning."
