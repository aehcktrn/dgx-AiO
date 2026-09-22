#!/usr/bin/env python3
from __future__ import annotations
import argparse
import json
import urllib.request

p = argparse.ArgumentParser()
p.add_argument("--model", default="internet-reference")
a = p.parse_args()
payload = {
    "model": a.model,
    "stream": False,
    "messages": [{"role": "user", "content": "Call the ping tool with value test. Do not answer in plain text."}],
    "tools": [{
        "type": "function",
        "function": {
            "name": "ping",
            "description": "Test tool",
            "parameters": {
                "type": "object",
                "properties": {"value": {"type": "string"}},
                "required": ["value"],
            },
        },
    }],
}
req = urllib.request.Request(
    "http://127.0.0.1:11434/api/chat",
    data=json.dumps(payload).encode(),
    headers={"Content-Type": "application/json"},
)
with urllib.request.urlopen(req, timeout=180) as r:
    data = json.load(r)
message = data.get("message", {})
calls = message.get("tool_calls") or []
if not calls:
    raise SystemExit(json.dumps(data, ensure_ascii=False, indent=2))
print(json.dumps(calls, ensure_ascii=False, indent=2))
