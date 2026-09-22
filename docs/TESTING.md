# Automated verification

The repository has two test layers.

## CI / no DGX required

GitHub Actions checks Bash syntax, Python syntax, workflow JSON syntax and repository consistency (version/manifest, Modelfiles, workflow contract, executable scripts and safe defaults).

Run locally:

```bash
python3 -m unittest discover -s tests -v
```

## On-device verification

### Quick

```bash
cd /srv/dgx-ai
bash scripts/verify.sh --quick
```

Checks preflight, service health, loopback bindings, model inventory and Open WebUI runtime connectivity. No LLM inference or image generation.

### Standard

```bash
bash scripts/verify.sh
```

Adds real inference through all four Ollama profiles, Native tool-calling on the Internet model, outbound web connectivity from Open WebUI, a real Z-Image generation, and verification that ComfyUI history points to a non-empty image actually written to disk.

The standard suite is automatically run at the end of a fresh install.

### Full acceptance

```bash
bash scripts/verify.sh --full
```

Adds service restart/recovery, post-restart inference, and a real Open WebUI backup with SHA-256 and archive-content verification.

Reports are written to `state/verify-*.json` and `state/verify-*.log`. The command returns non-zero if any check fails.

## Known v0.1 gap

Workspace presets are still created manually in Open WebUI. Therefore v0.1 cannot yet automate a true browser-to-Open-WebUI E2E test for Legacy image generation or Native `search_web` / `fetch_url` through the Workspace preset. Backend components are independently tested. Closing this gap is a v0.2 goal alongside automatic preset provisioning.
