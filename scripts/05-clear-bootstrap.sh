#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"
require_user
require_env

if [[ ! -f "$ROOT/.bootstrap-password" ]]; then
  echo "Bootstrap credential file already absent."
  exit 0
fi

read -r -p "Confirm you changed the Open WebUI admin password [y/N]: " answer
[[ "$answer" =~ ^[Yy]$ ]] || { echo "Nothing changed."; exit 1; }
rm -f "$ROOT/.bootstrap-password"
# Stop passing bootstrap credentials on future container recreations.
sed -i 's/^WEBUI_ADMIN_PASSWORD=.*/WEBUI_ADMIN_PASSWORD=/' "$ROOT/.env"
echo "Bootstrap credential removed."
