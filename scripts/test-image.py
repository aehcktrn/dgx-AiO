#!/usr/bin/env python3
"""Validate ComfyUI nodes, submit one image, verify history and the saved output file."""
from __future__ import annotations
import argparse
import json
import time
import urllib.error
import urllib.request
from pathlib import Path

def req(base: str, path: str, data=None):
    body = None if data is None else json.dumps(data).encode()
    request = urllib.request.Request(base + path, data=body, headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.load(response)
    except urllib.error.HTTPError as exc:
        raise RuntimeError(f"HTTP {exc.code}: {exc.read().decode(errors='replace')}") from exc

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", default="http://127.0.0.1:8188")
    parser.add_argument("--timeout", type=int, default=900)
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    workflow = json.loads((root / "workflows/z-image-turbo.api.json").read_text())
    catalog = req(args.base, "/object_info")

    for node_id, node in workflow.items():
        if node["class_type"] not in catalog:
            raise RuntimeError(f"Missing ComfyUI node: {node['class_type']}")
        required = catalog[node["class_type"]].get("input", {}).get("required", {})
        for key, spec in required.items():
            if key not in node["inputs"]:
                raise RuntimeError(f"Missing required input: {node_id}.{key}")
            value = node["inputs"][key]
            if isinstance(spec[0], list) and not isinstance(value, list) and value not in spec[0]:
                raise RuntimeError(f"Unavailable value: {node_id}.{key}={value!r}")

    reply = req(args.base, "/prompt", {"prompt": workflow, "client_id": "dgx-aio-smoke-test"})
    if reply.get("node_errors"):
        raise RuntimeError(json.dumps(reply["node_errors"], ensure_ascii=False))
    prompt_id = reply.get("prompt_id")
    if not prompt_id:
        raise RuntimeError(f"No prompt_id returned: {reply}")
    print(f"Generation submitted: {prompt_id}", flush=True)

    started = time.monotonic()
    output_root = (root / "comfy" / "ComfyUI" / "output").resolve()
    while time.monotonic() - started < args.timeout:
        entry = req(args.base, "/history/" + prompt_id).get(prompt_id)
        if entry:
            status = entry.get("status", {})
            if status.get("status_str") == "error":
                raise RuntimeError(json.dumps(entry, ensure_ascii=False))
            images = [image for output in entry.get("outputs", {}).values() for image in output.get("images", [])]
            if images:
                saved = []
                for image in images:
                    if image.get("type") != "output":
                        continue
                    candidate = (output_root / image.get("subfolder", "") / image.get("filename", "")).resolve()
                    if candidate != output_root and output_root not in candidate.parents:
                        raise RuntimeError(f"Unsafe output path returned by ComfyUI: {candidate}")
                    if not candidate.is_file() or candidate.stat().st_size == 0:
                        raise RuntimeError(f"ComfyUI history reports an image that is not on disk: {candidate}")
                    saved.append(str(candidate))
                if not saved:
                    raise RuntimeError("ComfyUI completed but no saved output image was verified.")
                print(json.dumps({"prompt_id": prompt_id, "elapsed_seconds": round(time.monotonic() - started, 2), "images": images, "verified_files": saved}, indent=2))
                return
        time.sleep(2)
    raise RuntimeError("Image verification timed out. Check ComfyUI before resubmitting.")

if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, RuntimeError) as exc:
        raise SystemExit(str(exc)) from exc
