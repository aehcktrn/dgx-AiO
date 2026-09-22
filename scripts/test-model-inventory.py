#!/usr/bin/env python3
"""Verify all models/profiles required by v0.1 are present in the live Ollama daemon."""
from __future__ import annotations
import json
import urllib.request

REQUIRED = {
    "cyber-reference:latest",
    "cyber-libre:latest",
    "discussion-libre:latest",
    "internet-reference:latest",
    "qwen3-coder:30b-a3b-q4_K_M",
    "huihui_ai/qwen3-coder-abliterated:30b-a3b-instruct-q4_K_M",
    "huihui_ai/qwen3-abliterated:30b-a3b-instruct-2507-q4_K_M",
    "qwen3:30b-a3b-instruct-2507-q4_K_M",
    "bge-m3:latest",
}

with urllib.request.urlopen("http://127.0.0.1:11434/api/tags", timeout=15) as response:
    payload = json.load(response)
present = {item.get("name", "") for item in payload.get("models", [])}
missing = sorted(REQUIRED - present)
if missing:
    raise SystemExit("Missing Ollama model(s):\n- " + "\n- ".join(missing))
print(f"model-inventory-ok ({len(REQUIRED)} required models present)")
