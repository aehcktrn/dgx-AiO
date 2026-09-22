#!/usr/bin/env bash
source "$(dirname -- "$0")/common.sh"
require_user
require_env

for service in ollama open-webui; do
  cid="$(dc ps -q "$service")"
  [[ -n "$cid" ]] || { echo "[FAIL] container missing: $service" >&2; exit 1; }
  privileged="$(sudo docker inspect -f '{{.HostConfig.Privileged}}' "$cid")"
  [[ "$privileged" == false ]] || { echo "[FAIL] privileged container: $service" >&2; exit 1; }
  security="$(sudo docker inspect -f '{{json .HostConfig.SecurityOpt}}' "$cid")"
  grep -q "no-new-privileges:true" <<<"$security" || { echo "[FAIL] no-new-privileges missing: $service" >&2; exit 1; }
  mounts="$(sudo docker inspect -f '{{range .Mounts}}{{println .Source "->" .Destination}}{{end}}' "$cid")"
  if grep -Eq '(^|[[:space:]])/var/run/docker\.sock([[:space:]]|$)|^/ -> ' <<<"$mounts"; then
    echo "[FAIL] dangerous mount on $service:" >&2
    echo "$mounts" >&2
    exit 1
  fi
  echo "[OK] $service runtime security baseline"
done

[[ "$(systemctl show -p User --value dgx-comfy.service)" == dgx-comfy ]] || { echo "[FAIL] ComfyUI not running as dgx-comfy" >&2; exit 1; }
[[ "$(systemctl show -p NoNewPrivileges --value dgx-comfy.service)" == yes ]] || { echo "[FAIL] ComfyUI NoNewPrivileges disabled" >&2; exit 1; }
echo "[OK] ComfyUI runtime security baseline"
echo "runtime-security-ok"
