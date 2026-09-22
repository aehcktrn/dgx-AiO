#!/usr/bin/env bash
set -Eeuo pipefail

ports=(8080 8188 11434)
listeners="$(sudo ss -H -lnt)"

for port in "${ports[@]}"; do
  mapfile -t addresses < <(awk -v p=":${port}" '$4 ~ p"$" {print $4}' <<<"$listeners")
  if (( ${#addresses[@]} == 0 )); then
    echo "[FAIL] No listener on port $port" >&2
    exit 1
  fi
  for address in "${addresses[@]}"; do
    case "$address" in
      127.0.0.1:"$port"|[::1]:"$port") ;;
      *)
        echo "[FAIL] Port $port is exposed on unexpected address: $address" >&2
        exit 1
        ;;
    esac
  done
  echo "[OK] port $port bound to loopback only"
done
