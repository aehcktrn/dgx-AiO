#!/usr/bin/env bash
# End-to-end on-device acceptance test. Continues after failures and returns one final status.
set -uo pipefail
source "$(dirname -- "$0")/common.sh"
require_user
require_env

mode="standard"
case "${1:-}" in
  "") ;;
  --quick) mode="quick" ;;
  --full) mode="full" ;;
  *) echo "Usage: $0 [--quick|--full]" >&2; exit 2 ;;
esac

mkdir -p "$ROOT/state"
stamp="$(date -u +%Y%m%dT%H%M%SZ)"
log="$ROOT/state/verify-$stamp.log"
tsv="$ROOT/state/verify-$stamp.tsv"
json="$ROOT/state/verify-$stamp.json"
: > "$tsv"

pass=0
fail=0

run_check() {
  local name="$1"; shift
  echo
  echo "===== $name =====" | tee -a "$log"
  local start end rc
  start="$(date +%s)"
  set +e
  "$@" 2>&1 | tee -a "$log"
  rc=${PIPESTATUS[0]}
  set -e
  end="$(date +%s)"
  if (( rc == 0 )); then
    echo "[PASS] $name" | tee -a "$log"
    printf '%s\tPASS\t%s\n' "$name" "$((end-start))" >> "$tsv"
    pass=$((pass+1))
  else
    echo "[FAIL] $name (rc=$rc)" | tee -a "$log"
    printf '%s\tFAIL\t%s\n' "$name" "$((end-start))" >> "$tsv"
    fail=$((fail+1))
  fi
}

run_check "preflight" bash "$ROOT/scripts/00-preflight.sh"
run_check "doctor-core" bash "$ROOT/scripts/doctor.sh"
run_check "network-loopback" bash "$ROOT/scripts/test-network-bindings.sh"
run_check "model-inventory" python3 "$ROOT/scripts/test-model-inventory.py"
run_check "openwebui-runtime" bash "$ROOT/scripts/test-openwebui-runtime.sh"

if [[ "$mode" != quick ]]; then
  for model in cyber-reference cyber-libre discussion-libre internet-reference; do
    run_check "llm-$model" python3 "$ROOT/scripts/test-llm-health.py" --model "$model"
  done
  run_check "native-tool-calling-internet" python3 "$ROOT/scripts/test-tools.py" --model internet-reference
  run_check "web-egress" bash "$ROOT/scripts/test-web-egress.sh"
  run_check "image-generation" python3 "$ROOT/scripts/test-image.py"
fi

if [[ "$mode" == full ]]; then
  run_check "restart-persistence" bash "$ROOT/scripts/test-restart.sh"
  run_check "post-restart-doctor" bash "$ROOT/scripts/doctor.sh"
  run_check "post-restart-inference" python3 "$ROOT/scripts/test-llm-health.py" --model cyber-reference
  run_check "backup-integrity" bash "$ROOT/scripts/test-backup.sh"
fi

python3 - "$tsv" "$json" "$mode" "$stamp" <<'PY'
import csv
import json
import sys
from pathlib import Path

src, dst, mode, stamp = sys.argv[1:]
checks = []
with open(src, newline="", encoding="utf-8") as handle:
    for name, status, seconds in csv.reader(handle, delimiter="\t"):
        checks.append({"name": name, "status": status, "seconds": int(seconds)})
payload = {
    "timestamp_utc": stamp,
    "mode": mode,
    "passed": sum(c["status"] == "PASS" for c in checks),
    "failed": sum(c["status"] == "FAIL" for c in checks),
    "checks": checks,
}
Path(dst).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
PY

echo
echo "===== VERIFICATION SUMMARY =====" | tee -a "$log"
echo "mode=$mode pass=$pass fail=$fail" | tee -a "$log"
echo "report=$json" | tee -a "$log"
echo "log=$log" | tee -a "$log"

(( fail == 0 ))
