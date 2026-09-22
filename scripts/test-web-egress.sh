#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"
require_user
require_env

dc exec -T open-webui python - <<'PY'
import urllib.request
req = urllib.request.Request(
    "https://duckduckgo.com/",
    headers={"User-Agent": "Mozilla/5.0 (X11; Linux aarch64) AppleWebKit/537.36 Chrome/126.0 Safari/537.36"},
)
with urllib.request.urlopen(req, timeout=15) as r:
    print("web-egress-ok", r.status, r.geturl())
PY
