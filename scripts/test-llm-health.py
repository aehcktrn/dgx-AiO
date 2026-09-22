#!/usr/bin/env python3
"""Fast deterministic inference probe for one local Ollama profile."""
from __future__ import annotations
import argparse
import json
import urllib.request

parser = argparse.ArgumentParser()
parser.add_argument("--model", required=True)
parser.add_argument("--timeout", type=int, default=300)
args = parser.parse_args()
marker = "DGX_AIO_OK"
payload = {
    "model": args.model,
    "stream": False,
    "prompt": f"Réponds uniquement par {marker}",
    "options": {"temperature": 0, "num_ctx": 2048, "num_predict": 32, "seed": 42},
}
request = urllib.request.Request(
    "http://127.0.0.1:11434/api/generate",
    data=json.dumps(payload).encode(),
    headers={"Content-Type": "application/json"},
)
with urllib.request.urlopen(request, timeout=args.timeout) as response:
    result = json.load(response)
text = result.get("response", "").strip()
if marker not in text:
    raise SystemExit(json.dumps({"model": args.model, "expected_marker": marker, "response": text}, ensure_ascii=False, indent=2))
print(json.dumps({"model": args.model, "status": "ok", "marker": marker,
    "load_seconds": round(result.get("load_duration", 0) / 1e9, 3),
    "eval_seconds": round(result.get("eval_duration", 0) / 1e9, 3)}, ensure_ascii=False))
