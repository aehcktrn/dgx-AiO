#!/usr/bin/env python3
"""Verify that at least one resident Ollama model has GPU-resident weights."""
from __future__ import annotations
import json
import urllib.request

with urllib.request.urlopen("http://127.0.0.1:11434/api/ps", timeout=15) as response:
    payload=json.load(response)
models=payload.get("models", [])
if not models:
    raise SystemExit("No resident Ollama model; run an inference probe first.")
gpu=[{"name":m.get("name") or m.get("model"), "size_vram":int(m.get("size_vram") or 0)} for m in models]
if not any(item["size_vram"] > 0 for item in gpu):
    raise SystemExit("No GPU-resident Ollama weights reported: " + json.dumps(gpu))
print(json.dumps({"status":"ok","resident":gpu}))
